import Foundation

@objc public class TestObject: NSObject {
    @objc internal var privateDetail: String {
        return "private detail: internal implementation info"
    }
}
