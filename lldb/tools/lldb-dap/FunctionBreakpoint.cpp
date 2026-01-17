//===-- FunctionBreakpoint.cpp ----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "FunctionBreakpoint.h"
#include "DAP.h"
#include "JSONUtils.h"
#include "lldb/API/SBMutex.h"
#include <mutex>

namespace lldb_dap {

FunctionBreakpoint::FunctionBreakpoint(DAP &d, const llvm::json::Object &obj)
    : Breakpoint(d, obj), functionName(std::string(GetString(obj, "name"))) {}

void FunctionBreakpoint::SetBreakpoint() {
  lldb::SBMutex lock = dap.GetAPIMutex();
  std::lock_guard<lldb::SBMutex> guard(lock);

  if (functionName.empty())
    return;
  bp = dap.target.BreakpointCreateByName(functionName.c_str());
  Breakpoint::SetBreakpoint();
}

} // namespace lldb_dap
