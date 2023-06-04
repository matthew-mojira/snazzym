#lang racket

(require "ast.rkt")

(provide (all-defined-out))

(define/match (type->size type)
  [('word) 2]
  [('byte) 1]
  [('void) 0]
  [('ret) 3] ; return address, should never be definable in a program
  [('long) 3]
  [((list 'array _)) 3]
  [((list 'func _ _)) 3]
  [((list 'enum _)) 3])
; need enum stuff here

(define (lookup-type id vars)
  (match (findf (lambda (var) (equal? id (car var))) vars)
    [(cons _ t) t]
    [_ #f]))

; Notes on dependent types:

;; THIS GETS VERY OUT OF HAND QUICKLY!!!
;; THUS, WE NEED TO THINK:
;;  SHOULD CONSTANT VALUES BE IN SCOPE AS BOTH LVALUES AND RVALUES?
;;   THIS MEANS THAT INSTEAD OF MISUSED VARIABLES NOT BEING FOUND, WE WILL SEE
;;   THAT THE TYPES DO NOT MATCH (TRYING TO BIND TO A CONSTANT IDENTIFIER)
;;    NEED TO ENCODE INFORMATION ABOUT CONSTANT INTO THE TYPES
;;    MAY BE MORE SEAMLESS WITH FUTURE CONSTANTS SYSTEM
;;    MAY BE MORE INTUITIVE GIVEN NO DUPLICATE IDENTIFIER CHECKING

; Eventually we will have a new function that will combine all the extractions
; of the different top-level declarations (because the number of top-level
; declaration is beginning to get overwhelming, and many work exactly the same)
; which puts all relevant top-level declarations into one global environment.
; (This may also give us an opportunity to at least check for duplicate names
; on the top level.)

; So we expect the types to look like
; -- the following relevant for globals
; word
; byte
; long
; void
; -- other top level declarations
; array TYPE            -- the array ptr itself is a `const long`
; const TYPE            -- new constant declaration coming soon
; func RETTYPE ARGTYPE* -- the func ptr itself is a `const long`
; enum NAME             -- the name is the name of the whole type

; observation: the first four for globals are the only ones on this list that
; are not directly modifyable. so trying to assign to identifiers of the last 4
; kinds should not work

; each name should be cons'd with the type, so like:
; '(x . byte)
; or
; '(x array byte)
; or
; '(f func void (byte byte byte))

; Thought: Should we parse types as well?

;; DEPENDENT TYPES ARE LISTS! NON-DEPENDENT TYPES ARE NOT LISTS

(define (typeof-expr expr env)
  (match expr
    ; this const stuff is actually not needed at all for the type checker
    [(Int _) '(const word)]
    [(IntOp1 _ e) (typeof-expr e env)]
    [(IntOp2 _ e1 e2)
     (match* ((typeof-expr e1 env) (typeof-expr e2 env))
       [('(const word) '(const word)) '(const word)]
       [(_ _) 'word])]
    ; will this always lookup a function successfully?
    ; i.e. same problem as below
    [(Call id es) (extract-func-ret-type (typeof-expr id env))]
    [(Var id) (typeof-var id env)]
    [(Void) 'void]
    ; assumption: both types of ternary operator are the same! (checked above)
    [(Ternary _ e _) (typeof-expr e env)]
    ; do we know that this lookup always succeeds? in other words, do we know
    ; that `id` refers to an array always?
    ; (if the types are correct yes, but do we know that yet here?)
    [(ArrayGet id _) (extract-array-type (typeof-expr id env))]))

(define (typeof-var id env)
  (lookup-type id env))

(define (constant-type? type)
  (match type
    [(cons 'const _) #t]
    [_ #f]))

; cadr for ret type: (func void ()) |-cdr-> (void ()) |-car-> void
(define (extract-func-ret-type type)
  (cadr (extract-const type)))

(define (extract-func-arg-types type)
  (caddr (extract-const type)))

(define (extract-array-type type)
  (cadr (extract-const type)))

(define (extract-const type)
  (match type
    [(list 'const t) t]
    [(cons 'const t) t]
    [_ type]))
