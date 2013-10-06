#!/Users/toru/local/gauche/bin/gosh
;; -*- scheme -*-

(use www.cgi)
(use sxml.serializer)
(use sxml.ssax)
(use redis)

(add-load-path "./lib" :relative)
(use elepaio)

(define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379)))

(define (main args)
  (cgi-main
   (lambda (params)
     (let ((room (cgi-get-parameter "room" params))
           (thread-id (cgi-get-parameter "thread-id" params))
           (user-id (cgi-get-parameter "user-id" params))
           (content (cdadr (ssax:xml->sxml (open-input-string
                                            (cgi-get-parameter "content" params)) ()))))
       (let1 index (elepaio-push! *elep* room thread-id user-id content)
             `(,(cgi-header)
               ,(srl:sxml->xml `(ok (@ (index ,index))))))))))
