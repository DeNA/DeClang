func f() {
  let sendable: any Sendable = 1
  let bitwiseCopyable: any BitwiseCopyable = 2
  let sendableAndBitwise: any Sendable & BitwiseCopyable = 3
  let realAndSendable: any Hashable & Sendable = 4

  print("break here")
}

f()
