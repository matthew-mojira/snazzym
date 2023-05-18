#lang snazzym

(if #t (return 10) (if #f (return 75) (return #t)))
