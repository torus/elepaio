(use www.cgi)
(use file.util)
(use makiki)

(define *pusher-key* (file->string "PUSHER_KEY"))

(define (handler-main req app)
  (let ((params (slot-ref req 'params)))
    (response-header-push! req :content-type "text/javascript; charset=UTF-8")
    (respond/ok req #`"function PUSHER_KEY(){return \",|*pusher-key*|\"}")))

