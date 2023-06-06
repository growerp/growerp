#!/bin/bash
set -x
. $(dirname "$0")/../param.sh # include parameter file in current directory
rm -rf moqui
echo "download from repository"
git clone https://github.com/growerp/moqui-framework.git moqui && cd moqui
git clone https://github.com/growerp/moqui-runtime.git runtime
git clone https://github.com/growerp/growerp-moqui.git runtime/component/growerp
git clone https://github.com/growerp/PopCommerce.git runtime/component/PopCommerce
git clone -b growerp --single-branch https://github.com/growerp/mantle-udm.git runtime/component/mantle-udm
git clone -b growerp --single-branch https://github.com/growerp/mantle-usl.git runtime/component/mantle-usl
git clone https://github.com/growerp/SimpleScreens.git runtime/component/SimpleScreens
git clone https://github.com/growerp/moqui-fop.git runtime/component/moqui-fop
curl -L https://jdbc.postgresql.org/download/postgresql-42.2.9.jar -o runtime/lib/postgresql-42.2.9.jar
# remove john doe login
rm runtime/component/@growerp/data/0-GrowerpDebug.xml
#  temporary only: the antwebsystems website
cp -r ../website runtime/component/growerp/service/growerp
cp ../AWSSetupAaaWebSiteData.xml runtime/component/growerp/data
./gradlew addRunTime
cd ..
rm -rf buildImage && mkdir buildImage && cp Dockerfile buildImage && cd buildImage
if unzip -q ../moqui/moqui-plus-runtime.war; then
    echo "downloaded and build successfully"
else
    echo "compile/build failed"
    exit
fi
echo "building image...."
docker build -t growerp/growerp-moqui .
docker tag growerp/growerp-moqui growerp/growerp-moqui:$DATE
echo "push image to hub.docker.com/growerp/growerp-moqui"
if docker login -u $DOCKERHUBACCOUNT -p $DOCKERHUBPASSWORD ; then
    if docker push growerp/growerp-moqui ; then
        cd ..
        rm -rf moqui; rm -rf buildImage
        docker rmi -f $(docker images -q)
        echo "image pushed to docker hub"
        exit
    fi
fi
echo "something went wrong?"
