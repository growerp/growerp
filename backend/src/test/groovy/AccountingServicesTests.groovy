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

/* Tests for the ledger (AccountingServices100) of a tenant set up with the
   default chart of accounts (init#PartyAccountingConfiguration):
   - list, create and update a gl account, account classes and types
   - time periods
   - ledger journals
   - a posted transaction shows in the ledger and the balance summary
   - item and payment types, the ledger dashboard

   To run: make sure moqui is in place with a loaded database, backend not running, then:
    "cd moqui && ./gradlew :runtime:component:growerp:test"
 */
class AccountingServicesTests extends Specification {
    @Shared ExecutionContext ec
    @Shared Map tenant
    @Shared String service = 'growerp.100.AccountingServices100'
    @Shared String run = Long.toString(System.currentTimeMillis(), 36)
    @Shared String year

    def setupSpec() {
        ec = Moqui.getExecutionContext()
        tenant = GrowerpTestSupport.tenant(ec, 'AccountingTest')
        year = ec.user.nowTimestamp.toLocalDateTime().year.toString()
    }

    def cleanupSpec() {
        if (ec) ec.destroy()
    }

    def cleanup() {
        ec.message.clearErrors()
    }

    List glAccounts(Map parameters = [:]) {
        return ec.service.sync().name("${service}.get#GlAccount").parameters([limit: 1000] + parameters)
                .call().glAccounts
    }

    /** posted balance of cash on hand (11100) in the balance summary of this year (period Y2026).
        The period summaries are kept by a scheduled job and the growerp
        recalculate#GlAccountOrgSummaries runs it async, so recalculate here directly. */
    BigDecimal cashBalance() {
        ec.service.sync().name('mantle.ledger.LedgerServices.recalculate#GlAccountOrgSummaries')
                .parameters([organizationPartyId: tenant.companyPartyId]).call()
        List accounts = ec.service.sync().name("${service}.get#BalanceSummary")
                .parameters([periodName: "Y${year}"]).call().ledgerReport?.glAccounts
        // the report shows the code through the code mask (111-00)
        return (accounts?.find { it.accountName == 'Cash on Hand' }?.postedBalance ?: 0) as BigDecimal
    }

    def "the tenant has the default chart of accounts"() {
        when:
        List accounts = glAccounts()

        then:
        !ec.message.hasError()
        accounts.size() > 50
        accounts.every { it.accountCode && it.accountClass?.topClassId }
        accounts.find { it.accountCode == '11100' }?.accountName == 'Cash on Hand'
    }

    def "create and update a gl account"() {
        given: 'a free code under cash, the default code mask has 5 digits'
        Set used = glAccounts()*.accountCode as Set
        String code = (11900..11999).collect { it.toString() }.find { !used.contains(it) }

        when:
        Map account = ec.service.sync().name("${service}.create#GlAccount")
                .parameters([glAccount: [accountCode: code, accountName: "Petty cash ${run}",
                        accountClass: [classId: 'CASH_EQUIVALENT']]]).call().glAccount

        then:
        !ec.message.hasError()
        account.glAccountId
        account.accountCode == code
        account.isDebit

        when:
        Map updated = ec.service.sync().name("${service}.update#GlAccount")
                .parameters([glAccount: [glAccountId: account.glAccountId, accountCode: code,
                        accountName: "Cash box ${run}", accountClass: [classId: 'CASH_EQUIVALENT'],
                        accountType: [accountTypeId: 'GatCurrentAsset']]])
                .call().glAccount

        then:
        !ec.message.hasError()
        updated.accountName == "Cash box ${run}"
        glAccounts([search: "Cash box ${run}"])*.glAccountId == [account.glAccountId]
    }

