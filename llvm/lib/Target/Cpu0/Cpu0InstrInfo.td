//===-- Cpu0InstrInfo.td - Cpu0 Instruction defs -----------*- tablegen -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.

//
//===----------------------------------------------------------------------===//
//
// This fiel contains the Cpu0 implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Cpu0 profiles and nodes
//===----------------------------------------------------------------------===//

def SDT_Cpu0Ret : SDTypeProfile<0, 1, [SDTCisInt<0>]>;

def SDT_Cpu0DivRem : SDTypeProfile<0, 2, [SDTCisInt<0>, SDTCisSameAs<0, 1>]>;

def SDT_Cpu0JmpLink : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;

def SDT_Cpu0CallSeqStart : SDCallSeqStart<[SDTCisVT<0, i32>]>;
def SDT_Cpu0CallSeqEnd : SDCallSeqEnd<[SDTCisVT<0, i32>, SDTCisVT<1, i32>]>;

// Hi and Lo nodes are used to handle global addresses. Used on
// Cpu0ISelLowering to lower stuff like GlobalAddress, ExternalSymbol
// static model. (nothing to do with Cpu0 Register Hi and Lo)
def Cpu0Hi    : SDNode<"Cpu0ISD::Hi", SDTIntUnaryOp>;
def Cpu0Lo    : SDNode<"Cpu0ISD::Lo", SDTIntUnaryOp>;
def Cpu0GPRel : SDNode<"Cpu0ISD::GPRel", SDTIntUnaryOp>;

// Call
def Cpu0JmpLink : SDNode<"Cpu0ISD::JmpLink", SDT_Cpu0JmpLink,
                         [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                          SDNPVariadic]>;
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_Cpu0CallSeqStart,
                           [SDNPHasChain, SDNPSideEffect, SDNPOutGlue]>;
def callseq_end : SDNode<"ISD::CALLSEQ_END", SDT_Cpu0CallSeqEnd,
                         [SDNPHasChain, SDNPOptInGlue,
                          SDNPSideEffect, SDNPOutGlue]>;
def Cpu0TailCall : SDNode<"Cpu0ISD::TailCall", SDT_Cpu0JmpLink,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Return
def Cpu0Ret : SDNode<"Cpu0ISD::Ret", SDTNone,
                     [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

def Cpu0DivRem  : SDNode<"Cpu0ISD::DivRem", SDT_Cpu0DivRem, [SDNPOutGlue]>;
def Cpu0DivRemU : SDNode<"Cpu0ISD::DivRemU", SDT_Cpu0DivRem, [SDNPOutGlue]>;

def Cpu0Wrapper : SDNode<"Cpu0ISD::Wrapper", SDTIntBinOp>;
//===----------------------------------------------------------------------===//
// Cpu0 Instruction Predicate Definitions.
//===----------------------------------------------------------------------===//
def EnableOverflow  : Predicate<"Subtarget->enableOverflow()">;
def DisableOverflow : Predicate<"Subtarget->disableOverflow()">;

def HasCmp          : Predicate<"Subtarget->hasCmp()">;
def HasSlt          : Predicate<"Subtarget->hasSlt()">;

def RelocPIC        : Predicate<"TM.getRelocationModel() == Reloc::PIC_">;
//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

include "Cpu0InstrFormats.td"

//===----------------------------------------------------------------------===//
// Cpu0 Operand, Complex Patterns and Transformations Definitions
//===----------------------------------------------------------------------===//

// Instruction operand types

// BEQ, BNE
def brtarget16    : Operand<OtherVT> {
  let EncoderMethod = "getBranch16TargetOpValue";
  let OperandType = "OPERAND_PCREL";
  let DecoderMethod = "DecodeBranch16Target";
}

// JEQ, JNE, ...
def brtarget24    : Operand<OtherVT> {
  let EncoderMethod = "getBranch24TargetOpValue";
  let OperandType = "OPERAND_PCREL";
  let DecoderMethod = "DecodeBranch24Target";
}

// JMP
def jmptarget : Operand<OtherVT> {
  let EncoderMethod = "getJumpTargetOpValue";
  let OperandType = "OPERAND_PCREL";
}

def calltarget : Operand<iPTR> {
  let EncoderMethod = "getJumpTargetOpValue";
}

let isCall = 1, hasDelaySlot = 1 in {
  class JumpLink<bits<8> op, string instrAsm>
      : FJ<op, (outs), (ins calltarget:$target, variable_ops),
         !strconcat(instrAsm, "\t$target"), [(Cpu0JmpLink imm:$target)],
         IIBranch> {
    let DecoderMethod = "DecodeJumpTarget";
  }
  class JumpLinkReg<bits<8> op, string instrAsm, RegisterClass RC>
      : FA<op, (outs), (ins RC:$rb, variable_ops),
           !strconcat(instrAsm, "\t$rb"), [(Cpu0JmpLink RC:$rb)],
           IIBranch> {
    let rc = 0;
    let ra = 14;
    let shamt = 0;
  }
}

let isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1, hasDelaySlot = 1,
    hasExtraSrcRegAllocReq = 1, Defs = [AT] in {
  class TailCall<Instruction JumpInst> :
    PseudoSE<(outs), (ins calltarget:$target), [], IIBranch>,
    PseudoInstExpansion<(JumpInst jmptarget:$target)>;

  class TailCallReg<RegisterClass RO, Instruction JRInst,
                    RegisterClass ResRO = RO> :
    PseudoSE<(outs), (ins RO:$rs), [(Cpu0TailCall RO:$rs)], IIBranch>,
    PseudoInstExpansion<(JRInst ResRO:$rs)>;
}

// Signed Operand
def simm16 : Operand<i32> {
  let DecoderMethod = "DecodeSimm16";
}

def shamt  : Operand<i32>;

def uimm16 : Operand<i32> {
  let PrintMethod = "printUnsignedImm";
}

def Cpu0MemAsmOperand : AsmOperandClass {
  let Name = "Mem";
  let ParserMethod = "parseMemOperand";
}

// Address operand
def mem : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops CPURegs, simm16);
  let EncoderMethod = "getMemEncoding";
  let ParserMatchClass = Cpu0MemAsmOperand;
}

