(define-module testutils
    (use util.match)
    (export check-match))

(define (check-match pat expr)
  (guard (exc (else #f))
         (eval `(match (quote ,expr) (,pat #t)) (interaction-environment))))
