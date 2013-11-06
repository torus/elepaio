#!/home/toru/local/gauche-head/bin/gosh
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
(use elepaio.id)
(use pusher)

(define *pusher-app-id* (file->string "PUSHER_APP_ID"))
(define *pusher-key* (file->string "PUSHER_KEY"))
(define *pusher-secret* (file->string "PUSHER_SECRET"))

(define (main args)
  (define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379) 0))
  (define (get-user-id params)
    (or (cgi-get-parameter "user-id" params)
        (let1 key (cgi-get-parameter "user-key" params)
              (and key (elepaio-lookup-key *elep* key)))
        0))

  (cgi-main
   (lambda (params)
     (let ((room (cgi-get-parameter "room" params))
           (thread-id (read-from-string (cgi-get-parameter "thread-id" params)))
           (user-id (get-user-id params))
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
             `(,(cgi-header :content-type "text/html; charset=UTF-8")
               ,(srl:sxml->xml `(ok (@ (index ,index))))))))
   :merge-cookies #t))