def mem_ea : Operand<iPTR> {
  let PrintMethod = "printMemOperandEA";
  let MIOperandInfo = (ops CPURegs, simm16);
  let EncoderMethod = "getMemEncoding";
}

// Node immediate fits as 16-bit sign extended on target immediate.
// e.g. addi, andi
def immSExt16 : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;

// Transformation Function: get the lower 16 bits.
def LO16 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0xffff);
}]>;

// Transformation Function: get the higher 16 bits.
def HI16 : SDNodeXForm<imm, [{
  return getImm(N, (N->getZExtValue() >> 16) & 0xffff);
}]>;

// Node immdiate fits as 16-bit zero extended on target immediate.
// The LO16 param means that only the lower 16 bits of the node
// immediate are caught.
// e.g. addiu, sltiu
def immZExt16 : PatLeaf<(imm), [{
  if (N->getValueType(0) == MVT::i32)
    return (uint32_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
  else
    return (uint64_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
}], LO16>;

// Immediate can be loaded with LUi (32-bit int with lower 16-bit cleared).
def immLow16Zero : PatLeaf<(imm), [{
  int64_t Val = N->getSExtValue();
  return isInt<32>(Val) && !(Val & 0xffff);
}]>;

// shamt field must fit in 5 bits.
def immZExt5 : ImmLeaf<i32, [{ return Imm == (Imm & 0x1f); }]>;

// Cpu0 Address Mode! SDNode frameindex could posibily be a match since
// load and store instructions from stack used it.
def addr : ComplexPattern<iPTR, 2, "SelectAddr",
                          [frameindex], [SDNPWantParent]>;

//===----------------------------------------------------------------------===//
// Pattern fragment for load/store
//===----------------------------------------------------------------------===//

class AlignedLoad<PatFrag Node>
  : PatFrag<(ops node:$ptr), (Node node:$ptr),
            [{
              LoadSDNode *LD = cast<LoadSDNode>(N);
              return LD->getMemoryVT().getSizeInBits()/8 <= LD->getAlignment();
            }]>;

class AlignedStore<PatFrag Node>
  : PatFrag<(ops node:$val, node:$ptr), (Node node:$val, node:$ptr),
            [{
              StoreSDNode *ST = cast<StoreSDNode>(N);
              return ST->getMemoryVT().getSizeInBits()/8 <= ST->getAlignment();
            }]>;

// Load/Store PatFrags
def sextloadi16_a   : AlignedLoad<sextloadi16>;
def zextloadi16_a   : AlignedLoad<zextloadi16>;
def extloadi16_a    : AlignedLoad<extloadi16>;
def load_a          : AlignedLoad<load>;
def truncstorei16_a : AlignedStore<truncstorei16>;
def store_a         : AlignedStore<store>;

//===----------------------------------------------------------------------===//
// Instructions specific format
//===----------------------------------------------------------------------===//

// Arithmetic and logical instructions with 3 register operands
class ArithLogicR<bits<8> op, string instrAsm, SDNode opNode,
                  InstrItinClass itin, RegisterClass RC, bit isComm = 0>
  : FA<op, (outs GPROut:$ra), (ins RC:$rb, RC:$rc),
       !strconcat(instrAsm, "\t$ra, $rb, $rc"),
       [(set GPROut:$ra, (opNode RC:$rb, RC:$rc))], itin> {
  let shamt = 0;
  let isCommutable = isComm;
  let isReMaterializable = 1;
}

// Arithmetic and logical instructions with 2 register operands
class ArithLogicI<bits<8> op, string instrAsm, SDNode opNode,
                  Operand od, PatLeaf immType, RegisterClass regClass>
  : FL<op, (outs GPROut:$ra), (ins regClass:$rb, od:$imm16),
       !strconcat(instrAsm, "\t$ra, $rb, $imm16"),
       [(set GPROut:$ra, (opNode regClass:$rb, immType:$imm16))], IIAlu> {
  let isReMaterializable = 1;
}

// Shifts with immediate value
class ShiftRotateI<bits<8> op, bits<4> isRotate, string instrAsm,
                   SDNode opNode, PatFrag PF, Operand ImmOperand,
                   RegisterClass RC>
  : FA<op, (outs GPROut:$ra), (ins RC:$rb, ImmOperand:$shamt),
       !strconcat(instrAsm, "\t$ra, $rb, $shamt"),
       [(set GPROut:$ra, (opNode RC:$rb, PF:$shamt))], IIAlu> {
  let rc = 0;
}


// Shifts with register
class ShiftRotateR<bits<8> op, bits<4> isRotate, string instrAsm,
                   SDNode opNode, RegisterClass RC>
  : FA<op, (outs GPROut:$ra), (ins RC:$rb, RC:$rc),
       !strconcat(instrAsm, "\t$ra, $rb, $rc"),
       [(set GPROut:$ra, (opNode RC:$rb, RC:$rc))], IIAlu> {
  let shamt = 0;
}

// Load Upper Immediate
class LoadUpper<bits<8> op, string instrAsm, RegisterClass RC, Operand Imm>
  : FL<op, (outs RC:$ra), (ins Imm:$imm16),
       !strconcat(instrAsm, "\t$ra, $imm16"), [], IIAlu> {
  let rb = 0;
  let isReMaterializable = 1;
}

class CmpInstr<bits<8> op, string instrAsm, InstrItinClass itin,
               RegisterClass RC, RegisterClass RD, bit isComm = 0>
  : FA<op, (outs RD:$ra), (ins RC:$rb, RC:$rc),
       !strconcat(instrAsm, "\t$ra, $rb, $rc"), [], itin> {
  let shamt = 0;
  let isCommutable = isComm;
  let Predicates = [HasCmp];
}

class SetCC_R<bits<8> op, string instrAsm, PatFrag condOp,
              RegisterClass RC>
  : FA<op, (outs GPROut:$ra), (ins RC:$rb, RC:$rc),
       !strconcat(instrAsm, "\t$ra, $rb, $rc"),
       [(set GPROut:$ra, (condOp RC:$rb, RC:$rc))],
       IIAlu>, Requires<[HasSlt]> {
  let shamt = 0;
}

class SetCC_I<bits<8> op, string instrAsm, PatFrag condOp, Operand Od,
              PatLeaf immType, RegisterClass RC>
  : FL<op, (outs GPROut:$ra), (ins RC:$rb, Od:$imm16),
       !strconcat(instrAsm, "\t$ra, $rb, $imm16"),
       [(set GPROut:$ra, (condOp RC:$rb, immType:$imm16))],
       IIAlu>, Requires<[HasSlt]>;

class FMem<bits<8> op, dag outs, dag ins, string asmStr, list<dag> pattern,
           InstrItinClass itin>
  : FL<op, outs, ins, asmStr, pattern, itin> {
  bits<20> addr;
  let Inst{19-16}   = addr{19-16};
  let Inst{15-0}    = addr{15-0};
  let DecoderMethod = "DecodeMem";
}

// Memory Load/Store
let canFoldAsLoad = 1 in
class LoadM<bits<8> op, string instrAsm, PatFrag opNode, RegisterClass regClass,
            Operand od, bit pseudo>
  : FMem<op, (outs regClass:$ra), (ins od:$addr),
         !strconcat(instrAsm, "\t$ra, $addr"),
         [(set regClass:$ra, (opNode addr:$addr))], IILoad> {
  let isPseudo = pseudo;
}

class StoreM<bits<8> op, string instrAsm, PatFrag opNode, RegisterClass regClass,
             Operand od, bit pseudo>
  : FMem<op, (outs), (ins regClass:$ra, od:$addr),
         !strconcat(instrAsm, "\t$ra, $addr"),
         [(opNode regClass:$ra, addr:$addr)], IIStore> {
  let isPseudo = pseudo;
}

// 32-bit load
multiclass LoadM32<bits<8> op, string instrAsm,
                   PatFrag opNode, bit pseudo=0> {
  //def #NAME# : LoadM<op, instrAsm, opNode, GPROut, mem, pseudo>;
  def LoadM32 : LoadM<op, instrAsm, opNode, GPROut, mem, pseudo>;
}

// 32-bit store
multiclass StoreM32<bits<8> op, string instrAsm,
                    PatFrag opNode, bit pseudo=0> {
  //def #NAME# : StoreM<op, instrAsm, opNode, CPURegs, mem, pseudo>;
  def StoreM32 : StoreM<op, instrAsm, opNode, CPURegs, mem, pseudo>;
}

// Conditional Branch
class CBranch24<bits<8> op, string instrAsm, RegisterClass RC,
                list<Register> UseRegs>
  : FJ<op, (outs), (ins RC:$ra, brtarget24:$addr),
       !strconcat(instrAsm, "\t$ra, $addr"),
       [], IIBranch>, Requires<[HasCmp]> {
  let isBranch = 1;
  let isTerminator = 1;
  let hasDelaySlot = 1;
}

// Conditional Branch
class CBranch16<bits<8> op, string instrAsm, PatFrag cond_op, RegisterClass RC>
  : FL<op, (outs), (ins RC:$ra, RC:$rb, brtarget16:$imm16),
       !strconcat(instrAsm, "\t$ra, $rb, $imm16"),
       [(brcond (i32 (cond_op RC:$ra, RC:$rb)), bb:$imm16)], IIBranch>,
       Requires<[HasSlt]> {
  let isBranch = 1;
  let isTerminator = 1;
  let hasDelaySlot = 1;
  let Defs = [AT];
}

// Unconditional branch, such as JMP
class UncondBranch<bits<8> op, string instrAsm>
  : FJ<op, (outs), (ins jmptarget:$addr),
  !strconcat(instrAsm, "\t$addr"), [(br bb:$addr)], IIBranch> {
  let isBranch = 1;
  let isTerminator = 1;
  let isBarrier = 1;
  let hasDelaySlot = 0;
}

// JumpFR
class JumpFR<bits<8> op, string instrAsm, RegisterClass regClass>
  : FL<op, (outs), (ins regClass:$ra),
       !strconcat(instrAsm, "\t$ra"), [(brind regClass:$ra)], IIBranch> {
  let rb = 0;
  let imm16 = 0;

  let isBranch = 1;
  let isTerminator = 1;
  let isBarrier = 1;
  let hasDelaySlot = 1;
  let isIndirectBranch = 1;

  let DecoderMethod = "DecodeJumpFR";
}

// Call
class IsTailCall {
  bit isCall = 1;
  bit isTerminator = 1;
  bit isReturn = 1;
  bit isBarrier = 1;
  bit hasExtraSrcRegAllocReq = 1;
  bit isCodeGenOnly = 1;
}

// Return
class RetBase<RegisterClass regClass> : JumpFR<0x3c, "ret", regClass> {
  let isReturn = 1;
  let isCodeGenOnly = 1;
  let hasCtrlDep = 1;
  let hasExtraSrcRegAllocReq = 1;
}

// Multiple
class Mult<bits<8> op, string instrAsm, InstrItinClass itin,
           RegisterClass RC, list<Register> DefRegs>
  : FA<op, (outs), (ins RC:$ra, RC:$rb),
       !strconcat(instrAsm, "\t$ra, $rb"), [], itin> {
  let rc = 0;
  let shamt = 0;
  let isCommutable = 1;
  let Defs = DefRegs;
  let hasSideEffects = 0;
}

class Mult32<bits<8> op, string instrAsm, InstrItinClass itin>
  : Mult<op, instrAsm, itin, CPURegs, [HI, LO]>;

// Divid
class Div<SDNode opNode, bits<8> op, string instrAsm, InstrItinClass itin,
          RegisterClass RC, list<Register> DefRegs>
  : FA<op, (outs), (ins RC:$ra, RC:$rb),
       !strconcat(instrAsm, "\t$ra, $rb"),
       [(opNode RC:$ra, RC:$rb)], itin> {
  let rc = 0;
  let shamt = 0;
  let Defs = DefRegs;
}

class Div32<SDNode opNode, bits<8> op, string instrAsm, InstrItinClass itin>
  : Div<opNode, op, instrAsm, itin, CPURegs, [HI, LO]>;

// Move from LO/HI
class MoveFromLOHI<bits<8> op, string instrAsm, RegisterClass RC,
                   list<Register> UseRegs>
  : FA<op, (outs RC:$ra), (ins),
       !strconcat(instrAsm, "\t$ra"), [], IIHiLo> {
  let rb = 0;
  let rc = 0;
  let shamt = 0;
  let Uses = UseRegs;
  let hasSideEffects = 0;
}

// Move to LO/HI
class MoveToLOHI<bits<8> op, string instrAsm, RegisterClass RC,
                 list<Register> DefRegs>
  : FA<op, (outs), (ins RC:$ra),
       !strconcat(instrAsm, "\t$ra"), [], IIHiLo> {
  let rb = 0;
  let rc = 0;
  let shamt = 0;
  let Defs = DefRegs;
  let hasSideEffects = 0;
}

// Move from C0 (co-processor 0) Register
class MoveFromC0<bits<8> op, string instrAsm, RegisterClass RC>
  : FA<op, (outs), (ins RC:$ra, C0Regs:$rb),
       !strconcat(instrAsm, "\t$ra, $rb"), [], IIAlu> {
  let rc = 0;
  let shamt = 0;
  let hasSideEffects = 0;
}

// Move to C0 Register
class MoveToC0<bits<8> op, string instrAsm, RegisterClass RC>
  : FA<op, (outs C0Regs:$ra), (ins RC:$rb),
       !strconcat(instrAsm, "\t$ra, $rb"), [], IIAlu> {
  let rc = 0;
  let shamt = 0;
  let hasSideEffects = 0;
}

// Move from C0 register to C0 register
class C0Move<bits<8> op, string instrAsm>
  : FA<op, (outs C0Regs:$ra), (ins C0Regs:$rb),
       !strconcat(instrAsm, "\t$ra, $rb"), [], IIAlu> {
  let rc = 0;
  let shamt = 0;
  let hasSideEffects = 0;
}

class CountLeading0<bits<8> op, string instrAsm, RegisterClass RC>
  : FA<op, (outs GPROut:$ra), (ins RC:$rb), !strconcat(instrAsm, "\t$ra, $rb"),
       [(set GPROut:$ra, (ctlz RC:$rb))], IICLZ> {
  let rc = 0;
  let shamt = 0;
}

class CountLeading1<bits<8> op, string instrAsm, RegisterClass RC>
  : FA<op, (outs GPROut:$ra), (ins RC:$rb), !strconcat(instrAsm, "\t$ra, $rb"),
       [(set GPROut:$ra, (ctlz (not RC:$rb)))], IICLO> {
  let rc = 0;
  let shamt = 0;
}

// Effective Address
class EffectiveAddress<string instrAsm, RegisterClass RC, Operand mem>
  : FMem<0x09, (outs RC:$ra), (ins mem:$addr), instrAsm,
         [(set RC:$ra, addr:$addr)], IIAlu>;

//===----------------------------------------------------------------------===//
// Instruction definition
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Pseudo Instruction definition
//===----------------------------------------------------------------------===//

class LoadImm32<string instrAsm, Operand Od, RegisterClass RC>
    : Cpu0AsmPseudoInst<(outs RC:$ra), (ins Od:$imm32),
                        !strconcat(instrAsm, "\t$ra, $imm32")>;
def LoadImm32Reg : LoadImm32<"li", shamt, GPROut>;

class LoadAddress<string instrAsm, Operand MemOpnd, RegisterClass RC>
    : Cpu0AsmPseudoInst<(outs RC:$ra), (ins MemOpnd:$addr),
                        !strconcat(instrAsm, "\t$ra, $addr")>;
def LoadAddr32Reg : LoadAddress<"la", mem, GPROut>;

class LoadAddressImm<string instrAsm, Operand Od, RegisterClass RC>
    : Cpu0AsmPseudoInst<(outs RC:$ra), (ins Od:$imm32),
                        !strconcat(instrAsm, "\t$ra, $imm32")>;
def LoadAddr32Imm : LoadAddressImm<"la", shamt, GPROut>;

//===----------------------------------------------------------------------===//
// Cpu0 Instructions
//===----------------------------------------------------------------------===//

// Load and Store Instructions
// already aligned
defm LD      : LoadM32<0x01,   "ld",   load_a>;
defm ST      : StoreM32<0x02,  "st",   store_a>;
defm LB      : LoadM32<0x03, "lb", sextloadi8>;
defm LBu     : LoadM32<0x04, "lbu", zextloadi8>;
defm SB      : StoreM32<0x05, "sb", truncstorei8>;
defm LH      : LoadM32<0x06, "lh", sextloadi16_a>;
defm LHu     : LoadM32<0x07, "lhu", zextloadi16_a>;
defm SH      : StoreM32<0x08, "sh", truncstorei16_a>;

// Arithmetic Instructions (ALU Immediate)
def ADDiu    : ArithLogicI<0x09, "addiu", add, simm16, immSExt16, CPURegs>;

def LUi      : LoadUpper<0x0f, "lui", GPROut, uimm16>;

// Arithmetic Instructions (3-Operand, R-Type)
let Predicates = [DisableOverflow] in {
  def ADDu   : ArithLogicR<0x11, "addu", add, IIAlu, CPURegs, 1>;
  def SUBu   : ArithLogicR<0x12, "subu", sub, IIAlu, CPURegs>;
}
let Predicates = [EnableOverflow] in {
  def ADD    : ArithLogicR<0x13, "add", add, IIAlu, CPURegs, 1>;
  def SUB    : ArithLogicR<0x14, "sub", sub, IIAlu, CPURegs>;
}

def MUL      : ArithLogicR<0x17, "mul", mul, IIImul, CPURegs, 1>;
def MULT     : Mult32<0x41, "mult", IIImul>;
def MULTu    : Mult32<0x42, "multu", IIImul>;
def SDIV     : Div32<Cpu0DivRem, 0x43, "div", IIIdiv>;
def UDIV     : Div32<Cpu0DivRem, 0x44, "divu", IIIdiv>;

// Shift Instructions
// shift left
def SHL      : ShiftRotateI<0x1e, 0x00, "shl", shl, immZExt5, shamt, CPURegs>;
// shift right arithmetic
def SRA      : ShiftRotateI<0x1d, 0x00, "sra", sra, immZExt5, shamt, CPURegs>;
// rotate shift left
def ROL      : ShiftRotateI<0x1b, 0x01, "rol", rotl, immZExt5, shamt, CPURegs>;
// rotate shift right
def ROR      : ShiftRotateI<0x1c, 0x01, "ror", rotr, immZExt5, shamt, CPURegs>;
// shift right
def SHR      : ShiftRotateI<0x1f, 0x00, "shr", srl, immZExt5, shamt, CPURegs>;

// shift right arithmetic
def SRAV     : ShiftRotateR<0x20, 0x00, "srav", sra, CPURegs>;
// shift left
def SHLV     : ShiftRotateR<0x21, 0x00, "shlv", shl, CPURegs>;
// shift right
def SHRV     : ShiftRotateR<0x22, 0x00, "shrv", srl, CPURegs>;
// rotate shift left
def ROLV     : ShiftRotateR<0x23, 0x01, "rolv", rotl, CPURegs>;
// rotate shift right
def RORV     : ShiftRotateR<0x24, 0x01, "rorv", rotr, CPURegs>;

// Jump Instructions
def JR       : JumpFR<0x3c, "jr", GPROut>;

// Jump & link and return instruction
def JSUB     : JumpLink<0x3b, "jsub">;

def RET      : RetBase<GPROut>;

def JALR     : JumpLinkReg<0x39, "jalr", GPROut>;

def MFHI     : MoveFromLOHI<0x46, "mfhi", CPURegs, [HI]>;
def MFLO     : MoveFromLOHI<0x47, "mflo", CPURegs, [LO]>;
def MTHI     : MoveToLOHI<0x48, "mthi", CPURegs, [HI]>;
def MTLO     : MoveToLOHI<0x49, "mtlo", CPURegs, [LO]>;

def MFC0     : MoveFromC0<0x50, "mfc0", CPURegs>;
def MTC0     : MoveToC0<0x51, "mtc0", CPURegs>;

def C0MOVE   : C0Move<0x52, "c0mov">;

// Logic Instructions
def ANDi     : ArithLogicI<0x0c, "andi", and, uimm16, immZExt16, CPURegs>;
def ORi      : ArithLogicI<0x0d, "ori", or, uimm16, immZExt16, CPURegs>;
def XORi     : ArithLogicI<0x0e, "xori", xor, uimm16, immZExt16, CPURegs>;

def AND      : ArithLogicR<0x18, "and", and, IIAlu, CPURegs, 1>;
def OR       : ArithLogicR<0x19, "or", or, IIAlu, CPURegs, 1>;
def XOR      : ArithLogicR<0x1a, "xor", xor, IIAlu, CPURegs, 1>;

def CMP      : CmpInstr<0x10, "cmp", IIAlu, CPURegs, SR, 0>;

let Predicates = [HasSlt] in {
def SLTi     : SetCC_I<0x26, "slti", setlt, simm16, immSExt16, CPURegs>;
def SLTiu    : SetCC_I<0x27, "sltiu", setult, simm16, immSExt16, CPURegs>;
def SLT      : SetCC_R<0x28, "slt", setlt, CPURegs>;
def SLTu     : SetCC_R<0x29, "sltu", setult, CPURegs>;
}

// No Operation Instructions
let addr=0 in
def NOP    : FJ<0, (outs), (ins), "nop", [], IIAlu>;

def CLZ : CountLeading0<0x15, "clz", CPURegs>;
def CLO : CountLeading1<0x16, "clo", CPURegs>;

// FrameIndexs are legalized when they are opreands from load/store instruction.
// The same not happens for stack address copies, so an add op with mem
// ComplexPattern is used and the stack address copy can be matched.
// It's similar to Sparc LEA_ADDRi
def LEA_ADDiu : EffectiveAddress<"addiu\t$ra, $addr", CPURegs, mem_ea> {
  let isCodeGenOnly = 1;
}

let isReturn=1, isTerminator=1, hasDelaySlot=1, isBarrier=1, hasCtrlDep=1 in
  def RetLR  : Cpu0Pseudo<(outs), (ins), "", [(Cpu0Ret)]>;

let Predicates = [HasCmp] in {
  def JEQ     : CBranch24<0x30, "jeq", SR, [SW]>;
  def JNE     : CBranch24<0x31, "jne", SR, [SW]>;
  def JLT     : CBranch24<0x32, "jlt", SR, [SW]>;
  def JGT     : CBranch24<0x33, "jgt", SR, [SW]>;
  def JLE     : CBranch24<0x34, "jle", SR, [SW]>;
  def JGE     : CBranch24<0x35, "jge", SR, [SW]>;
}

let Predicates = [HasSlt] in {
  def BEQ     : CBranch16<0x37, "beq", seteq, GPROut>;
  def BNE     : CBranch16<0x38, "bne", setne, GPROut>;
}

// Branch Instructions
def JMP       : UncondBranch<0x36, "jmp">;

let Defs = [SP], Uses = [SP], hasSideEffects = 1 in {
  // As stack alignment is always done with addiu, we need a 16-bit immediate
  def ADJCALLSTACKDOWN : Cpu0Pseudo<(outs), (ins uimm16:$amt1, uimm16:$amt2),
                                    "!ADJCALLSTACKDOWN $amt1",
                                    [(callseq_start timm:$amt1, timm:$amt2)]>;
  def ADJCALLSTACKUP : Cpu0Pseudo<(outs), (ins uimm16:$amt1, uimm16:$amt2),
                                  "!ADJCALLSTACKUP $amt1",
                                  [(callseq_end timm:$amt1, timm:$amt2)]>;
}

// When handling PIC code the assembler needs .cpload and .cprestore
// directives. If the real instructions corresponding these directives
// are used, we have the same behavior, but get also a bunch of warnings
// from the assembler.
let hasSideEffects = 0 in
  def CPRESTORE : Cpu0Pseudo<(outs), (ins i32imm:$loc, CPURegs:$gp),
                             ".cprestore\t$loc", []>;

def TAILCALL : TailCall<JMP>;
def TAILCALL_R : TailCallReg<GPROut, JR>;


//===----------------------------------------------------------------------===//
// Arbitrary patterns that map to one or more instructions
//===----------------------------------------------------------------------===//

// Small Immediates
def : Pat<(i32 immSExt16:$in),
          (ADDiu ZERO, imm:$in)>;

def : Pat<(i32 immZExt16:$in),
          (ORi ZERO, imm:$in)>;

def : Pat<(i32 immLow16Zero:$in),
          (LUi (HI16 imm:$in))>;

// Arbitrary immediates
def : Pat<(i32 imm:$imm),
          (ORi (LUi (HI16 imm:$imm)), (LO16 imm:$imm))>;

// hi/lo relocs
def : Pat<(Cpu0Hi tglobaladdr:$in), (LUi tglobaladdr:$in)>;

def : Pat<(Cpu0Hi tblockaddress:$in), (LUi tblockaddress:$in)>;
def : Pat<(Cpu0Hi tjumptable:$in), (LUi tjumptable:$in)>;

def : Pat<(Cpu0Lo tglobaladdr:$in), (ORi ZERO, tglobaladdr:$in)>;

def : Pat<(Cpu0Lo tblockaddress:$in), (ORi ZERO, tblockaddress:$in)>;
def : Pat<(Cpu0Lo tjumptable:$in), (ORi ZERO, tjumptable:$in)>;

def : Pat<(add CPURegs:$hi, (Cpu0Lo tglobaladdr:$lo)),
          (ORi CPURegs:$hi, tglobaladdr:$lo)>;

def : Pat<(add CPURegs:$hi, (Cpu0Lo tblockaddress:$lo)),
          (ORi CPURegs:$hi, tblockaddress:$lo)>;
def : Pat<(add CPURegs:$hi, (Cpu0Lo tjumptable:$lo)),
          (ORi CPURegs:$hi, tjumptable:$lo)>;

// gp_rel relocs
def : Pat<(add CPURegs:$gp, (Cpu0GPRel tglobaladdr:$in)),
          (ORi CPURegs:$gp, tglobaladdr:$in)>;

// wrapper_pic
class WrapperPat<SDNode node, Instruction ORiOp, RegisterClass RC>
  : Pat<(Cpu0Wrapper RC:$gp, node:$in), (ORiOp RC:$gp, node:$in)>;
def : WrapperPat<tglobaladdr, ORi, GPROut>;

def : WrapperPat<tjumptable, ORi, GPROut>;

// Use logic operator
def : Pat<(not CPURegs:$in),
          (XORi CPURegs:$in, 1)>;

//def : Pat<(i32 (extloadi1  addr:$src)), (LBu addr:$src)>;
//def : Pat<(i32 (extloadi8  addr:$src)), (LBu addr:$src)>;
def : Pat<(i32 (extloadi1  addr:$src)), (LBuLoadM32 addr:$src)>;
def : Pat<(i32 (extloadi8  addr:$src)), (LBuLoadM32 addr:$src)>;
def : Pat<(i32 (extloadi16_a addr:$src)), (LHuLoadM32 addr:$src)>;

// SetCC patterns
multiclass SeteqPatsCmp<RegisterClass RC> {
  // a == b
  def : Pat<(seteq RC:$lhs, RC:$rhs),
            (SHR (ANDi (CMP RC:$lhs, RC:$rhs), 2), 1)>;
  // a != b
  def : Pat<(setne RC:$lhs, RC:$rhs),
            (XORi (SHR (ANDi (CMP RC:$lhs, RC:$rhs), 2), 1), 1)>;
}

// a < b
multiclass SetltPatsCmp<RegisterClass RC> {
  def : Pat<(setlt RC:$lhs, RC:$rhs),
            (ANDi (CMP RC:$lhs, RC:$rhs), 1)>;
  // if cpu0 `define N    `SW[31] instead of `SW[0]  // Negative flag, then need
  // 2 more isntructions as follows,
  //        (XORi (ANDi (SHR (CMP RC:$lhs, RC:$rhs), (LUi 0x8000), 31, 1), 1)>;
  def : Pat<(setult RC:$lhs, RC:$rhs),
            (ANDi (CMP RC:$lhs, RC:$rhs), 1)>;
}

// a <= b
multiclass SetlePatsCmp<RegisterClass RC> {
  def : Pat<(setle RC:$lhs, RC:$rhs),
  // a <= b is equal to (XORi (b < a), 1)
            (XORi (ANDi (CMP RC:$rhs, RC:$lhs), 1), 1)>;
  def : Pat<(setule RC:$lhs, RC:$rhs),
            (XORi (ANDi (CMP RC:$rhs, RC:$lhs), 1), 1)>;
}

// a > b
multiclass SetgtPatsCmp<RegisterClass RC> {
  def : Pat<(setgt RC:$lhs, RC:$rhs),
  // a > b is equal to b < a is equal to setlt(b, a)
            (ANDi (CMP RC:$rhs, RC:$lhs), 1)>;
  def : Pat<(setugt RC:$lhs, RC:$rhs),
            (ANDi (CMP RC:$rhs, RC:$lhs), 1)>;
}

// a >= b
multiclass SetgePatsCmp<RegisterClass RC> {
  def : Pat<(setge RC:$lhs, RC:$rhs),
  // a >= b is equal to b <= a
            (XORi (ANDi (CMP RC:$lhs, RC:$rhs), 1), 1)>;
  def : Pat<(setuge RC:$lhs, RC:$rhs),
            (XORi (ANDi (CMP RC:$lhs, RC:$rhs), 1), 1)>;
}

// setcc for slt instruction
multiclass SeteqPatsSlt<RegisterClass RC, Instruction SLTiuOp, Instruction XOROp,
                        Instruction SLTuOp, Register ZEROReg> {
  // a == b
  def : Pat<(seteq RC:$lhs, RC:$rhs),
            (SLTiuOp (XOROp RC:$lhs, RC:$rhs), 1)>;

  // a != b
  def : Pat<(setne RC:$lhs, RC:$rhs),
            (SLTuOp ZEROReg, (XOROp RC:$lhs, RC:$rhs))>;
}

// a <= b
multiclass SetlePatsSlt<RegisterClass RC, Instruction SLTOp, Instruction SLTuOp> {
  def : Pat<(setle RC:$lhs, RC:$rhs),
  // a <= b is equal to (XORi (b < a), 1)
            (XORi (SLTOp RC:$rhs, RC:$lhs), 1)>;
  def : Pat<(setule RC:$lhs, RC:$rhs),
            (XORi (SLTuOp RC:$rhs, RC:$lhs), 1)>;
}

// a > b
multiclass SetgtPatsSlt<RegisterClass RC, Instruction SLTOp, Instruction SLTuOp> {
  def : Pat<(setgt RC:$lhs, RC:$rhs),
  // a > b is equal to b < a is equal to setlt(b, a)
            (SLTOp RC:$rhs, RC:$lhs)>;
  def : Pat<(setugt RC:$lhs, RC:$rhs),
            (SLTuOp RC:$rhs, RC:$lhs)>;
}

// a >= b
multiclass SetgePatsSlt<RegisterClass RC, Instruction SLTOp, Instruction SLTuOp> {
  def : Pat<(setge RC:$lhs, RC:$rhs),
  // a >= b is equal to b <= a
            (XORi (SLTOp RC:$lhs, RC:$rhs), 1)>;
  def : Pat<(setuge RC:$lhs, RC:$rhs),
            (XORi (SLTuOp RC:$lhs, RC:$rhs), 1)>;
}

multiclass SetgeImmPatsSlt<RegisterClass RC, Instruction SLTiOp,
                           Instruction SLTiuOp> {
  def : Pat<(setge RC:$lhs, immSExt16:$rhs),
            (XORi (SLTiOp RC:$lhs, immSExt16:$rhs), 1)>;
  def : Pat<(setuge RC:$lhs, immSExt16:$rhs),
            (XORi (SLTiuOp RC:$lhs, immSExt16:$rhs), 1)>;
}

let Predicates = [HasSlt] in {
defm : SeteqPatsSlt<CPURegs, SLTiu, XOR, SLTu, ZERO>;
defm : SetlePatsSlt<CPURegs, SLT, SLTu>;
defm : SetgtPatsSlt<CPURegs, SLT, SLTu>;
defm : SetgePatsSlt<CPURegs, SLT, SLTu>;
defm : SetgeImmPatsSlt<CPURegs, SLTi, SLTiu>;
}

let Predicates = [HasCmp] in {
defm : SeteqPatsCmp<CPURegs>;
defm : SetltPatsCmp<CPURegs>;
defm : SetlePatsCmp<CPURegs>;
defm : SetgtPatsCmp<CPURegs>;
defm : SetgePatsCmp<CPURegs>;
}

// brcond for cmp instruction
multiclass BrcondPatsCmp<RegisterClass RC, Instruction JEQOp, Instruction JNEOp,
Instruction JLTOp, Instruction JGTOp, Instruction JLEOp, Instruction JGEOp,
Instruction CMPOp, Register ZEROReg> {
def : Pat<(brcond (i32 (seteq RC:$lhs, RC:$rhs)), bb:$dst),
          (JEQOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setueq RC:$lhs, RC:$rhs)), bb:$dst),
          (JEQOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setne RC:$lhs, RC:$rhs)), bb:$dst),
          (JNEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setune RC:$lhs, RC:$rhs)), bb:$dst),
          (JNEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setlt RC:$lhs, RC:$rhs)), bb:$dst),
          (JLTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setult RC:$lhs, RC:$rhs)), bb:$dst),
          (JLTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setgt RC:$lhs, RC:$rhs)), bb:$dst),
          (JGTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setugt RC:$lhs, RC:$rhs)), bb:$dst),
          (JGTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setle RC:$lhs, RC:$rhs)), bb:$dst),
          (JLEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setule RC:$lhs, RC:$rhs)), bb:$dst),
          (JLEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setge RC:$lhs, RC:$rhs)), bb:$dst),
          (JGEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i32 (setuge RC:$lhs, RC:$rhs)), bb:$dst),
          (JGEOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;

def : Pat<(brcond RC:$cond, bb:$dst),
          (JNEOp (CMPOp RC:$cond, ZEROReg), bb:$dst)>;
}

