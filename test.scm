(use gauche.test)
(use file.util)
(use www.cgi.test)
(use sxml.serializer)
(use sxml.ssax)
(use util.match)

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

(define *elep* (elepaio-connect *redis*))

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

(test-section "app ID CGI")

(test* "pusher-key.cgi"
       #`"function PUSHER_KEY(){return \",|*pusher-key*|\"}"
       (let-values (((header body)
                     (run-cgi-script->string "./pusher-key.cgi")))
         body))

(test-section "push CGI")

(define post-content (srl:sxml->xml `(content ,@(content 3))))
(define (check-match pat expr)
  (guard (exc (else #f))
         (eval `(match (quote ,expr) (,pat #t)) (interaction-environment))))

(test* "check-match"
       '(_ _ (1 2 (? string?)))
       '(abc def (1 2 "34"))
       check-match)

(test* "check-match"
       '(_ _ (1 2 (? string?)))
       '(abc def (1 2 34))
       (lambda (pat expr) (not (check-match pat expr))))

(test* "check-match"
       '((? number?)
         (hoge (? string?)
               (? number?)) ...)
       '(10 (hoge "a" 1) (hoge "b" 2) (hoge "c" 3))
       check-match)

(test* "push.cgi"
       '`(*TOP* (ok (@ (index "2"))))
       (let-values (((header body)
                     (run-cgi-script->sxml "./push.cgi"
                                           :environment '((REQUEST_METHOD . "POST"))
                                           :parameters `((room . ,room)
                                                         (user-id . ,user-id)
                                                         (thread-id . ,thread-id)
                                                         (content . ,post-content)))))
         body)
       check-match)

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
