#!/Users/toru/local/gauche/bin/gosh
;; -*- scheme -*-

(use www.cgi)
(use file.util)
(use sxml.serializer)
(use sxml.ssax)
(use rfc.http)
(use rfc.cookie)
(use redis)

(add-load-path "./lib" :relative)
(use elepaio)
(use elepaio.id)

(define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379) 0))

(define (main args)
  (cgi-main
   (lambda (params)
     (let ((key (elepaio-new-key! *elep*))
           (id (elepaio-new-id! *elep*)))
       (elepaio-register-key! *elep* id key)
       `(,(cgi-header :content-type "text/html; charset=UTF-8"
                      :cookies (construct-cookie-string
                                `(("user-key" ,key
                                   :expires ,(+ (sys-time) 3.15569e7)))))
         ,(srl:sxml->xml
           `(*TOP* (user (@ (id ,id) (key ,key))))))))))
