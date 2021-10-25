; RUN: llc -mtriple=arm64_32-apple-watchos %s -o - | FileCheck %s

declare swifttailcc void @pointer_align_callee([8 x i64], i32, i32, i32, i8*)
define swifttailcc void @pointer_align_caller(i8* swiftasync %as, i8* %in) "frame-pointer"="all" {
; CHECK-LABEL: pointer_align_caller:
; CHECK: b _pointer_align_callee
  alloca i32
  musttail call swifttailcc void @pointer_align_callee([8 x i64] undef, i32 0, i32 1, i32 2, i8* %in)
  ret void
}
