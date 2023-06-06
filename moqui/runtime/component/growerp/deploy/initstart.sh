#!/bin/bash
set -x

HOME_DIR=$PWD
echo $HOME_DIR

CONF_FILE="conf/MoquiProductionConf.xml"

# =================== start ===============================

#cd $HOME_DIR

#load data if required
if [ ! -z "$DB_DATA" ] && [ "$DB_DATA" != "NONE" ] ; then
    if [ "$DB_DATA" == "CONVERSION" ] ; then
        echo "Loading conversion data...takes hours to start up......."
        java -cp . MoquiStart load types=seed,seed-initial,install,conversion timeout=10800 conf=$CONF_FILE
    fi
    if [ "$DB_DATA" == "DEMO" ] ; then
        echo "Loading demo data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed,seed-initial,demo conf=$CONF_FILE
    fi
    if [ "$DB_DATA" == "SEED-INITIAL" ] ; then
        echo "Loading seed and seed-initial data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed,seed-initial conf=$CONF_FILE
    fi
    if [ "$DB_DATA" == "INSTALL" ] ; then
        echo "Loading seed and seed-initial data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed,seed-initial,install conf=$CONF_FILE
    fi
    if [ "$DB_DATA" == "SEED" ] ; then
        echo "Loading seed data...takes minutes to start up......."
        java -cp . MoquiStart load types=seed conf=$CONF_FILE
    fi
fi

# start moqui
java -cp . MoquiStart port=80 conf=$CONF_FILE

