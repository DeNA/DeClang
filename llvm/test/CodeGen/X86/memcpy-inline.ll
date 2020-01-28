; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-linux-gnu -mcpu=core2 | FileCheck -check-prefix=X64 %s

declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture, i64, i1) nounwind
declare void @llvm.memcpy.inline.p0i8.p0i8.i64(i8* nocapture, i8* nocapture, i64, i1) nounwind

define void @test1(i8* %a, i8* %b) nounwind {
; X64-LABEL: test1:
; X64:       # %bb.0:
; X64-NEXT:    movq (%rsi), %rax
; X64-NEXT:    movq %rax, (%rdi)
; X64-NEXT:    retq
; R600: LLVM ERROR
  tail call void @llvm.memcpy.inline.p0i8.p0i8.i64(i8* %a, i8* %b, i64 8, i1 0 )
  ret void
}

define void @regular_memcpy_calls_external_function(i8* %a, i8* %b) nounwind {
; X64-LABEL: regular_memcpy_calls_external_function:
; X64:       # %bb.0:
; X64-NEXT:    movl $128, %edx
; X64-NEXT:    jmp memcpy # TAILCALL
  tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* %a, i8* %b, i64 128, i1 0 )
  ret void
}

define void @inlined_copy_doesnt_call_external_function(i8* %a, i8* %b) nounwind {
; X64-LABEL: inlined_copy_doesnt_call_external_function:
; X64:       # %bb.0:
; X64-NEXT:    movl $128, %ecx
; X64-NEXT:    rep;movsb (%rsi), %es:(%rdi)
; X64-NEXT:    retq
  tail call void @llvm.memcpy.inline.p0i8.p0i8.i64(i8* %a, i8* %b, i64 128, i1 0 )
  ret void
}
