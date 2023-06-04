#lang racket

(provide (all-defined-out))
(require "ast.rkt"
         "types.rkt")

(define (extract-global-env prog)
  (foldr (lambda (tl rest)
           ; append because we can have a top level declaration
           ; transform into a list (see enum)
           (append (match tl
                     [(Global id t) `((,id . ,t))]
                     ; for functions, extracts the types with `cdr`
                     [(Func id t as _) `((,id const func ,t ,(map cdr as)))]
                     [(Enum name ids) (map (lambda (id) `(,id enum ,name)) ids)]
                     [(Include id _) `((,id const . long))]
                     [(Array id t _) `((,id const array ,t))]
                     [_ '()])
                   rest))
         '()
         prog))
