include(${CMAKE_CURRENT_LIST_DIR}/Apple-lldb-base.cmake)

set(LLVM_DISTRIBUTION_COMPONENTS
  lldb
  liblldb
  lldb-argdumper
  lldb-python-scripts
  lldb-server
  repl_swift
  CACHE STRING "")
