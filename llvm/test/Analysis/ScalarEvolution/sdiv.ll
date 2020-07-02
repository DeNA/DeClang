; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py
; RUN: opt < %s -scalar-evolution -analyze | FileCheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define dso_local void @_Z4loopi(i32 %width) local_unnamed_addr #0 {
; CHECK-LABEL: '_Z4loopi'
; CHECK-NEXT:  Classifying expressions for: @_Z4loopi
; CHECK-NEXT:    %storage = alloca [2 x i32], align 4
; CHECK-NEXT:    --> %storage U: [0,-3) S: [-9223372036854775808,9223372036854775805)
; CHECK-NEXT:    %0 = bitcast [2 x i32]* %storage to i8*
; CHECK-NEXT:    --> %storage U: [0,-3) S: [-9223372036854775808,9223372036854775805)
; CHECK-NEXT:    %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
; CHECK-NEXT:    --> {0,+,1}<nuw><nsw><%for.cond> U: [0,-2147483648) S: [0,-2147483648) Exits: %width LoopDispositions: { %for.cond: Computable }
; CHECK-NEXT:    %rem = sdiv i32 %i.0, 2
; CHECK-NEXT:    --> (zext i1 {false,+,true}<%for.cond> to i32) U: [0,2) S: [0,2) Exits: (zext i1 (trunc i32 %width to i1) to i32) LoopDispositions: { %for.cond: Computable }
; CHECK-NEXT:    %idxprom = sext i32 %rem to i64
; CHECK-NEXT:    --> (zext i1 {false,+,true}<%for.cond> to i64) U: [0,2) S: [0,2) Exits: (zext i1 (trunc i32 %width to i1) to i64) LoopDispositions: { %for.cond: Computable }
; CHECK-NEXT:    %arrayidx = getelementptr inbounds [2 x i32], [2 x i32]* %storage, i64 0, i64 %idxprom
; CHECK-NEXT:    --> ((4 * (zext i1 {false,+,true}<%for.cond> to i64))<nuw><nsw> + %storage)<nsw> U: [0,-3) S: [-9223372036854775808,9223372036854775805) Exits: ((4 * (zext i1 (trunc i32 %width to i1) to i64))<nuw><nsw> + %storage)<nsw> LoopDispositions: { %for.cond: Computable }
; CHECK-NEXT:    %1 = load i32, i32* %arrayidx, align 4
; CHECK-NEXT:    --> %1 U: full-set S: full-set Exits: <<Unknown>> LoopDispositions: { %for.cond: Variant }
; CHECK-NEXT:    %call = call i32 @_Z3adji(i32 %1)
; CHECK-NEXT:    --> %call U: full-set S: full-set Exits: <<Unknown>> LoopDispositions: { %for.cond: Variant }
; CHECK-NEXT:    %2 = load i32, i32* %arrayidx, align 4
; CHECK-NEXT:    --> %2 U: full-set S: full-set Exits: <<Unknown>> LoopDispositions: { %for.cond: Variant }
; CHECK-NEXT:    %add = add nsw i32 %2, %call
; CHECK-NEXT:    --> (%2 + %call) U: full-set S: full-set Exits: <<Unknown>> LoopDispositions: { %for.cond: Variant }
; CHECK-NEXT:    %inc = add nsw i32 %i.0, 1
; CHECK-NEXT:    --> {1,+,1}<nuw><%for.cond> U: [1,0) S: [1,0) Exits: (1 + %width) LoopDispositions: { %for.cond: Computable }
; CHECK-NEXT:  Determining loop execution counts for: @_Z4loopi
; CHECK-NEXT:  Loop %for.cond: backedge-taken count is %width
; CHECK-NEXT:  Loop %for.cond: max backedge-taken count is -1
; CHECK-NEXT:  Loop %for.cond: Predicated backedge-taken count is %width
; CHECK-NEXT:   Predicates:
; CHECK:       Loop %for.cond: Trip multiple is 1
;
entry:
  %storage = alloca [2 x i32], align 4
  %0 = bitcast [2 x i32]* %storage to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* %0) #4
  call void @llvm.memset.p0i8.i64(i8* align 4 %0, i8 0, i64 8, i1 false)
  br label %for.cond

for.cond:
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %cmp = icmp ne i32 %i.0, %width
  br i1 %cmp, label %for.body, label %for.cond.cleanup

for.cond.cleanup:
  call void @llvm.lifetime.end.p0i8(i64 8, i8* %0) #4
  ret void

for.body:
  %rem = sdiv i32 %i.0, 2
  %idxprom = sext i32 %rem to i64
  %arrayidx = getelementptr inbounds [2 x i32], [2 x i32]* %storage, i64 0, i64 %idxprom
  %1 = load i32, i32* %arrayidx, align 4
  %call = call i32 @_Z3adji(i32 %1)
  %2 = load i32, i32* %arrayidx, align 4
  %add = add nsw i32 %2, %call
  store i32 %add, i32* %arrayidx, align 4
  %inc = add nsw i32 %i.0, 1
  br label %for.cond
}

declare void @llvm.lifetime.start.p0i8(i64 immarg, i8* nocapture) #1

declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i1 immarg) #2

declare dso_local i32 @_Z3adji(i32) local_unnamed_addr #3

declare void @llvm.lifetime.end.p0i8(i64 immarg, i8* nocapture) #1
