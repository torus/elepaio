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

(use elepaio.util.test)

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


(test-section "archive")

#?=(elepaio-archive-sxml room 0)


(test-end)
