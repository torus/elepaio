(use gauche.test)

(test-record-file "test.record")

(test-start "pusher")
(use pusher)
(test-module 'pusher)

(test-section "Pusher API")

(test* "Pusher authentication signature"
       "da454824c97ba181a32ccc17a72625ba02771f50b50e1e7430e47a1f3f457e6c"
       (pusher-sign
        '("/apps/3/events"
          (body_md5 "ec365a775a4cd0599faeb73354201b6f")
          (auth_version "1.0")
          (auth_key "278d425bdf160c739803")
          (auth_timestamp "1353088179"))
        "7ad3773142a6692b25b8"))

(test* "MD5 digest"
       "ec365a775a4cd0599faeb73354201b6f"
       (pusher-body-md5
        "{\"name\":\"foo\",\"channels\":[\"project-3\"],\"data\":\"{\\\"some\\\":\\\"data\\\"}\"}"))

(test-end)
