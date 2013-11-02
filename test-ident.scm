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
(define *elep* (elepaio-connect *redis* 1)) ; uses different db for testing

(define id (elepaio-new-id! *elep*))
(define key "ABRACADABRA")

(test* "register new user"
       '(? number?)
       id
       check-match)

(test* "register new key"
       'ok
       (elepaio-register-key! *elep* id key))

(test* "lookup key"
       id
       (elepaio-lookup-key *elep* key))

(define new-key (elepaio-new-key! *elep*))

(test* "generate a new key"
       #f
       (read-from-string (redis-hget *redis* "elepaio:user:keys" new-key)))

(test-end)
