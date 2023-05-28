# Local variables

Local variables can be declared using a `local` block:
```
(local ([id1 t1] [id2 t2] ... [idn tn]) s1 s2 ... sn)
```
Each `[id1 t1]` defines a declaration of a local variable with name `id1` of
type `t1`. The statements `s1`,...,`sn` are then executed in the scope of the
local variables that have been declared.

Local variables are **not** initialized with any value. The result of using a
local variable before it is given a value is left unspecified.

## Shadowing and name conflicts

Local blocks can be nested. A declaration with the same identifier in an inner
scope will shadow the declaration of the outer block:
```
(local ([x byte])
  (local ([x word])
    ...))
```
A local block will also shadow function parameters and global variables or
other identifiers declared on the top level.

There is no checking to determine duplicate declarations within the same local
block:
```
(local ([x byte] [x long])
  ...)
```
In this case, the actual `x` being referred to is left unspecified.
