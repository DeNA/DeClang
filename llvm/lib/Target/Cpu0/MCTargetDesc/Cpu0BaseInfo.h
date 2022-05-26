//===-- Cpu0BaseInfo.h - Top level definitions for CPU0 MC ------*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone helper functions and enum definitions for
// the Cpu0 target useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU0_MCTARGETDESC_CPU0BASEINFO_H
#define LLVM_LIB_TARGET_CPU0_MCTARGETDESC_CPU0BASEINFO_H

#include "Cpu0MCTargetDesc.h"
#include "Cpu0FixupKinds.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/DataTypes.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {

// Cpu0II - This namespace holds all of the target specific flags that
// instruction info tracks
namespace Cpu0II {
  // Target Operand Flag enum.
  enum TOF {
    MO_NO_FLAG,

    // MO_GOT_CALL: Represents the offset into the global offset table at
    // which the address of a call site relocation entry symbol resides
    // during execution. This is different from the above since this flag
    // can only be present in call instructions.
    MO_GOT_CALL,

    // MO_GOT16: Represents the offset into the global offset table at which
    // the address the relocation entry symbol resides during execution.
    MO_GOT16,
    MO_GOT,

    // MO_GPREL: Represents the offset from the current gp value to be used
    // for the relocatable object file being produced.
    MO_GPREL,

    // MO_ABS_HI/LO: Represents the high or low part of an absolute symbol
    // address.
    MO_ABS_HI,
    MO_ABS_LO,

    // MO_GOT_HI16/LO16: Relocations used for large GOTs.
    MO_GOT_HI16,
    MO_GOT_LO16,
  };

  // These are the standard/most common forms for Cpu0 instructions.
  enum {
    // Pseudo: This represents an instruction that is a pseudo instruction
    // or one that has not been implemented yet. It is illegal to code generate
    // it, but tolerated for internediate implementation stages.
    Pseudo = 0,

    // FrmR: This form is for instructions of the format R.
    FrmR = 1,

    // FrmI: This form is for instructions of the format I.
    FrmI = 2,

    // FrmJ: This form is for instructions of the format J.
    FrmJ = 3,

    // FrmOther: This form is for instructions that have no specific format.
    FrmOther = 4,

    FrmMask = 15
  };

} // end namespace Cpu0II
} // end namespace llvm

#endif