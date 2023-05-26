# SNES Language

The goal is to create some kind of programming language that hopefully makes
game development for the SNES (from scratch) a little less painful than it
usually is.

Does this generate fast assembly? Probably not that fast. This assembler uses
some idioms (such as local variables on the stack) which are slow by the
standards of the 65816. Generally, you will be able to write faster assembly
than this compiler can output. But that's not the point. The point is that you
don't *have* to write the assembly. You can focus on the algorithms and the
bigger picture of your project. That's the whole point of a programming
language, you know.

In any case, if it's too slow, even for Fast ROM, then we'll just cheat and use
SA-1.
