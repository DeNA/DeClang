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
#include "llvm/Transforms/Scalar.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/IR/Instructions.h"
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
  
  void fixStack(Function *f);
  bool valueEscapes(Instruction *Inst);

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
      logFile->flush();

      llvm::Regex reFuncName(funcName);

      std::string seed = obj.getAsObject()->getString("seed")->str();
      if (reFuncName.match(F.getName()) && flattenedFuncs.find(F.getName().str()) == flattenedFuncs.end() ) {
        flattenedFuncs.insert(F.getName().str());
        (*logFile) << "[Frontend]: Flattening func " << F.getName() << "\n";
        if (flatten(&F, seed) ) {
          (*logFile) << "[Frontend]: Successfully flattened func " << F.getName() << "\n";
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

  //FIXME: when llvm vesion >= 9, call LowerSwtichPass will crash
#if LLVM_VERSION_MAJOR < 9
  // Lower switch
  FunctionPass *lower = createLowerSwitchPass();
  lower->runOnFunction(*f);
#else
#endif

  // Save all original BB
  for (Function::iterator i = f->begin(); i != f->end(); ++i) {
    BasicBlock *tmp = &*i;
    origBB.push_back(tmp);

    BasicBlock *bb = &*i;
    if (!isa<BranchInst>(bb->getTerminator()) && !isa<ReturnInst>(bb->getTerminator()) &&
        !isa<InvokeInst>(bb->getTerminator()) && !isa<UnreachableInst>(bb->getTerminator()) &&
        !isa<ResumeInst>(bb->getTerminator()) && !isa<SwitchInst>(bb->getTerminator()) ) {
      (*logFile) << "[Frontend]: (Warning) " << f->getName() << " Terminator Error. Not Flattening.\n";
      *(logFile) << "[Frontend]: Terminator is: \n";
      bb->getTerminator()->print(*logFile);
      *(logFile) << "\n";
      return false;
    }
  }

  // Nothing to flatten
  if (origBB.size() <= 1) {
    (*logFile) << f->getName() << "[Frontend]: (Warning) Function too small. Not Flattening.\n";
    return false;
  }
  if (origBB.size() > 5000) {
    (*logFile) << f->getName() << "[frontend]: bb count is 5000. skip flattening.\n";
    logFile->flush();
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

    //Dont put LandingPad in switch statement
    if (isa<LandingPadInst>(i->getFirstNonPHIOrDbgOrLifetime()) ) {
      continue;
    }

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

    //skip invalid terminator BB
    if (isa<InvokeInst>(i->getTerminator()) ||
        isa<UnreachableInst>(i->getTerminator()) ||
        isa<ResumeInst>(i->getTerminator()) || 
        isa<SwitchInst>(i->getTerminator()) ) {
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
  
  //f->print(*logFile);
  //logFile->flush();
  this->fixStack(f);
  return true;
}

// Try to remove phi node and demote reg to stack
void Flattening::fixStack(Function *f)
{
  // Insert all new allocas into entry block.
  BasicBlock *BBEntry = &f->getEntryBlock();
  assert(pred_empty(BBEntry) &&
      "Entry block to function must not have predecessors!");

  // Find first non-alloca instruction and create insertion point. This is
  // safe if block is well-formed: it always have terminator, otherwise
  // we'll get and assertion.
  BasicBlock::iterator I = BBEntry->begin();
  while (isa<AllocaInst>(I)) ++I;

  CastInst *AllocaInsertionPoint = new BitCastInst(
      Constant::getNullValue(Type::getInt32Ty(f->getContext())),
      Type::getInt32Ty(f->getContext()), "reg2mem alloca point", &*I);

  // Find the escaped instructions. But don't create stack slots for
  // allocas in entry block.
  std::list<Instruction*> WorkList;
  for (BasicBlock &ibb : *f)
    for (BasicBlock::iterator iib = ibb.begin(), iie = ibb.end(); iib != iie;
        ++iib) {
      if (!(isa<AllocaInst>(iib) && iib->getParent() == BBEntry) &&
          valueEscapes(&*iib)) {
        WorkList.push_front(&*iib);
      }
    }

  // Demote escaped instructions
  //NumRegsDemoted += WorkList.size();
  for (Instruction *ilb : WorkList) {
    DemoteRegToStack(*ilb, false, AllocaInsertionPoint);
  }

  WorkList.clear();

  // Find all phi's
  for (BasicBlock &ibb : *f)
    for (BasicBlock::iterator iib = ibb.begin(), iie = ibb.end(); iib != iie;
        ++iib)
      if (isa<PHINode>(iib))
        WorkList.push_front(&*iib);

  // Demote phi nodes
  //NumPhisDemoted += WorkList.size();
  for (Instruction *ilb : WorkList)
    DemotePHIToStack(cast<PHINode>(ilb), AllocaInsertionPoint);
}

bool Flattening::valueEscapes(Instruction *Inst) {
  const BasicBlock *BB = Inst->getParent();
  for (const User *U : Inst->users()) {
    const Instruction *UI = cast<Instruction>(U);
    if (UI->getParent() != BB || isa<PHINode>(UI))
      return true;
  }
  return false;
}
