#lang brag


statement:


call:
return:
conditional:
assignment:
local:
while:
native:
array_assign:

type: VOID
  | BYTE
  | WORD
  | LONG
  | /LEFT-PAREN ARRAY type /RIGHT-PAREN
  | /LEFT-PAREN FUNC type /LEFT-PAREN type* /RIGHT-PAREN /RIGHT-PAREN


predicate: TRUE | FALSE | disjunction
disjunction:  conjunction "or" disjunction | conjunction
conjunction:  equality "and" conjunction | equality
equality:     relational EQ-OP equality | relational
relational:   unary REL-OP relational | unary
unary:        "not" unary
