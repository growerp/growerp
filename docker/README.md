# Docker files

## To run locally (Java 11 sdk, Flutter)

add to /etc/hosts file: 
```
127.0.0.1 backend.growerp.local # moqui server  
127.0.0.1 chat.growerp.local # chat server  
127.0.0.1 admin.growerp.local # flutter admin app  
127.0.0.1 hotel.growerp.local # flutter admin app  
127.0.0.1 100000.growerp.local # first generated website 
```

### run compose 
This will start admin/moqui/chat images:
```sh
docker compose up -d # start the images
```

### use the system
```
browser logon to backend: https://backend.growerp.local/vapps
create company with admin or hotel with browser
browser flutter frontend: https://admin.growerp.local
browser hotel frontend: https://hotel.growerp.local
```

ignore ssl errors of self signed cert.

Because images already prepared at dockerhub.com the system will start in a couple of minutes.