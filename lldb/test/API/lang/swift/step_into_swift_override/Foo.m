#import "Foo.h"
extern pointer_t class_getMethodImplementation(Class, SEL);

@implementation Foo

- (id)init {
  return self;
}

- (void) callOverride {
  Class my_class = [self class];
  SEL my_sel = sel_getUid("doSomething");
  pointer_t real_addr = class_getMethodImplementation(my_class, my_sel);
  //pointer_t real_addr_2 = class_getMethodImplementation(self->isa, my_sel);
  [self doSomething]; // break here
}

- (void) doSomething {
  NSLog(@"100");
}
@end
