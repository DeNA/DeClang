//===-- Cpu0RegisterInfo.td - Cpu0 Register defs -----------*- tablegen -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.

//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Declarations that describe the CPU0 register file
//===----------------------------------------------------------------------===//

// We have banks of 16 registers each.
class Cpu0Reg<bits<16> Enc, string n> : Register<n> {
  // For tablegen(... -gen-emitter) in CMakeLists.txt
  let HWEncoding = Enc;
  let Namespace = "Cpu0";
}

// Cpu0 CPU Registers
class Cpu0GPRReg<bits<16> Enc, string n> : Cpu0Reg<Enc, n>;

// Co-processor 0 Registers
class Cpu0C0Reg<bits<16> Enc, string n> : Cpu0Reg<Enc, n>;

//===----------------------------------------------------------------------===//
//@Registers
//===----------------------------------------------------------------------===//
// The register string, such as "9" or "gp" will show on "llvm-objdump -d"
//@ All registers dfinition
let Namespace = "Cpu0" in {
  //@ General Purpose Registers
  def ZERO : Cpu0GPRReg<0,   "zero">, DwarfRegNum<[0]>;
  def AT   : Cpu0GPRReg<1,   "1">,    DwarfRegNum<[1]>;
  def V0   : Cpu0GPRReg<2,   "2">,    DwarfRegNum<[2]>;
  def V1   : Cpu0GPRReg<3,   "3">,    DwarfRegNum<[3]>;
  def A0   : Cpu0GPRReg<4,   "4">,    DwarfRegNum<[4]>;
  def A1   : Cpu0GPRReg<5,   "5">,    DwarfRegNum<[5]>;
  def T9   : Cpu0GPRReg<6,   "6">,    DwarfRegNum<[6]>;
  def T0   : Cpu0GPRReg<7,   "7">,    DwarfRegNum<[7]>;
  def T1   : Cpu0GPRReg<8,   "8">,    DwarfRegNum<[8]>;
  def S0   : Cpu0GPRReg<9,   "9">,    DwarfRegNum<[9]>;
  def S1   : Cpu0GPRReg<10,  "10">,   DwarfRegNum<[10]>;
  def GP   : Cpu0GPRReg<11,  "gp">,   DwarfRegNum<[11]>;
  def FP   : Cpu0GPRReg<12,  "fp">,   DwarfRegNum<[12]>;
  def SP   : Cpu0GPRReg<13,  "sp">,   DwarfRegNum<[13]>;
  def LR   : Cpu0GPRReg<14,  "lr">,   DwarfRegNum<[14]>;
  def SW   : Cpu0GPRReg<15,  "sw">,   DwarfRegNum<[15]>;

  def PC   : Cpu0C0Reg<0, "pc">,    DwarfRegNum<[20]>;
  def EPC  : Cpu0C0Reg<1, "epc">,   DwarfRegNum<[21]>;

  def HI   : Cpu0Reg<0, "ac0">, DwarfRegNum<[18]>;
  def LO   : Cpu0Reg<0, "ac0">, DwarfRegNum<[19]>;
}

//===----------------------------------------------------------------------===//
// @Register Classes
//===----------------------------------------------------------------------===//

def CPURegs : RegisterClass<"Cpu0", [i32], 32, (add
  // Reserved
  ZERO, AT,
  // Return Values and Arguments
  V0, V1, A0, A1,
  // Not preserved across procedure calls
  T9, T0, T1,
  // Callee save
  S0, S1,
  // Reserved
  GP, FP,
  SP, LR, SW)>;

// @Status Registers class
def SR : RegisterClass<"Cpu0", [i32], 32, (add SW)>;

// @Co-processor 0 Registers class
def C0Regs : RegisterClass<"Cpu0", [i32], 32, (add PC, EPC)>;

def HILO   : RegisterClass<"Cpu0", [i32], 32, (add HI, LO)>;

