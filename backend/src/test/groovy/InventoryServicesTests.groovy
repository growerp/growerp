/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import spock.lang.Shared
import spock.lang.Specification

/* Tests for warehouse locations and assets (InventoryServices100):
   - create, get, update and delete a location
   - create, get and update an asset of a product in a location
   - another tenant does not see the locations

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class InventoryServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant
    @Shared String service = 'growerp.100.InventoryServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'InventoryTestOther')
        tenant = GrowerpTestSupport.tenant(ec, 'InventoryTest')
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        if (ec.user.username != tenant.username) ec.user.internalLoginUser(tenant.username)
    }

    Map createLocation(String name) {
        return ec.service.sync().name("${service}.create#Location")
                .parameters([location: [locationName: name]]).call()?.location
    }

    def "create, get, update and delete a location"() {
        when:
        Map location = createLocation("Shelf A ${run}")

        then:
        !ec.message.hasError()
        location.locationId
        location.locationName == "Shelf A ${run}"

        when:
        List locations = ec.service.sync().name("${service}.get#Location")
                .parameters([locationId: location.locationId]).call().locations

        then:
        locations*.locationName == ["Shelf A ${run}".toString()]

        when:
        Map updated = ec.service.sync().name("${service}.update#Location")
                .parameters([location: [locationId: location.locationId, locationName: "Shelf B ${run}"]])
                .call().location

        then:
        !ec.message.hasError()
        updated.locationName == "Shelf B ${run}"

        when:
        ec.service.sync().name("${service}.delete#Location")
                .parameters([location: [locationId: location.locationId]]).call()

        then:
        !ec.message.hasError()
        !ec.service.sync().name("${service}.get#Location")
                .parameters([locationId: location.locationId]).call().locations
    }

    def "create, get and update an asset in a location"() {
        given:
        Map location = createLocation("Bin ${run}")
        Map product = ec.service.sync().name('growerp.100.CatalogServices100.create#Product')
                .parameters([product: [productName: "Widget ${run}", productTypeId: 'Physical Good',
                        price: 5, useWarehouse: true]]).call().product

        when:
        Map asset = ec.service.sync().name("${service}.create#Asset")
                .parameters([asset: [assetName: "Widget stock ${run}", statusId: 'Available',
                        quantityOnHand: 10, availableToPromise: 10, acquireCost: 2,
                        product: [productId: product.productId],
                        location: [locationId: location.locationId]]]).call().asset

        then:
        !ec.message.hasError()
        asset.assetId
        asset.product.productId == product.productId
        asset.location.locationId == location.locationId
        asset.quantityOnHand as BigDecimal == 10

        when:
        List assets = ec.service.sync().name("${service}.get#Assets")
                .parameters([productId: product.productId]).call().assets

        then:
        assets*.assetId == [asset.assetId]

        when: 'the location lists the asset'
        List locations = ec.service.sync().name("${service}.get#Location")
                .parameters([locationId: location.locationId]).call().locations

        then:
        locations[0].assets*.assetId == [asset.assetId]

        when:
        Map updated = ec.service.sync().name("${service}.update#Asset")
                .parameters([asset: [assetId: asset.assetId, assetName: "Widget stock ${run}",
                        statusId: 'Available', quantityOnHand: 7, availableToPromise: 7, acquireCost: 2,
                        product: [productId: product.productId],
                        location: [locationId: location.locationId]]]).call().asset

        then:
        !ec.message.hasError()
        updated.quantityOnHand as BigDecimal == 7
    }

    // https://github.com/growerp/growerp/issues/53
    def "update an asset without an acquire cost"() {
        given:
        Map product = ec.service.sync().name('growerp.100.CatalogServices100.create#Product')
                .parameters([product: [productName: "Nocost ${run}", productTypeId: 'Physical Good',
                        useWarehouse: true]]).call().product
        Map asset = ec.service.sync().name("${service}.create#Asset")
                .parameters([asset: [assetName: "Nocost stock ${run}", statusId: 'Available',
                        quantityOnHand: 1, availableToPromise: 1,
                        product: [productId: product.productId]]]).call().asset

        when:
        ec.service.sync().name("${service}.update#Asset")
                .parameters([asset: [assetId: asset.assetId, assetName: "Nocost stock ${run}",
                        statusId: 'Available', quantityOnHand: 2, availableToPromise: 2,
                        product: [productId: product.productId]]]).call()

        then:
        !ec.message.hasError()
    }

    def "update an asset without a quantity on hand keeps the quantity"() {
        given:
        Map product = ec.service.sync().name('growerp.100.CatalogServices100.create#Product')
                .parameters([product: [productName: "Noqty ${run}", productTypeId: 'Physical Good',
                        useWarehouse: true]]).call().product
        Map asset = ec.service.sync().name("${service}.create#Asset")
                .parameters([asset: [assetName: "Noqty stock ${run}", statusId: 'Available',
                        quantityOnHand: 3, availableToPromise: 3, acquireCost: 5,
                        product: [productId: product.productId]]]).call().asset

        when:
        ec.service.sync().name("${service}.update#Asset")
                .parameters([asset: [assetId: asset.assetId, assetName: "Noqty stock ${run} b",
                        statusId: 'Available', quantityOnHand: '', availableToPromise: 3,
                        acquireCost: 5, product: [productId: product.productId]]]).call()

        then:
        !ec.message.hasError()
        ec.entity.find('mantle.product.asset.Asset').condition('assetId', asset.assetId)
                .useCache(false).one().quantityOnHandTotal == 3
    }

    def "another tenant does not see the locations"() {
        given:
        Map location = createLocation("Hidden ${run}")

        when:
        ec.user.internalLoginUser(otherTenant.username)
        List found = ec.service.sync().name("${service}.get#Location")
                .parameters([search: "Hidden ${run}"]).call().locations

        then:
        !found*.locationId.contains(location.locationId)
    }

    def "the dashboard counts the locations"() {
        given:
        createLocation("Counted ${run}")

        when:
        Map out = ec.service.sync().name("${service}.get#InventoryDashboard").call()

        then:
        !ec.message.hasError()
        out.whLocations > 0
    }
}
