import Foo

func f() {
  let variable: Foo? = Foo()
  print("break here") // break here
  _ = variable
}

f()
