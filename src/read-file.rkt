#lang racket
(provide main)
(require racket/pretty
         "parse.rkt"
         "compile.rkt"
         "type-check.rkt"
         "65816.rkt")

(define (main fn)
  (let ([prog (parse (read-file fn))])
;    (pretty-print prog)
    (type-check prog)
    (printer (compile prog))
    ))

(define (read-lines file)
  (let ([line (read file)])
    (if (eof-object? line)
        '()
        (match line
          [(list 'import f2) (append (read-file f2) (read-lines file))]
          ; please don't do a circular inclusion!
          [_ (cons line (read-lines file))]))))

(define (read-file name)
  (let ([file (open-input-file name)])
    (read-line file) ; initial #lang snazzym line of file
    (let ([lines (read-lines file)])
      (close-input-port file)
      lines)))
