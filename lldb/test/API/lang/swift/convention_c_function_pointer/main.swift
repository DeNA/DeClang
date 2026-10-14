struct S {
    var callback: @convention(c) () -> ()
}

func noop() {}

func f() {
    let cFunc: @convention(c) () -> Void = noop
    let variable = S(callback: cFunc)
    print("break here") // break here
}

f()
