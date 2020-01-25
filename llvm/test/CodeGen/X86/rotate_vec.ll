; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=bdver4 | FileCheck %s --check-prefixes=CHECK,XOP
; RUN: llc < %s -mtriple=x86_64-unknown -mcpu=skylake-avx512 | FileCheck %s --check-prefixes=CHECK,AVX512

define <4 x i32> @rot_v4i32_splat(<4 x i32> %x) {
; XOP-LABEL: rot_v4i32_splat:
; XOP:       # %bb.0:
; XOP-NEXT:    vprotd $31, %xmm0, %xmm0
; XOP-NEXT:    retq
;
; AVX512-LABEL: rot_v4i32_splat:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vprold $31, %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 1, i32 1, i32 1, i32 1>
  %2 = shl <4 x i32> %x, <i32 31, i32 31, i32 31, i32 31>
  %3 = or <4 x i32> %1, %2
  ret <4 x i32> %3
}

define <4 x i32> @rot_v4i32_non_splat(<4 x i32> %x) {
; XOP-LABEL: rot_v4i32_non_splat:
; XOP:       # %bb.0:
; XOP-NEXT:    vprotd {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    retq
;
; AVX512-LABEL: rot_v4i32_non_splat:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vprolvd {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 1, i32 2, i32 3, i32 4>
  %2 = shl <4 x i32> %x, <i32 31, i32 30, i32 29, i32 28>
  %3 = or <4 x i32> %1, %2
  ret <4 x i32> %3
}

define <4 x i32> @rot_v4i32_splat_2masks(<4 x i32> %x) {
; XOP-LABEL: rot_v4i32_splat_2masks:
; XOP:       # %bb.0:
; XOP-NEXT:    vprotd $31, %xmm0, %xmm0
; XOP-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    retq
;
; AVX512-LABEL: rot_v4i32_splat_2masks:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vprold $31, %xmm0, %xmm0
; AVX512-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 1, i32 1, i32 1, i32 1>
  %2 = and <4 x i32> %1, <i32 4294901760, i32 4294901760, i32 4294901760, i32 4294901760>

  %3 = shl <4 x i32> %x, <i32 31, i32 31, i32 31, i32 31>
  %4 = and <4 x i32> %3, <i32 0, i32 4294901760, i32 0, i32 4294901760>
  %5 = or <4 x i32> %2, %4
  ret <4 x i32> %5
}

define <4 x i32> @rot_v4i32_non_splat_2masks(<4 x i32> %x) {
; XOP-LABEL: rot_v4i32_non_splat_2masks:
; XOP:       # %bb.0:
; XOP-NEXT:    vprotd {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    retq
;
; AVX512-LABEL: rot_v4i32_non_splat_2masks:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vprolvd {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = lshr <4 x i32> %x, <i32 1, i32 2, i32 3, i32 4>
  %2 = and <4 x i32> %1, <i32 4294901760, i32 4294901760, i32 4294901760, i32 4294901760>

  %3 = shl <4 x i32> %x, <i32 31, i32 30, i32 29, i32 28>
  %4 = and <4 x i32> %3, <i32 0, i32 4294901760, i32 0, i32 4294901760>
  %5 = or <4 x i32> %2, %4
  ret <4 x i32> %5
}

define <4 x i32> @rot_v4i32_zero_non_splat(<4 x i32> %x) {
; CHECK-LABEL: rot_v4i32_zero_non_splat:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vbroadcastss %xmm0, %xmm0
; CHECK-NEXT:    retq
  %1 = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %x, <4 x i32> %x, <4 x i32> <i32 0, i32 1, i32 2, i32 3>)
  %2 = shufflevector <4 x i32> %1, <4 x i32> undef, <4 x i32> zeroinitializer
  ret <4 x i32> %2
}

define <4 x i32> @rot_v4i32_allsignbits(<4 x i32> %x, <4 x i32> %y) {
; CHECK-LABEL: rot_v4i32_allsignbits:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vpsrad $31, %xmm0, %xmm0
; CHECK-NEXT:    retq
  %1 = ashr <4 x i32> %x, <i32 31, i32 31, i32 31, i32 31>
  %2 = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %1, <4 x i32> %1, <4 x i32> %y)
  ret <4 x i32> %2
}

define <4 x i32> @rot_v4i32_mask_ashr0(<4 x i32> %a0) {
; XOP-LABEL: rot_v4i32_mask_ashr0:
; XOP:       # %bb.0:
; XOP-NEXT:    vpsravd {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    vprotd $1, %xmm0, %xmm0
; XOP-NEXT:    vpsravd {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    retq
;
; AVX512-LABEL: rot_v4i32_mask_ashr0:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vpsravd {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    vprold $1, %xmm0, %xmm0
; AVX512-NEXT:    vpsravd {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = ashr <4 x i32> %a0, <i32 25, i32 26, i32 27, i32 28>
  %2 = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %1, <4 x i32> %1, <4 x i32> <i32 1, i32 1, i32 1, i32 1>)
  %3 = ashr <4 x i32> %2, <i32 1, i32 2, i32 3, i32 4>
  %4 = and <4 x i32> %3, <i32 -32768, i32 -65536, i32 -32768, i32 -65536>
  ret <4 x i32> %4
}

define <4 x i32> @rot_v4i32_mask_ashr1(<4 x i32> %a0) {
; XOP-LABEL: rot_v4i32_mask_ashr1:
; XOP:       # %bb.0:
; XOP-NEXT:    vpsrad $25, %xmm0, %xmm0
; XOP-NEXT:    vmovdqa {{.*#+}} xmm1 = [1,2,3,4]
; XOP-NEXT:    vprotd %xmm1, %xmm0, %xmm0
; XOP-NEXT:    vpbroadcastd %xmm0, %xmm0
; XOP-NEXT:    vpsravd %xmm1, %xmm0, %xmm0
; XOP-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; XOP-NEXT:    retq
;
; AVX512-LABEL: rot_v4i32_mask_ashr1:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovdqa {{.*#+}} xmm1 = [1,2,3,4]
; AVX512-NEXT:    vpsrad $25, %xmm0, %xmm0
; AVX512-NEXT:    vprolvd %xmm1, %xmm0, %xmm0
; AVX512-NEXT:    vpbroadcastd %xmm0, %xmm0
; AVX512-NEXT:    vpsravd %xmm1, %xmm0, %xmm0
; AVX512-NEXT:    vpand {{.*}}(%rip), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = ashr <4 x i32> %a0, <i32 25, i32 26, i32 27, i32 28>
  %2 = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %1, <4 x i32> %1, <4 x i32> <i32 1, i32 2, i32 3, i32 4>)
  %3 = shufflevector <4 x i32> %2, <4 x i32> undef, <4 x i32> zeroinitializer
  %4 = ashr <4 x i32> %3, <i32 1, i32 2, i32 3, i32 4>
  %5 = and <4 x i32> %4, <i32 -4096, i32 -8192, i32 -4096, i32 -8192>
  ret <4 x i32> %5
}

declare <4 x i32> @llvm.fshl.v4i32(<4 x i32>, <4 x i32>, <4 x i32>)