// brcond for slt instruction
multiclass BrcondPatsSlt<RegisterClass RC, Instruction BEQOp, Instruction BNEOp,
                      Instruction SLTOp, Instruction SLTuOp, Instruction SLTiOp,
                      Instruction SLTiuOp, Register ZEROReg> {
def : Pat<(brcond (i32 (setne RC:$lhs, 0)), bb:$dst),
              (BNEOp RC:$lhs, ZEROReg, bb:$dst)>;
def : Pat<(brcond (i32 (seteq RC:$lhs, 0)), bb:$dst),
              (BEQOp RC:$lhs, ZEROReg, bb:$dst)>;

def : Pat<(brcond (i32 (seteq RC:$lhs, RC:$rhs)), bb:$dst),
              (BEQOp RC:$lhs, RC:$rhs, bb:$dst)>;
def : Pat<(brcond (i32 (setueq RC:$lhs, RC:$rhs)), bb:$dst),
              (BEQOp RC:$lhs, RC:$rhs, bb:$dst)>;
def : Pat<(brcond (i32 (setne RC:$lhs, RC:$rhs)), bb:$dst),
              (BNEOp RC:$lhs, RC:$rhs, bb:$dst)>;
def : Pat<(brcond (i32 (setune RC:$lhs, RC:$rhs)), bb:$dst),
              (BNEOp RC:$lhs, RC:$rhs, bb:$dst)>;
def : Pat<(brcond (i32 (setlt RC:$lhs, RC:$rhs)), bb:$dst),
              (BNE (SLTOp RC:$lhs, RC:$rhs), ZERO, bb:$dst)>;
def : Pat<(brcond (i32 (setult RC:$lhs, RC:$rhs)), bb:$dst),
              (BNE (SLTuOp RC:$lhs, RC:$rhs), ZERO, bb:$dst)>;
def : Pat<(brcond (i32 (setgt RC:$lhs, RC:$rhs)), bb:$dst),
              (BNE (SLTOp RC:$rhs, RC:$lhs), ZERO, bb:$dst)>;
def : Pat<(brcond (i32 (setugt RC:$lhs, RC:$rhs)), bb:$dst),
              (BNE (SLTuOp RC:$rhs, RC:$lhs), ZERO, bb:$dst)>;
def : Pat<(brcond (i32 (setle RC:$lhs, RC:$rhs)), bb:$dst),
              (BEQ (SLTOp RC:$rhs, RC:$lhs), ZERO, bb:$dst)>;
def : Pat<(brcond (i32 (setule RC:$lhs, RC:$rhs)), bb:$dst),
              (BEQ (SLTuOp RC:$rhs, RC:$lhs), ZERO, bb:$dst)>;
def : Pat<(brcond (i32 (setge RC:$lhs, RC:$rhs)), bb:$dst),
              (BEQ (SLTOp RC:$lhs, RC:$rhs), ZERO, bb:$dst)>;
def : Pat<(brcond (i32 (setuge RC:$lhs, RC:$rhs)), bb:$dst),
              (BEQ (SLTuOp RC:$lhs, RC:$rhs), ZERO, bb:$dst)>;

def : Pat<(brcond RC:$cond, bb:$dst),
              (BNEOp RC:$cond, ZEROReg, bb:$dst)>;
}

