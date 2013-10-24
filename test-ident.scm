(use gauche.test)
(use redis)
(use elepaio)
(use util.match)
(use testutils)

(test-start "elepaio.id")
(use elepaio.id)
(test-module 'elepaio.id)

(test-section "Identification")

(define *redis* (redis-open "127.0.0.1" 6379))
(define *elep* (elepaio-connect *redis*))

(test* "register new user"
       '(? number?)
       (elepaio-new-id! *elep*)
       check-match)

(test-end)
