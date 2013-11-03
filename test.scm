(use gauche.test)
(use file.util)
(use www.cgi.test)
(use sxml.serializer)
(use sxml.ssax)
(use util.match)

(use testutils)
(use redis)

(test-record-file "test.record")

(test-start "elepaio")
(use elepaio)
(test-module 'elepaio)


(define *redis* (redis-open "127.0.0.1" 6379))
(define *pusher-key* (file->string "PUSHER_KEY"))

(define user-id 12345)
(define thread-id 987654)
(define (content n)
  `((screen-name "Gwaihir")
    (text ,#`"Hi, there! ,n")))
(define room (string-append "test-room-" (x->string (sys-time))))

(test-section "low level APIs")

(test* "get key"
       "elepaio:room:lotr"
       (elepaio-get-room-key "lotr"))

(test-section "initialize")

(define *elep* (elepaio-connect *redis* 0))

(test-section "post")

(define index (elepaio-push! *elep* room thread-id user-id (content 1)))

(test* "index" 0 index)

(test* "Redis data type"
       'list
       (redis-type *redis* (elepaio-get-room-key room)))

(test* "post"
       `(elepaio-entry (user-id . ,user-id)
                       (thread-id . ,thread-id)
                       (content ,@(content 1)))
       (read-from-string
        (vector-ref (redis-lrange *redis* (elepaio-get-room-key room) -1 -1) 0)))

(test-section "read")

(test* "get the first post"
       `((elepaio-entry (index . 0)
                        (user-id . ,user-id)
                        (thread-id . ,thread-id)
                        (content ,@(content 1))))
       (elepaio-get-latest-entries *elep* room 10))

(define index2 (elepaio-push! *elep* room thread-id user-id (content 2)))

(test* "get the second post"
       `(elepaio-entry (user-id . ,user-id)
                       (thread-id . ,thread-id)
                       (content ,@(content 2)))
       (read-from-string
        (vector-ref (redis-lrange *redis* (elepaio-get-room-key room) -1 -1) 0)))

(test* "get the recent posts"
       `((elepaio-entry (index . 0)
                        (user-id . ,user-id)
                        (thread-id . ,thread-id)
                        (content ,@(content 1)))
         (elepaio-entry (index . 1)
                        (user-id . ,user-id)
                        (thread-id . ,thread-id)
                        (content ,@(content 2))))
       (elepaio-get-latest-entries *elep* room 10))


(test-section "register CGI")

(match-define ((("content-type" _)
                ("set-cookie" (? #/user-key=/)))
               `(*TOP* (user (@ (key ,user-key) (id ,idstr)))))
              (let-values (((header body)
                            (run-cgi-script->sxml "./register.cgi")))
                (list header body)))
(define registered-user-id (read-from-string idstr))

(test* "id" #t (number? registered-user-id))
(test* "key" #t (string? user-key))

(test* "key registered" registered-user-id
       (read-from-string (redis-hget *redis* "elepaio:user:keys" user-key)))

(test-section "app ID CGI")

(test* "pusher-key.cgi"
       #`"function PUSHER_KEY(){return \",|*pusher-key*|\"}"
       (let-values (((header body)
                     (run-cgi-script->string "./pusher-key.cgi")))
         body))

(test-section "push CGI")

(define post-content (srl:sxml->xml `(content ,@(content 3))))

(test* "push.cgi"
       '`(*TOP* (ok (@ (index "2"))))
       (let-values (((header body)
                     (run-cgi-script->sxml "./push.cgi"
                                           :environment '((REQUEST_METHOD . "POST"))
                                           :parameters `((room . ,room)
                                                         (user-key . ,user-key)
                                                         (thread-id . ,thread-id)
                                                         (content . ,post-content)))))
         body)
       check-match)

(test* "key and id"
       `((elepaio-entry (index . 2)
                        (user-id . ,registered-user-id)
                        (thread-id . ,thread-id)
                        (content ,@(content 3))))
       (elepaio-get-latest-entries *elep* room 1))

(test-section "pull CGI")

(test* "pull.cgi"
       '(*TOP* (entries ('@ (room (? string?)))
                        (entry ('@ (index (? string?)))
                               (user-id (? string?))
                               (thread-id (? string?))
                               (content (screen-name (? string?))
                                        (text (? string?))))
                        ..2
                        ))
       (let-values (((header body)
                     (run-cgi-script->sxml "./pull.cgi"
                                           :parameters `((room . ,room)
                                                         (count . "100")))))
         body)
       check-match)

(test* "count paramter ommited"
       '(*TOP* (entries ('@ (room (? string?)))
                        (entry ('@ (index (? string?)))
                               (user-id (? string?))
                               (thread-id (? string?))
                               (content (screen-name (? string?))
                                        (text (? string?))))
                        ..2
                        ))
       (let-values (((header body)
                     (run-cgi-script->sxml "./pull.cgi"
                                           :parameters `((room . ,room)))))
         body)
       check-match)

(elepaio-push! *elep* room thread-id user-id (content 4))
(elepaio-push! *elep* room thread-id user-id (content 5))
(elepaio-push! *elep* room thread-id user-id (content 6))
(elepaio-push! *elep* room thread-id user-id (content 7))

(test* "with after paramter"
       3
       (let-values (((header body)
                     (run-cgi-script->sxml "./pull.cgi"
                                           :parameters `((room . ,room)
                                                         (after . 3)))))
         (length (cddadr body)))
       check-match)


(test-end)
