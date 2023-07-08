# Todos

## New features

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
* Union types
  - useful in the case where there are multiple gamemodes, each requiring its
    own global area, but the global area between these game modes are mutually
    exclusive (saves allocation space)
  - declare how?
  - need to figure out more details. likely if it's going to be for game mode
    space optimization it will really be one huge union for all the global
    variables in a game mode
* Error handling function
  - errors should be when `BRK` instruction occurs, use extra byte for error
    info?
  - in theory the code our language generates should never error. should the
    user be able to make errors themselves? i.e. `(error #x42)`
  - catch all errors with overarching `(func void ([info byte]))` where `info`
    is that second byte if we include it
  - should we be able to return from an error? where? would need a kind of
    try/catch statement
* Add hardware registers as identifiers that can be stored/read directly
  without native blocks
  - think about the goals of the language, and whether or not this should be
    even possible, or if it is forced to only native code
* signed integers and comparison
* Multi-dimensional arrays

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
