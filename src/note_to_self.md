The evaluation order of binary operations is left unspecified and may change at
any time for optimization reasons. This is important in the case of expressions
where the evaluation has a side effect.

Bytes are automatically transformed to words when it is loaded into the
registers. This means operations on bytes may have extra information within the
accumulator that eventually gets ignored, so it should be okay. (NOT OKAY!!)
But it's
unoptimized.

It is not a goal of the language to support dynamic memory allocation. In the
cases where this might be desired,
