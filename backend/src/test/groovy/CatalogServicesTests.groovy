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
import spock.lang.PendingFeature
import spock.lang.Shared
import spock.lang.Specification

/* Tests for categories and products (CatalogServices100):
   - create, get, update and delete a category and a product
   - a product in a category, search and paging
   - another tenant does not see the products

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class CatalogServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant, otherTenant
    @Shared String service = 'growerp.100.CatalogServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        otherTenant = GrowerpTestSupport.tenant(ec, 'CatalogTestOther')
        tenant = GrowerpTestSupport.tenant(ec, 'CatalogTest')
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
        if (ec.user.username != tenant.username) ec.user.internalLoginUser(tenant.username)
    }

    Map createProduct(Map product) {
        return ec.service.sync().name("${service}.create#Product")
                .parameters([product: [productTypeId: 'Physical Good'] + product]).call()?.product
    }

    def "create, get, update and delete a category"() {
        when:
        Map category = ec.service.sync().name("${service}.create#ProductCategory")
                .parameters([category: [categoryName: "Tools ${run}", description: 'Hand tools']])
                .call().category

        then:
        !ec.message.hasError()
        category.categoryId
        category.categoryName == "Tools ${run}"

        when:
        List categories = ec.service.sync().name("${service}.get#ProductCategory")
                .parameters([categoryId: category.categoryId]).call().categories

        then:
        categories.size() == 1
        categories[0].description == 'Hand tools'

        when:
        Map updated = ec.service.sync().name("${service}.update#ProductCategory")
                .parameters([category: [categoryId: category.categoryId, categoryName: "Power tools ${run}",
                        description: 'Electric']]).call().category

        then:
        !ec.message.hasError()
        updated.categoryName == "Power tools ${run}"

        when:
        ec.service.sync().name("${service}.delete#ProductCategory")
                .parameters([category: [categoryId: category.categoryId]]).call()

        then:
        !ec.message.hasError()
        !ec.service.sync().name("${service}.get#ProductCategory")
                .parameters([search: "Power tools ${run}"]).call().categories
    }

    def "create, get, update and delete a product in a category"() {
        given:
        Map category = ec.service.sync().name("${service}.create#ProductCategory")
                .parameters([category: [categoryName: "Shelf ${run}"]]).call().category

        when:
        Map product = createProduct([productName: "Hammer ${run}", price: 12.5, listPrice: 15,
                description: 'Claw hammer', categories: [[categoryId: category.categoryId]]])

        then:
        !ec.message.hasError()
        product.productId
        product.pseudoId
        product.price as BigDecimal == 12.5
        product.productTypeId == 'Physical Good'
        product.categories*.categoryId == [category.categoryId]

        when:
        List products = ec.service.sync().name("${service}.get#Product")
                .parameters([productId: product.productId]).call().products

        then:
        products.size() == 1
        products[0].productName == "Hammer ${run}"
        products[0].listPrice as BigDecimal == 15
        products[0].currency?.currencyId == 'USD'

        when: 'the product is listed per category'
        List inCategory = ec.service.sync().name("${service}.get#Product")
                .parameters([categoryId: category.categoryId]).call().products

        then:
        inCategory*.productId == [product.productId]

        when:
        Map updated = ec.service.sync().name("${service}.update#Product")
                .parameters([product: [productId: product.productId, productName: "Sledgehammer ${run}",
                        productTypeId: 'Physical Good', price: 20, listPrice: 25,
                        categories: [[categoryId: category.categoryId]]]]).call().product

        then:
        !ec.message.hasError()
        updated.productName == "Sledgehammer ${run}"
        updated.price as BigDecimal == 20

        when:
        ec.service.sync().name("${service}.delete#Product")
                .parameters([product: [productId: product.productId]]).call()

        then:
        !ec.message.hasError()
        !ec.service.sync().name("${service}.get#Product")
                .parameters([productId: product.productId]).call().products
    }

    def "search products"() {
        given:
        (1..3).each { createProduct([productName: "Finder${run} ${it}", price: it]) }

        when:
        List found = ec.service.sync().name("${service}.get#Product")
                .parameters([search: "Finder${run}"]).call().products

        then:
        found*.productName.sort() == (1..3).collect { "Finder${run} ${it}".toString() }
    }

    @PendingFeature(reason = 'https://github.com/growerp/growerp/issues/51')
    def "a page holds at most limit products"() {
        given:
        (1..3).each { createProduct([productName: "Pager${run} ${it}", price: it]) }

        when:
        List page = ec.service.sync().name("${service}.get#Product")
                .parameters([search: "Pager${run}", start: 0, limit: 2]).call().products

        then:
        page.size() == 2
    }

    def "a service product without a warehouse"() {
        when:
        Map product = createProduct([productName: "Consult ${run}", productTypeId: 'Service',
                price: 100, useWarehouse: false])

        then:
        !ec.message.hasError()
        product.productTypeId == 'Service'
        !product.useWarehouse
    }

    def "another tenant does not see the products"() {
        given:
        Map product = createProduct([productName: "Private ${run}", price: 1])

        when:
        ec.user.internalLoginUser(otherTenant.username)
        List found = ec.service.sync().name("${service}.get#Product")
                .parameters([search: "Private ${run}"]).call().products

        then:
        !found
    }

    def "the dashboard counts the products"() {
        when:
        Map out = ec.service.sync().name("${service}.get#CatalogDashboard").call()

        then:
        !ec.message.hasError()
        out.activeProducts > 0
    }
}
