#lang racket

(provide (all-defined-out))
(require "ast.rkt"
         "types.rkt")

(define (extract-consts prog)
  (filter-map (match-lambda
                [(Include id _) (cons id 'long)]
                [_ #f]) prog))
