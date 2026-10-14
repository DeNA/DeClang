import TestFramework
// Importing the companion private Clang module is what causes
// LLDB to see the private @objc property as ambiguous.
import TestFramework_Private

func main() {
    let o = TestObject()
    print(o.privateDetail) // break here
}
main()
