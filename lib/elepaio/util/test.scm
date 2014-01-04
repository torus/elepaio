(define-module elepaio.util.test
  (use srfi-9)
  (export make-mock-request)
  )

(select-module elepaio.util.test)

(define-record-type mock-request make-mock-request #t
  params              ; query parameters
  headers             ; request headers
)
