#!/bin/bash
set -x

echo "params 1: $1 2: $2 3: $3"
echo "docker tag: $TAG"

CONF_FILE="conf/MoquiProductionConf.xml"

# =================== start ===============================

#insert version
#if [ -n "$TAG" ] ; then
#    sed -i -e "s/\XXXXX/$TAG/g" runtime/component/growerp/component.xml
#fi

# insert some sensitive data from docker-compose
if [ "$SMTP_USER" != "" ] ; then
    echo "updating email"
    sed -i -e "s/SMTP_USER/${SMTP_USER}/g" runtime/component/growerp/data/GrowerpAbSeedData.xml
    sed -i -e "s/SMTP_PASSWORD/${SMTP_PASSWORD}/g" runtime/component/growerp/data/GrowerpAbSeedData.xml
fi
if [ "$BIRDSEND_API_KEY" != "" ] ; then
    echo "updating birdsend"
    sed -i -e "s/BIRDSEND_API_KEY/${BIRDSEND_API_KEY}/g" runtime/component/growerp/data/GrowerpAbSeedData.xml
    sed -i -e "s/BIRDSEND_AUTM_SEQUENCE/${BIRDSEND_AUTM_SEQUENCE}/g" runtime/component/growerp/data/GrowerpAbSeedData.xml
fi
if [ "$STRIPE_SECRET_KEY" != "" ] ; then
    echo "updating stripe key"
    sed -i -e "s/\STRIPE_SECRET_KEY/${STRIPE_SECRET_KEY}/g" runtime/component/mantle-stripe/data/StripeInstallData.xml
fi

#load data if required
if [ ! -z "$DB_DATA" ] && [ "$DB_DATA" != "NONE" ] ; then
    if [ "$DB_DATA" == "CONVERSION" ] ; then
        echo "Loading conversion data...takes hours to start up......."
        java -cp . MoquiStart load types=seed,seed-initial,install,conversion timeout=10800 conf=$CONF_FILE no-run-es
    fi
    if [ "$DB_DATA" == "DEMO" ] ; then
        echo "Loading demo data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed,seed-initial,demo conf=$CONF_FILE no-run-es
    fi
    if [ "$DB_DATA" == "SEED-INITIAL" ] ; then
        echo "Loading seed and seed-initial data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed,seed-initial conf=$CONF_FILE no-run-es
    fi
    if [ "$DB_DATA" == "INSTALL" ] ; then
        echo "Loading seed and seed-initial and Install data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed,seed-initial,install conf=$CONF_FILE no-run-es
    fi
    if [ "$DB_DATA" == "SEED" ] ; then
        echo "Loading seed data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed conf=$CONF_FILE
    fi
fi

# start moqui
java -cp . MoquiStart port=80 conf=$CONF_FILE no-run-es

