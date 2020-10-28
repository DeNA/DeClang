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

#include "llvm/InitializePasses.h"
#include "llvm-c/Initialization.h"
#include "llvm/PassRegistry.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/Pass.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/VirtualFileSystem.h"
#include "llvm/Transforms/AntiHack/Obfuscation.h"
#include "llvm/Transforms/AntiHack/Flattening.h"
#include "llvm/Transforms/AntiHack/SplitBasicBlock.h"
#include "llvm/Transforms/AntiHack/DynamicBranch.h"
#include <fstream>

using namespace llvm;

namespace {
  struct Obfuscation: ModulePass {
    static char ID;  // Pass identification, replacement for typeid

    std::vector<FunctionPass*> functionPasses;

    llvm::json::Value *configJson;
    llvm::raw_fd_ostream *logFile;
    std::string homeDir;
    bool doObfuscation;

    Obfuscation(): ModulePass(ID), logFile(nullptr), configJson(nullptr), doObfuscation(false) {};
    Obfuscation(llvm::json::Value *configJson, llvm::raw_fd_ostream *logFile, std::string homeDir);
    ~Obfuscation();

    virtual bool doInitialization(Module &m);
    bool runOnModule(Module &M);
  };

  bool Obfuscation::doInitialization(Module &m)
  {
    if (!doObfuscation) {
      return false;
    }
    FunctionPass *fp = static_cast<FunctionPass*>(createSplitBasicBlock(configJson, logFile, homeDir));
    functionPasses.push_back(fp);

    fp = static_cast<FunctionPass*>(createFlattening(configJson, logFile, homeDir));
    functionPasses.push_back(fp);

    fp = static_cast<FunctionPass*>(createDynamicBranch(configJson, logFile, homeDir));
    functionPasses.push_back(fp);
    return true;
  }

  bool Obfuscation::runOnModule(Module& m)
  {
    bool modified = false;

    if (doObfuscation) {
      for (FunctionPass* p : functionPasses) {
        for (Module::iterator iter = m.begin(); iter != m.end(); iter++) {
          Function &F = *iter;
          if (!F.isDeclaration()) {
            modified |= p->runOnFunction(F);
          }
        }
      }
    }
    return modified;
  }

  Obfuscation::Obfuscation(llvm::json::Value *configJson, llvm::raw_fd_ostream *logFile, std::string homeDir)
    : ModulePass(ID), configJson(configJson), logFile(logFile), homeDir(homeDir)
  {
    doObfuscation = true;
    llvm::json::Object *jsonObj = configJson->getAsObject();
    int enable_obf = jsonObj->getInteger("enable_obfuscation").getValueOr(1);
    if (!enable_obf) {
      doObfuscation = false;
      (*logFile) << "[Frontend]: (Info) enable_obf is 0, all obfuscations will be disabled.\n";
    }
  }

  Obfuscation::~Obfuscation()
  {
    for (Pass* p : functionPasses) {
      delete p;
    }
  }

} // namespace

char Obfuscation::ID = 0;
INITIALIZE_PASS(Obfuscation, "Obfuscation", "Obfuscation Pass", false, false)

Pass *llvm::createObfuscation(llvm::json::Value *configJson, llvm::raw_fd_ostream *logFile, std::string homeDir) {
  return new Obfuscation(configJson, logFile, homeDir);
}