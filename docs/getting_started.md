# Getting started

Each file must have the declaration
```scheme
#lang snazzym
```
on the first line.

Each program must have the following functions defined:
* `(define (init void ()) ... )`: this function is run once at the start of the
  program once the SNES is finished initialization
* `(define (main void ()) ... )`: this function represents the "main game loop"
  and is run every frame while the PPU is drawing an image to the screen
* `(define (vblank void ()) ... )`: this function is run during every VBlank
  period when NMIs are enabled

There is only a check for if the functions are defined. There is no checking if
the function signature matches the above. The behavior when adding parameters
or changing the return type is left unspecified.

## Todo

Need to clarify what exactly gets initialized before the `init` function and
also what bookkeeping happens outside of calling the `vblank` function in the
NMI handler.
