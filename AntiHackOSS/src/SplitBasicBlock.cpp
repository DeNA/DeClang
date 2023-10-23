//===- SplitBasicBlock.cpp - SplitBasicBlock Obfuscation pass--------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the split basic block pass
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/AntiHack/Obfuscation.h"
#include "llvm/Transforms/AntiHack/SplitBasicBlock.h"
#include "llvm/Transforms/AntiHack/Utils.h"
#include "llvm/Transforms/AntiHack/CryptoUtils.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/Regex.h"
#include <set>

#define DEBUG_TYPE "split"

using namespace llvm;
using namespace std;

// Stats
//STATISTIC(Split, "Basicblock splitted");

namespace {
struct SplitBasicBlock : public FunctionPass {
  static char ID; // Pass identification, replacement for typeid
  bool flag;
  std::set<std::string> splittedFuncs;

  llvm::json::Value* configJson;

  std::string homeDir;
  bool doSplit;
  llvm::raw_fd_ostream *logFile;

  SplitBasicBlock() : FunctionPass(ID), configJson(0) {}
  SplitBasicBlock(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile);

  bool runOnFunction(Function &F);
  void split(Function *f, int SplitNum, std::string seed);

  bool containsPHI(BasicBlock *b);
  void shuffle(std::vector<int> &vec);
};
}

char SplitBasicBlock::ID = 0;
INITIALIZE_PASS(SplitBasicBlock, "split_basic_block", "Split Basic Block", false, false)

Pass *llvm::createSplitBasicBlock(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile, std::string homeDir) {
  return new SplitBasicBlock(configJson, logFile);
}

SplitBasicBlock::SplitBasicBlock(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile) : FunctionPass(ID), configJson(0) 
{ 
  this->doSplit = true;
  this->configJson = configJson;
  this->logFile = logFile;
}

bool SplitBasicBlock::runOnFunction(Function &F) {
  // Check if the number of applications is correct
  if (!this->doSplit) {
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
      llvm::Regex reFuncName(funcName);

      std::string seed = obj.getAsObject()->getString("seed")->str();
      int SplitNum = obj.getAsObject()->getInteger("split_level").getValueOr(0);
      if (!((SplitNum >= 0) && (SplitNum <= 10))) {
        (*logFile) << "[Frontend]: Config Error: split_level should be 0 to 10.\n";
        return false;
      }
      //only split function once
      if (reFuncName.match(F.getName()) && splittedFuncs.find(F.getName().str()) == splittedFuncs.end() ) {
        splittedFuncs.insert(F.getName().str());
        Function *tmp = &F;
        (*logFile) << "[Frontend]: Splitting " << F.getName() << " by " << SplitNum << "\n";
        split(tmp, SplitNum, seed);
      }

    }
  }

  return true;
}

void SplitBasicBlock::split(Function *f, int SplitNum, std::string seed) {

  if (seed.size() == 0) {
    (*logFile) << "[Frontend]: Split Warning: missing 'seed' in flatten array\n";
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
    if ((size_t)splitN >= curr->size()) {
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
    for (int i = 0; i < splitN-1; ++i) {
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

bool SplitBasicBlock::containsPHI(BasicBlock *b) {
  for (BasicBlock::iterator I = b->begin(), IE = b->end(); I != IE; ++I) {
    if (isa<PHINode>(I)) {
      return true;
    }
  }
  return false;
}

void SplitBasicBlock::shuffle(std::vector<int> &vec) {
  int n = vec.size();
  for (int i = n - 1; i > 0; --i) {
    std::swap(vec[i], vec[cryptoutils->get_uint32_t() % (i + 1)]);
  }
}

