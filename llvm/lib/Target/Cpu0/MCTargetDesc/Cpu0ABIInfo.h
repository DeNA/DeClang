//===-- Cpu0ABIInfo.h - Information about Cpu0 ABI --------------*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU0_MCTARGETDESC_CPU0ABIINFO_H
#define LLVM_LIB_TARGET_CPU0_MCTARGETDESC_CPU0ABIINFO_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/Triple.h"
#include "llvm/IR/CallingConv.h"
#include "llvm/MC/MCRegisterInfo.h"

namespace llvm {

class MCTargetOptions;
class StringRef;
class TargetRegisterClass;

class Cpu0ABIInfo {
public:
  enum class ABI { Unknown, O32, S32 };

protected:
  ABI ThisABI;

public:
  Cpu0ABIInfo(ABI ThisABI) : ThisABI(ThisABI) { }

  static Cpu0ABIInfo Unknown() { return Cpu0ABIInfo(ABI::Unknown); }
  static Cpu0ABIInfo O32() { return Cpu0ABIInfo(ABI::O32); }
  static Cpu0ABIInfo S32() { return Cpu0ABIInfo(ABI::S32); }
  static Cpu0ABIInfo computeTargetABI();

  bool IsKnown() const { return ThisABI != ABI::Unknown; }
  bool IsO32() const { return ThisABI == ABI::O32; }
  bool IsS32() const { return ThisABI == ABI::S32; }
  ABI GetEnumValue() const { return ThisABI; }

  // The registers to use for byval arguments
  const ArrayRef<MCPhysReg> GetByValArgRegs() const;

  // The registers to use for variable argument list
  const ArrayRef<MCPhysReg> GetVarArgRegs() const;

  // Obtain the size of the area allocated by the callee for arguments
  // CallingConv::FastCall affects the value for O32
  unsigned GetCalleeAllocdArgSizeInBytes(CallingConv::ID CC) const;

  // Cpu0GenSubtargetInfo.inc will use this to resolve conflicts when given
  // multiple ABI options
  bool operator<(const Cpu0ABIInfo Other) const {
    return ThisABI < Other.GetEnumValue();
  }

  unsigned GetStackPtr() const;
  unsigned GetFramePtr() const;
  unsigned GetNullPtr() const;

  unsigned GetEhDataReg(unsigned I) const;
  int EhDataRegSize() const;
};
} // End llvm namespace

#endif
