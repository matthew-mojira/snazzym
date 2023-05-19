#lang snazzym

(function (f int ())
          (if #t ; main check
              (return 10)
              (if #f (return 75) (return 11))))

(function (g bool ()) (return #f))

(function (main int ()) (if #f (return 1) (if #t (return 3) (return 99))))
