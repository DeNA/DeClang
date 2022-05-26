add_llvm_component_library(LLVMCpu0Disassembler
  Cpu0Disassembler.cpp

  LINK_COMPONENTS
  MCDisassembler 
  Support 
  Cpu0Info

  ADD_TO_COMPONENT
  Cpu0
)
