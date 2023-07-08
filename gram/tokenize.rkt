#lang racket

(require brag/support)
(provide tokenize)

(define (tokenize s)
  (for/list ([str (regexp-match* #px"\\(|\\)|\\w+" s)])
    (match str
      ["(" (token 'LEFT-PAREN str)]
      [")" (token 'RIGHT-PAREN str)]
      ["void" (token 'VOID str)]
      ["byte" (token 'BYTE str)]
      ["word" (token 'WORD str)]
      ["long" (token 'LONG str)]
      ["array" (token 'ARRAY str)]
      ["func" (token 'FUNC str)]
      )))
