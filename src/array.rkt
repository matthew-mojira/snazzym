#lang racket

(provide (all-defined-out))
(require "ast.rkt"
         "types.rkt")

(define (extract-arrays prog)
  (filter-map (match-lambda
                [(Array id t _) (cons id t)] ; dont care about length
                [_ #f]) prog))
