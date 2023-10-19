//===- Flattening.cpp - Flattening Obfuscation pass------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the flattening pass
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/AntiHack/Flattening.h"
#include "llvm/Transforms/AntiHack/Obfuscation.h"
#include "llvm/Transforms/AntiHack/CryptoUtils.h"
#include "llvm/Transforms/AntiHack/Utils.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/IR/Constants.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/Regex.h"
#include "llvm/Transforms/Utils.h"
#include <fstream>
#include <set>

#define DEBUG_TYPE "flattening"

using namespace llvm;

// Stats
//STATISTIC(Flattened, "Functions flattened");

namespace {
struct Flattening : public FunctionPass {
  static char ID;  // Pass identification, replacement for typeid
  llvm::json::Value* configJson;

  std::string homeDir;
  bool doFlattening;
  llvm::raw_fd_ostream *logFile;
  std::set<std::string> flattenedFuncs;

  Flattening() : FunctionPass(ID), configJson(0) {}
  Flattening(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile);
  ~Flattening();
  bool runOnFunction(Function &F);
  bool flatten(Function *f, std::string seed);

  void split(Function *f, int SplitNum, const std::string seed);
  bool containsPHI(BasicBlock *b);
  void shuffle(std::vector<int> &vec);
};
}

char Flattening::ID = 0;
INITIALIZE_PASS(Flattening, "flattening", "Call graph Flattening", false, false)

Pass *llvm::createFlattening(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile, std::string homeDir) {
  return new Flattening(configJson, logFile);
}

Flattening::Flattening(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile) : FunctionPass(ID), configJson(0) 
{ 
  this->doFlattening = true;
  this->configJson = configJson;
  this->logFile = logFile;

}

Flattening::~Flattening()
{
}

bool Flattening::runOnFunction(Function &F) {
  if (!this->doFlattening) {
    return false;
  }

  llvm::json::Object *jsonObj = configJson->getAsObject();
  if (jsonObj->getArray("flatten")) {
    llvm::json::Array *flattenArray = jsonObj->getArray("flatten");

    for (auto &obj : *flattenArray) {
      if (!obj.getAsObject()->getString("name")) {
        (*logFile) << "[Frontend]: Config Error: missing 'name' string object in flatten array\n";
        std::exit(EXIT_FAILURE);
      }

      std::string funcName = obj.getAsObject()->getString("name")->str();
      //(*logFile) << "[Frontend]: flattening, try match " << F.getName() << " with " << funcName << "\n";
      //logFile->flush();

      llvm::Regex reFuncName(funcName);

      std::string seed = obj.getAsObject()->getString("seed")->str();
      if (reFuncName.match(F.getName()) && flattenedFuncs.find(F.getName().str()) == flattenedFuncs.end() ) {
        flattenedFuncs.insert(F.getName().str());
        (*logFile) << "[Frontend]: Flattening func " << F.getName() << "\n";
        //F.print(*logFile);
        if (flatten(&F, seed) ) {
          (*logFile) << "[Frontend]: Successfully flattened func " << F.getName() << "\n";
          //F.print(*logFile);
          logFile->flush();
        }
      }
    }
  }

  return false;
}

