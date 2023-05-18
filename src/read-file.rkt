#lang racket
(provide main)
(require "parse.rkt"
         "compile.rkt"
         "65816.rkt")

(define (main fn)
  (let ([p (open-input-file fn)])
    (begin
      (read-line p)
      (printer (compile (parse (read-all p))))
      (close-input-port p))))

(define (read-all p)
  (let ([r (read p)]) (if (eof-object? r) '() (cons r (read-all p)))))
