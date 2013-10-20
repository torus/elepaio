(define-module elepaio
  (use gauche.sequence)
  (use util.match)
  (use redis)

  (export elepaio-connect
          elepaio-push!
          elepaio-get-room-key
          elepaio-get-entries
          elepaio-get-latest-entries
          ))

(select-module elepaio)

(define (elepaio-connect redis)
  `(,redis))

(define (elepaio-push! elep room thread-id user-id content)
  (let ((red (car elep)))
    (let ((length (redis-rpush red (elepaio-get-room-key room)
                               (write-to-string
                                `(elepaio-entry (user-id . ,user-id)
                                                (thread-id . ,thread-id)
                                                (content . ,content))))))
      (- length 1))))

(define (elepaio-get-room-key room)
  (string-append "elepaio:room:" room))

(define (elepaio-get-entries elep room after count)
  (let1 start (+ 1 after)
        (map (lambda (index x)
               (let ((data (read-from-string x)))
                 (match data
                        (`(elepaio-entry . ,rest)
                         `(elepaio-entry (index . ,index) ,@rest))
                        (else
                         '(error)))))
             (iota count start)
             (redis-lrange (car elep) (elepaio-get-room-key room)
                           start (+ after count)))))

(define (elepaio-get-latest-entries elep room number)
  (let* ((total (redis-llen (car elep) (elepaio-get-room-key room)))
         (start (max 0 (- total number)))
         (stop (- total 1))
         (count (- total start)))
    (map (lambda (index x)
           (let ((data (read-from-string x)))
             (match data
                    (`(elepaio-entry . ,rest)
                     `(elepaio-entry (index . ,index) ,@rest))
                    (else
                     '(error)))))
         (iota count start)
         (redis-lrange (car elep) (elepaio-get-room-key room) start stop))))
