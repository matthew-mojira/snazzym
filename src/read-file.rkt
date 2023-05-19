#lang racket
(provide main)
(require racket/pretty
         "parse.rkt"
         "compile.rkt"
         "type-check.rkt"
         "65816.rkt")

(define (main fn)
  (let ([p (open-input-file fn)])
    (begin
      (read-line p)
      (let ([prog (parse (read-all p))])
;        (pretty-print prog)
        (type-check prog)
        (printer (compile prog)))
      (close-input-port p))))

(define (read-all p)
  (let ([r (read p)]) (if (eof-object? r) '() (cons r (read-all p)))))
