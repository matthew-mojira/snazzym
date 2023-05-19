#lang snazzym

(func (f int ())
      (if/else #t ; main check
               ((return 10))
               ((if/else #f ((return 75)) ((return 11))))))

(func (g bool ()) (return #f))

(func (main int ())
      (f)
      (g)
      (if/else (g) ;bool func call
               ((f) ; block stuff
                (return 1)) ;end of block
               ((if/else #t
                         ((return (f))) ;proper output value
                         ((return 25))))))

;(func (cond-test int ())
;      (print "print program")
;      (if/else (zero? 42)
;               [(print "bastion")
;                (determine-out-of-bounds xyz abc 14)
;                (print "done")
;                (dinette-set)
;                (return 63)]
;               [(thigs)
;                (feelings)
;                (paperclips "things are about to be great")
;                (indent this stupid thing)
;                (return 42)])
;      (unreachable-code))
