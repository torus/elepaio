(use makiki)

(define-http-handler #/^(\/1)?\/pull.cgi/ (cgi-script "./pull.cgi"))
(define-http-handler #/^(\/1)?\/push.cgi/ (cgi-script "./push.cgi"))
(define-http-handler #/^(\/1)?\/pusher-key.cgi/ (cgi-script "./pusher-key.cgi"))
(define-http-handler #/^(\/1)?\/register.cgi/ (cgi-script "./register.cgi"))
(define-http-handler #// (file-handler))

(start-http-server :access-log #t :error-log #t :document-root "./public")
