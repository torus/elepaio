#!/home/toru/local/gauche-head/bin/gosh
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

(define (main args)
  (define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379) 0))

  (cgi-main
   (lambda (params)
     (let ((key (elepaio-new-key! *elep*))
           (id (elepaio-new-id! *elep*)))
       (elepaio-register-key! *elep* id key)
       `(,(cgi-header :content-type "text/html; charset=UTF-8"
                      :cookies (construct-cookie-string
                                `(("user-key" ,key
                                   :path "/"
                                   :expires ,(+ (sys-time) (* 60 60 24 365))
                                   :max-age ,(* 60 60 24 365)))
                                0))     ; old version cookie format for Set-Cookie header
         ,(srl:sxml->xml
           `(*TOP* (user (@ (id ,id) (key ,key))))))))))
