add_llvm_component_library(LLVMCpu0AsmParser
  Cpu0AsmParser.cpp

  LINK_COMPONENTS
  Cpu0Desc 
  Cpu0Info 
  MC 
  MCParser 
  Support

  ADD_TO_COMPONENT
  Cpu0
  )
