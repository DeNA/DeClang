/// Workaround for DWARFImporter-only mode.
///
/// This test is using Array types in the expression evaluator that
/// are not used by the program itself. With ClangImporter disabled,
/// the DWARF type definition for _storage is searched for in the
/// SwiftShims module in the Clang module cache of the Swift
/// stdlib. Unfortunately many bots clean the module cache between
/// individual runs, so we need to force DWARF for this type to be
/// generated by importing SwiftShims here manually.
/// \{
import SwiftShims
/// \}

func main() -> Int {
  let names = ["foo", "patatino"]

  var reversedNames = names.sorted(by: {
    $0 > $1 } //%self.expect('p $0', substrs=['patatino'])
              //%self.expect('p $1', substrs=['foo'])
              //%self.expect('frame var $0', substrs=['patatino'])
              //%self.expect('frame var $1', substrs=['foo'])
  )

  var tinky = [1,2].map({
    $0 * 2 //%self.expect('expr [12, 14].map({$0 + 2})', substrs=['[0] = 14', '[1] = 16'])
  })

  return 0 //%self.expect('expr tinky.map({$0 * 2})', substrs=['[0] = 4', '[1] = 8'])
           //%self.expect('expr [2,4].map({$0 * 2})', substrs=['[0] = 4', '[1] = 8'])
           //%self.expect('expr $0', substrs=['unresolved identifier \'$0\''], error=True)
}

_ = main()
