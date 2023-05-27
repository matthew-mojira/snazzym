# Integers

The types `byte` and `word` are members of the integral type class, which
allows for shared commonalities between the two.

## Integer conversion rules

All integer operations are done with 16-bit integers. Loading a variable of
type `byte` will result in the promotion of the byte to a word; this is done by
prepending 0 as the upper byte. Storing to a variable of type `byte` will
discard the upper byte and only store the lower byte.

The practical upshot of this is that operations on bytes should work as
expected, and mixing bytes and words should not mess things up. As far as type
checking is concerned, bytes and words are completely interchangable.

## Integral expressions

The following expressions are defined on integers:
* `(<< i)`: takes the arithmetic shift left of `i`
* `(>> i)`: takes the arithmetic shift right of `i`
* `(1+ i)`: takes the successor element of `i`
* `(1- i)`: takes the predecessor element of `i`
* `(+ i1 i2)`: takes the sum of `i1` and `i2`
* `(- i1 i2)`: takes the difference of `i2` and `i1` (essentially `i1 - i2`)
* `(bit-not i)`: takes the bitwise negation of `i`
* `(bit-and i1 i2)`: takes the bitwise conjunction of `i1` and `i2`
* `(bit-or i1 i2)`: takes the bitwise disjunction of `i1` and `i2`

All binary operations have constant folding optimization for when the second
constant is an integer literal.
