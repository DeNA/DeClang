add_llvm_component_library(LLVMCpu0Desc
  Cpu0ABIInfo.cpp
  Cpu0MCAsmInfo.cpp
  Cpu0MCTargetDesc.cpp
  Cpu0AsmBackend.cpp
  Cpu0MCCodeEmitter.cpp
  Cpu0MCExpr.cpp
  Cpu0ELFObjectWriter.cpp
  Cpu0ELFStreamer.cpp
  Cpu0TargetStreamer.cpp

  LINK_COMPONENTS
  MC
  Cpu0Info
  Support
  Cpu0AsmPrinter

  ADD_TO_COMPONENT
  Cpu0
  )
