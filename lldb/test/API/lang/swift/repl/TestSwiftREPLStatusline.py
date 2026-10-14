import lldb
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test.lldbpexpect import PExpectTest


class TestSwiftREPLStatusline(PExpectTest):
    # PExpect uses many timeouts internally and doesn't play well
    # under ASAN on a loaded machine..
    @skipIfAsan
    @skipUnlessDarwin
    @swiftTest
    def test_repl_no_statusline_interleaving(self):
        """Test that statusline ANSI sequences don't interleave with REPL output."""
        self.launch(extra_args=["--repl"], executable=None, dimensions=(10, 60))

        # Wait for the REPL to be ready.
        self.child.expect_exact("1>")

        # Send an expression that produces multi-line output to expose any
        # interleaving.
        self.child.sendline('Array("0123456789")')
        for i, c in enumerate("0123456789"):
            self.child.expect_exact('[{}] = "{}"'.format(i, c))

        self.child.expect_exact("2>")

        self.quit()

    def setUpCommands(self):
        # TODO: Create a REPL test case class to avoid redefining these methods.
        return []  # REPL doesn't take any setup commands.

    def expect_prompt(self):
        pass  # No constant prompt on the REPL.
