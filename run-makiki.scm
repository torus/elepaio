(use makiki)

(add-load-path "./lib" :relative)
(use elepaio)

;; /1/resource/action[.ext]

(define-http-handler #/\/1\/([\w-]+)\/([\w-]+)(\.\w+)?\/?$/
  (^[req app]
    (let ((mod (make-module #f))
          (resource ((slot-ref req 'path-rxmatch) 1))
          (action ((slot-ref req 'path-rxmatch) 2))
          (ext ((slot-ref req 'path-rxmatch) 3)))
      (load #`"./lib/elepaio/handler/,|resource|.scm" :environment mod)
      (respond/ok req
                  ((global-variable-ref mod (string->symbol action)) req app)
                  :content-type "application/xml"))))

;; /room/<roomname>.html[#<thread_id>]
(define-http-handler #/room\/(.+?)\.html$/
  (^[req app]
    (respond/ok req '(file "./html/index.html"))
    ))

;; /archive/<roomname>/<roomname>_<index>.html
(define-http-handler #/archive\/(.+?)\/\1_(\d+?)\.html$/
  (^[req app]
    (let ((room ((slot-ref req 'path-rxmatch) 1))
          (index ((slot-ref req 'path-rxmatch) 2)))
      (respond/ok req `(sxml ,(elepaio-archive-sxml room index))))))

;; /1/path/to/resource.js

(define-http-handler #/\/1\/(.+?)(\.js)?\/?$/
  (^[req app]
    (let ((mod (make-module #f))
          (path ((slot-ref req 'path-rxmatch) 1)))
      (load #`"./lib/elepaio/handler/,|path|.scm" :environment mod)
      ((global-variable-ref mod 'handler-main) req app))))

(define-http-handler #// (file-handler))

(start-http-server :access-log #t :error-log #t :document-root "./public")
