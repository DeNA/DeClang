add_llvm_component_group(Cpu0)

set (LLVM_TARGET_DEFINITIONS Cpu0Asm.td)
tablegen(LLVM Cpu0GenAsmMatcher.inc -gen-asm-matcher)

set (LLVM_TARGET_DEFINITIONS Cpu0Other.td)

# Generate Cpu0GenRegisterInfo.inc and Cpu0GenInstrInfo.inc which included by
#  your hand code C++ files.
# Cpu0GenRegisterInfo.inc came from Cpu0RegisterInfo.td, Cpu0GenInstrInfo.inc
#  came from Cpu0InstrInfo.td.
tablegen(LLVM Cpu0GenRegisterInfo.inc -gen-register-info)
tablegen(LLVM Cpu0GenInstrInfo.inc -gen-instr-info)
tablegen(LLVM Cpu0GenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM Cpu0GenMCPseudoLowering.inc -gen-pseudo-lowering)
tablegen(LLVM Cpu0GenDAGISel.inc -gen-dag-isel)
tablegen(LLVM Cpu0GenCallingConv.inc -gen-callingconv)
tablegen(LLVM Cpu0GenCodeEmitter.inc -gen-emitter)
tablegen(LLVM Cpu0GenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM Cpu0GenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM Cpu0GenDisassemblerTables.inc -gen-disassembler)

# Cpu0CommonTableGen must be defined
add_public_tablegen_target(Cpu0CommonTableGen)

# Cpu0CodeGen should match with LLVMBuild.txt Cpu0CodeGen
add_llvm_target(Cpu0CodeGen
  Cpu0ISelDAGToDAG.cpp
  Cpu0SEISelDAGToDAG.cpp
  Cpu0TargetMachine.cpp
  Cpu0InstrInfo.cpp
  Cpu0ISelLowering.cpp
  Cpu0MachineFunctionInfo.cpp
  Cpu0RegisterInfo.cpp
  Cpu0FrameLowering.cpp
  Cpu0SEFrameLowering.cpp
  Cpu0SEInstrInfo.cpp
  Cpu0SEISelLowering.cpp
  Cpu0SERegisterInfo.cpp
  Cpu0Subtarget.cpp
  Cpu0TargetObjectFile.cpp
  Cpu0AsmPrinter.cpp
  Cpu0MCInstLower.cpp
  Cpu0AnalyzeImmediate.cpp
  Cpu0DelUselessJMP.cpp
  Cpu0DelaySlotFiller.cpp


  LINK_COMPONENTS
  CodeGen 
  Core 
  MC
  Cpu0Desc
  Cpu0Info
  SelectionDAG
  Support
  Target
  AsmPrinter
  Cpu0AsmPrinter

  ADD_TO_COMPONENT
  Cpu0
  )

add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
add_subdirectory(InstPrinter)
add_subdirectory(Disassembler)
add_subdirectory(AsmParser)
