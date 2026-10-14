class State {
  init(x: Int) {
    number = x
    print("breakpoint 1")
  }

  var number : Int
}

struct S { var properties: Bool = true }

func f(_ strct : S) {
  print("breakpoint 2")
}

class C<T> {
  func g(_ t : T) {
    print("breakpoint 3")
  }
}

let s = S()
f(s)
State(x: 20)
C<S>().g(s)
