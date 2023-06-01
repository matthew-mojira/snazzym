#lang racket
(provide main)
(require racket/pretty
         "ast.rkt"
         "parse.rkt"
         "compile.rkt"
         "type-check.rkt"
         "65816.rkt")

(define (main fn)
  (let ([prog (parse (read-file fn))])
    (pretty-print (extract-global-env prog))
    ;    (pretty-print prog)
    ;    (type-check prog)
    ;    (printer (compile prog))
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

; function probably should not live here
(define (extract-global-env prog)
  (foldr (lambda (tl rest)
           ; append because we can have a top level declaration
           ; transform into a list (see enum)
           (append (match tl
                     [(Global id t) `((,id ,t))]
                     ; for functions, extracts the types with `cdr`
                     [(Func id t as _) `((,id func ,t ,(map cdr as)))]
                     [(Enum name ids) (map (lambda (id) `(,id enum ,name)) ids)]
                     [(Include id _) `((,id const long))]
                     [(Array id t _) `((,id array ,t))]
                     [_ '()])
                   rest))
         '()
         prog))
