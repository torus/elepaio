(use gauche.test)
(use www.cgi.test)
(use sxml.serializer)
(use redis)

(test-start "elepaio")
(use elepaio)
(test-module 'elepaio)


(define *redis* (redis-open "127.0.0.1" 6379))

(define user-id 12345)
(define thread-id 987654)
(define content '((screen-name "Gwaihir")
                  (text "Hi, there!")))
(define room (string-append "test-room-" (x->string (sys-time))))

(test-section "low level APIs")

(test* "get key"
       "elepaio:room:lotr"
       (elepaio-get-room-key "lotr"))

(test-section "initialize")

(define *elep* (elepaio-connect *redis*))

(test-section "post")

(define entry-id (elepaio-push! *elep* room thread-id user-id content))

(test* "entry-id" 0 entry-id)

(test* "Redis data type"
       'list
       (redis-type *redis* (elepaio-get-room-key room)))

(test* "post"
       `(elepaio-entry (room . ,room)
                       (user-id . ,user-id)
                       (thread-id . ,thread-id)
                       (content . ,content))
       (read-from-string
        (vector-ref (redis-lrange *redis* (elepaio-get-room-key room) -1 -1) 0)))

(test-section "read")

(test* "get the first post"
       `((elepaio-entry (room . ,room)
                        (user-id . ,user-id)
                        (thread-id . ,thread-id)
                        (content . ,content)))
       (elepaio-get-latest-entries *elep* room 10))

(define entry-id2 (elepaio-push! *elep* room thread-id user-id content))

(test* "get the recent posts"
       `((elepaio-entry (room . ,room)
                        (user-id . ,user-id)
                        (thread-id . ,thread-id)
                        (content . ,content))
         (elepaio-entry (room . ,room)
                        (user-id . ,user-id)
                        (thread-id . ,thread-id)
                        (content . ,content)))
       (elepaio-get-latest-entries *elep* room 10))


(test-section "push CGI")

(define post-content #?=(srl:sxml->xml `(content ,@content)))

(run-cgi-script->sxml "push.cgi"
                      :parameters `((room . ,room)
                                    (user-id . ,user-id)
                                    (thread-id . ,thread-id)
                                    (content . ,post-content)))

(test-end)
