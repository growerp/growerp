# GrowERP Moqui backend

This is the backend to the flutter frontend at: https://github.com/growerp/growerp

## For an existing installation change the following line below:
git clone >>>-b existing<<< https://github.com/growerp/growerp-moqui.git runtime/component/growerp
And in the app: 
change the assets/cfg/ app_settings.json: singleCompany: partyId of single company


## to run the backend locally:
```
git clone -b growerp https://github.com/growerp/moqui-framework.git moqui && cd moqui
git clone https://github.com/growerp/moqui-runtime runtime
git clone https://github.com/growerp/growerp-moqui.git runtime/component/growerp
git clone -b growerp https://github.com/growerp/PopRestStore.git runtime/component/PopRestStore
git clone -b growerp https://github.com/growerp/mantle-udm.git -b growerp runtime/component/mantle-udm
git clone -b growerp https://github.com/growerp/mantle-usl.git runtime/component/mantle-usl
git clone https://github.com/growerp/mantle-stripe.git runtime/component/mantle-stripe
git clone https://github.com/growerp/moqui-fop.git runtime/component/moqui-fop

./gradlew downloadel
./gradlew build
java -jar moqui.war load types=seed,seed-initial,install
java -jar moqui.war
```

In another teminal start also the chat server: https://github.com/growerp/growerp-chat

and in a separate terminal:
```
git clone https://github.com/growerp/growerp
cd growerp/packages/admin
flutter run
```




