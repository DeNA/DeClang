//===-- Cpu0ABIInfo.cpp - Information about Cpu0 ABI ------------*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Design for Cpu0 Application Binary Interface.
//
//===----------------------------------------------------------------------===//

#include "Cpu0ABIInfo.h"
#include "Cpu0RegisterInfo.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

static cl::opt<bool>
EnableCpu0S32Calls("cpu0-s32-calls", cl::Hidden,
                   cl::desc("CPU0 S32 call: use stack only to pass arguments."),
                   cl::init(false));

namespace {
  static const MCPhysReg O32IntRegs[4] = {Cpu0::A0, Cpu0::A1};
  static const MCPhysReg S32IntRegs = {};
}

const ArrayRef<MCPhysReg> Cpu0ABIInfo::GetByValArgRegs() const {
  if (IsO32())
    return makeArrayRef(O32IntRegs);
  if (IsS32())
    return makeArrayRef(S32IntRegs);

  llvm_unreachable("Unhandled ABI");
}

const ArrayRef<MCPhysReg> Cpu0ABIInfo::GetVarArgRegs() const {
  if (IsO32())
    return makeArrayRef(O32IntRegs);
  if (IsS32())
    return makeArrayRef(S32IntRegs);

  llvm_unreachable("Unhandled ABI");
}

unsigned Cpu0ABIInfo::GetCalleeAllocdArgSizeInBytes(CallingConv::ID CC) const {
  if (IsO32())
    return CC != 0;
  if (IsS32())
    return 0;

  llvm_unreachable("Unhandled ABI");
}

Cpu0ABIInfo Cpu0ABIInfo::computeTargetABI() {
  Cpu0ABIInfo abi(ABI::Unknown);

  if (EnableCpu0S32Calls)
    abi = ABI::S32;
  else
    abi = ABI::O32;

  // Assert exactly one ABI was chosen.
  assert(abi.ThisABI != ABI::Unknown);

  return abi;
}

unsigned Cpu0ABIInfo::GetStackPtr() const { return Cpu0::SP; }

unsigned Cpu0ABIInfo::GetFramePtr() const { return Cpu0::FP; }

unsigned Cpu0ABIInfo::GetNullPtr() const { return Cpu0::ZERO; }

unsigned Cpu0ABIInfo::GetEhDataReg(unsigned I) const {
  static const unsigned EhDataReg[] = { Cpu0::A0, Cpu0::A1 };

  return EhDataReg[I];
}

int Cpu0ABIInfo::EhDataRegSize() const {
  if (ThisABI == ABI::S32)
    return 0;
  else
    return 2;
}
