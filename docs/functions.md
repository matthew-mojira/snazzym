# Functions

Of course, you can define functions that do things. Functions can be defined on
the top level with

```
(func (id type ([x1 t1] [x2 t2] ... [xn tn])) s1 s2 ... sn)
```
* `id` is the name of the function
* `type` is the return type of the function
* each `[xi ti]` defines a parameter with name `xi` of type `ti`
* `s1`,...,`sn` are the statements that define the body of the function

## Returning from a function

Returns can be done with `(return e)` where `e` is an expression with the same
type as the return type. For functions that of return type `void` you would
have to return the void object `()`.

There is no check to determine whether any function returns; without a return
execution may continue beyond the end of a function. The behavior in that case
is left unspecified. There is also no check for redundant `return`s or any
check about unreachable code following a `return`.
