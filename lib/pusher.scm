(define-module pusher
  (use gauche.sequence)
  (use binary.pack)
  (use gauche.uvector)
  (use util.match)
  (use rfc.hmac)
  (use rfc.md5)
  (use rfc.sha)

  (export pusher-sign
          pusher-body-md5
          )
)

(select-module pusher)

(define (pusher-sign uri key)
  (define (connect= a)
    (string-append (symbol->string (car a)) "=" (cadr a)))
  (let ((path (car uri))
        (params (sort (cdr uri)
                      (lambda (a b)
                        (string>? (symbol->string (car a))
                                  (symbol->string (car b)))))))
    (let ((str (fold (lambda (a b) (string-append a "&" b))
                     (connect= (car params))
                     (map connect= (cdr params)))))
      ;(display (string-append "POST\n" path "\n" str))
      (car (unpack "H*" :from-string
                   (hmac-digest-string (string-append "POST\n" path "\n" str)
                                       :key key
                                       :hasher <sha256>)))
    )))

(define (pusher-body-md5 body)
  (car (unpack "H*" :from-string (md5-digest-string body))))
