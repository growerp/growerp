# Docker files

## To run locally

add to /etc/hosts:
127.0.0.1 backend.growerp.local # moqui server
127.0.0.1 chat.growerp.local # chat server
127.0.0.1 admin.growerp.local # flutter admin app
127.0.0.1 100000.growerp.local # first generated website


run compose which will build and start admin/moqui/chat images:
```sh
docker compose build # create the moqui, chat, admin images
docker compose up -d # start the images
```

browser logon to backend: https://backand.growerp.local/vapps
browser flutter frontend: https://admin.growerp.local
ignore ssl errors of self signed cert.

