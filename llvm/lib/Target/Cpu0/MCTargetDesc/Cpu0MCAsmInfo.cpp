//===-- Cpu0MCAsmInfo.cpp - Cpu0 Asm Info -----------------------*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the definitions of the Cpu0MCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#include "Cpu0MCAsmInfo.h"

#include "llvm/ADT/Triple.h"

using namespace llvm;

void Cpu0MCAsmInfo::anchor() { }

Cpu0MCAsmInfo::Cpu0MCAsmInfo(const Triple &TheTriple) {
  if ((TheTriple.getArch() == Triple::cpu0))
    IsLittleEndian = false;  // the default is true

  AlignmentIsInBytes  = false;
  Data16bitsDirective = "\t.2byte\t";
  Data32bitsDirective = "\t.4byte\t";
  Data64bitsDirective = "\t.8byte\t";
  PrivateGlobalPrefix = "$";
  PrivateLabelPrefix  = "$";
  CommentString       = "#";
  ZeroDirective       = "\t.space\t";
  GPRel32Directive    = "\t.gpword\t";
  GPRel64Directive    = "\t.gpdword\t";
  WeakRefDirective    = "\t.weak\t";
  UseAssignmentForEHBegin  = true;

  SupportsDebugInformation = true;
  ExceptionsType           = ExceptionHandling::DwarfCFI;
  DwarfRegNumForCFI        = true;
}
