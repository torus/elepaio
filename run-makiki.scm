(use makiki)

(add-load-path "./lib" :relative)

(use elepaio.handler.pusher-key)

#;(define-http-handler #/^(\/1)?\/pusher-key(.js)?(.cgi)?/
  (lambda (req app)
    (slot-set! req 'params (acons "b" 789 (slot-ref req 'params)))
    ((cgi-script "./pusher-key.cgi") req app)))


;(define-http-handler #/^(\/1)?\/pusher-key(.js)?(.cgi)?/ (cgi-script "./pusher-key.cgi"))
(define-http-handler #/^(\/1)?\/register(.cgi)?/ (cgi-script "./register.cgi"))

(define-http-handler #/^(\/1)?\/pull(.cgi)?/ (cgi-script "./pull.cgi"))
(define-http-handler #/^(\/1)?\/push(.cgi)?$/ (cgi-script "./push.cgi"))

(define-http-handler #/^(\/1)?\/pusher-key(.js)?(.cgi)?/ handler-main)

(define-http-handler #// (file-handler))

(start-http-server :access-log #t :error-log #t :document-root "./public")