let Predicates = [HasSlt] in {
defm : BrcondPatsSlt<CPURegs, BEQ, BNE, SLT, SLTu, SLTi, SLTiu, ZERO>;
}

let Predicates = [HasCmp] in {
defm : BrcondPatsCmp<CPURegs, JEQ, JNE, JLT, JGT, JLE, JGE, CMP, ZERO>;
}

def : Pat<(Cpu0JmpLink (i32 tglobaladdr:$dst)),
          (JSUB tglobaladdr:$dst)>;
def : Pat<(Cpu0JmpLink (i32 texternalsym:$dst)),
          (JSUB texternalsym:$dst)>;

def : Pat<(Cpu0TailCall (iPTR tglobaladdr:$dst)),
          (TAILCALL tglobaladdr:$dst)>;
def : Pat<(Cpu0TailCall (iPTR texternalsym:$dst)),
          (TAILCALL texternalsym:$dst)>;

// Conditional moves:
// These instructions are expanded in
// Cpu0ISelLowering::EmitInstrWithCustomInserter if target does not have
// conditional move instructions.
// cond:int, data:int
class CondMovIntInt<RegisterClass CRC, RegisterClass DRC, bits<8> op,
                    string instrAsm> :
  FA<op, (outs DRC:$ra), (ins DRC:$rb, CRC:$rc, DRC:$F),
     !strconcat(instrAsm, "\t$ra, $rb, $rc"), [], IIAlu> {
  let shamt = 0;
  let Constraints = "$F = $ra";
}

