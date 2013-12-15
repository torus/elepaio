(define-module elepaio.handler.pusher-key
  (use www.cgi)
  (use file.util)
  (use makiki)
  (export handler-main))

(select-module elepaio.handler.pusher-key)

(define *pusher-key* (file->string "PUSHER_KEY"))

(define (handler-main req app)
  (let ((params (slot-ref req 'params)))
    (response-header-push! req :content-type "text/javascript; charset=UTF-8")
    (respond/ok req #`"function PUSHER_KEY(){return \",|*pusher-key*|\"}")))