bool Flattening::flatten(Function *f, std::string seed) {
  vector<BasicBlock *> origBB;
  BasicBlock *loopEntry;
  BasicBlock *loopEnd;
  LoadInst *load;
  SwitchInst *switchI;
  AllocaInst *switchVar;

  // SCRAMBLER
  if (seed.size() == 0) {
    (*logFile) << "[Frontend]: Config Error: missing 'seed' in flatten array\n";
  }
  llvm::cryptoutils->prng_seed(seed);
  char scrambling_key[16];
  llvm::cryptoutils->get_bytes(scrambling_key, 16);
  // END OF SCRAMBLER

  //FIXME: when llvm version >= 9, call LowerSwitchPass will crash
#if LLVM_VERSION_MAJOR < 9
  // Lower switch
  FunctionPass *lower = createLowerSwitchPass();
  lower->runOnFunction(*f);
#else
#endif

  // Save all original BB
  for (Function::iterator i = f->begin(); i != f->end(); ++i) {
    BasicBlock *tmp = &*i;
    //tmp->print(*logFile);
    if (tmp->isEHPad() || tmp->isLandingPad() || isa<InvokeInst>(tmp->getTerminator()) ) {
          (*logFile) << f->getName() << "[Frontend]: (Warning) Exception handing instructions is unsupported for flattening "
            "in DeClang OSS version. Contact us if you really need to flatten functions with exception handling.\n";
          return false;
    }
    origBB.push_back(tmp);

    BasicBlock *bb = &*i;
    if (!isa<BranchInst>(bb->getTerminator()) && !isa<ReturnInst>(bb->getTerminator()) &&
         !isa<UnreachableInst>(bb->getTerminator()) ) {
      (*logFile) << "[Frontend]: (Warning) " << f->getName() << " Terminator Error. Not Flattening.\n";
      (*logFile) << "terminator: ";
      bb->getTerminator()->print(*logFile);
      return false;
    }
  }

  // Nothing to flatten
  if (origBB.size() <= 1) {
    (*logFile) << f->getName() << "[Frontend]: (Warning) Function too small. Not Flattening.\n";
    return false;
  }

  // Remove first BB
  origBB.erase(origBB.begin());

  // Get a pointer on the first BB
  Function::iterator tmp = f->begin(); //++tmp;
  BasicBlock *insert = &*tmp;

  BranchInst *br = NULL;
  if (isa<BranchInst>(insert->getTerminator())) {
    br = cast<BranchInst>(insert->getTerminator());
  }

  // always split first BB
  if ((br != NULL/* && br->isConditional()*/) ||
      insert->getTerminator()->getNumSuccessors() > 1) {
    BasicBlock::iterator i = insert->end();
    --i;

    if (insert->size() > 1) {
      --i;
    }

    BasicBlock *tmpBB = insert->splitBasicBlock(i, "first");
    origBB.insert(origBB.begin(), tmpBB);
  }

  // Remove jump
  Instruction* oldTerm=insert->getTerminator();

  // Create switch variable and set as it
  switchVar =
      new AllocaInst(Type::getInt32Ty(f->getContext()), 0, "switchVar",oldTerm);
  oldTerm->eraseFromParent();
  new StoreInst(
      ConstantInt::get(Type::getInt32Ty(f->getContext()),
                       llvm::cryptoutils->scramble32(0, scrambling_key)),
      switchVar, insert);

  // Create main loop
  loopEntry = BasicBlock::Create(f->getContext(), "loopEntry", f, insert);
  loopEnd = BasicBlock::Create(f->getContext(), "loopEnd", f, insert);

  load = new LoadInst(Type::getInt32Ty(f->getContext()), switchVar, "switchVar", loopEntry);

  // Move first BB on top
  insert->moveBefore(loopEntry);
  BranchInst::Create(loopEntry, insert);

  // loopEnd jump to loopEntry
  BranchInst::Create(loopEntry, loopEnd);

  BasicBlock *swDefault =
      BasicBlock::Create(f->getContext(), "switchDefault", f, loopEnd);
  BranchInst::Create(loopEnd, swDefault);

  // Create switch instruction itself and set condition
  switchI = SwitchInst::Create(&*f->begin(), swDefault, 0, loopEntry);
  switchI->setCondition(load);

  // Remove branch jump from 1st BB and make a jump to the while
  f->begin()->getTerminator()->eraseFromParent();

  BranchInst::Create(loopEntry, &*f->begin());

  // Put all BB in the switch
  for (vector<BasicBlock *>::iterator b = origBB.begin(); b != origBB.end();
       ++b) {
    BasicBlock *i = *b;
    ConstantInt *numCase = NULL;

    // Move the BB inside the switch (only visual, no code logic)
    i->moveBefore(loopEnd);

    // Add case to switch
    numCase = cast<ConstantInt>(ConstantInt::get(
        switchI->getCondition()->getType(),
        llvm::cryptoutils->scramble32(switchI->getNumCases(), scrambling_key)));
    switchI->addCase(numCase, i);
  }

  // Recalculate switchVar
  for (vector<BasicBlock *>::iterator b = origBB.begin(); b != origBB.end();
       ++b) {
    BasicBlock *i = *b;
    ConstantInt *numCase = NULL;

    // Ret BB
    if (i->getTerminator()->getNumSuccessors() == 0) {
      continue;
    }

    // If it's a non-conditional jump
    if (i->getTerminator()->getNumSuccessors() == 1) {
      // Get successor and delete terminator
      BasicBlock *succ = i->getTerminator()->getSuccessor(0);
      i->getTerminator()->eraseFromParent();

      // Get next case
      numCase = switchI->findCaseDest(succ);

      // If next case == default case (switchDefault)
      if (numCase == NULL) {
        numCase = cast<ConstantInt>(
            ConstantInt::get(switchI->getCondition()->getType(),
                             llvm::cryptoutils->scramble32(
                                 switchI->getNumCases() - 1, scrambling_key)));
      }

      // Update switchVar and jump to the end of loop
      new StoreInst(numCase, load->getPointerOperand(), i);
      BranchInst::Create(loopEnd, i);
      continue;
    }

    // If it's a conditional jump
    if (i->getTerminator()->getNumSuccessors() == 2) {
      // Get next cases
      ConstantInt *numCaseTrue =
          switchI->findCaseDest(i->getTerminator()->getSuccessor(0));
      ConstantInt *numCaseFalse =
          switchI->findCaseDest(i->getTerminator()->getSuccessor(1));

      // Check if next case == default case (switchDefault)
      if (numCaseTrue == NULL) {
        numCaseTrue = cast<ConstantInt>(
            ConstantInt::get(switchI->getCondition()->getType(),
                             llvm::cryptoutils->scramble32(
                                 switchI->getNumCases() - 1, scrambling_key)));
      }

      if (numCaseFalse == NULL) {
        numCaseFalse = cast<ConstantInt>(
            ConstantInt::get(switchI->getCondition()->getType(),
                             llvm::cryptoutils->scramble32(
                                 switchI->getNumCases() - 1, scrambling_key)));
      }

      // Create a SelectInst
      BranchInst *br = cast<BranchInst>(i->getTerminator());
      SelectInst *sel =
          SelectInst::Create(br->getCondition(), numCaseTrue, numCaseFalse, "",
                             i->getTerminator());

      // Erase terminator
      i->getTerminator()->eraseFromParent();
      // Update switchVar and jump to the end of loop
      new StoreInst(sel, load->getPointerOperand(), i);
      BranchInst::Create(loopEnd, i);
      continue;
    }
  }
  //f->dump();
  fixStack(f);
  return true;
}