    // https://github.com/growerp/growerp/issues/55
    def "update a gl account without an account type"() {
        given:
        Map root = glAccounts().find { it.accountCode == '10000' }

        when:
        ec.service.sync().name("${service}.update#GlAccount")
                .parameters([glAccount: [glAccountId: root.glAccountId, accountCode: '10000',
                        accountName: root.accountName, accountClass: [classId: 'ASSET']]]).call()

        then:
        !ec.message.hasError()
    }

    def "account classes and types"() {
        when:
        Map out = ec.service.sync().name("${service}.get#GlAccountClasses")
                .parameters([accountClass: [classId: 'CASH_EQUIVALENT']]).call()
        List types = ec.service.sync().name("${service}.get#GlAccountType").parameters([limit: 100])
                .call().accountTypes

        then:
        !ec.message.hasError()
        out.classEnumId == 'CASH_EQUIVALENT'
        out.classes.every { it.parentClassId == 'ASSET' }
        types
    }

    def "the current year has time periods"() {
        when:
        List periods = ec.service.sync().name("${service}.get#TimePeriod")
                .parameters([periodType: 'Y', year: year]).call().timePeriods

        then:
        !ec.message.hasError()
        periods*.periodName.any { it.contains(year) }
        periods.every { !it.isClosed }
    }

    def "create and update a ledger journal"() {
        when:
        Map journal = ec.service.sync().name("${service}.create#LedgerJournal")
                .parameters([ledgerJournal: [journalName: "Journal ${run}"]]).call().ledgerJournal

        then:
        !ec.message.hasError()
        journal.journalId

        when:
        Map updated = ec.service.sync().name("${service}.update#LedgerJournal")
                .parameters([ledgerJournal: [journalId: journal.journalId, journalName: "Year end ${run}"]])
                .call().ledgerJournal
        List journals = ec.service.sync().name("${service}.get#LedgerJournal")
                .parameters([search: "Year end ${run}"]).call().ledgerJournals

        then:
        !ec.message.hasError()
        updated.journalName == "Year end ${run}"
        journals*.journalId == [journal.journalId]
    }

    def "a posted transaction shows in the ledger and the balance summary"() {
        given:
        List accounts = glAccounts()
        Map cash = accounts.find { it.accountCode == '11100' }
        Map equity = accounts.find { it.accountClass.parentClassId == 'EQUITY' && it.accountClass.classId }
        BigDecimal cashBefore = cashBalance()

        when: 'the owner puts 500 into the cash account'
        Map transaction = ec.service.sync().name('growerp.100.FinDocServices100.create#FinDoc')
                .parameters([finDoc: [docType: 'transaction', sales: false, description: "Capital ${run}",
                        isPosted: true,
                        items: [[glAccount: [glAccountId: cash.glAccountId], isDebit: true, price: 500],
                                [glAccount: [glAccountId: equity.glAccountId], isDebit: false, price: 500]]]])
                .call().finDoc

        then:
        !ec.message.hasError()
        transaction.transactionId
        ec.service.sync().name('growerp.100.FinDocServices100.get#FinDoc')
                .parameters([docType: 'transaction', finDocId: transaction.transactionId])
                .call().finDocs[0].isPosted

        when:
        Map ledger = ec.service.sync().name("${service}.get#Ledger").call().ledgerReport

        then:
        !ec.message.hasError()
        cashBalance() - cashBefore == 500
        ledger.glAccounts
    }

    def "item and payment types are mapped to gl accounts"() {
        when:
        List itemTypes = ec.service.sync().name("${service}.get#ItemType").parameters([sales: true])
                .call().itemTypes
        List paymentTypes = ec.service.sync().name("${service}.get#PaymentType").parameters([sales: true])
                .call().paymentTypes

        then:
        !ec.message.hasError()
        itemTypes.find { it.itemTypeId == 'ItemProduct' }?.accountCode
        paymentTypes
    }

    def "the ledger dashboard counts the accounts"() {
        when:
        Map out = ec.service.sync().name("${service}.get#LedgerDashboard").call()

        then:
        !ec.message.hasError()
        out.accounts as Integer > 50
    }
}
