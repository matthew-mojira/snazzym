# Todos

## New features

* Dependent types (function/array types)
  - Should be able to declare array types like `[x (array byte)]`, note no
    information about the length of the array (note: this is a pointer to
    the array!! it would be a mess to pass around the actual array!!)
  - Function types can be something like `[f (func byte (word long))]`
  - need to be fully type checked everywhere
  - what happens to type `long`?
* Function pointers
  - functions are constants and so should be able to be stored into variables
    of functional type
  - need this for the below item
* Dynamic function calls
  - looks like `(call f arg1 arg2 ... argn)`
  - may not need `call`, just transform all calls to be dynamic, and use
    constant folding optimization
  - need to be able to get the type of `f` here, makes things easy
* Dynamic array accesses
  - like the above except for `array-get` and `array-set!`
  - use constant folding in the case the first argument is already an array,
    and not a local variable/shadowed thing
* Constant tables
* constants
  - top level declaration, substitution made when? (an early substitution may
    mean we lose the ability to leverage assembler labels/constants)
  - const expression must be a literal expression (should literal expressions
    include arithmetic between literal expressions?)
  - `(const max-points 100)`
* inlined functions
  - standard library would like this very much
  - maybe they shouldn't be functions? will conflict with func pointers
  - perhaps just make it a macro (need to ensure hygiene)
* enumerated types
  - `(enum type (id1 id2 ... idn))`
  - just a bunch of constants starting from 0 counting up
  - don't support integer operations. type is explicit
  - `switch` case on enumerated types. use jump tables (enums assigned in order
    to keep size of table at its minimum)
* Struct types
  - declare with `(struct name ([id1 t1] [id2 t2] ... [idn tn]))`
  - can declare global variables and arrays only (Idea: if it can fit in the
    registers, it can be a local type, hence no arrays as parameters)
* Error handling function
  - errors should be when `BRK` instruction occurs, use extra byte for error
    info?
  - in theory the code our language generates should never error. should the
    user be able to make errors themselves? i.e. `(error #x42)`
  - catch all errors with overarching `(func void ([info byte]))` where `info`
    is that second byte if we include it
  - should we be able to return from an error? where? would need a kind of
    try/catch statement

## Optimizations

* expansion of constant folding optimization
  - more comparisons
  - first argument constant folding
* optimization: do not try to get return value on a function call whose result
  is thrown away
* More standard library functions
  - properly document each one
  - implement more everywhere
  - think about high level library functions (e.g. stripe image loaders,
    buffers)
* Rethink runtime scheme
  - or document it better
  - the runtime does things outside the function call... should the user be
    able to control it themselves more?

## Pipe dreams

* Organize racket files better
* A better grammar?
  - see sample docs
* Documentation
  - a real website?
* Learn the SNES APU
