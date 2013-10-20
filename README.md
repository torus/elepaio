elepaio
=======

Online text chat system working with Redis and Pusher.

Demo -> http://torus.jp:8080

SYSTEM REQUIREMENTS
-------------------

- Gauche http://practical-scheme.net/gauche/
- Gauche-makiki https://github.com/shirok/Gauche-makiki
- Gauche-redis https://github.com/bizenn/Gauche-redis
- Redis http://redis.io

PREPARATION
-----------

Go the Pusher site and get your app registered.

http://pusher.com

### Server Side

Store your app ID, key and secret into files respectively:

- PUSHER_APP_ID
- PUSHER_KEY
- PUSHER_SECRET

### Client Side

Edit `public/elepaio.js` and replace the value of `PUSHER_KEY` with your own key.

    var PUSHER_KEY = '836e48f052310de70869'

AUTHOR
------

Toru Hisai @torus

LICENSE
-------

BSD
