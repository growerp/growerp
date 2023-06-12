# Docker files

## To run locally

add to /etc/hosts:
127.0.0.1 moqui.local # moqui server
127.0.0.1 moqui1.local # chat server
127.0.0.1 moqui2.local # flutter admin app


run compose which will build and start admin/moqui/chat images:
```sh
docker compose -up -d
```


browser logon to backend: https://moqui.local/vapps
ignore ssl errors of self signed cert.

