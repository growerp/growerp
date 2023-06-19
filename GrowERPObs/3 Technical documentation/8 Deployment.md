# General


## Docker environment

The initial installation can be done by installing docker on your server and using the docker-compose.yaml  in the docker directory.

However the GrowERP three images will be created locally and are better stored in https://dockerhub.com or adjusted so that they use the [growerp images](https://hub.docker.com/search?q=growerp)

You can request the ssl certificates from letsencrypt and needs to be stored in the certs directory in the form of:

the file privkey.pem need to be renamed to domainname.key
the file fullchain.pem need to be renamed to domainname.crt

wild cards are working fine.

## IOS Appstore

please check https://github.com/moqui/moqui/flutter/packages/admin/ios/README.md

## Android Playstore.

please check https://github.com/moqui/moqui/flutter/packages/admin/android/README.md

