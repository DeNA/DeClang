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
#include "llvm/Transforms/AntiHack/AntiHack.h"
#include "llvm/Transforms/AntiHack/Obfuscation.h"
#include <fstream>

using namespace llvm;


  bool AntiHack::doInitialization(Module &m)
  {
    if (!doAntiHack) {
      return false;
    }

    ModulePass *mp = static_cast<ModulePass*>(createObfuscation(&configJson, logFile, homeDir));
    mp->doInitialization(m);
    modulePasses.push_back(mp);

    return true;
  }

  PreservedAnalyses AntiHack::run(Module& m, ModuleAnalysisManager &AM)
  {
    bool modified = false;

    if (doAntiHack) {
      if (!initialized) {
        doInitialization(m);
        initialized = true;
      }

      for (ModulePass *p : modulePasses) {
        modified |= p->runOnModule(m);
      }

      for (FunctionPass *p : functionPasses) {
        for (Module::iterator iter = m.begin(); iter != m.end(); iter++) {
          Function &F = *iter;
          if (!F.isDeclaration()) {
            modified |= p->runOnFunction(F);
          }
        }
      }
    }
    return PreservedAnalyses::none();
  }

  AntiHack::AntiHack(std::string configPath)
    : configJson(0)
  {

    initialized = false;
    profilerPass = nullptr;
    logFile = nullptr;

    doAntiHack = true;
    char* home_dir = getenv("DECLANG_HOME");
    if (home_dir == nullptr) {
      home_dir = getenv("HOME");
    }
    if (home_dir == nullptr) {
      home_dir = getenv("USERPROFILE");
    }
    if (home_dir == nullptr) {
      llvm::errs() << "[Frontend]: (Warning) Cannot find $DECLANG_HOME, $HOME or %USERPROFILE%\n";
      llvm::errs().flush();
      std::exit(EXIT_FAILURE);
    }
    homeDir.assign(home_dir);
    homeDir = llvm::sys::path::convert_to_slash(homeDir);

    llvm::sys::fs::create_directory(homeDir+"/.DeClang/");

    if (configPath == "") {
      configPath = homeDir + "/.DeClang/config.json";
    }
    std::string logPath = homeDir + "/.DeClang/log.txt";
    std::error_code EC; 
    logFile = new llvm::raw_fd_ostream(logPath, EC, sys::fs::OF_Append);
    if (EC) {
      errs() << "[Frontend]: Open logFile Failed. Check DECLANG_HOME maybe?: " << EC.message() << "\n";
    }

    ifstream configFile(configPath);
    if (!configFile) {
      doAntiHack = false;
      (*logFile) << "[Frontend]: (Warning) Config file "<< configPath << " not found! Pass won't work'\n";
      logFile->flush();
      return;
    }

    std::string content(
        (std::istreambuf_iterator<char>(configFile) ),
        (std::istreambuf_iterator<char>() ) );

    // if content length is zero (which means no config file in ~/.DeClang/)
    // abort the rest handling
    if (content.length() == 0) {
      doAntiHack = false;
      (*logFile) << "[Frontend]: (Warning) Config "<< configPath << "'s JSON content length is 0, Pass won't work'!\n";
      logFile->flush();
      return;
    }

    llvm::Expected<llvm::json::Value> expectedConfig = llvm::json::parse(content.c_str());
    //configJson = llvm::json::parse(content.c_str());
    if (llvm::Error EC = expectedConfig.takeError()) {
      doAntiHack = false;
      (*logFile) << "[Frontend]: (Error) (AntiHack.cpp) Config Error: llvm::json::parse error \n";
      logFile->flush();
      return;
    }
    configJson = expectedConfig.get();
    if (!configJson.getAsObject()) {
      doAntiHack = false;
      (*logFile) << "[Frontend]: (Error) (AntiHack.cpp) Config Error: JSON is broken\n";
      logFile->flush();
      return;
    }

  }


//INITIALIZE_PASS(AntiHack, "AntiHack", "AntiHack Pass", false, false)

Pass* llvm::createAntiHack(std::string configPath) {
  //return new AntiHack(configPath);
}
