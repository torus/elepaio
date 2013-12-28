(use makiki)

(add-load-path "./lib" :relative)

#;(use elepaio.handler.pusher-key)

#;(define-http-handler #/^(\/1)?\/pusher-key(.js)?(.cgi)?/
  (lambda (req app)
    (slot-set! req 'params (acons "b" 789 (slot-ref req 'params)))
    ((cgi-script "./pusher-key.cgi") req app)))


#;(define-http-handler #/^(\/1)?\/pusher-key(.js)?(.cgi)?/ (cgi-script "./pusher-key.cgi"))
#;(define-http-handler #/^\/1\/register$/ (cgi-script "./register.cgi"))

;; (define-http-handler #/\/1\/pull$/ (cgi-script "./pull.cgi"))
;; (define-http-handler #/\/1\/push$/ (cgi-script "./push.cgi"))

;; /1/resource/method[.ext]

(define-http-handler #/\/1\/([\w-]+)\/([\w-]+)(\.\w+)?\/?$/
  (^[req app]
    (let ((mod (make-module #f))
          (resource ((slot-ref req 'path-rxmatch) 1))
          (method ((slot-ref req 'path-rxmatch) 2))
          (ext ((slot-ref req 'path-rxmatch) 3)))
      (load #`"./lib/elepaio/handler/,|resource|.scm" :environment mod)
      ((global-variable-ref mod (string->symbol method)) req app))))

;; /1/path/to/resource.js

(define-http-handler #/\/1\/(.+?)(\.js)?\/?$/
  (^[req app]
    (let ((mod (make-module #f))
          (path ((slot-ref req 'path-rxmatch) 1)))
      (load #`"./lib/elepaio/handler/,|path|.scm" :environment mod)
      ((global-variable-ref mod 'handler-main) req app))))

(define-http-handler #// (file-handler))

(start-http-server :access-log #t :error-log #t :document-root "./public")
