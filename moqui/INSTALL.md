# Moqui for GrowERP

The current version is V3 installed from:
https://github.com/moqui/moqui-framework/releases/download/v3.0.0/MoquiDemo-3.0.0.zip

1. unzipped in this directory
2. deleted files from runtime/component/mantle-udm/data
   1. ZaaGlAccountsInstallData.xml
   2. ZapPayrollTaxInstallData.xml
   3. ItemTypeData.xml
3. Updated file at runtime/component/mantle-udm/entity/FacilityEntities.xml
   added line 262 after 260:
   ```xml
   <relationship type="one" title="Capacity" related="moqui.basic.Uom" short-alias="capacityUom">
            <key-map field-name="capacityUomId"/></relationship>
    ```
    ```xml 
   <relationship type="many" related="mantle.product.asset.Asset" short-alias="AssetLocation">
            <key-map field-name="facilityId"/><key-map field-name="locationSeqId"/></relationship>
    ```
4. deleted all components at runtime/component EXCEPT:
   1. mantle-udm
   2. mantle-usl
   3. moqui-fop
5. added growerp components:
   1. growerp
   2. PopRestStore
   3. mantle-stripe -> add stripe-java-xxxx.jar to /runtime/lib , adjust build.gradle

Build moqui system:
```sh
    ./gradlew downloadel #only first time
    ./gradlew build
    java -jar moqui.war load types=seed,seed-initial,install
    java -jar moqui.war
```



