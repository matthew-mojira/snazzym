# Identifiers



## Internally

All identifiers are compiled with the attempt to preserve the original
identifier name. For example, the following code
```
(global x word)
(func (foo word ())
  (return x))
```
would be compiled as
```
org $7E0010
x: skip 2
foo:
  LDA.B x
  RTL
```
with the identifiers left intact as label names.

The rules for identifiers in scheme is less restrictive than in asar.
Multi-word identifier names are hypenated `like-this`. Namespaces are
informally separated using `/` e.g. `oam/table`. These characters are illegal
for a label name in asar. The rule to convert identifiers to labels is that any
non-alphanumeric character is changed to `_`. This means that *different*
identifiers could lead to the same label name, which may be a conflict.

Identifiers of local variables are not saved in the compiled assembly. They are
automatically converted to the stack offset value (which may change depending
on new bindings in a local environment).

## Duplicate identifiers

There are no checks whatsoever regarding duplicate identifiers from the
compiler's perspective. The assembler may warn depending on which identifiers
have been duplicated during the assembly phase.

There is defined behavior for variable shadowing, when a variable defined in a
local environment shadows a definition of a global variable, function
parameter, or another local variable in an enclosing scope.

Besides local variable shadowing, you should not rely on defining duplicate
names at the same level. The behavior of what the variable actually refers to
is left undefined.
