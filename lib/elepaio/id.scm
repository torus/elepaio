(define-module elepaio.id
  (use redis)
  (use elepaio)
  (export elepaio-new-id!
          elepaio-register-key!
          elepaio-lookup-key
          elepaio-new-key!
          ))

(select-module elepaio.id)

(define (elepaio-new-id! elep)
  (let ((red (elepaio-get-redis elep)))
    (redis-incr red "elepaio:user:last_id")))

(define (elepaio-register-key! elep id key)
  (let ((red (elepaio-get-redis elep)))
    (redis-hset red "elepaio:user:keys" key id)
    'ok))

(define (elepaio-lookup-key elep key)
  (let ((red (elepaio-get-redis elep)))
    (read-from-string (redis-hget red "elepaio:user:keys" key))))

(define (elepaio-new-key! elep)
  (let ((red (elepaio-get-redis elep)))
    (redis-eval red (string-append
                     "math.randomseed(ARGV[1]);"
                     "while true do "
                     "local k = string.format('%04x%04x%04x%04x',"
                     " math.random(0x10000),"
                     " math.random(0x10000),"
                     " math.random(0x10000),"
                     " math.random(0x10000));"
                     " if redis.call('hexists', 'elepaio:user:keys', k) == 0 then"
                     "  redis.call('hset', 'elepaio:user:keys', k, '#f');"
                     "  return k;"
                     " end "
                     "end") 0 (sys-time))))
