#!/home/toru/local/gauche-head/bin/gosh
;; -*- scheme -*-

(use www.cgi)
(use sxml.serializer)
(use util.match)
(use redis)

(add-load-path "./lib" :relative)
(use elepaio)

(define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379) 0))

(define (main args)
  (cgi-main
   (lambda (params)
     (let ((room (cgi-get-parameter "room" params)))
       (let* ((after (cgi-get-parameter "after" params))
              (count (let1 p (cgi-get-parameter "count" params)
                           (or (and p (x->integer p)) 100))))
         (let1 entries (if after
                           (elepaio-get-entries *elep* room (x->integer after) count)
                           (elepaio-get-latest-entries *elep* room count))
               `(,(cgi-header :content-type "text/html; charset=UTF-8")
                 ,(srl:sxml->xml
                   `(*TOP* (entries
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
                                           (user-id ,user-id)
                                           (thread-id ,thread-id)
                                           (content (screen-name ,screen-name)
                                                    (text ,text))))
                                  (else '(error "match failed"))))
                               entries)))))))))))
