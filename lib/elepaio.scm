(define-module elepaio
  (use gauche.sequence)
  (use util.match)
  (use sxml.ssax)

  (use redis)

  (export elepaio-connect
          elepaio-push!
          elepaio-get-room-key
          elepaio-get-entries
          elepaio-get-latest-entries
          elepaio-get-redis
          elepaio-archive-sxml
          ))

(select-module elepaio)

(define (elepaio-connect redis db)
  (redis-select redis db)
  `(,redis))

(define elepaio-get-redis car)

(define (elepaio-push! elep room thread-id user-id content)
  (let ((red (elepaio-get-redis elep)))
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
             (redis-lrange (elepaio-get-redis elep) (elepaio-get-room-key room)
                           start (+ after count)))))

(define (elepaio-get-latest-entries elep room number)
  (let* ((total (redis-llen (elepaio-get-redis elep) (elepaio-get-room-key room)))
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
         (redis-lrange (elepaio-get-redis elep) (elepaio-get-room-key room) start stop))))

(define (make-elp-content room index content)
  (let1 elep (elepaio-connect (redis-open "127.0.0.1" 6379) 0)
        `(div (@ (class "container"))
              (div (@ (class "row"))
                   (div (@ (class "col-md-12"))
                        (div (@ (class "panel panel-default"))
                             (table (@ (class "table"))
        ,(map
        (lambda (e)
                (match
                 e
                 (`(elepaio-entry (index . ,index)
                                  (user-id . ,user-id)
                                  (thread-id . ,thread-id)
                                  (content . ((screen-name ,screen-name)
                                              (text ,text))))

                  `(tr
                    (td
                     (span (@ (style "font-weight:bold"))
                                ,screen-name "> ")
                     (span ,text))))
                 (else '(tr (td "match failed")))))
        (elepaio-get-entries elep room (* index 100) 100)))))))))

(define (elepaio-archive-sxml room index)
  (let ((doc (ssax:xml->sxml (open-input-file "html/archive.html") '())))
    (define (m child)
      (match child
             [('elp-content children ...) (make-elp-content
                                           room (x->number index) children)]
             [('script ('@ attr ...)) (list 'script (cons '@ attr) "")]
             [('ins ('@ attr ...)) (list 'ins (cons '@ attr) "")]
             [(a children ...) (cons a (map m children))]
             [a a]))
    #?=(cadr (m doc))
    ))
