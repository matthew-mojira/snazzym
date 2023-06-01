#lang racket

(provide (all-defined-out))
(require "ast.rkt"
         "types.rkt")

(define (extract-enums prog)
  (foldr (lambda (tl rest)
           (match tl
             [(Enum name ids)
              (append (map (lambda (id) (cons id `(enum ,name))) ids) rest)]
             [_ rest]))
         '()
         prog))
