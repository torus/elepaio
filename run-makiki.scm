(use makiki)

(add-load-path "./lib" :relative)

;; /1/resource/action[.ext]

(define-http-handler #/\/1\/([\w-]+)\/([\w-]+)(\.\w+)?\/?$/
  (^[req app]
    (let ((mod (make-module #f))
          (resource ((slot-ref req 'path-rxmatch) 1))
          (action ((slot-ref req 'path-rxmatch) 2))
          (ext ((slot-ref req 'path-rxmatch) 3)))
      (load #`"./lib/elepaio/handler/,|resource|.scm" :environment mod)
      (respond/ok req
                  ((global-variable-ref mod (string->symbol action)) req app)))))

;; /1/path/to/resource.js

(define-http-handler #/\/1\/(.+?)(\.js)?\/?$/
  (^[req app]
    (let ((mod (make-module #f))
          (path ((slot-ref req 'path-rxmatch) 1)))
      (load #`"./lib/elepaio/handler/,|path|.scm" :environment mod)
      ((global-variable-ref mod 'handler-main) req app))))

(define-http-handler #// (file-handler))

(start-http-server :access-log #t :error-log #t :document-root "./public")
