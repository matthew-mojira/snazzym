# Native code

For when this language isn't enough, native assembly code can be written using
the native block. The syntax is
```scheme
(native i1 i2 ... in)
```
Where each `ij` is an instruction written in `asar` syntax encoded in a string.
For example, it could look like
```scheme
(native
  "LDA.B $00"
  "STA.W $1000")
```
The strings in a native block are compiled verbatim with a newline separating
each line. Potentially, you could include all kinds of `asar` macros and
directives in here, but it's on you to make sure it doesn't break the
compilation of anything else.

## Using language-allocated variables

Access to global variables and other functions are available because they are
compiled with label names similar to its identifier in the language. The
compiled label name is the same, except all non-alphanumeric characters are
replaced with underscores. So something like `thing/table-1` would be available
as the label `thing_table_1`.

Global variables are allocated in RAM starting at address $7E0010. There is
technically no limit to the number of global variables, which may conflict with
the stack eventually (or even go beyond the mirror of RAM in bank 0). Arrays
and other large structures in RAM are allocated starting at address $7E2000.
Again, there is no check for allocations that eventually go beyond the RAM
area.

## Calling conventions and invariants

The calling convention defines the expectations that a function has regarding
where it should put arguments and receive outputs. To ensure compatibility
between natively defined functions and language-defined functions, follow these
rules.

Regarding the placement of arguments to a function:
* All arguments are placed on the stack. They are pushed from left to right,
  and the size of each push matches the size of the type. In other words, there
  is no need for stack alignment or other padding.
* The return value is placed above the arguments. All function calls use long
  addressing, so `JSL` and `RTL` can be used to jump and return as expected.
* The caller is responsible for deallocating the space on the stack for the
  function arguments after execution returns from the function.

Regarding the placement of the return value of a function:
* For `void` type, nothing is returned, so the accumulator can be anything.
* For `byte` and `word` types, the return value is in the accumulator. When
  returning, the zero flag should reflect whether the return value is 0 or not.
* For `byte`, the upper byte of the accumulator does not necessarily have to be
  0. The caller should clear the upper byte to ensure no unintended side
  effects.
  (Note to self: the callee should sanitize the upper byte; fix this later).
* For `long` type, the lower 16-bits should be the in the accumulator and the
  bank byte should be in the X index register.

Regarding the state of the registers/processor:
* The accumulator must be in 16-bit mode and the index registers in 8-bit mode.
  Of course you can change these inside a function, but it should be set back
  to this before returning.
* The data bank register and direct register must both be 0.
* The stack pointer should be the same (a pull for every push). Essentially,
  the `RTL` instruction should be pulling the same return address that was
  pushed with `JSL`.

The first 16 bytes of the zero page (addresses $7E0000 to $7E000F) are
available as scratch area. This area is caller-saved; there is no expectation
that this memory will be preserved across function calls.
