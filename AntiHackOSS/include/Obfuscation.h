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

#ifndef _OBFUSCATION_INCLUDES_
#define _OBFUSCATION_INCLUDES_

#include "llvm/Pass.h"
#include "llvm/IR/Function.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Transforms/IPO.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/JSON.h"

using namespace std;

namespace llvm {
  void initializeObfuscationPass(PassRegistry &Registry);
  Pass *createObfuscation(llvm::json::Value* configJson, llvm::raw_fd_ostream *logFile, std::string homeDir);
}

#endif
