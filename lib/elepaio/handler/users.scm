(use www.cgi)
(use file.util)
(use makiki)

(define *pusher-key* (file->string "PUSHER_KEY"))

(define (pusher-key req app)
  (let ((params (slot-ref req 'params)))
    (response-header-push! req :content-type "text/javascript; charset=UTF-8")
    (respond/ok req #`"function PUSHER_KEY(){return \",|*pusher-key*|\"}")))

(use sxml.serializer)
(use sxml.ssax)
(use rfc.http)
(use rfc.cookie)
(use redis)

(add-load-path "./lib" :relative)
(use elepaio)
(use elepaio.id)

(define (register req app)
  (define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379) 0))

  (let ((params (slot-ref req 'params)))
     (let ((key (elepaio-new-key! *elep*))
           (id (elepaio-new-id! *elep*)))
       (elepaio-register-key! *elep* id key)
       (response-header-push! req :content-type "text/html; charset=UTF-8")
       (response-header-push! req :set-cookie
                              (string-join (construct-cookie-string
                                            `(("user-key" ,key
                                               :path "/"
                                               :max-age ,(* 60 60 24 365))))
                                           ","))
       (respond/ok
        req
        `(sxml
          (user (@ (id ,id) (key ,key))))))))
