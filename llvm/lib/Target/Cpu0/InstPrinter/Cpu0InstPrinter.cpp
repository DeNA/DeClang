//===-- Cpu0InstPrinter.cpp - Convert MCInst to assembly syntax -*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an Cpu0 MCInst to an assembly file.
//
//===----------------------------------------------------------------------===//

#include "Cpu0InstPrinter.h"

#include "Cpu0.h"
#include "MCTargetDesc/Cpu0MCExpr.h"
#include "Cpu0InstrInfo.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"

#define PRINT_ALIAS_INSTR
#include "Cpu0GenAsmWriter.inc"

void Cpu0InstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const {
  // getRegisterName(RegNo) defiend in Cpu0GenAsmWriter.inc which indicate in Cpu0.td
  OS << '$' << StringRef(getRegisterName(RegNo)).lower();
}

void Cpu0InstPrinter::printInst(const MCInst *MI,uint64_t Address, StringRef Annot,
                 const MCSubtargetInfo &STI, raw_ostream &O) {
  // Try to print any aliases first
  if (!printAliasInstr(MI, Address, O))
    // printInstruction(MI, O) defined in Cpu0GenAsmWriter.inc which came from
    // Cpu0.td indicate.
    printInstruction(MI, Address, O);
  printAnnotation(O, Annot);
}

void Cpu0InstPrinter::printOperand(const MCInst *MI, uint64_t Address, unsigned OpNo,
                                   raw_ostream &O) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    printRegName(O, Op.getReg());
    return;
  }

  if (Op.isImm()) {
    O << Op.getImm();
    return;
  }

  assert(Op.isExpr() && "unknown operand kind in printOperand");
  Op.getExpr()->print(O, &MAI, true);
}

void Cpu0InstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &O) {
  printOperand(MI, 0, OpNo, O);
}

void Cpu0InstPrinter::printUnsignedImm(const MCInst *MI, int OpNum,
                                       raw_ostream &O) {
  const MCOperand &MO = MI->getOperand(OpNum);
  if (MO.isImm())
    O << (unsigned short int)MO.getImm();
  else
    printOperand(MI, OpNum, O);
}

void Cpu0InstPrinter::printMemOperand(const MCInst *MI, int OpNum,
                                      raw_ostream &O) {
  // Load/Store memory operands => imm($reg)
  // If PIC target, the target is loaded as the
  // pattern => ld $t9, %call16(%gp)
  printOperand(MI, OpNum+1, O);
  O << "(";
  printOperand(MI, OpNum, O);
  O << ")";
}

void Cpu0InstPrinter::printMemOperandEA(const MCInst *MI, int opNum,
                                        raw_ostream &O) {
  // when using stack locations for not load/store instructions
  // print the same way as all normal 3 operand instructions.
  printOperand(MI, opNum, O);
  O << ", ";
  printOperand(MI, opNum+1, O);
  return;
}
