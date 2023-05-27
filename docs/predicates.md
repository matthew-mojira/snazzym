# Predicates

A predicate represents some condition which may be true or false. It is not a
statement (it doesn't *do* anything) and it is not an expression (it does not
have a value). It is merely a computation that, when leveraged with certain
statements, affects the execution of a program.

Essentially, you can think of them as booleans, except they can only be used in
certain situations and can't be assigned to a variable.

## List of predicates

### Constant predicates

The following constant predicates are defined:
* `true`: always true
* `false`: always false

### Boolean predicates

The following operations are defined which take predicates as arguments:
* `(not p)`: true if `p` is false, true otherwise
* `(and p1 p2)`: true if `p1` and `p2` are both true, false otherwise
* `(or p1 p2)`: true if at least one of `p1` and `p2` are true, false otherwise

Both binary operators determine the truth value of the argument predicates from
left to right, and benefit from short circuit optimization.

### Integer predicates

The following comparisons are defined on integers:
* `(zero? i)`: true if `i` evaluates to 0, false otherwise
* `(nonzero? i)`: true if `i` does not evaluate to 0, false otherwise
* `(= i1 i2)`: true if `i1` evaluates to the same value as `i2`, false
  otherwise
* `(!= i1 i2)`: true if `i1` does not evaluate to the same value as `i2`,
  false otherwise
* `(> i1 i2)`: true if `i1` evaluates to a value greater than `i2`
* `(< i1 i2)`: true if `i1` evaluates to a value less than `i2`
* `(>= i1 i2)`: true if `i1` evaluates to a value greater than or equal to `i2`
* `(<= i1 i2)`: true if `i1` evaluates to a value less than or equal to `i2`

Note all integer comparisons are unsigned, and the evaluation order of binary
comparisons is left unspecified.

Constant folding optimization is used for `=`, `!=`, `<`, and `>=` when the
second argument is an integer literal.

## Statements with predicates

### Conditional statements

Conditional execution is done using the if statement:
```
(if p s1 s2 ... sn)
```
The list of statements `s1`,...,`sn` will execute if `p` is a true predicate.

```
(if-else p (s1 s2 ... sn) (t1 t2 ... tn))
```
The statements `s1`,...,`sn` will execute if `p` is a true predicate or
`t1`,...,`tn` will execute if `p` is a false predicate. Syntactically, the
statements of the true and false branches must be wrapped in a set of
parentheses. This is not the case for the regular `if`.

```
(cond
  [p1 (s1 ... sn)]
  [p2 (s1 ... sn)]
  ...
  [pn (s1 ... sn)])
```
Like a chain of elseifs, the cond block will determine the truth values of the
predicates in order and execute the associated statements for the first true
predicate. There is no requirement for an "else" branch for when all predicates
are false. One can be made using the `true` predicate.

### While loops

The syntax of the while loop is
```
(while p s1 ... sn)
```
The statements `s1`,...,`sn` will execute as long as `p` is a true predicate.
The predicate will be checked before any statments are allowed to execute.

## Ternary operator

The ternary operator is like an if statement, but it is an expression. This
means it evaluates to a value depending on a predicate, instead of executing
statements. The syntax is:
```
(if-expr p e1 e2)
```
The expression evaluates to `e1` if `p` is a true predicate and `e2` if it is
false.
