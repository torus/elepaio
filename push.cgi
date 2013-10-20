#!/Users/toru/local/gauche/bin/gosh
;; -*- scheme -*-

(use www.cgi)
(use file.util)
(use sxml.serializer)
(use sxml.ssax)
(use rfc.json)
(use rfc.http)
(use redis)

(add-load-path "./lib" :relative)
(use elepaio)
(use pusher)

(define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379)))
(define *pusher-app-id* (file->string "PUSHER_APP_ID"))
(define *pusher-key* (file->string "PUSHER_KEY"))
(define *pusher-secret* (file->string "PUSHER_SECRET"))

(define (main args)
  (cgi-main
   (lambda (params)
     (let ((room (cgi-get-parameter "room" params))
           (thread-id (cgi-get-parameter "thread-id" params))
           (user-id (cgi-get-parameter "user-id" params))
           (content (cdadr (ssax:xml->sxml (open-input-string
                                            (cgi-get-parameter "content" params)) ()))))
       (let1 index (elepaio-push! *elep* room thread-id user-id content)
             (let* ((json (construct-json-string `(("index" . ,index))))
                    (md5 (pusher-body-md5 json))
                    (channel (string-append "room_" room))
                    (uri `(,#`"/apps/,|*pusher-app-id*|/channels/,|channel|/events"
                           (name "update")
                           (body_md5 ,md5)
                           (auth_version "1.0")
                           (auth_key ,*pusher-key*)
                           (auth_timestamp ,(number->string (sys-time)))
                           ))
                    (sign (pusher-sign uri *pusher-secret*))
                    )
               (http-post "api.pusherapp.com"
                          (append uri `((auth_signature ,sign))) json))
             `(,(cgi-header)
               ,(srl:sxml->xml `(ok (@ (index ,index))))))))))
