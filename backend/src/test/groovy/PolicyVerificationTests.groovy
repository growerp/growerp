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

/* Tests for get#PolicyVerification, the public proof of insurance behind the QR code of the
   digital policy card: it answers without login, shows validity, masks the plate and never
   returns the insured's personal data.

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class PolicyVerificationTests extends Specification {
    @Shared ExecutionContext ec
    @Shared String token = 'verifytesttoken0000000000000001'
    @Shared String expiredToken = 'verifytesttoken0000000000000002'

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.user.loginUser('SystemSupport', 'moqui')
        ec.artifactExecution.disableAuthz()
        long day = 24L * 3600L * 1000L
        long now = System.currentTimeMillis()
        [[policyId: 'VERIFY_TEST_1', verificationToken: token, statusId: 'InpsActive',
          effectiveDate: new java.sql.Timestamp(now - 30 * day),
          expirationDate: new java.sql.Timestamp(now + 300 * day)],
         [policyId: 'VERIFY_TEST_2', verificationToken: expiredToken, statusId: 'InpsLapsed',
          effectiveDate: new java.sql.Timestamp(now - 400 * day),
          expirationDate: new java.sql.Timestamp(now - 35 * day)]].each { p ->
            ec.entity.makeValue('growerp.insurance.Policy').setAll(p + [ownerPartyId: '100000',
                pseudoId: p.policyId, policyNumber: 'TNDS-' + p.policyId, insuredPartyId: 'VERIFY_INSURED',
                policyTypeEnumId: 'InptMotorCompulsory', vehiclePlate: '51K-238.46',
                vehicleDescription: 'Geely Coolray', premiumAmount: 480000]).createOrUpdate()
        }
        ec.user.logoutUser()
    }

    def cleanupSpec() {
        ec.entity.find('growerp.insurance.Policy').condition('policyId', 'in',
            ['VERIFY_TEST_1', 'VERIFY_TEST_2']).disableAuthz().deleteAll()
        if (ec) ec.destroy()
    }

    private Map verify(String t) {
        ec.service.sync().name('growerp.100.InsuranceServices100.get#PolicyVerification')
            .parameters([verificationToken: t]).call()
    }

    def "an active policy is valid without login, with a masked plate"() {
        when:
        Map out = verify(token)
        then:
        !ec.user.userId
        out.found && out.valid
        out.vehiclePlate == '51K-***.46'
        out.policyNumber == 'TNDS-VERIFY_TEST_1'
        out.policyType
    }

    def "no personal data or premium is returned"() {
        when:
        Map out = verify(token)
        then:
        !out.containsKey('insuredPartyId')
        !out.containsKey('premiumAmount')
        !out.values().any { it?.toString()?.contains('VERIFY_INSURED') }
    }

    def "a lapsed policy is found but not valid"() {
        when:
        Map out = verify(expiredToken)
        then:
        out.found && !out.valid
    }

    def "an unknown or short token is not found"() {
        expect:
        !verify('verifytesttoken0000000000000099').found
        !verify('short').found
    }
}
