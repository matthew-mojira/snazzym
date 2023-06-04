# The type system


## Flat types

The language contains 4 distinct flat types:
* `void`
* `byte`
* `word`
* `long`
These types are identified by how many bytes they take up, being 0, 1, 2, and 3
respectively.

## Compound types

The language contains 2 compound types:
* `array ELEM_TYPE`
* `func RET_TYPE (ARG_TYPE*)`
These types are represented as pointers (explained in a later section).

## Enumerated types

Enumerated types may be declared

## Integers

The `byte` and `word` types are members of the `int` type class. They support
integer arithmetic expressions, like addition and subtraction, as well as
comparison predicates. They may be considered unsigned or signed depending on
your use case, however the comparison predicates are all unsigned.

## Pointers

The `long` type and the array and function types are all considered pointers.
This language only considers the full 24-bit pointer of the data. The array
type is the address of the first element of the array in RAM and function type
represents the address of the function in ROM.

The `long` type is a generic pointer type. Array and function pointer types are
stored as their raw address, so they can be cast to `long` type without issue.
However, it cannot be cast the other way.

## Constants

Expressions and variables whose values are constant are typed as `const`
internally. These may be compiled differently than the non-`const` version as
an optimization. The following are situations in which the type gets the
`const` qualifier:
* arrays and functions declared on the top level
* enumeration constants
* integer literals and integral expressions where all subexpressions are
  constant
In the case of integer literals, it is the value that is considered constant.
For array and function pointers, the name of the initial declaration is the
constant.

Constant types cannot be declared manually by the user; it is only an internal
feature.