// select patterns
multiclass MovzPatsSlt<RegisterClass CRC, RegisterClass DRC,
                       Instruction MOVZInst, Instruction SLTOp,
                       Instruction SLTuOp, Instruction SLTiOp,
                       Instruction SLTiuOp> {
  def : Pat<(select (i32 (setge CRC:$lhs, CRC:$rhs)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, (SLTOp CRC:$lhs, CRC:$rhs), DRC:$F)>;
  def : Pat<(select (i32 (setuge CRC:$lhs, CRC:$rhs)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, (SLTuOp CRC:$lhs, CRC:$rhs), DRC:$F)>;
  def : Pat<(select (i32 (setge CRC:$lhs, immSExt16:$rhs)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, (SLTiOp CRC:$lhs, immSExt16:$rhs), DRC:$F)>;
  def : Pat<(select (i32 (setuge CRC:$lh, immSExt16:$rh)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, (SLTiuOp CRC:$lh, immSExt16:$rh), DRC:$F)>;
  def : Pat<(select (i32 (setle CRC:$lhs, CRC:$rhs)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, (SLTOp CRC:$rhs, CRC:$lhs), DRC:$F)>;
  def : Pat<(select (i32 (setule CRC:$lhs, CRC:$rhs)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, (SLTuOp CRC:$rhs, CRC:$lhs), DRC:$F)>;
}

multiclass MovzPats<RegisterClass CRC, RegisterClass DRC,
                    Instruction MOVZInst, Instruction XOROp> {
  def : Pat<(select (i32 (seteq CRC:$lhs, CRC:$rhs)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, (XOROp CRC:$lhs, CRC:$rhs), DRC:$F)>;
  def : Pat<(select (i32 (seteq CRC:$lhs, 0)), DRC:$T, DRC:$F),
            (MOVZInst DRC:$T, CRC:$lhs, DRC:$F)>;
}

multiclass MovnPats<RegisterClass CRC, RegisterClass DRC, Instruction MOVNInst,
                    Instruction XOROp> {
  def : Pat<(select (i32 (setne CRC:$lhs, CRC:$rhs)), DRC:$T, DRC:$F),
            (MOVNInst DRC:$T, (XOROp CRC:$lhs, CRC:$rhs), DRC:$F)>;
  def : Pat<(select CRC:$cond, DRC:$T, DRC:$F),
            (MOVNInst DRC:$T, CRC:$cond, DRC:$F)>;
  def : Pat<(select (i32 (setne CRC:$lhs, 0)),DRC:$T, DRC:$F),
            (MOVNInst DRC:$T, CRC:$lhs, DRC:$F)>;
}

// Instantiation of instructions.
def MOVZ_I_I     : CondMovIntInt<CPURegs, CPURegs, 0x0a, "movz">;

def MOVN_I_I     : CondMovIntInt<CPURegs, CPURegs, 0x0b, "movn">;

// Instantiation of conditional move patterns.
let Predicates = [HasSlt] in {
defm : MovzPatsSlt<CPURegs, CPURegs, MOVZ_I_I, SLT, SLTu, SLTi, SLTiu>;
}

defm : MovzPats<CPURegs, CPURegs, MOVZ_I_I, XOR>;

defm : MovnPats<CPURegs, CPURegs, MOVN_I_I, XOR>;


//===----------------------------------------------------------------------===//
// Instruction aliases
//===----------------------------------------------------------------------===//
class Cpu0InstAlias<string Asm, dag Result, bit Emit = 0b1> :
  InstAlias<Asm, Result, Emit>;

def : Cpu0InstAlias<"move $dst, $src",
                    (ADDu GPROut:$dst, GPROut:$src, ZERO), 1>;

