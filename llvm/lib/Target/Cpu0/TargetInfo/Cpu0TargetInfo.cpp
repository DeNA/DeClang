//===-- Cpu0TargetInfo.cpp - Cpu0 Target Implementation ---------*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Cpu0.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

Target &llvm::getTheCpu0Target() {
  static Target TheCpu0Target;
  return TheCpu0Target;
}
Target &llvm::getTheCpu0elTarget() {
  static Target TheCpu0elTarget;
  return TheCpu0elTarget;
}

extern "C" void LLVMInitializeCpu0TargetInfo() {
  RegisterTarget<Triple::cpu0, /*HasJIT=*/true> X(getTheCpu0Target(),
                                                  "cpu0", "Cpu0", "Cpu0");

  RegisterTarget<Triple::cpu0el, /*HasJIT=*/true> Y(getTheCpu0elTarget(),
                                                    "cpu0el", "Cpu0el", "Cpu0");
}