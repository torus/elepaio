#!/home/toru/local/gauche-head/bin/gosh
;; -*- scheme -*-

(use www.cgi)
(use file.util)

(define *pusher-key* (file->string "PUSHER_KEY"))

(define (main args)
  (cgi-main
   (lambda (params)
     `(,(cgi-header :content-type "text/javascript; charset=UTF-8")
       ,#`"function PUSHER_KEY(){return \",|*pusher-key*|\"}"))))
