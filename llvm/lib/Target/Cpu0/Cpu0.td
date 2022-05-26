//===-- Cpu0.td - Describe the Cpu0 Target Machine ----*- tablegen -*-===//
//
//                  The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.

//
//===----------------------------------------------------------------------===//
// This is the top level entry point for the Cpu0 target.
//===----------------------------------------------------------------------===//

// Cpu0.td, Cpu0RegisterInfo.td are included in Cpu0Asm.td and Cpu0Other.td

//===----------------------------------------------------------------------===//
// Target-dependent interfaces
//===----------------------------------------------------------------------===//

// Calling Conversion
include "Cpu0Schedule.td"

// Instruction Description
include "Cpu0InstrInfo.td"

// Calling Convention
include "Cpu0CallingConv.td"

//===----------------------------------------------------------------------===//
// Cpu0 SUbtarget features
//===----------------------------------------------------------------------===//

def FeatureCmp            : SubtargetFeature<"cmp", "HasCmp", "true",
                                             "Enable 'cmp' instructions.">;
def FeatureSlt            : SubtargetFeature<"slt", "HasSlt", "true",
                                             "Enable 'slt' instructions.">;
def FeatureCpu032I        : SubtargetFeature<"cpu032I", "Cpu0ArchVersion",
                                             "Cpu032I", "Cpu032I ISA Support",
                                             [FeatureCmp]>;
def FeatureCpu032II       : SubtargetFeature<"cpu032II", "Cpu0ArchVersion",
                                             "Cpu032II", "Cpu032II ISA Support",
                                             [FeatureCmp, FeatureSlt]>;

//===----------------------------------------------------------------------===//
// Cpu0 processors supported
//===----------------------------------------------------------------------===//
class Proc<string Name, list<SubtargetFeature> Features>
  : Processor<Name, Cpu0GenericItineraries, Features>;

def : Proc<"cpu032I", [FeatureCpu032I]>;
def : Proc<"cpu032II", [FeatureCpu032II]>;
// Above make Cpu0GenSubtargetInfo.inc set feature bit as the following order:
// enum {
//   FeatureCmp =  1ULL << 0,
//   FeatureCpu032I =  1ULL << 1,
//   FeatureCpu032II =  1ULL << 2,
//   FeatureSlt =  1ULL << 3
// };

def Cpu0InstrInfo : InstrInfo;

def Cpu0AsmParser : AsmParser {
  let ShouldEmitMatchRegisterName = 0;
}

def Cpu0AsmParserVariant : AsmParserVariant {
  int Variant = 0;

  // Recognize hard coded registers.
  string RegisterPrefix = "$";
}

// Whill generate Cpu0GenAsmWrite.inc included by Cpu0InstPrinter.cpp, contents
// as follows,
// void Cpu0InstPrinter::printInstruction(const MCInst *MI, raw_ostream &O) {...}
// const char* Cpu0InstPrinter::getRegisterName(unsigned RegNo) {...}
def Cpu0 : Target {
  // def Cpu0InstrInfo : InstrInfo as before.
  let InstructionSet = Cpu0InstrInfo;
  let AssemblyParsers = [Cpu0AsmParser];
  let AssemblyParserVariants = [Cpu0AsmParserVariant];
}
