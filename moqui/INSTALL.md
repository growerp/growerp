# Moqui for GrowERP

The current version is V3 installed from:
https://github.com/moqui/moqui-framework/releases/download/v3.0.0/MoquiDemo-3.0.0.zip

1. unzipped in this directory
2. deleted all components at runtime/component **EXCEPT**:
   1. mantle-udm
   2. mantle-usl
   3. moqui-fop
3. added growerp components:
   1. growerp
   2. PopRestStore
   3. mantle-stripe -> add stripe-java-xxxx.jar to /runtime/lib , adjust build.gradle
4. delete files from runtime/component/mantle-udm/data
   1. ZaaGlAccountsInstallData.xml
   2. ZapPayrollTaxInstallData.xml
   3. ItemTypeData.xml
5. To connect an asset to one or more locations
Update file at runtime/component/mantle-udm/entity/FacilityEntities.xml
   added line 262 after 260 from:
```xml
   <relationship type="one" title="Capacity" related="moqui.basic.Uom" short-alias="capacityUom">
            <key-map field-name="capacityUomId"/></relationship>
```
   to:
```xml 
   <relationship type="many" related="mantle.product.asset.Asset" short-alias="AssetLocation">
            <key-map field-name="facilityId"/><key-map field-name="locationSeqId"/></relationship>
```
6. To enable different ledgerformats for different companies 
Update file at: runtime/component/mantle-udm/entity/AccountingLedgerEntities.xml line 57
```xml
   from: <index name="GLACCT_UNQCD" unique="true">.....
   to: <index name="GLACCT_UNQCD" unique="false">....
```
7. update log4j to remove error message at startup

overwrite the following lines in framework/build.gradle starting from line167
    // SLF4J, Log4j 2 (note Log4j 2 is used by various libraries, best not to replace it even if mostly possible with SLF4J)
    api 'org.slf4j:slf4j-api:2.0.7'
    implementation 'org.apache.logging.log4j:log4j-core:2.20.0'
    implementation 'org.apache.logging.log4j:log4j-api:2.20.0'
    runtimeOnly 'org.apache.logging.log4j:log4j-jcl:2.20.0'
    runtimeOnly 'org.apache.logging.log4j:log4j-slf4j2-impl:2.20.0'
(https://forum.moqui.org/t/receiver-class-org-apache-logging-slf4j-slf4jserviceprovider-does-not-define-or-inherit-an-implementation-of-the-resolved-method-abstract-java-lang-string-getrequestedapiversion-of-interface-org-slf4j-spi-slf4jserviceprovider/345/6)

Build moqui system:
```sh
    ./gradlew downloadel #only first time
    ./gradlew build
    java -jar moqui.war load types=seed,seed-initial,install
    java -jar moqui.war
```



