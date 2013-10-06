#!/Users/toru/local/gauche/bin/gosh
;; -*- scheme -*-

(use www.cgi)
(use sxml.serializer)
(use util.match)
(use redis)

(add-load-path "./lib" :relative)
(use elepaio)

(define *elep* (elepaio-connect (redis-open "127.0.0.1" 6379)))

(define (main args)
  (cgi-main
   (lambda (params)
     (let ((room (cgi-get-parameter "room" params))
           (count (let1 p (cgi-get-parameter "count" params)
                        (or (and p (x->integer p)) 100))))
       (let1 entries (elepaio-get-latest-entries *elep* room count)
             `(,(cgi-header)
               ,(srl:sxml->xml
                 (match
                  entries
                  (`((elepaio-entry (index . ,index)
                                    (user-id . ,user-id)
                                    (thread-id . ,thread-id)
                                    (content . ((screen-name ,screen-name)
                                                (text ,text)))) ...)
                   `(*TOP* (entries
                            (@ (room ,room))
                            ,@(map (lambda (index user-id thread-id screen-name text)
                                    `(entry (@ (index ,index))
                                            (user-id ,user-id)
                                            (thread-id ,thread-id)
                                            (content (screen-name ,screen-name)
                                                     (text ,text))))
                                  index user-id thread-id screen-name text
                                  ))))))))))))
