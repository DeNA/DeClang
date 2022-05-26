//===-- Cpu0MachineFunctionInfo.cpp - Private data used for Cpu0 -*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Cpu0 specific subclass of MachineFunctionInfo.
//
//===----------------------------------------------------------------------===//

#include "Cpu0MachineFunctionInfo.h"

#include "Cpu0InstrInfo.h"
#include "Cpu0Subtarget.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"

using namespace llvm;

bool FixGlobalBaseReg;

Cpu0MachineFunctionInfo::~Cpu0MachineFunctionInfo() { }

bool Cpu0MachineFunctionInfo::globalBaseRegFixed() const {
  return FixGlobalBaseReg;
}

bool Cpu0MachineFunctionInfo::globalBaseRegSet() const {
  return GlobalBaseReg;
}

unsigned Cpu0MachineFunctionInfo::getGlobalBaseReg() {
  return GlobalBaseReg = Cpu0::GP;
}

void Cpu0MachineFunctionInfo::anchor() { }

MachinePointerInfo Cpu0MachineFunctionInfo::callPtrInfo(const char *ES) {
  return MachinePointerInfo(MF.getPSVManager().getExternalSymbolCallEntry(ES));
}

MachinePointerInfo Cpu0MachineFunctionInfo::callPtrInfo(const GlobalValue *GV) {
  return MachinePointerInfo(MF.getPSVManager().getGlobalValueCallEntry(GV));
}

