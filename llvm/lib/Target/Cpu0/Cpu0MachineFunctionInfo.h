//===-- Cpu0MachineFunctionInfo.h - Private data used for Cpu0 --*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_CPU0_CPU0MACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_CPU0_CPU0MACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/CodeGen/PseudoSourceValue.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"
#include <map>

namespace llvm {
  // This class is derived from MachienFunction private Cpu0 target-specific
  // information for each MachineFunction.
  class Cpu0MachineFunctionInfo : public MachineFunctionInfo {
  public:
    Cpu0MachineFunctionInfo(MachineFunction &MF)
        : MF(MF),
          SRetReturnReg(0), VarArgsFrameIndex(0),
          CallsEhReturn(false), CallsEhDwarf(false),
          MaxCallFrameSize(0), EmitNOAT(false), GlobalBaseReg(0),
          InArgFIRange(std::make_pair(-1, 0)),
          OutArgFIRange(std::make_pair(-1, 0)), GPFI(0), DynAllocFI(0) { }

    ~Cpu0MachineFunctionInfo();

    unsigned getSRetReturnReg() const { return SRetReturnReg; }
    void setSRetReturnReg(unsigned Reg) { SRetReturnReg = Reg; }

    bool globalBaseRegFixed() const;
    bool globalBaseRegSet() const;
    unsigned getGlobalBaseReg();

    int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
    void setVarArgsFrameIndex(int Index) { VarArgsFrameIndex = Index; }

    bool hasByvalArg() const { return HasByvalArg; }
    void setFormalArgInfo(unsigned Size, bool HasByval) {
      IncomingArgSize = Size;
      HasByvalArg = HasByval;
    }

    bool getEmitNOAT() const { return EmitNOAT; }
    void setEmitNOAT() { EmitNOAT = true; }

    unsigned getIncomingArgSize() const { return IncomingArgSize; }

    bool callsEhReturn() const { return CallsEhReturn; }
    void setCallsEhReturn() { CallsEhReturn = true; }

    bool callsEhDwarf() const { return CallsEhDwarf; }
    void setCallsEhDwarf() { CallsEhDwarf = true; }

    void createEhDataRegsFI();
    int getEhDataRegFI(unsigned Reg) const { return EhDataRegFI[Reg]; }

    unsigned getMaxCallFrameSize() const { return MaxCallFrameSize; }
    void setMaxCallFrameSize(unsigned S) { MaxCallFrameSize = S; }

    bool isInArgFI(int FI) const {
      return FI <= InArgFIRange.first && FI >= InArgFIRange.second;
    }
    void setLastInArgFI(int FI) { InArgFIRange.second = FI; }
    bool isOutArgFI(int FI) const {
      return FI <= OutArgFIRange.first && FI >= OutArgFIRange.second;
    }
    int getGPFI() const { return GPFI; }
    void setGPFI(int FI) { GPFI = FI; }
    bool isGPFI(int FI) const { return GPFI && GPFI == FI; }

    bool isDynAllocFI(int FI) const { return DynAllocFI && DynAllocFI == FI; }

    // Create a MachinePointerInfo that has an ExternalSymbolPseudoSourceValue
    // object representing a GOT entry for an external function.
    MachinePointerInfo callPtrInfo(const char *ES);

    // Create a MachinePointerInfo that has a GlobalValuePseudoSourceValue
    // object representing a GOT entry for a global function.
    MachinePointerInfo callPtrInfo(const GlobalValue *GV);

  private:
    virtual void anchor();

    MachineFunction &MF;

    // Some subtargets require that sret lowering includes returning the value
    // of the returned struct in a register. This field holds the virtual
    // register into which the sret argument is passed.
    unsigned SRetReturnReg;

    // Frame index for start of varargs area.
    int VarArgsFrameIndex;

    // True if function has a byval argument.
    bool HasByvalArg;

    // Size of incoming argument area.
    unsigned IncomingArgSize;

    // Whether the function calls llvm.eh.return.
    bool CallsEhReturn;

    // Whether the function calls llvm.eh.dwarf.
    bool CallsEhDwarf;

    // Frame objects for spilling eh data registers.
    bool EhDataRegFI[2];

    unsigned MaxCallFrameSize;

    bool EmitNOAT;

    // Keeps track of the virtual register initialized for use as the global
    // base register. This is used for PIC in some PIC relocation models.
    unsigned GlobalBaseReg;

    // Range of frame object indices.
    // InArgFIRange: Range of indices of all frame objects created during call
    //               to LowerFormalArguments.
    // OutArgFIRange: Range of indices of all frame objects created during call
    //                to LowerCall except for the frame object for restoring $gp.
    std::pair<int, int> InArgFIRange, OutArgFIRange;

    int GPFI;  // Index of the frame object for restoring $gp

    mutable int DynAllocFI; // Frame index of dynamically allocated stack area.

  };
} // End llvm namespace
#endif
