#import <TestFramework/TestFramework.h>

@interface TestObject (Private)
@property(readonly, copy) NSString *privateDetail;
@end
