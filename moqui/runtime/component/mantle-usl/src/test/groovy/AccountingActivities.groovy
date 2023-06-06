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
import org.slf4j.Logger
import org.slf4j.LoggerFactory
import spock.lang.Shared
import spock.lang.Specification

import java.sql.Timestamp

/* To run these make sure moqui, and mantle are in place and run:
    "gradle cleanAll load runtime/mantle/mantle-usl:test"
   Or to quick run with saved DB copy use "gradle loadSave" once then each time "gradle reloadSave runtime/mantle/mantle-usl:test"
 */

class AccountingActivities extends Specification {
    @Shared
    protected final static Logger logger = LoggerFactory.getLogger(AccountingActivities.class)
    @Shared
    ExecutionContext ec
    @Shared
    String organizationPartyId = 'ORG_ZIZI_RETAIL', currencyUomId = 'USD', timePeriodId
    @Shared
    String organizationPartyId2 = 'ORG_ZIZI_CORP', timePeriodId2
    @Shared
    long effectiveTime = System.currentTimeMillis()
    @Shared
    long totalFieldsChecked = 0


    def setupSpec() {
        // init the framework, get the ec
        ec = Moqui.getExecutionContext()
        ec.user.loginUser("john.doe", "moqui")

        // Uncomment to wait for profiler attach; this is the first test class run in mantle-usl (see MantleUslSuite.groovy)
        // logger.warn("Waiting...")
        // Thread.sleep(40000)

        // set an effective date so data check works, etc
        ec.user.setEffectiveTime(new Timestamp(effectiveTime))

        ec.entity.tempSetSequencedIdPrimary("mantle.party.time.TimePeriod", 55100, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.invoice.Invoice", 55100, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans", 55100, 10)
    }

    def cleanupSpec() {
        ec.entity.tempResetSequencedIdPrimary("mantle.party.time.TimePeriod")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.invoice.Invoice")
        ec.entity.tempResetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans")

        logger.info("Accounting Activities complete, ${totalFieldsChecked} record fields checked")
    }

    def setup() {
        ec.artifactExecution.disableAuthz()
    }

    def cleanup() {
        ec.artifactExecution.enableAuthz()
    }

