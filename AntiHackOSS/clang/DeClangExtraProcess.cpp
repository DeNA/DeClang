#include "clang/Driver/Compilation.h"
#include "llvm/Support/raw_ostream.h"

using namespace clang::driver;
using namespace clang;
using namespace llvm::opt;

void DeClangExtraProcess(const Compilation &C, const std::string& homeDir, llvm::raw_fd_ostream *logFile) {
  // do nothing
}
