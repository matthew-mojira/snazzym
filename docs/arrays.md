# Arrays

An array is a contiguous block of memory in RAM that can be used to store data.
An array declaration must be made at the top level as follows:

```scheme
(array id type size)
```

* `id` is the name of the array.
* `type` is the type of the underlying elements (all elements must be of the
  same type).
* `size` is the number of elements in the array (not the size in bytes).

The memory for arrays in RAM is allocated sequentially starting at $7E2000.
There is no check for arrays that cross the bank $7E/7F boundary or that go
beyond RAM.

## Array operations

Setting an element in an array is done with the statement
```scheme
(array-set! a index elem)
```
* `a` is the array, which may be an expression which evaluates to the chosen
  array.
* `index` is an integral expression which represents the index into the array.
  There is no check for an index beyond the end of the array.
* `elem` is an expression for the element that will be written into the array.
  This expression must be of the same type class as the underlying type of the
  array.

Getting an element in an array is done with
```scheme
(array-get a index)
```
which is an expression that evaluates to the selected element in the array.
* `a` is the the array which may be an expression which evaluates to the chosen
  array.
* `index` is an integral expression which represents the index into the array.
  There is no check for an index beyond the end of the array.
