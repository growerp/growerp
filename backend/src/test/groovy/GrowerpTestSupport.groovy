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

import org.moqui.context.ExecutionContext

/* Tenants for the backend specs, set up the way a registration does:
   create#Tenant then complete#TenantSetup (accounting, product store, warehouse),
   without demo data.

   The first registration on a database takes over the seeded GROWERP owner, so
   GROWERP is set up first with its own admin; every spec then gets a tenant of
   its own. Tenants are found again by the admin email, the test database
   persists between runs.
 */
class GrowerpTestSupport {
    static final String GROWERP_ADMIN = 'growerp-admin@spock.example.com'

    /** Log in as the admin of the tenant named key, creating the tenant on first use.
        Returns [ownerPartyId, companyPartyId, adminPartyId, username]. */
    static Map tenant(ExecutionContext ec, String key, String currencyId = 'USD') {
        ec.artifactExecution.disableAuthz()
        if (!userExists(ec, GROWERP_ADMIN)) register(ec, GROWERP_ADMIN, 'GrowERP', 'USD')
        String email = "${key.toLowerCase()}@spock.example.com"
        if (!userExists(ec, email)) register(ec, email, "${key} Co", currencyId)
        ec.user.internalLoginUser(email)
        Map related = ec.service.sync().name('growerp.100.GeneralServices100.get#RelatedCompanyAndOwner').call()
        return [ownerPartyId: related.ownerPartyId, companyPartyId: related.companyPartyId,
                adminPartyId: related.userPartyId, username: email]
    }

    static boolean userExists(ExecutionContext ec, String username) {
        return ec.entity.find('moqui.security.UserAccount').condition('username', username)
                .useCache(false).one() != null
    }

    static void register(ExecutionContext ec, String email, String companyName, String currencyId) {
        Map created = ec.service.sync().name('growerp.100.TenantServices100.create#Tenant')
                .parameters([adminEmail: email, adminFirstName: 'Admin', adminLastName: companyName,
                        password: 'qqqqqq9!', applicationId: 'AppAdmin']).call()
        ec.user.internalLoginUser(email)
        ec.service.sync().name('growerp.100.TenantServices100.complete#TenantSetup')
                .parameters([ownerPartyId: created.ownerPartyId, companyPartyId: created.companyPartyId,
                        companyName: companyName, currencyId: currencyId, demoData: false,
                        applicationId: 'AppAdmin', userPartyId: created.adminPartyId]).call()
        if (ec.message.hasError()) throw new IllegalStateException(
                "Tenant setup for ${email} failed: ${ec.message.errorsString}")
        ec.user.logoutUser()
    }
}
