# Arrays

An array is a contiguous block of memory in RAM that can be used to store data.
An array declaration must be made at the top level as follows:

```scheme
(array id type size)
```

* `id` is the name of the array. The identifier itself is of type `long` and
  represents the address of the first element in the array.
* `type` is the type of the underlying elements (all elements must be of the
  same type). At the moment, arrays are supported for types `byte` and `word`
  only. In the future there will be support of arrays of type `long`.
* `size` is the number of elements in the array (not the size in bytes).

The memory for arrays in RAM is allocated sequentially starting at $7E2000.
There is no check for arrays that cross the bank $7E/7F boundary or that go
beyond RAM.

## Array operations

Setting an element in an array is done with the statement
```scheme
(array-set! id index elem)
```
* `id` is the name of the array which must be known at compiletime. In the
  future, this may be an expression which evaluates to the chosen array.
* `index` is an integral expression which represents the index into the array.
  There is no check for an index beyond the end of the array.
* `elem` is an expression for the element that will be written into the array.
  This expression must be of the same type class as the underlying type of the
  array.

Getting an element in an array is done with
```scheme
(array-get id index)
```
which is an expression that evaluates to the selected element in the array.
* `id` is the name of the array which must be known at compiletime. In the
  future, this may be an expression which evaluates to the chosen array.
* `index` is an integral expression which represents the index into the array.
  There is no check for an index beyond the end of the array.