void Flattening::split(Function *f, int SplitNum, string seed) {

  if (seed.size() == 0) {
    (*logFile) << "[Frontend]: Config Error: missing 'seed' in flatten array\n";
  }
  llvm::cryptoutils->prng_seed(seed);


  std::vector<BasicBlock *> origBB;
  int splitN = SplitNum;

  // Save all basic blocks
  for (Function::iterator I = f->begin(), IE = f->end(); I != IE; ++I) {
    origBB.push_back(&*I);
  }

  for (std::vector<BasicBlock *>::iterator I = origBB.begin(),
                                           IE = origBB.end();
       I != IE; ++I) {
    BasicBlock *curr = *I;

    // No need to split a 1 inst bb
    // Or ones containing a PHI node
    if (curr->size() < 2 || containsPHI(curr)) {
      continue;
    }

    // Check splitN and current BB size
    if ((size_t)splitN > curr->size()) {
      splitN = curr->size() - 1;
    }

    // Generate splits point
    std::vector<int> test;
    for (unsigned i = 1; i < curr->size(); ++i) {
      test.push_back(i);
    }

    // Shuffle
    if (test.size() != 1) {
      shuffle(test);
      std::sort(test.begin(), test.begin() + splitN);
    }

    // Split
    BasicBlock::iterator it = curr->begin();
    BasicBlock *toSplit = curr;
    int last = 0;
    for (int i = 0; i < splitN; ++i) {
      for (int j = 0; j < test[i] - last; ++j) {
        ++it;
      }
      last = test[i];
      if(toSplit->size() < 2)
        continue;
      toSplit = toSplit->splitBasicBlock(it, toSplit->getName() + ".split");
    }

  }
}

bool Flattening::containsPHI(BasicBlock *b) {
  for (BasicBlock::iterator I = b->begin(), IE = b->end(); I != IE; ++I) {
    if (isa<PHINode>(I)) {
      return true;
    }
  }
  return false;
}

void Flattening::shuffle(std::vector<int> &vec) {
  int n = vec.size();
  for (int i = n - 1; i > 0; --i) {
    std::swap(vec[i], vec[cryptoutils->get_uint32_t() % (i + 1)]);
  }
}
