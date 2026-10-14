// RUN: rm -rf %t.dir && mkdir -p %t.dir

/// Check use pgo profile.
// RUN: llvm-profdata merge -o %t.profdata %S/Inputs/pgo.profraw
// RUN: %clang -cc1depscan -fdepscan=inline -o %t1.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.profdata
// RUN: rm %t.profdata
// RUN: %clang @%t1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

/// Check change profile data will cause cache miss.
// RUN: llvm-profdata merge -o %t.profdata %S/Inputs/pgo2.profraw
// RUN: %clang -cc1depscan -fdepscan=inline -o %t2.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.profdata
// RUN: not diff %t.rsp %t2.rsp
// RUN: %clang @%t2.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS

// CACHE-MISS: remark: compile job cache miss
// CACHE-HIT: remark: compile job cache hit

/// Check remapping for profile.
// RUN: mkdir -p %t.dir/a && mkdir -p %t.dir/b
// RUN: cp %t.profdata %t.dir/a/a.profdata
// RUN: cp %t.profdata %t.dir/b/a.profdata
// RUN: %clang -cc1depscan -fdepscan=inline -o %t4.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/a /testdir  \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/a/a.profdata
// RUN: %clang -cc1depscan -fdepscan=inline -o %t5.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/b /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/b/a.profdata
// RUN: cat %t4.rsp | FileCheck %s --check-prefix=REMAP
// RUN: %clang @%t4.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t5.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

// RUN: cat %t4.rsp | sed \
// RUN:   -e "s/^.*\"-fcas-include-tree\" \"//" \
// RUN:   -e "s/\" .*$//" > %t.dir/cache-key1
// RUN: cat %t5.rsp | sed \
// RUN:   -e "s/^.*\"-fcas-include-tree\" \"//" \
// RUN:   -e "s/\" .*$//" > %t.dir/cache-key2
// RUN: grep llvmcas %t.dir/cache-key1
// RUN: diff -u %t.dir/cache-key1 %t.dir/cache-key2

// REMAP: -fprofile-instrument-use-path={{/|\\\\}}testdir{{/|\\\\}}a.profdata

/// Check use of sample profile.
// RUN: cp %S/Inputs/sample.prof %t.sample.prof
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-sample1.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.sample.prof
// RUN: rm %t.sample.prof
// RUN: %clang @%t-sample1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-sample1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

/// Check changing sample profile data causes a cache miss.
// RUN: cp %S/Inputs/sample2.prof %t.sample.prof
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-sample2.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.sample.prof
// RUN: not diff %t-sample1.rsp %t-sample2.rsp
// RUN: %clang @%t-sample2.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS

/// Check prefix mapping for sample profile.
// RUN: mkdir -p %t.dir/sa && mkdir -p %t.dir/sb
// RUN: cp %S/Inputs/sample.prof %t.dir/sa/sample.prof
// RUN: cp %S/Inputs/sample.prof %t.dir/sb/sample.prof
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-sample3.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/sa /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.dir/sa/sample.prof
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-sample4.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/sb /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.dir/sb/sample.prof
// RUN: cat %t-sample3.rsp | FileCheck %s --check-prefix=SAMPLE-REMAP
// RUN: %clang @%t-sample3.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-sample4.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

// SAMPLE-REMAP: -fprofile-sample-use={{/|\\\\}}testdir{{/|\\\\}}sample.prof

/// Check prefix mapping for remapping file (pgo instrument-use).
// RUN: mkdir -p %t.dir/ra && mkdir -p %t.dir/rb
// RUN: cp %t.profdata %t.dir/ra/a.profdata
// RUN: cp %t.profdata %t.dir/rb/a.profdata
// RUN: cp %S/Inputs/profile-remap.map %t.dir/ra/remap.map
// RUN: cp %S/Inputs/profile-remap.map %t.dir/rb/remap.map
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-rmap3.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/ra /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/ra/a.profdata -fprofile-remapping-file=%t.dir/ra/remap.map
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-rmap4.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/rb /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/rb/a.profdata -fprofile-remapping-file=%t.dir/rb/remap.map
// RUN: cat %t-rmap3.rsp | FileCheck %s --check-prefix=RMAP-REMAP
// RUN: %clang @%t-rmap3.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-rmap4.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

// RMAP-REMAP: -fprofile-remapping-file={{/|\\\\}}testdir{{/|\\\\}}remap.map

/// Check use of sample profile with a profile remapping file.
// RUN: cp %S/Inputs/sample.prof %t.sample.prof
// RUN: cp %S/Inputs/profile-remap.map %t.remap.map
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-srmap1.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.sample.prof -fprofile-remapping-file=%t.remap.map
// RUN: rm %t.sample.prof %t.remap.map
// RUN: %clang @%t-srmap1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-srmap1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

/// Check prefix mapping for remapping file (sample-use).
// RUN: mkdir -p %t.dir/sra && mkdir -p %t.dir/srb
// RUN: cp %S/Inputs/sample.prof %t.dir/sra/sample.prof
// RUN: cp %S/Inputs/sample.prof %t.dir/srb/sample.prof
// RUN: cp %S/Inputs/profile-remap.map %t.dir/sra/remap.map
// RUN: cp %S/Inputs/profile-remap.map %t.dir/srb/remap.map
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-srmap3.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/sra /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.dir/sra/sample.prof -fprofile-remapping-file=%t.dir/sra/remap.map
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-srmap4.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O3 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/srb /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.dir/srb/sample.prof -fprofile-remapping-file=%t.dir/srb/remap.map
// RUN: cat %t-srmap3.rsp | FileCheck %s --check-prefixes=SAMPLE-REMAP,RMAP-REMAP
// RUN: %clang @%t-srmap3.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-srmap4.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

/// Check prefix mapping for profile data file at -O0.
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-o0-prof1.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O0 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/a /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/a/a.profdata
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-o0-prof2.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O0 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/b /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/b/a.profdata
// RUN: cat %t-o0-prof1.rsp | FileCheck %s --check-prefix=REMAP
// RUN: %clang @%t-o0-prof1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-o0-prof2.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

/// Check prefix mapping for sample profile at -O0.
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-o0-sample1.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O0 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/sa /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.dir/sa/sample.prof
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-o0-sample2.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O0 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/sb /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-sample-use=%t.dir/sb/sample.prof
// RUN: cat %t-o0-sample1.rsp | FileCheck %s --check-prefix=SAMPLE-REMAP
// RUN: %clang @%t-o0-sample1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-o0-sample2.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT

/// Check prefix mapping for remapping file at -O0.
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-o0-rmap1.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O0 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/ra /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/ra/a.profdata -fprofile-remapping-file=%t.dir/ra/remap.map
// RUN: %clang -cc1depscan -fdepscan=inline -o %t-o0-rmap2.rsp -cc1-args -cc1 -triple x86_64-apple-macosx12.0.0 -emit-obj -O0 -Rcompile-job-cache -fdepscan-prefix-map %t.dir/rb /testdir \
// RUN:   -x c %s -o %t.o -fcas-path %t.dir/cas -fprofile-instrument-use=clang -fprofile-instrument-use-path=%t.dir/rb/a.profdata -fprofile-remapping-file=%t.dir/rb/remap.map
// RUN: cat %t-o0-rmap1.rsp | FileCheck %s --check-prefix=RMAP-REMAP
// RUN: %clang @%t-o0-rmap1.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-MISS
// RUN: %clang @%t-o0-rmap2.rsp 2>&1 | FileCheck %s --check-prefix=CACHE-HIT
