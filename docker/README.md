# Docker files

## To run locally (Java 11 sdk, Flutter)

add to /etc/hosts:
127.0.0.1 backend.growerp.local # moqui server
127.0.0.1 chat.growerp.local # chat server
127.0.0.1 admin.growerp.local # flutter admin app
127.0.0.1 hotel.growerp.local # flutter admin app
127.0.0.1 100000.growerp.local # first generated website

# to use this system:
# docker compose build
# docker compose up -d
# go to the browser: https://admin.growerp.local
#                    https://hotel.growerp.local
#                    https://backend.growerp.local/vapps


run compose which will build and start admin/moqui/chat images:
```sh
docker compose build # create the moqui, chat, admin images
docker compose up -d # start the images
```

browser logon to backend: https://backend.growerp.local/vapps
browser flutter frontend: https://admin.growerp.local
browser hotel frontend: https://hotel.growerp.local
ignore ssl errors of self signed cert.

be patient, will take about 30 minutes.