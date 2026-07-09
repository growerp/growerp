/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 *
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 *
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import org.moqui.Moqui
import org.moqui.context.ExecutionContext
import org.moqui.entity.EntityValue
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification
import spock.lang.Stepwise

import java.sql.Timestamp

/* Tests for currency conversion in the one-page checkout (checkOut#OnePage) and
   tenant subscription renewal (renew#TenantSubscription).

   Exchange rates are seeded as fresh moqui.basic.UomConversion records so
   convert#Currency uses the cache and never calls a live rate API.
   Subscription expiry dates are checked by shifting ec.user.setEffectiveTime
   (the backend counterpart of the frontend CustomizableDateTime).

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
@Stepwise
class CurrencyAndSubscriptionTests extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(CurrencyAndSubscriptionTests.class)
    @Shared ExecutionContext ec
    @Shared long effectiveTime = System.currentTimeMillis()
    @Shared long dayMillis = 24 * 60 * 60 * 1000L

    @Shared String ownerPartyId = 'CURTEST_OWNER'
    @Shared String companyPartyId = 'CURTEST_COMP'
    @Shared String productStoreId = 'CURTEST_STORE'
    @Shared String tenantId = 'CURTEST_TENANT'
    @Shared String planProductId = 'CURTEST_PLAN'
    @Shared String subscriberPartyId = 'CURTEST_SUBS'
    @Shared String growerpCompanyId, growerpBaseCurrency
    @Shared String subscriptionId, renewPaymentId

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        ec.user.setEffectiveTime(new Timestamp(effectiveTime))
        // SystemSupport ships with the growerp component install data
        ec.user.loginUser('SystemSupport', 'moqui')
        ec.artifactExecution.disableAuthz()

        // receiving company with EUR base currency and its product store
        // (idempotent: the test database persists between runs)
        if (ec.entity.find('mantle.party.Party').condition('partyId', ownerPartyId).one() == null) {
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: ownerPartyId, partyTypeEnumId: 'PtyOrganization']).call()
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: companyPartyId, partyTypeEnumId: 'PtyOrganization',
                            ownerPartyId: ownerPartyId]).call()
            ec.service.sync().name('create#mantle.party.Organization').disableAuthz()
                    .parameters([partyId: companyPartyId, organizationName: 'Currency Test Co']).call()
            ec.service.sync().name('create#mantle.ledger.config.PartyAcctgPreference').disableAuthz()
                    .parameters([organizationPartyId: companyPartyId, baseCurrencyUomId: 'EUR']).call()
            ec.service.sync().name('create#mantle.product.store.ProductStore').disableAuthz()
                    .parameters([productStoreId: productStoreId, organizationPartyId: companyPartyId,
                            storeName: 'Currency Test Store', defaultCurrencyUomId: 'EUR']).call()
        }

        // deterministic fresh exchange rate so convert#Currency never calls a live API
        ec.service.sync().name('create#moqui.basic.UomConversion').disableAuthz()
                .parameters([uomId: 'USD', toUomId: 'EUR', conversionFactor: 2.0,
                        fromDate: new Timestamp(System.currentTimeMillis())]).call()
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def "convert same currency is identity"() {
        when:
        Map out = ec.service.sync().name('growerp.100.GeneralServices100.convert#Currency')
                .parameters([amount: 100.0, fromCurrencyUomId: 'USD', toCurrencyUomId: 'USD'])
                .disableAuthz().call()

        then:
        out.converted
        out.convertedAmount == 100.0
        out.exchangeRate == 1
    }

    def "convert uses cached UomConversion rate"() {
        when:
        Map out = ec.service.sync().name('growerp.100.GeneralServices100.convert#Currency')
                .parameters([amount: 10.5, fromCurrencyUomId: 'USD', toCurrencyUomId: 'EUR'])
                .disableAuthz().call()

        then:
        out.converted
        out.exchangeRate == 2.0
        out.convertedAmount == 21.00
    }

    def "one page checkout books payment in company currency with original USD amount"() {
        when:
        Map out = ec.service.sync().name('growerp.100.AccountingServices100.checkOut#OnePage')
                .parameters([productStoreId: productStoreId, email: 'curtest@example.com',
                        firstName: 'Currency', lastName: 'Test',
                        creditCardNumber: '4242424242424242', creditCardType: 'Visa',
                        nameOnCard: 'Currency Test', expireMonth: '12', expireYear: '30',
                        cVC: '123', amount: 10.0])
                .disableAuthz().call()
        EntityValue payment = ec.entity.find('mantle.account.payment.Payment')
                .condition('toPartyId', companyPartyId).orderBy('-effectiveDate').list().first

        then:
        out.result.toString() == 'true'
        payment != null
        payment.amountUomId == 'EUR'
        payment.amount == 20.00
        payment.originalCurrencyAmount == 10.0
        payment.originalCurrencyUomId == 'USD'
    }

    def "trial subscription expires after 14 days using effective time"() {
        setup:
        // the GROWERP main company that receives renewal payments (create when absent)
        EntityValue growerpCompany = ec.entity.find('mantle.party.PartyDetailAndRole')
                .condition([ownerPartyId: 'GROWERP', partyTypeEnumId: 'PtyOrganization',
                        roleTypeId: 'OrgInternal'] as Map).list().first
        if (growerpCompany == null) {
            growerpCompanyId = 'CURTEST_GW'
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: growerpCompanyId, partyTypeEnumId: 'PtyOrganization',
                            ownerPartyId: 'GROWERP']).call()
            ec.service.sync().name('create#mantle.party.Organization').disableAuthz()
                    .parameters([partyId: growerpCompanyId, organizationName: 'GrowERP Test HQ']).call()
            ec.service.sync().name('create#mantle.party.PartyRole').disableAuthz()
                    .parameters([partyId: growerpCompanyId, roleTypeId: 'OrgInternal']).call()
            ec.service.sync().name('create#mantle.ledger.config.PartyAcctgPreference').disableAuthz()
                    .parameters([organizationPartyId: growerpCompanyId, baseCurrencyUomId: 'EUR']).call()
        } else {
            growerpCompanyId = growerpCompany.partyId
        }
        EntityValue acctgPref = ec.entity.find('mantle.ledger.config.PartyAcctgPreference')
                .condition('organizationPartyId', growerpCompanyId).one()
        growerpBaseCurrency = acctgPref?.baseCurrencyUomId ?: 'USD'
        // fresh rate for the GROWERP company currency when it is neither USD nor the seeded EUR
        if (!(growerpBaseCurrency in ['USD', 'EUR'])) {
            ec.service.sync().name('create#moqui.basic.UomConversion').disableAuthz()
                    .parameters([uomId: 'USD', toUomId: growerpBaseCurrency, conversionFactor: 2.0,
                            fromDate: new Timestamp(System.currentTimeMillis())]).call()
        }

        // GROWERP-owned plan product with a current USD price (idempotent)
        if (ec.entity.find('mantle.product.Product').condition('productId', planProductId).one() == null) {
            ec.service.sync().name('create#mantle.product.Product').disableAuthz()
                    .parameters([productId: planProductId, productTypeEnumId: 'PtService',
                            ownerPartyId: 'GROWERP', productName: 'Currency Test Plan']).call()
            ec.service.sync().name('create#mantle.product.ProductPrice').disableAuthz()
                    .parameters([productId: planProductId, priceTypeEnumId: 'PptCurrent',
                            pricePurposeEnumId: 'PppPurchase', price: 499.0, priceUomId: 'USD',
                            fromDate: new Timestamp(effectiveTime - 365 * dayMillis)]).call()
        }

        // tenant subscriber (idempotent) with a fresh 14-day trial subscription
        if (ec.entity.find('mantle.party.Party').condition('partyId', subscriberPartyId).one() == null) {
            ec.service.sync().name('create#mantle.party.Party').disableAuthz()
                    .parameters([partyId: subscriberPartyId, partyTypeEnumId: 'PtyPerson',
                            ownerPartyId: 'GROWERP']).call()
            ec.service.sync().name('create#mantle.party.Person').disableAuthz()
                    .parameters([partyId: subscriberPartyId, firstName: 'Renewal', lastName: 'Test']).call()
        }
        // remove subscriptions from previous runs so expiry assertions are deterministic
        ec.entity.find('mantle.product.subscription.Subscription')
                .condition('externalSubscriptionId', tenantId).list()
                .each { EntityValue sub -> sub.delete() }
        Map subOut = ec.service.sync().name('create#mantle.product.subscription.Subscription').disableAuthz()
                .parameters([ownerPartyId: 'GROWERP', subscriberPartyId: subscriberPartyId,
                        externalSubscriptionId: tenantId, productId: planProductId,
                        description: '14-day trial subscription',
                        fromDate: new Timestamp(effectiveTime),
                        thruDate: new Timestamp(effectiveTime + 14 * dayMillis)]).call()
        subscriptionId = subOut.subscriptionId

        when: 'checked within the trial period'
        Map active = ec.service.sync().name('growerp.100.TenantServices100.check#TenantSubscription')
                .parameters([ownerPartyId: tenantId]).disableAuthz().call()

        and: 'the clock is moved 15 days ahead, past the trial'
        ec.user.setEffectiveTime(new Timestamp(effectiveTime + 15 * dayMillis))
        Map expired = ec.service.sync().name('growerp.100.TenantServices100.check#TenantSubscription')
                .parameters([ownerPartyId: tenantId]).disableAuthz().call()

        then:
        active.hasActiveSubscription
        !expired.hasActiveSubscription
        // the date-filter in check#TenantSubscription drops past subscriptions,
        // so a lapsed trial reports 'none' rather than 'expired'
        expired.subscriptionStatus in ['expired', 'none']
    }

    def "renew charges converted plan price and extends subscription one month"() {
        setup:
        BigDecimal expectedAmount = growerpBaseCurrency == 'USD' ? 499.00 : 998.00
        // still 15 days ahead from the previous test
        Timestamp shiftedNow = ec.user.nowTimestamp

        when:
        Map out = ec.service.sync().name('growerp.100.TenantServices100.renew#TenantSubscription')
                .parameters([ownerPartyId: tenantId, plan: planProductId,
                        creditCardNumber: '5555555555554444', creditCardType: 'Mastercard',
                        nameOnCard: 'Renewal Test', expireMonth: '12', expireYear: '30', cVC: '123'])
                .disableAuthz().call()
        renewPaymentId = out.paymentId
        EntityValue payment = ec.entity.find('mantle.account.payment.Payment')
                .condition('paymentId', renewPaymentId).one()
        EntityValue creditCard = ec.entity.find('mantle.account.method.CreditCard')
                .condition('paymentMethodId', payment.paymentMethodId).one()
        EntityValue subscription = ec.entity.find('mantle.product.subscription.Subscription')
                .condition('subscriptionId', subscriptionId).one()
        Map renewed = ec.service.sync().name('growerp.100.TenantServices100.check#TenantSubscription')
                .parameters([ownerPartyId: tenantId]).disableAuthz().call()

        then: 'payment is booked in the GROWERP company currency with USD originals'
        payment != null
        payment.toPartyId == growerpCompanyId
        payment.fromPartyId == subscriberPartyId
        payment.amountUomId == growerpBaseCurrency
        payment.amount == expectedAmount
        growerpBaseCurrency == 'USD' || payment.originalCurrencyAmount == 499.0
        growerpBaseCurrency == 'USD' || payment.originalCurrencyUomId == 'USD'

        and: 'card type matched despite the Mastercard/Master Card spelling difference'
        creditCard.creditCardTypeEnumId == 'CctMastercard'

        and: 'subscription extended one month from the shifted now'
        subscription.thruDate == Timestamp.valueOf(shiftedNow.toLocalDateTime().plusMonths(1))
        renewed.hasActiveSubscription
    }
}
