//===-- Cpu0MCAsmInfo.h - Cpu0 Asm Info -------------------------*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the Cpu0MCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU0_MCTARGETDESC_CPU0MCASMINFO_H
#define LLVM_LIB_TARGET_CPU0_MCTARGETDESC_CPU0MCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
  class Triple;

  class Cpu0MCAsmInfo : public MCAsmInfoELF {
    void anchor() override;
  public:
    explicit Cpu0MCAsmInfo(const Triple &TheTriple);
  };

} // end namespace llvm

#endif
