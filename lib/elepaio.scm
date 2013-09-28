(define-module elepaio
  (use gauche.sequence)
  (use redis)
  (export elepaio-connect
          elepaio-push!
          elepaio-get-room-key
          elepaio-get-latest-entries)
)

(select-module elepaio)

(define (elepaio-connect redis)
  `(,redis))

(define (elepaio-push! elep room thread-id user-id content)
  (let ((red (car elep)))
    (let ((length (redis-lpush red (elepaio-get-room-key room)
                               (write-to-string
                                `(elepaio-entry (room . ,room)
                                                (user-id . ,user-id)
                                                (thread-id . ,thread-id)
                                                (content . ,content))))))
      (- length 1))))

(define (elepaio-get-room-key room)
  (string-append "elepaio:room:" room))

(define (elepaio-get-latest-entries elep room number)
  (map read-from-string
       (redis-lrange (car elep) (elepaio-get-room-key room) (- number) -1)))
