//===-- Cpu0DelUselessJMP.cpp - Cpu0 Delete JMP Pass ------------*- C++ -*-===//
//
//                    The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "Cpu0TargetMachine.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/Statistic.h"

using namespace llvm;

#define DEBUG_TYPE "del-jmp"

STATISTIC(NumDelJmp, "Number of useless jmp deleted");

static cl::opt<bool> EnableDelJmp(
  "enable-cpu0-del-useless-jmp",
  cl::init(true),
  cl::desc("Delete useless jmp instruction: jmp 0."),
  cl::Hidden
);

namespace {
  struct DelJmp : public MachineFunctionPass {
    static char ID;
    DelJmp(TargetMachine &tm)
      : MachineFunctionPass(ID) { }

    StringRef getPassName() const override {
      return "Cpu0 Del Useless jmp";
    }

    bool runOnMachineBasicBlock(MachineBasicBlock &MBB,
                                MachineBasicBlock &MBBN);

    bool runOnMachineFunction(MachineFunction &F) override {
      bool Changed = false;
      if (EnableDelJmp) {
        MachineFunction::iterator FJ = F.begin();
        if (FJ != F.end())
          FJ++;
        if (FJ == F.end())
          return Changed;
        for (MachineFunction::iterator FI = F.begin(), FE = F.end();
             FJ != FE; ++FI, ++FJ) {
          Changed |= runOnMachineBasicBlock(*FI, *FJ);
        }
      }
      return Changed;
    }
  };
  char DelJmp::ID = 0;
} // end of anonymous namespace

bool DelJmp::
runOnMachineBasicBlock(MachineBasicBlock &MBB, MachineBasicBlock &MBBN) {
  bool Changed = false;

  MachineBasicBlock::iterator I = MBB.end();
  if (I != MBB.begin())
    I--;               // set I to the last instruction
  else
    return Changed;

  if (I->getOpcode() == Cpu0::JMP && I->getOperand(0).getMBB() == &MBBN) {
    // I is the instruction of "jmp #offset=0", as follows,
    //     jmp     $BB0_3
    //  $BB0_3:
    //     ld      $4, 28($sp)
    ++NumDelJmp;
    MBB.erase(I);
    Changed = true;
  }
  return Changed;
}

/// createCpu0DelJmpPass - Return a pass that DelJmp in Cpu0 MachineFunctions
FunctionPass *llvm::createCpu0DelJmpPass(Cpu0TargetMachine &tm) {
  return new DelJmp(tm);
}
