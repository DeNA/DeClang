// RUN: %clang_cc1 -triple x86_64-linux-gnu  -fsyntax-only -verify %s

void __attribute__((target("sse4.2"))) no_default(void);
void __attribute__((target("arch=sandybridge")))  no_default(void);

void use1(void){
  // expected-error@+1 {{no matching function for call to 'no_default'}}
  no_default();
}

void __attribute__((target("sse4.2"))) has_def(void);
void __attribute__((target("default")))  has_def(void);

void use2(void){
  // expected-error@+2 {{reference to overloaded function could not be resolved; did you mean to call it?}}
  // expected-note@-4 {{possible target for call}}
  +has_def;
}

int __attribute__((target("sse4.2"))) no_proto();
// expected-error@-1 {{multiversioned function must have a prototype}}
// expected-note@+1 {{function multiversioning caused by this declaration}}
int __attribute__((target("arch=sandybridge"))) no_proto();

// The following should all be legal, since they are just redeclarations.
int __attribute__((target("sse4.2"))) redecl1(void);
int __attribute__((target("sse4.2"))) redecl1(void) { return 1; }
int __attribute__((target("arch=sandybridge")))  redecl1(void) { return 2; }

int __attribute__((target("sse4.2"))) redecl2(void) { return 1; }
int __attribute__((target("sse4.2"))) redecl2(void);
int __attribute__((target("arch=sandybridge")))  redecl2(void) { return 2; }

int __attribute__((target("sse4.2"))) redecl3(void) { return 0; }
int __attribute__((target("arch=ivybridge"))) redecl3(void) { return 1; }
int __attribute__((target("arch=sandybridge")))  redecl3(void);
int __attribute__((target("arch=sandybridge")))  redecl3(void) { return 2; }

int __attribute__((target("sse4.2"))) redecl4(void) { return 1; }
int __attribute__((target("arch=sandybridge")))  redecl4(void) { return 2; }
int __attribute__((target("arch=sandybridge")))  redecl4(void);

int __attribute__((target("sse4.2"))) redef(void) { return 1; }
int __attribute__((target("arch=ivybridge"))) redef(void) { return 1; }
int __attribute__((target("arch=sandybridge")))  redef(void) { return 2; }
// expected-error@+2 {{redefinition of 'redef'}}
// expected-note@-2 {{previous definition is here}}
int __attribute__((target("arch=sandybridge")))  redef(void) { return 2; }

int __attribute__((target("default"))) redef2(void) { return 1;}
// expected-error@+2 {{redefinition of 'redef2'}}
// expected-note@-2 {{previous definition is here}}
int __attribute__((target("default"))) redef2(void) { return 1;}

int __attribute__((target("sse4.2"))) mv_after_use(void) { return 1; }
int use3(void) {
  return mv_after_use();
}

// expected-error@+1 {{function declaration cannot become a multiversioned function after first usage}}
int __attribute__((target("arch=sandybridge")))  mv_after_use(void) { return 2; }

int __attribute__((target("sse4.2,arch=sandybridge"))) mangle(void) { return 1; }
//expected-error@+2 {{multiversioned function redeclarations require identical target attributes}}
//expected-note@-2 {{previous declaration is here}}
int __attribute__((target("arch=sandybridge,sse4.2")))  mangle(void) { return 2; }

int prev_no_target(void);
int __attribute__((target("arch=sandybridge")))  prev_no_target(void) { return 2; }
// expected-error@-2 {{function declaration is missing 'target' attribute in a multiversioned function}}
// expected-note@+1 {{function multiversioning caused by this declaration}}
int __attribute__((target("arch=ivybridge")))  prev_no_target(void) { return 2; }

int __attribute__((target("arch=sandybridge")))  prev_no_target2(void);
int prev_no_target2(void);
// expected-error@-1 {{function declaration is missing 'target' attribute in a multiversioned function}}
// expected-note@+1 {{function multiversioning caused by this declaration}}
int __attribute__((target("arch=ivybridge")))  prev_no_target2(void);

void __attribute__((target("sse4.2"))) addtl_attrs(void);
//expected-error@+1 {{attribute 'target' multiversioning cannot be combined}}
void __attribute__((used,target("arch=sandybridge")))  addtl_attrs(void);

//expected-error@+1 {{attribute 'target' multiversioning cannot be combined}}
void __attribute__((target("default"), used)) addtl_attrs2(void);

//expected-error@+2 {{attribute 'target' multiversioning cannot be combined}}
//expected-note@+2 {{function multiversioning caused by this declaration}}
void __attribute__((used,target("sse4.2"))) addtl_attrs3(void);
void __attribute__((target("arch=sandybridge")))  addtl_attrs3(void);

void __attribute__((target("sse4.2"))) addtl_attrs4(void);
void __attribute__((target("arch=sandybridge")))  addtl_attrs4(void);
//expected-error@+1 {{attribute 'target' multiversioning cannot be combined}}
void __attribute__((used,target("arch=ivybridge")))  addtl_attrs4(void);

int __attribute__((target("sse4.2"))) diff_cc(void);
// expected-error@+1 {{attribute 'target' multiversioning cannot be combined with other attributes}}
__vectorcall int __attribute__((target("arch=sandybridge")))  diff_cc(void);

int __attribute__((target("sse4.2"))) diff_ret(void);
// expected-error@+1 {{multiversioned function declaration has a different return type}}
short __attribute__((target("arch=sandybridge")))  diff_ret(void);
