(use www.cgi)
(use sxml.serializer)
(use util.match)
(use redis)
(use makiki)

(add-load-path "./lib" :relative)
(use elepaio)

(define (pull req app)
  (define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379) 0))

  (let ((params (slot-ref req 'params)))
    (let ((room (cgi-get-parameter "room" params)))
      (let* ((after (cgi-get-parameter "after" params))
             (count (let1 p (cgi-get-parameter "count" params)
                          (or (and p (x->integer p)) 100)))
             (entries (if after
                          (elepaio-get-entries *elep* room (x->integer after) count)
                          (elepaio-get-latest-entries *elep* room count))))
        `(sxml
          (entries
           (@ (room ,room))
           ,@(map
              (lambda (e)
                (match
                 e
                 (`(elepaio-entry (index . ,index)
                                  (user-id . ,user-id)
                                  (thread-id . ,thread-id)
                                  (content . ((screen-name ,screen-name)
                                              (text ,text))))
                  `(entry (@ (index ,index))
                          (user-id ,(x->string user-id))
                          (thread-id ,(x->string thread-id))
                          (content (screen-name ,screen-name)
                                   (text ,text))))
                 (else '(error "match failed"))))
              entries)))))))

(use file.util)
(use sxml.serializer)
(use sxml.ssax)
(use rfc.json)
(use rfc.http)

(add-load-path "./lib" :relative)
(use elepaio.id)
(use pusher)

(define *pusher-app-id* (file->string "PUSHER_APP_ID"))
(define *pusher-key* (file->string "PUSHER_KEY"))
(define *pusher-secret* (file->string "PUSHER_SECRET"))

(define push
  (with-post-parameters
   (lambda (req app)
     (define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379) 0))
     (define (get-user-id params)
       (or (cgi-get-parameter "user-id" params)
           (let1 key (cgi-get-parameter "user-key" params)
                 (and key (elepaio-lookup-key *elep* key)))
           0))

     (let ((params (slot-ref req 'params)))
       (let ((room (cgi-get-parameter "room" params))
             (thread-id (read-from-string (cgi-get-parameter "thread-id" params)))
             (user-id (get-user-id params))
             (content (cdadr (ssax:xml->sxml (open-input-string
                                              (cgi-get-parameter "content" params)) ()))))
         (let ((index (elepaio-push! *elep* room thread-id user-id content)))
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
           `(sxml (ok (@ (index ,index))))))))))
