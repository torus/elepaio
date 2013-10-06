(use makiki)

(define-http-handler #/^\/pull.cgi/ (cgi-script "./pull.cgi"))
(define-http-handler #/^\/push.cgi/ (cgi-script "./push.cgi"))
(define-http-handler #// (file-handler))

(start-http-server :access-log #t :error-log #t :document-root "./public")
