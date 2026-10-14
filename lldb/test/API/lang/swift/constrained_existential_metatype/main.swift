public protocol MyProto<T> {
    associatedtype T
}

public struct MyImpl: MyProto {
    public typealias T = Int
}

public func myAnyType(
    _ x: any MyProto<Int>
) -> any MyProto<Int>.Type {
    return type(of: x)
}

func f() {
    let c: any MyProto<Int> = MyImpl()
    let variable = myAnyType(c)
    print("break here")
    _ = variable
}

f()
