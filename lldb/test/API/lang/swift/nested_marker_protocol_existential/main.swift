@_marker protocol Foo {}

extension Int: Foo {}

protocol Bar {
    var bar: Int { get }
}

struct Conformer: Foo, Bar {
    let bar: Int
}

public struct Box<T> {
    public var payload: T
    public var tag: Int
}

func f() {
    let bareMarker: any Foo = 1
    let bareComposition: any Foo & Bar = Conformer(bar: 2)
    let arrayOfMarker: [any Foo] = [5, 6, 7]
    let genericBox = Box<any Foo & Bar>(payload: Conformer(bar: 8), tag: 9)

    print("break here")
    print(bareMarker, bareComposition, arrayOfMarker, genericBox)
}

f()
