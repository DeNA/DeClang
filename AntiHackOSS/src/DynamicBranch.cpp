/*
 * Copyright 2020 DeNA Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "llvm/Transforms/AntiHack/DynamicBranch.h"
#include "llvm/Transforms/AntiHack/Obfuscation.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/CodeGen/IntrinsicLowering.h"
#include "llvm/Transforms/Utils.h"
#include "llvm/IR/ValueSymbolTable.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
#include "llvm/Linker/Linker.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/Regex.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/VirtualFileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/LineIterator.h"

#include <cstdlib>
#include <cstdio>
#include <ctime>
#include <fstream>
#include <vector>


#include "llvm/IR/GlobalValue.h"

#define DEBUG_TYPE "dynamicbranch"

using namespace llvm;

namespace {
  struct DynamicBranch: public FunctionPass {
    static char ID;  // Pass identification, replacement for typeid
    bool doDynamicBranch;
    int overallObf;

    std::string homeDir;
    llvm::json::Value* configJson;

    llvm::raw_fd_ostream *logFile;

    DynamicBranch() : FunctionPass(ID), configJson(0) {}
    DynamicBranch(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile);
    ~DynamicBranch();

    bool runOnFunction(Function &F);


    virtual StringRef getPassName() const {
      return "DynamicBranch Pass";
    }

  };
}

char DynamicBranch::ID = 0;
INITIALIZE_PASS(DynamicBranch, "DynamicBranch", "obfuscate branch instruction", false, false)

Pass *llvm::createDynamicBranch(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile, std::string homeDir) {
  return new DynamicBranch(configJson, logFile);
}

DynamicBranch::~DynamicBranch()
{
}

DynamicBranch::DynamicBranch(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile)
  : FunctionPass(ID), configJson(0)
{
  this->doDynamicBranch = true;
  this->logFile = logFile;
  this->configJson = configJson;

  llvm::json::Object *jsonObj = configJson->getAsObject();

  overallObf = jsonObj->getInteger("overall_obfuscation").getValueOr(0);
  if (overallObf == 0) {
    this->doDynamicBranch = false;
  }

  if (overallObf < 0 || overallObf > 100) {
    (*logFile) << "[Frontend]: Config Error: overall_obfuscation should be within 0 to 100.\n";
    this->doDynamicBranch = false;
  }
  else {
    (*logFile) << "[Frontend]: Doing overallObf: " << overallObf << "%\n";
  }

}


bool DynamicBranch::runOnFunction(Function &Func) 
{

  Module *m = Func.getParent();
  
#if 0
  IntrinsicLowering *IL = new IntrinsicLowering(m->getDataLayout());
  errs() << "lowering " << Func.getName() << "\n";
  for (inst_iterator I = inst_begin(Func); I != inst_end(Func); I++) {
    Instruction *Inst = &(*I);
    if (IntrinsicInst *II = dyn_cast<IntrinsicInst>(Inst)) {
      errs() << "lowering 1\n";
      IL->LowerIntrinsicCall(II);
    }
  }
  errs() << "lowering 2\n";
  delete IL;
#endif

  if (!this->doDynamicBranch) {
    return false;
  }

  //Module *m = Func.getParent();
  std::string triple = m->getTargetTriple();
  bool is64bit = false;
  if (triple.find("arm64") != std::string::npos || 
      triple.find("aarch64") != std::string::npos ||
      triple.find("x86_64") != std::string::npos) {
    is64bit = true;
  }

  std::vector<BranchInst*> condBrIns;
  for (inst_iterator I = inst_begin(Func); I != inst_end(Func); I++) {
    Instruction *Inst = &(*I);
    if (BranchInst *BI = dyn_cast<BranchInst>(Inst)) {
      if (BI->isConditional()) {
        condBrIns.push_back(BI);
      }
    }
  }
  int obfNum = (int)(((double)overallObf / 100) * condBrIns.size());

  //alloc an variable in advance instead of every time
  AllocaInst* ai;
  if (is64bit) {
    ai  = new AllocaInst(Type::getInt64Ty(m->getContext()), 0, "jumpdest", &Func.front().front());
  }
  else {
    ai  = new AllocaInst(Type::getInt32Ty(m->getContext()), 0, "jumpdest", &Func.front().front());
  }

  for (BranchInst* BI: condBrIns) {
    obfNum--;
    if (obfNum < 0) {
      break;
    }
    BasicBlock *TrueDest = BI->getSuccessor(0);//BI is a conditional branch
    BasicBlock *FalseDest = BI->getSuccessor(1);
    BlockAddress * TrueDestAddr = BlockAddress::get(TrueDest);
    BlockAddress * FalseDestAddr = BlockAddress::get(FalseDest);
    Value * ConditionValue = BI->getCondition();
    SelectInst * SI = SelectInst::Create(ConditionValue, TrueDestAddr, FalseDestAddr, "", BI);
#if 1
    StoreInst *si = new StoreInst(SI, ai, BI);
    LoadInst *li = new LoadInst(ai, "tmpload", BI);
    IndirectBrInst *indirBr = IndirectBrInst::Create(li, 2, BI);
    indirBr->addDestination(TrueDest);
    indirBr->addDestination(FalseDest);
#else
    IndirectBrInst *indirBr = IndirectBrInst::Create(SI, 2, BI);
    indirBr->addDestination(TrueDest);
    indirBr->addDestination(FalseDest);
#endif
    BI->eraseFromParent();

  }
  
  //if (Func.getName().find("run") != std::string::npos) {
  //  Func.dump();
  //  errs() << "===================\n";
  //}

  return true;
}