    def "initial Investment AcctgTrans"() {
        when:
        // find the current Fiscal Months
        Map fiscalMonthOut = ec.service.sync().name("mantle.ledger.LedgerServices.get#OrganizationFiscalTimePeriods")
                .parameters([organizationPartyId:organizationPartyId, filterDate:ec.user.nowTimestamp, timePeriodTypeId:'FiscalMonth']).call()
        timePeriodId = fiscalMonthOut.timePeriodList[0].timePeriodId
        fiscalMonthOut = ec.service.sync().name("mantle.ledger.LedgerServices.get#OrganizationFiscalTimePeriods")
                .parameters([organizationPartyId:organizationPartyId2, filterDate:ec.user.nowTimestamp, timePeriodTypeId:'FiscalMonth']).call()
        timePeriodId2 = fiscalMonthOut.timePeriodList[0].timePeriodId

        // create investment postings
        Map transOut = ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTrans")
                .parameters([acctgTransTypeEnumId:'AttCapitalization', organizationPartyId:organizationPartyId, amountUomId:currencyUomId]).call()
        String acctgTransId = transOut.acctgTransId
        String firstAcctgTransId = transOut.acctgTransId
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'111100000', debitCreditFlag:'D', amount:100000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'331100000', debitCreditFlag:'C', amount:100000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:acctgTransId]).call()

        transOut = ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTrans")
                .parameters([acctgTransTypeEnumId:'AttCapitalization', organizationPartyId:organizationPartyId, amountUomId:currencyUomId]).call()
        acctgTransId = transOut.acctgTransId
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'111100000', debitCreditFlag:'D', amount:125000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'331100000', debitCreditFlag:'C', amount:100000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'332100000', debitCreditFlag:'C', amount:25000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:acctgTransId]).call()

        transOut = ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTrans")
                .parameters([acctgTransTypeEnumId:'AttCapitalization', organizationPartyId:organizationPartyId2, amountUomId:currencyUomId]).call()
        acctgTransId = transOut.acctgTransId
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'111100000', debitCreditFlag:'D', amount:150000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'331100000', debitCreditFlag:'C', amount:150000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:acctgTransId]).call()

        // commented to test real time summary updates: recalculate summaries, create GlAccountOrgTimePeriod records
        // ec.service.sync().name("mantle.ledger.LedgerServices.recalculate#GlAccountOrgSummaries").call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <acctgTrans acctgTransId="55100" organizationPartyId="${organizationPartyId}" amountUomId="USD" isPosted="Y" 
                    acctgTransTypeEnumId="AttCapitalization" glFiscalTypeEnumId="GLFT_ACTUAL" postedDate="${effectiveTime}" transactionDate="${effectiveTime}">
                <entries acctgTransEntrySeqId="01" amount="100000" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="D"/>
                <entries acctgTransEntrySeqId="02" amount="100000" glAccountId="331100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="C"/>
            </acctgTrans>
            <acctgTrans acctgTransId="55101" organizationPartyId="${organizationPartyId}" amountUomId="USD" isPosted="Y" 
                    acctgTransTypeEnumId="AttCapitalization" glFiscalTypeEnumId="GLFT_ACTUAL" postedDate="${effectiveTime}" transactionDate="${effectiveTime}">
                <entries acctgTransEntrySeqId="01" amount="125000" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="D"/>
                <entries acctgTransEntrySeqId="02" amount="100000" glAccountId="331100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="C"/>
                <entries acctgTransEntrySeqId="03" amount="25000" glAccountId="332100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="C"/>
            </acctgTrans>
            <acctgTrans acctgTransId="55102" organizationPartyId="ORG_ZIZI_CORP" amountUomId="USD" isPosted="Y" 
                    acctgTransTypeEnumId="AttCapitalization" glFiscalTypeEnumId="GLFT_ACTUAL" postedDate="${effectiveTime}" transactionDate="${effectiveTime}">
                <entries acctgTransEntrySeqId="01" amount="150000" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="D"/>
                <entries acctgTransEntrySeqId="02" amount="150000" glAccountId="331100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="C"/>
            </acctgTrans>
            
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="111100000" timePeriodId="${timePeriodId}"
                    postedCredits="0" postedDebits="225000" endingBalance="225000" organizationPartyId="${organizationPartyId}"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="331100000" timePeriodId="${timePeriodId}"
                    postedCredits="200000" postedDebits="0" endingBalance="200000" organizationPartyId="${organizationPartyId}"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="332100000" timePeriodId="${timePeriodId}"
                    postedCredits="25000" postedDebits="0" endingBalance="25000" organizationPartyId="${organizationPartyId}"/>

            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="111100000" timePeriodId="${timePeriodId2}"
                    postedCredits="0" postedDebits="150000" endingBalance="150000" organizationPartyId="${organizationPartyId2}"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="331100000" timePeriodId="${timePeriodId2}"
                    postedCredits="150000" postedDebits="0" endingBalance="150000" organizationPartyId="${organizationPartyId2}"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
        firstAcctgTransId == "55100"
    }

    def "unpost and Check GlAccountOrgTimePeriod"() {
        when:
        ec.service.sync().name("mantle.ledger.LedgerServices.unpost#AcctgTrans").parameters([acctgTransId:'55100']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <acctgTrans acctgTransId="55100" organizationPartyId="${organizationPartyId}" amountUomId="USD" isPosted="N"/> 
            
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="111100000" timePeriodId="${timePeriodId}"
                    postedCredits="0" postedDebits="125000" endingBalance="125000" organizationPartyId="${organizationPartyId}"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="331100000" timePeriodId="${timePeriodId}"
                    postedCredits="100000" postedDebits="0" endingBalance="100000" organizationPartyId="${organizationPartyId}"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "repost and Check GlAccountOrgTimePeriod"() {
        when:
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:'55100']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <acctgTrans acctgTransId="55100" organizationPartyId="${organizationPartyId}" amountUomId="USD" isPosted="Y"/> 
            
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="111100000" timePeriodId="${timePeriodId}"
                    postedCredits="0" postedDebits="225000" endingBalance="225000" organizationPartyId="${organizationPartyId}"/>
            <mantle.ledger.account.GlAccountOrgTimePeriod glAccountId="331100000" timePeriodId="${timePeriodId}"
                    postedCredits="200000" postedDebits="0" endingBalance="200000" organizationPartyId="${organizationPartyId}"/>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "record Retained Earnings and Dividends Distributable AcctgTrans"() {
        when:
        // Net Income to Retained Earnings
        Map transOut = ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTrans")
                .parameters([acctgTransTypeEnumId:'AttPeriodClosing', organizationPartyId:organizationPartyId, amountUomId:currencyUomId]).call()
        String acctgTransId = transOut.acctgTransId
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'850000000', debitCreditFlag:'D', amount:1000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'335000000', debitCreditFlag:'C', amount:1000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:acctgTransId]).call()

        // Retained Earnings to Dividends - Common Stock
        transOut = ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTrans")
                .parameters([acctgTransTypeEnumId:'AttPeriodClosing', organizationPartyId:organizationPartyId, amountUomId:currencyUomId]).call()
        acctgTransId = transOut.acctgTransId
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'335000000', debitCreditFlag:'D', amount:600]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'333100000', debitCreditFlag:'C', amount:600]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:acctgTransId]).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <acctgTrans acctgTransId="55103" organizationPartyId="ORG_ZIZI_RETAIL" amountUomId="USD" isPosted="Y" 
                    acctgTransTypeEnumId="AttPeriodClosing" glFiscalTypeEnumId="GLFT_ACTUAL" postedDate="${effectiveTime}" transactionDate="${effectiveTime}">
                <entries acctgTransEntrySeqId="01" amount="1000" glAccountId="850000000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="D"/>
                <entries acctgTransEntrySeqId="02" amount="1000" glAccountId="335000000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="C"/>
            </acctgTrans>
            <acctgTrans acctgTransId="55104" organizationPartyId="ORG_ZIZI_RETAIL" amountUomId="USD" isPosted="Y" 
                    acctgTransTypeEnumId="AttPeriodClosing" glFiscalTypeEnumId="GLFT_ACTUAL" postedDate="${effectiveTime}" transactionDate="${effectiveTime}">
                <entries acctgTransEntrySeqId="01" amount="600" glAccountId="335000000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="D"/>
                <entries acctgTransEntrySeqId="02" amount="600" glAccountId="333100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="C"/>
            </acctgTrans>            
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "pay Dividends AcctgTrans"() {
        when:
        Map transOut = ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTrans")
                .parameters([acctgTransTypeEnumId:'AttDisbursement', organizationPartyId:organizationPartyId, amountUomId:currencyUomId]).call()
        String acctgTransId = transOut.acctgTransId
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'333100000', debitCreditFlag:'D', amount:300]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'111100000', debitCreditFlag:'C', amount:300]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:acctgTransId]).call()

        /* pay out just one of the dividends to see amounts for both in accounts in different states
        transOut = ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTrans")
                .parameters([acctgTransTypeEnumId:'AttDisbursement', organizationPartyId:organizationPartyId, amountUomId:currencyUomId]).call()
        acctgTransId = transOut.acctgTransId
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'335000000', debitCreditFlag:'D', amount:50000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.create#AcctgTransEntry")
                .parameters([acctgTransId:acctgTransId, glAccountId:'111100000', debitCreditFlag:'C', amount:50000]).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.post#AcctgTrans").parameters([acctgTransId:acctgTransId]).call()
        */

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
        <acctgTrans acctgTransId="55105" organizationPartyId="ORG_ZIZI_RETAIL" amountUomId="USD" isPosted="Y" 
                acctgTransTypeEnumId="AttDisbursement" glFiscalTypeEnumId="GLFT_ACTUAL" postedDate="${effectiveTime}" transactionDate="${effectiveTime}">
            <entries acctgTransEntrySeqId="01" amount="300" glAccountId="333100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="D"/>
            <entries acctgTransEntrySeqId="02" amount="300" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N" debitCreditFlag="C"/>
        </acctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }

    def "expense Invoice"() {
        when:
        Map invoiceOut = ec.service.sync().name("mantle.account.InvoiceServices.create#Invoice")
                .parameters([fromPartyId:'ZiddlemanInc', toPartyId:organizationPartyId, currencyUomId:currencyUomId]).call()
        String invoiceId = invoiceOut.invoiceId

        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpCommTelephone', description:'Land Line Service',
                             quantity:1, amount:123.45]).call()
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpCommCellular', description:'Cell Service',
                             quantity:1, amount:234.56]).call()
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpCommNetwork', description:'Internet Service',
                             quantity:1, amount:345.67]).call()
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpHosting', description:'Site Hosting',
                             quantity:1, amount:45.45]).call()

        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpOfficeSup', description:'Office Supplies',
                             quantity:1, amount:101.01]).call()

        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpUtilHeating', description:'Heating',
                             quantity:1, amount:33.33]).call()
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpUtilElec', description:'Electricity',
                             quantity:1, amount:111.11]).call()
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpUtilWater', description:'Water',
                             quantity:1, amount:30.00]).call()
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpUtilTrash', description:'Trash Disposal',
                             quantity:1, amount:34.00]).call()

        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpInterestEquip', description:'Equipment Interest',
                             quantity:1, amount:321.12]).call()
        ec.service.sync().name("mantle.account.InvoiceServices.create#InvoiceItem")
                .parameters([invoiceId:invoiceId, itemTypeEnumId:'ItemExpInterestReal', description:'Real Estate Interest',
                             quantity:1, amount:444.55]).call()

        ec.service.sync().name("update#mantle.account.invoice.Invoice")
                .parameters([invoiceId:invoiceId, statusId:'InvoiceReceived']).call()
        ec.service.sync().name("update#mantle.account.invoice.Invoice")
                .parameters([invoiceId:invoiceId, statusId:'InvoiceApproved']).call()

        List<String> dataCheckErrors = []
        long fieldsChecked = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.invoice.Invoice invoiceId="${invoiceId}" invoiceTypeEnumId="InvoiceSales" toPartyId="ORG_ZIZI_RETAIL"
                    fromPartyId="ZiddlemanInc" acctgTransResultEnumId="AtrSuccess" invoiceDate="${effectiveTime}"
                    currencyUomId="USD" statusId="InvoiceApproved">
                <mantle.account.invoice.InvoiceItem amount="123.45" quantity="1" description="Land Line Service"
                        invoiceItemSeqId="01" itemTypeEnumId="ItemExpCommTelephone"/>
                <mantle.account.invoice.InvoiceItem amount="234.56" quantity="1" description="Cell Service"
                        invoiceItemSeqId="02" itemTypeEnumId="ItemExpCommCellular"/>
                <mantle.account.invoice.InvoiceItem amount="345.67" quantity="1" description="Internet Service"
                        invoiceItemSeqId="03" itemTypeEnumId="ItemExpCommNetwork"/>
                <mantle.account.invoice.InvoiceItem amount="45.45" quantity="1" description="Site Hosting"
                        invoiceItemSeqId="04" itemTypeEnumId="ItemExpHosting"/>
                <mantle.account.invoice.InvoiceItem amount="101.01" quantity="1" description="Office Supplies"
                        invoiceItemSeqId="05" itemTypeEnumId="ItemExpOfficeSup"/>
                <mantle.account.invoice.InvoiceItem amount="33.33" quantity="1" description="Heating"
                        invoiceItemSeqId="06" itemTypeEnumId="ItemExpUtilHeating"/>
                <mantle.account.invoice.InvoiceItem amount="111.11" quantity="1" description="Electricity"
                        invoiceItemSeqId="07" itemTypeEnumId="ItemExpUtilElec"/>
                <mantle.account.invoice.InvoiceItem amount="30" quantity="1" description="Water"
                        invoiceItemSeqId="08" itemTypeEnumId="ItemExpUtilWater"/>
                <mantle.account.invoice.InvoiceItem amount="34" quantity="1" description="Trash Disposal"
                        invoiceItemSeqId="09" itemTypeEnumId="ItemExpUtilTrash"/>
                <mantle.account.invoice.InvoiceItem amount="321.12" quantity="1" description="Equipment Interest"
                        invoiceItemSeqId="10" itemTypeEnumId="ItemExpInterestEquip"/>
                <mantle.account.invoice.InvoiceItem amount="444.55" quantity="1" description="Real Estate Interest"
                        invoiceItemSeqId="11" itemTypeEnumId="ItemExpInterestReal"/>
            </mantle.account.invoice.Invoice>
            <mantle.ledger.transaction.AcctgTrans acctgTransId="55106" invoiceId="${invoiceId}" otherPartyId="ZiddlemanInc"
                    postedDate="${effectiveTime}" amountUomId="USD" isPosted="Y" acctgTransTypeEnumId="AttPurchaseInvoice"
                    glFiscalTypeEnumId="GLFT_ACTUAL" transactionDate="${effectiveTime}" organizationPartyId="ORG_ZIZI_RETAIL">
                <mantle.ledger.transaction.AcctgTransEntry amount="123.45" glAccountId="614110000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="01" debitCreditFlag="D" acctgTransEntrySeqId="01"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="234.56" glAccountId="614140000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="02" debitCreditFlag="D" acctgTransEntrySeqId="02"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="345.67" glAccountId="614200000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="03" debitCreditFlag="D" acctgTransEntrySeqId="03"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="45.45" glAccountId="616300000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="04" debitCreditFlag="D" acctgTransEntrySeqId="04"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="101.01" glAccountId="652100000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="05" debitCreditFlag="D" acctgTransEntrySeqId="05"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="33.33" glAccountId="611210000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="06" debitCreditFlag="D" acctgTransEntrySeqId="06"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="111.11" glAccountId="611220000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="07" debitCreditFlag="D" acctgTransEntrySeqId="07"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="30" glAccountId="611230000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="08" debitCreditFlag="D" acctgTransEntrySeqId="08"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="34" glAccountId="611240000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="09" debitCreditFlag="D" acctgTransEntrySeqId="09"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="321.12" glAccountId="791100000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="10" debitCreditFlag="D" acctgTransEntrySeqId="10"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="444.55" glAccountId="791300000" reconcileStatusId="AterNot"
                        invoiceItemSeqId="11" debitCreditFlag="D" acctgTransEntrySeqId="11"/>
                <mantle.ledger.transaction.AcctgTransEntry amount="1824.25" glAccountId="212000000" reconcileStatusId="AterNot"
                        glAccountTypeEnumId="GatAccountsPayable" debitCreditFlag="C" acctgTransEntrySeqId="12"/>
            </mantle.ledger.transaction.AcctgTrans>
        </entity-facade-xml>""").check(dataCheckErrors)
        totalFieldsChecked += fieldsChecked
        if (dataCheckErrors) for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)
        if (ec.message.hasError()) logger.warn(ec.message.getErrorsString())

        then:
        dataCheckErrors.size() == 0
    }
}
