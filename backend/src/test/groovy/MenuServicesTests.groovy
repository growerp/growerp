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
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Stepwise

/* Tests for MenuServices100 screen access (issue #75):
   - the security grid stores the organization's changes as overrides, not a menu copy
   - a menu item added to the seed reaches an organization that changed screen access
   - an override holds for the menu and for REST authorization
   - existing organization copies migrate into overrides

   Uses two seed items of its own in ADMIN_DEFAULT, on test domains, so the
   assertions do not depend on the shipped menu.

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
@Stepwise
class MenuServicesTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(MenuServicesTests.class)
    @Shared ExecutionContext ec
    @Shared Map tenant
    @Shared Map migrateTenant

    static final String ITEM_A = 'SPOCK_MENU_A'
    static final String ITEM_B = 'SPOCK_MENU_B'
    static final String DOMAIN_A = 'SPOCK_DOMAIN_A'
    static final String DOMAIN_B = 'SPOCK_DOMAIN_B'

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'MenuOverrides')
        migrateTenant = GrowerpTestSupport.tenant(ec, 'MenuMigrate')
        ec.artifactExecution.disableAuthz()
        removeTestItems()
        createSeedItem(ITEM_A, DOMAIN_A, 900)
    }

    def cleanupSpec() {
        if (ec) {
            ec.artifactExecution.disableAuthz()
            removeTestItems()
            ec.destroy()
        }
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
        ec.message.clearAll()
        ec.user.internalLoginUser(tenant.username)
    }

    private void createSeedItem(String menuItemId, String domain, int sequenceNum) {
        ec.service.sync().name('create#growerp.menu.MenuItem').parameters([menuItemId: menuItemId,
                menuConfigurationId: 'ADMIN_DEFAULT', title: menuItemId, route: '/' + menuItemId,
                widgetName: menuItemId, artifactGroupId: domain, sequenceNum: sequenceNum]).call()
    }

    private void removeTestItems() {
        // copies first: they are found by title, the seed items by id
        List copies = ec.entity.find('growerp.menu.MenuItem')
                .condition('title', 'in', [ITEM_A, ITEM_B]).list()
        ec.entity.find('growerp.menu.MenuItemAccess')
                .condition('menuItemId', 'in', [ITEM_A, ITEM_B]).deleteAll()
        copies.each { it.delete() }
        [tenant, migrateTenant].each { t ->
            if (!t) return
            ec.entity.find('growerp.menu.MenuConfiguration')
                    .condition('ownerPartyId', t.ownerPartyId).list().each { config ->
                ec.entity.find('growerp.menu.MenuItem')
                        .condition('menuConfigurationId', config.menuConfigurationId)
                        .condition('parentMenuItemId', 'is-not-null', null).deleteAll()
                ec.entity.find('growerp.menu.MenuItem')
                        .condition('menuConfigurationId', config.menuConfigurationId).deleteAll()
                config.delete()
            }
        }
    }

    private Map domainAccess(Map t, String userGroupId) {
        return ec.service.sync().name('growerp.100.SecurityServices100.get#OwnerDomainAccess')
                .parameters([ownerPartyId: t.ownerPartyId, userGroupId: userGroupId]).call().domainAccess
    }

    private Map menuItem(String menuItemId, Map parameters = [:]) {
        Map config = ec.service.sync().name('growerp.100.MenuServices100.get#MenuConfiguration')
                .parameters([appId: 'admin', userVersion: true, includeAllGroups: true] + parameters).call()
        return config.menuItems.find { it.menuItemId == menuItemId }
    }

    def "screen access set in the grid is stored as an override, not as a menu copy"() {
        when:
        ec.service.sync().name('growerp.100.MenuServices100.set#MenuItemGroups')
                .parameters([menuItemId: ITEM_A, userGroups: ['GROWERP_M_ADMIN'],
                        updateGroups: ['GROWERP_M_ADMIN']]).call()

        then:
        !ec.message.hasError()
        ec.entity.find('growerp.menu.MenuItemAccess').condition('ownerPartyId', tenant.ownerPartyId)
                .condition('menuItemId', ITEM_A).one()?.userGroupsJson == '["GROWERP_M_ADMIN"]'
        ec.entity.find('growerp.menu.MenuConfiguration').condition('ownerPartyId', tenant.ownerPartyId)
                .count() == 0
    }

    def "the override holds for the menu and for REST"() {
        expect: 'the menu serves the seed item with the organization groups'
        menuItem(ITEM_A)?.userGroups == ['GROWERP_M_ADMIN']

        and: 'employees lose the domain, the admin keeps write'
        domainAccess(tenant, 'GROWERP_M_EMPLOYEE')[DOMAIN_A] == null
        domainAccess(tenant, 'GROWERP_M_ADMIN')[DOMAIN_A] == 'WRITE'

        and: 'another organization keeps the shipped default'
        domainAccess(migrateTenant, 'GROWERP_M_EMPLOYEE')[DOMAIN_A] == 'WRITE'
    }

    def "a menu item added to the seed shows up for an organization with overrides"() {
        when:
        createSeedItem(ITEM_B, DOMAIN_B, 910)

        then: 'no migration needed, the shipped default groups apply'
        menuItem(ITEM_B, [includeAllGroups: false]) != null
        domainAccess(tenant, 'GROWERP_M_EMPLOYEE')[DOMAIN_B] == 'WRITE'
    }

    def "a new personal copy starts with the organization access"() {
        when:
        Map ensured = ec.service.sync().name('growerp.100.MenuServices100.ensure#UserMenuConfiguration')
                .parameters([menuConfigurationId: 'ADMIN_DEFAULT']).call()

        then:
        ensured.wasCloned
        ec.entity.find('growerp.menu.MenuItem')
                .condition('menuConfigurationId', ensured.userMenuConfigurationId)
                .condition('title', ITEM_A).one()?.userGroupsJson == '["GROWERP_M_ADMIN"]'

        cleanup:
        ec.service.sync().name('growerp.100.MenuServices100.reset#MenuConfiguration')
                .parameters([menuConfigurationId: ensured.userMenuConfigurationId]).call()
    }

    def "the grid still rejects system access and removing the administrator"() {
        when:
        ec.service.sync().name('growerp.100.MenuServices100.set#MenuItemGroups')
                .parameters([menuItemId: ITEM_A, userGroups: ['GROWERP_M_ADMIN', 'GROWERP_M_SYSTEM']]).call()

        then:
        ec.message.errorsString.contains('GROWERP_M_SYSTEM')

        when:
        ec.message.clearAll()
        ec.service.sync().name('growerp.100.MenuServices100.set#MenuItemGroups')
                .parameters([menuItemId: ITEM_A, userGroups: ['GROWERP_M_EMPLOYEE']]).call()

        then:
        ec.message.errorsString.contains('cannot remove administrator access')

        cleanup:
        ec.message.clearAll()
    }

    def "an existing organization copy migrates into overrides"() {
        setup: 'an organization copy of the admin menu, as the grid used to make it'
        String configId = ec.service.sync().name('create#growerp.menu.MenuConfiguration')
                .parameters([ownerPartyId: migrateTenant.ownerPartyId, appId: 'admin',
                        name: 'Admin Menu (Organization)']).call().menuConfigurationId
        Map idMap = [:]
        List seedItems = ec.entity.find('growerp.menu.MenuItem')
                .condition('menuConfigurationId', 'ADMIN_DEFAULT').list()
        seedItems.each { item ->
            Map fields = item.getMap().findAll { k, v -> !(k in ['menuItemId', 'parentMenuItemId',
                    'lastUpdatedStamp']) }
            fields.menuConfigurationId = configId
            if (item.menuItemId == ITEM_A) fields.userGroupsJson = '["GROWERP_M_ADMIN"]'
            idMap[item.menuItemId] = ec.service.sync().name('create#growerp.menu.MenuItem')
                    .parameters(fields).call().menuItemId
        }
        seedItems.findAll { it.parentMenuItemId != null }.each { item ->
            ec.service.sync().name('update#growerp.menu.MenuItem').parameters(
                    [menuItemId: idMap[item.menuItemId], parentMenuItemId: idMap[item.parentMenuItemId]]).call()
        }
        ec.user.internalLoginUser('SystemSupport')

        when:
        Map out = ec.service.sync().name('growerp.100.MenuServices100.migrate#OwnerMenuOverrides').call()

        then: 'only the changed item becomes an override, the copy is gone'
        !ec.message.hasError()
        out.migratedCount >= 1
        ec.entity.find('growerp.menu.MenuConfiguration')
                .condition('ownerPartyId', migrateTenant.ownerPartyId).count() == 0
        ec.entity.find('growerp.menu.MenuItemAccess')
                .condition('ownerPartyId', migrateTenant.ownerPartyId).list()*.menuItemId == [ITEM_A]

        and: 'access is the same as with the copy'
        domainAccess(migrateTenant, 'GROWERP_M_EMPLOYEE')[DOMAIN_A] == null
        domainAccess(migrateTenant, 'GROWERP_M_EMPLOYEE')[DOMAIN_B] == 'WRITE'

        when: 'running it again changes nothing'
        out = ec.service.sync().name('growerp.100.MenuServices100.migrate#OwnerMenuOverrides').call()

        then:
        out.migratedCount == 0
    }
}
