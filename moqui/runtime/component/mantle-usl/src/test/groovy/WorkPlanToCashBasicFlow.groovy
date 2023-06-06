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

import spock.lang.*

import org.moqui.context.ExecutionContext
import org.moqui.Moqui

import org.slf4j.LoggerFactory
import org.slf4j.Logger

import java.sql.Timestamp

/* To run these make sure moqui, and mantle are in place and run: "gradle cleanAll load runtime/mantle/mantle-usl:test" */
class WorkPlanToCashBasicFlow extends Specification {
    @Shared protected final static Logger logger = LoggerFactory.getLogger(WorkPlanToCashBasicFlow.class)
    @Shared ExecutionContext ec
    @Shared Map vendorResult, workerResult, clientRateResult, vendorRateResult, clientResult, expInvResult, clientInvResult
    @Shared long effectiveTime
    @Shared Timestamp effectiveThruDate
    @Shared String startYear = "2016"

    def setupSpec() {
        // init the framework, get the ec
        ec = Moqui.getExecutionContext()
        ec.user.loginUser("john.doe", "moqui")
        effectiveThruDate = ec.l10n.parseTimestamp(ec.l10n.format(ec.user.nowTimestamp, 'yyyy-MM-dd HH:mm'), 'yyyy-MM-dd HH:mm')
        // set an effective date so data check works, etc
        ec.user.setEffectiveTime(effectiveThruDate)
        effectiveTime = effectiveThruDate.time

        ec.entity.tempSetSequencedIdPrimary("mantle.account.invoice.Invoice", 55900, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.account.invoice.InvoiceItemAssoc", 55900, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans", 55900, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.party.Party", 55900, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.request.Request", 55900, 10)
        ec.entity.tempSetSequencedIdPrimary("mantle.work.time.TimeEntry", 55900, 10)
        ec.entity.tempSetSequencedIdPrimary("moqui.entity.EntityAuditLog", 55900, 100)
        ec.entity.tempSetSequencedIdPrimary("moqui.security.UserAccount", 55900, 10)
    }

    def cleanupSpec() {
        ec.entity.tempResetSequencedIdPrimary("mantle.account.invoice.Invoice")
        ec.entity.tempResetSequencedIdPrimary("mantle.account.invoice.InvoiceItemAssoc")
        ec.entity.tempResetSequencedIdPrimary("mantle.ledger.transaction.AcctgTrans")
        ec.entity.tempResetSequencedIdPrimary("mantle.party.Party")
        ec.entity.tempResetSequencedIdPrimary("mantle.request.Request")
        ec.entity.tempResetSequencedIdPrimary("mantle.work.time.TimeEntry")
        ec.entity.tempResetSequencedIdPrimary("moqui.entity.EntityAuditLog")
        ec.entity.tempResetSequencedIdPrimary("moqui.security.UserAccount")

        ec.destroy()
    }

    def setup() { ec.artifactExecution.disableAuthz() }
    def cleanup() { ec.artifactExecution.enableAuthz() }

    def "create Vendor"() {
        when:
        vendorResult = ec.service.sync().name("mantle.party.PartyServices.create#Organization")
                .parameters([roleTypeId:'Vendor', organizationName:'Test Vendor']).call()
        Map vendorCiResult = ec.service.sync().name("mantle.party.ContactServices.store#PartyContactInfo")
                .parameters([partyId:vendorResult.partyId, postalContactMechPurposeId:'PostalPayment',
                    telecomContactMechPurposeId:'PhonePayment', emailContactMechPurposeId:'EmailPayment', countryGeoId:'USA',
                    address1:'51 W. Center St.', unitNumber:'1234', city:'Orem', stateProvinceGeoId:'USA_UT',
                    postalCode:'84057', postalCodeExt:'4605', countryCode:'1', areaCode:'801', contactNumber:'123-4567',
                    emailAddress:'vendor.ar@test.com']).call()
        // internal org and accounting config default settings
        ec.service.sync().name("create#mantle.party.PartyRole").parameters([partyId:vendorResult.partyId, roleTypeId:'OrgInternal']).call()
        ec.service.sync().name("mantle.ledger.LedgerServices.init#PartyAccountingConfiguration")
                .parameters([sourcePartyId:'DefaultSettings', organizationPartyId:vendorResult.partyId, startYear:startYear]).call()
        // vendor payment/ar rep
        Map vendorRepResult = ec.service.sync().name("mantle.party.PartyServices.create#Account")
                .parameters([firstName:'Vendor', lastName:'TestRep', emailAddress:'vendor.rep@test.com',
                    username:'vendor.rep', newPassword:'moqui1!!', newPasswordVerify:'moqui1!!', loginAfterCreate:false]).call()
        Map repRelResult = ec.service.sync().name("create#mantle.party.PartyRelationship")
                .parameters([relationshipTypeEnumId:'PrtRepresentative', fromPartyId:vendorRepResult.partyId,
                    fromRoleTypeId:'Manager', toPartyId:vendorResult.partyId, toRoleTypeId:'Vendor',
                    fromDate:ec.user.nowTimestamp]).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.party.Party partyId="${vendorResult.partyId}" partyTypeEnumId="PtyOrganization"/>
            <mantle.party.Organization partyId="${vendorResult.partyId}" organizationName="Test Vendor"/>
            <mantle.party.PartyRole partyId="${vendorResult.partyId}" roleTypeId="OrgInternal"/>
            <mantle.party.PartyRole partyId="${vendorResult.partyId}" roleTypeId="Vendor"/>

            <mantle.party.contact.ContactMech contactMechId="${vendorCiResult.postalContactMechId}" contactMechTypeEnumId="CmtPostalAddress"/>
            <mantle.party.contact.PostalAddress contactMechId="${vendorCiResult.postalContactMechId}" address1="51 W. Center St." unitNumber="1234"
                city="Orem" stateProvinceGeoId="USA_UT" countryGeoId="USA" postalCode="84057" postalCodeExt="4605"/>
            <mantle.party.contact.PartyContactMech partyId="${vendorResult.partyId}" contactMechId="${vendorCiResult.postalContactMechId}"
                contactMechPurposeId="PostalPayment" fromDate="${effectiveTime}"/>
            <mantle.party.contact.ContactMech contactMechId="${vendorCiResult.telecomContactMechId}" contactMechTypeEnumId="CmtTelecomNumber"/>
            <mantle.party.contact.PartyContactMech partyId="${vendorResult.partyId}" contactMechId="${vendorCiResult.telecomContactMechId}"
                contactMechPurposeId="PhonePayment" fromDate="${effectiveTime}"/>
            <mantle.party.contact.TelecomNumber contactMechId="${vendorCiResult.telecomContactMechId}" countryCode="1"
                areaCode="801" contactNumber="123-4567"/>
            <mantle.party.contact.ContactMech contactMechId="${vendorCiResult.emailContactMechId}"
                contactMechTypeEnumId="CmtEmailAddress" infoString="vendor.ar@test.com"/>
            <mantle.party.contact.PartyContactMech partyId="${vendorResult.partyId}"
                contactMechId="${vendorCiResult.emailContactMechId}" contactMechPurposeId="EmailPayment" fromDate="${effectiveTime}"/>

            <mantle.ledger.transaction.GlJournal glJournalId="${vendorResult.partyId}Error"
                glJournalName="Error Journal for Test Vendor" organizationPartyId="${vendorResult.partyId}"/>
            <mantle.ledger.config.PartyAcctgPreference organizationPartyId="${vendorResult.partyId}"
                taxFormEnumId="TxfUsIrs1120" cogsMethodEnumId="CogsActualCost" baseCurrencyUomId="USD"
                invoiceSequenceEnumId="InvSqStandard" orderSequenceEnumId="OrdSqStandard"
                errorGlJournalId="${vendorResult.partyId}Error"/>
            <mantle.ledger.config.GlAccountTypeDefault glAccountTypeEnumId="GatAccountsReceivable"
                organizationPartyId="${vendorResult.partyId}" glAccountId="121000000"/>
            <mantle.ledger.config.GlAccountTypeDefault glAccountTypeEnumId="GatAccountsPayable"
                organizationPartyId="${vendorResult.partyId}" glAccountId="212000000"/>
            <mantle.ledger.config.PaymentInstrumentGlAccount paymentInstrumentEnumId="PiCompanyCheck" isPayable="E"
                organizationPartyId="${vendorResult.partyId}" glAccountId="111100000"/>
            <mantle.ledger.config.ItemTypeGlAccount glAccountId="412000000" direction="O" itemTypeEnumId="ItemTimeEntry"
                organizationPartyId="${vendorResult.partyId}"/>
            <mantle.ledger.config.ItemTypeGlAccount glAccountId="550000000" direction="I" itemTypeEnumId="ItemTimeEntry"
                organizationPartyId="${vendorResult.partyId}"/>
            <mantle.ledger.config.ItemTypeGlAccount itemTypeEnumId="ItemExpTravAir" direction="E" glAccountId="681100000"
                organizationPartyId="${vendorResult.partyId}"/>
            <mantle.ledger.account.GlAccountOrganization glAccountId="121000000" organizationPartyId="${vendorResult.partyId}"/>
            <mantle.ledger.account.GlAccountOrganization glAccountId="212000000" organizationPartyId="${vendorResult.partyId}"/>
            <mantle.ledger.config.PaymentTypeGlAccount paymentTypeEnumId="PtInvoicePayment"
                organizationPartyId="${vendorResult.partyId}" isPayable="N" isApplied="Y" glAccountId="121000000"/>
            <mantle.ledger.config.PaymentTypeGlAccount paymentTypeEnumId="PtInvoicePayment"
                organizationPartyId="${vendorResult.partyId}" isPayable="Y" isApplied="Y" glAccountId="212000000"/>

            <mantle.party.Party partyId="${vendorRepResult.partyId}" partyTypeEnumId="PtyPerson" disabled="N"/>
            <mantle.party.Person partyId="${vendorRepResult.partyId}" firstName="Vendor" lastName="TestRep"/>
            <moqui.security.UserAccount userId="${vendorRepResult.userId}" username="vendor.rep" userFullName="Vendor TestRep"
                passwordHashType="SHA-256" passwordSetDate="${effectiveTime}" disabled="N" requirePasswordChange="N"
                emailAddress="vendor.rep@test.com" partyId="${vendorRepResult.partyId}"/>
            <!-- the salt is generated randomly so can't easily validate the actual password or salt: currentPassword="32ce60c14d9e72c1fb17938ede30fe9de04390409cce7310743c2716a2c7bf89" passwordSalt="{.rqlPt8x" -->
            <mantle.party.contact.ContactMech contactMechId="${vendorRepResult.emailContactMechId}"
                contactMechTypeEnumId="CmtEmailAddress" infoString="vendor.rep@test.com"/>
            <mantle.party.contact.PartyContactMech partyId="${vendorRepResult.partyId}"
                contactMechId="${vendorRepResult.emailContactMechId}" contactMechPurposeId="EmailPrimary" fromDate="${effectiveTime}"/>
            <mantle.party.PartyRelationship partyRelationshipId="${repRelResult.partyRelationshipId}"
                relationshipTypeEnumId="PrtRepresentative" fromPartyId="${vendorRepResult.partyId}" fromRoleTypeId="Manager"
                toPartyId="${vendorResult.partyId}" toRoleTypeId="Vendor" fromDate="${effectiveTime}"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55901" changedEntityName="mantle.party.Party"
                changedFieldName="disabled" pkPrimaryValue="${vendorRepResult.partyId}" newValueText="N" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55902" changedEntityName="moqui.security.UserAccount"
                changedFieldName="username" pkPrimaryValue="${vendorRepResult.userId}" newValueText="vendor.rep" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
        </entity-facade-xml>""").check()
        logger.info("TEST create Vendor data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "create Worker and Rates"() {
        when:
        // worker
        workerResult = ec.service.sync().name("mantle.party.PartyServices.create#Account")
                .parameters([firstName:'Test', lastName:'Worker', emailAddress:'worker@test.com',
                    username:'worker', newPassword:'moqui1!!', newPasswordVerify:'moqui1!!', loginAfterCreate:false]).call()
        Map workerRelResult = ec.service.sync().name("create#mantle.party.PartyRelationship")
                .parameters([relationshipTypeEnumId:'PrtAgent', fromPartyId:workerResult.partyId,
                    fromRoleTypeId:'Worker', toPartyId:vendorResult.partyId, toRoleTypeId:'Vendor',
                    fromDate:ec.user.nowTimestamp]).call()
        // Rate Amounts
        clientRateResult = ec.service.sync().name("create#mantle.humanres.rate.RateAmount")
                .parameters([rateTypeEnumId:'RatpStandard', ratePurposeEnumId:'RaprClient', timePeriodUomId:'TF_hr',
                    emplPositionClassId:'Programmer', fromDate:'1265184000000', rateAmount:'60.00',
                    rateCurrencyUomId:'USD', partyId:workerResult.partyId]).call()
        vendorRateResult = ec.service.sync().name("create#mantle.humanres.rate.RateAmount")
                .parameters([rateTypeEnumId:'RatpStandard', ratePurposeEnumId:'RaprVendor', timePeriodUomId:'TF_hr',
                    emplPositionClassId:'Programmer', fromDate:'1265184000000', rateAmount:'40.00',
                    rateCurrencyUomId:'USD', partyId:workerResult.partyId]).call()
        // no charge rate, still pay vendor (using default 0 amount rate for client no explicit create for that)
        ec.service.sync().name("create#mantle.humanres.rate.RateAmount")
                .parameters([rateTypeEnumId:'RatpNoCharge', ratePurposeEnumId:'RaprVendor', timePeriodUomId:'TF_hr',
                             emplPositionClassId:'Programmer', fromDate:'1265184000000', rateAmount:'40.00',
                             rateCurrencyUomId:'USD']).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.party.Party partyId="${workerResult.partyId}" partyTypeEnumId="PtyPerson" disabled="N"/>
            <mantle.party.Person partyId="${workerResult.partyId}" firstName="Test" lastName="Worker"/>
            <moqui.security.UserAccount userId="${workerResult.userId}" username="worker" userFullName="Test Worker"
                passwordHashType="SHA-256" passwordSetDate="${effectiveTime}" disabled="N" requirePasswordChange="N"
                emailAddress="worker@test.com" partyId="${workerResult.partyId}"/>
            <!-- the salt is generated randomly so can't easily validate the actual password or salt: currentPassword="32ce60c14d9e72c1fb17938ede30fe9de04390409cce7310743c2716a2c7bf89" passwordSalt="{.rqlPt8x" -->
            <mantle.party.contact.ContactMech contactMechId="${workerResult.emailContactMechId}"
                contactMechTypeEnumId="CmtEmailAddress" infoString="worker@test.com"/>
            <mantle.party.contact.PartyContactMech partyId="${workerResult.partyId}"
                contactMechId="${workerResult.emailContactMechId}" contactMechPurposeId="EmailPrimary" fromDate="${effectiveTime}"/>
            <mantle.party.PartyRelationship partyRelationshipId="${workerRelResult.partyRelationshipId}"
                relationshipTypeEnumId="PrtAgent" fromPartyId="${workerResult.partyId}" fromRoleTypeId="Worker"
                toPartyId="${vendorResult.partyId}" toRoleTypeId="Vendor" fromDate="${effectiveTime}"/>

            <mantle.humanres.rate.RateAmount rateAmountId="${clientRateResult.rateAmountId}" rateTypeEnumId="RatpStandard"
                ratePurposeEnumId="RaprClient" timePeriodUomId="TF_hr" partyId="${workerResult.partyId}"
                emplPositionClassId="Programmer" fromDate="1265184000000" rateAmount="60.00" rateCurrencyUomId="USD"/>
            <mantle.humanres.rate.RateAmount rateAmountId="${vendorRateResult.rateAmountId}" rateTypeEnumId="RatpStandard"
                ratePurposeEnumId="RaprVendor" timePeriodUomId="TF_hr" partyId="${workerResult.partyId}"
                emplPositionClassId="Programmer" fromDate="1265184000000" rateAmount="40.00" rateCurrencyUomId="USD"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55903" changedEntityName="mantle.party.Party"
                changedFieldName="disabled" pkPrimaryValue="${workerResult.partyId}" newValueText="N" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55904" changedEntityName="moqui.security.UserAccount"
                changedFieldName="username" pkPrimaryValue="${workerResult.userId}" newValueText="worker" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
        </entity-facade-xml>""").check()
        logger.info("TEST create Worker and Rates data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "create Client"() {
        when:
        clientResult = ec.service.sync().name("mantle.party.PartyServices.create#Organization")
                .parameters([roleTypeId:'Customer', organizationName:'Test Client']).call()
        Map clientCiResult = ec.service.sync().name("mantle.party.ContactServices.store#PartyContactInfo")
                .parameters([partyId:clientResult.partyId, postalContactMechPurposeId:'PostalBilling',
                    telecomContactMechPurposeId:'PhoneBilling', emailContactMechPurposeId:'EmailBilling', countryGeoId:'USA',
                    address1:'1350 E. Flamingo Rd.', unitNumber:'1234', city:'Las Vegas', stateProvinceGeoId:'USA_NV',
                    postalCode:'89119', postalCodeExt:'5263', countryCode:'1', areaCode:'702', contactNumber:'123-4567',
                    emailAddress:'client.ap@test.com']).call()

        Map clientRepResult = ec.service.sync().name("mantle.party.PartyServices.create#Account")
                .parameters([firstName:'Client', lastName:'TestRep', emailAddress:'client.rep@test.com',
                    username:'client.rep', newPassword:'moqui1!!', newPasswordVerify:'moqui1!!', loginAfterCreate:false]).call()
        Map repRelResult = ec.service.sync().name("create#mantle.party.PartyRelationship")
                .parameters([relationshipTypeEnumId:'PrtRepresentative', fromPartyId:clientRepResult.partyId,
                    fromRoleTypeId:'ClientBilling', toPartyId:clientResult.partyId, toRoleTypeId:'Customer',
                    fromDate:ec.user.nowTimestamp]).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.party.Party partyId="${clientResult.partyId}" partyTypeEnumId="PtyOrganization"/>
            <mantle.party.Organization partyId="${clientResult.partyId}" organizationName="Test Client"/>
            <mantle.party.PartyRole partyId="${clientResult.partyId}" roleTypeId="Customer"/>

            <mantle.party.contact.ContactMech contactMechId="${clientCiResult.postalContactMechId}" contactMechTypeEnumId="CmtPostalAddress"/>
            <mantle.party.contact.PostalAddress contactMechId="${clientCiResult.postalContactMechId}"
                address1="1350 E. Flamingo Rd." unitNumber="1234" city="Las Vegas" stateProvinceGeoId="USA_NV"
                countryGeoId="USA" postalCode="89119" postalCodeExt="5263"/>
            <mantle.party.contact.PartyContactMech partyId="${clientResult.partyId}" contactMechId="${clientCiResult.postalContactMechId}"
                contactMechPurposeId="PostalBilling" fromDate="${effectiveTime}"/>
            <mantle.party.contact.ContactMech contactMechId="${clientCiResult.telecomContactMechId}" contactMechTypeEnumId="CmtTelecomNumber"/>
            <mantle.party.contact.PartyContactMech partyId="${clientResult.partyId}" contactMechId="${clientCiResult.telecomContactMechId}"
                contactMechPurposeId="PhoneBilling" fromDate="${effectiveTime}"/>
            <mantle.party.contact.TelecomNumber contactMechId="${clientCiResult.telecomContactMechId}" countryCode="1"
                areaCode="702" contactNumber="123-4567"/>
            <mantle.party.contact.ContactMech contactMechId="${clientCiResult.emailContactMechId}"
                contactMechTypeEnumId="CmtEmailAddress" infoString="client.ap@test.com"/>
            <mantle.party.contact.PartyContactMech partyId="${clientResult.partyId}"
                contactMechId="${clientCiResult.emailContactMechId}" contactMechPurposeId="EmailBilling" fromDate="${effectiveTime}"/>

            <mantle.party.Party partyId="${clientRepResult.partyId}" partyTypeEnumId="PtyPerson" disabled="N"/>
            <mantle.party.Person partyId="${clientRepResult.partyId}" firstName="Client" lastName="TestRep"/>
            <moqui.security.UserAccount userId="${clientRepResult.userId}" username="client.rep" userFullName="Client TestRep"
                passwordHashType="SHA-256" passwordSetDate="${effectiveTime}" disabled="N" requirePasswordChange="N"
                emailAddress="client.rep@test.com" partyId="${clientRepResult.partyId}"/>
            <!-- the salt is generated randomly so can't easily validate the actual password or salt: currentPassword="32ce60c14d9e72c1fb17938ede30fe9de04390409cce7310743c2716a2c7bf89" passwordSalt="{.rqlPt8x" -->
            <mantle.party.contact.ContactMech contactMechId="${clientRepResult.emailContactMechId}"
                contactMechTypeEnumId="CmtEmailAddress" infoString="client.rep@test.com"/>
            <mantle.party.contact.PartyContactMech partyId="${clientRepResult.partyId}"
                contactMechId="${clientRepResult.emailContactMechId}" contactMechPurposeId="EmailPrimary" fromDate="${effectiveTime}"/>
            <mantle.party.PartyRelationship partyRelationshipId="${repRelResult.partyRelationshipId}"
                relationshipTypeEnumId="PrtRepresentative" fromPartyId="${clientRepResult.partyId}"
                fromRoleTypeId="ClientBilling" toPartyId="${clientResult.partyId}" toRoleTypeId="Customer" fromDate="${effectiveTime}"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55906" changedEntityName="mantle.party.Party"
                changedFieldName="disabled" pkPrimaryValue="55904" newValueText="N" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55907" changedEntityName="moqui.security.UserAccount"
                changedFieldName="username" pkPrimaryValue="55902" newValueText="client.rep" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>

        </entity-facade-xml>""").check()
        logger.info("TEST create Client data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "create TEST Project"() {
        when:
        ec.service.sync().name("mantle.work.ProjectServices.create#Project")
                .parameters([workEffortId:'TEST', workEffortName:'Test Proj', clientPartyId:clientResult.partyId,
                    vendorPartyId:vendorResult.partyId, totalClientCostAllowed:"2000", costUomId:"USD"])
                .call()
        ec.service.sync().name("mantle.work.ProjectServices.update#Project")
                .parameters([workEffortId:'TEST', workEffortName:'Test Project', statusId:'WeInProgress'])
                .call()
        // assign Joe Developer to TEST project as Programmer (necessary for determining RateAmount, etc)
        ec.service.sync().name("create#mantle.work.effort.WorkEffortParty")
                .parameters([workEffortId:'TEST', partyId:workerResult.partyId, roleTypeId:'Assignee', emplPositionClassId:'Programmer',
                    fromDate:startYear + '-11-01', statusId:'WeptAssigned']).call()

        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.work.effort.WorkEffort workEffortId="TEST" workEffortTypeEnumId="WetProject" statusId="WeInProgress" workEffortName="Test Project"/>
            <mantle.work.effort.WorkEffortParty workEffortId="TEST" partyId="EX_JOHN_DOE" roleTypeId="Manager" fromDate="${effectiveTime}" statusId="WeptAssigned"/>
            <mantle.work.effort.WorkEffortParty workEffortId="TEST" partyId="${clientResult.partyId}" roleTypeId="Customer" fromDate="${effectiveTime}"/>
            <mantle.work.effort.WorkEffortParty workEffortId="TEST" partyId="${vendorResult.partyId}" roleTypeId="Vendor" fromDate="${effectiveTime}"/>
            <mantle.work.effort.WorkEffortParty workEffortId="TEST" partyId="${workerResult.partyId}" roleTypeId="Assignee"
                fromDate="1477976400000" statusId="WeptAssigned" emplPositionClassId="Programmer"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55908" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST" newValueText="WeInPlanning" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55909" changedEntityName="mantle.work.effort.WorkEffortParty"
                changedFieldName="statusId" pkPrimaryValue="TEST" pkSecondaryValue="EX_JOHN_DOE"
                pkRestCombinedValue="roleTypeId:'Manager',fromDate:'${effectiveTime}'" newValueText="WeptAssigned"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55910" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST" oldValueText="WeInPlanning" newValueText="WeInProgress"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55911" changedEntityName="mantle.work.effort.WorkEffortParty"
                changedFieldName="statusId" pkPrimaryValue="TEST" pkSecondaryValue="${workerResult.partyId}"
                pkRestCombinedValue="roleTypeId:'Assignee',fromDate:'1477976400000'" newValueText="WeptAssigned"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            </entity-facade-xml>""").check()
        logger.info("TEST Project data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "create TEST Milestones"() {
        when:
        ec.service.sync().name("mantle.work.ProjectServices.create#Milestone")
                .parameters([rootWorkEffortId:'TEST', workEffortId:'TEST-MS-01', workEffortName:'Test Milestone 1',
                    estimatedStartDate:startYear + '-11-01', estimatedCompletionDate:startYear + '-11-30', statusId:'WeInProgress'])
                .call()
        ec.service.sync().name("mantle.work.ProjectServices.create#Milestone")
                .parameters([rootWorkEffortId:'TEST', workEffortId:'TEST-MS-02', workEffortName:'Test Milestone 2',
                    estimatedStartDate:startYear + '-12-01', estimatedCompletionDate:startYear + '-12-31', statusId:'WeApproved'])
                .call()

        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.work.effort.WorkEffort workEffortId="TEST-MS-01" rootWorkEffortId="TEST" workEffortTypeEnumId="WetMilestone"
                statusId="WeInProgress" workEffortName="Test Milestone 1" estimatedStartDate="${startYear}-11-01 00:00:00.0" estimatedCompletionDate="${startYear}-11-30 00:00:00.0"/>
            <mantle.work.effort.WorkEffort workEffortId="TEST-MS-02" rootWorkEffortId="TEST" workEffortTypeEnumId="WetMilestone"
                statusId="WeApproved" workEffortName="Test Milestone 2" estimatedStartDate="${startYear}-12-01 00:00:00.0" estimatedCompletionDate="${startYear}-12-31 00:00:00.0"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55912" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-MS-01" newValueText="WeInProgress"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55913" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-MS-02" newValueText="WeApproved"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            </entity-facade-xml>""").check()
        logger.info("TEST Milestones data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "create TEST Project Tasks"() {
        when:
        ec.service.sync().name("mantle.work.TaskServices.create#Task")
                .parameters([rootWorkEffortId:'TEST', parentWorkEffortId:null, workEffortId:'TEST-001', milestoneWorkEffortId:'TEST-MS-01',
                    workEffortName:'Test Task 1', estimatedCompletionDate:startYear + '-11-15', statusId:'WeApproved',
                    assignToPartyId:workerResult.partyId, priority:3, purposeEnumId:'WepTask', estimatedWorkTime:10,
                    description:'Will be really great when it\'s done'])
                .call()
        ec.service.sync().name("mantle.work.TaskServices.create#Task")
                .parameters([rootWorkEffortId:'TEST', parentWorkEffortId:'TEST-001', workEffortId:'TEST-001A', milestoneWorkEffortId:'TEST-MS-01',
                    workEffortName:'Test Task 1A', estimatedCompletionDate:startYear + '-11-15', statusId:'WeInPlanning',
                    assignToPartyId:workerResult.partyId, priority:4, purposeEnumId:'WepNewFeature', estimatedWorkTime:2,
                    description:'One piece of the puzzle'])
                .call()
        ec.service.sync().name("mantle.work.TaskServices.create#Task")
                .parameters([rootWorkEffortId:'TEST', parentWorkEffortId:'TEST-001', workEffortId:'TEST-001B', milestoneWorkEffortId:'TEST-MS-01',
                    workEffortName:'Test Task 1B', estimatedCompletionDate:startYear + '-11-15', statusId:'WeApproved',
                    assignToPartyId:workerResult.partyId, priority:4, purposeEnumId:'WepFix', estimatedWorkTime:2,
                    description:'Broken piece of the puzzle'])
                .call()
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.work.effort.WorkEffort workEffortId="TEST-001" rootWorkEffortId="TEST" workEffortTypeEnumId="WetTask"
                purposeEnumId="WepTask" resolutionEnumId="WerUnresolved" statusId="WeApproved" priority="3"
                workEffortName="Test Task 1" description="Will be really great when it's done"
                estimatedWorkTime="10" remainingWorkTime="10" timeUomId="TF_hr"/>
            <mantle.work.effort.WorkEffortParty workEffortId="TEST-001" partyId="${workerResult.partyId}" roleTypeId="Assignee"
                fromDate="${effectiveTime}" statusId="WeptAssigned"/>
            <mantle.work.effort.WorkEffortAssoc workEffortId="TEST-MS-01" toWorkEffortId="TEST-001"
                workEffortAssocTypeEnumId="WeatMilestone" fromDate="${effectiveTime}"/>

            <mantle.work.effort.WorkEffort workEffortId="TEST-001A" parentWorkEffortId="TEST-001" rootWorkEffortId="TEST"
                workEffortTypeEnumId="WetTask" purposeEnumId="WepNewFeature" resolutionEnumId="WerUnresolved"
                statusId="WeInPlanning" priority="4" workEffortName="Test Task 1A" description="One piece of the puzzle"
                estimatedWorkTime="2" remainingWorkTime="2" timeUomId="TF_hr"/>
            <mantle.work.effort.WorkEffortParty workEffortId="TEST-001A" partyId="${workerResult.partyId}" roleTypeId="Assignee"
                fromDate="${effectiveTime}" statusId="WeptAssigned"/>
            <mantle.work.effort.WorkEffortAssoc workEffortId="TEST-MS-01" toWorkEffortId="TEST-001A"
                workEffortAssocTypeEnumId="WeatMilestone" fromDate="${effectiveTime}"/>

            <mantle.work.effort.WorkEffort workEffortId="TEST-001B" parentWorkEffortId="TEST-001" rootWorkEffortId="TEST"
                workEffortTypeEnumId="WetTask" purposeEnumId="WepFix" resolutionEnumId="WerUnresolved" statusId="WeApproved"
                priority="4" workEffortName="Test Task 1B" description="Broken piece of the puzzle"
                estimatedWorkTime="2" remainingWorkTime="2" timeUomId="TF_hr"/>
            <mantle.work.effort.WorkEffortParty workEffortId="TEST-001B" partyId="${workerResult.partyId}" roleTypeId="Assignee"
                fromDate="${effectiveTime}" statusId="WeptAssigned"/>
            <mantle.work.effort.WorkEffortAssoc workEffortId="TEST-MS-01" toWorkEffortId="TEST-001B"
                workEffortAssocTypeEnumId="WeatMilestone" fromDate="${effectiveTime}"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55914" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001" newValueText="WeApproved" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55919" changedEntityName="mantle.work.effort.WorkEffortParty"
                changedFieldName="statusId" pkPrimaryValue="TEST-001" pkSecondaryValue="${workerResult.partyId}"
                pkRestCombinedValue="roleTypeId:'Assignee',fromDate:'${effectiveTime}'" newValueText="WeptAssigned"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55920" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001A" newValueText="WeInPlanning"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55925" changedEntityName="mantle.work.effort.WorkEffortParty"
                changedFieldName="statusId" pkPrimaryValue="TEST-001A" pkSecondaryValue="${workerResult.partyId}"
                pkRestCombinedValue="roleTypeId:'Assignee',fromDate:'${effectiveTime}'" newValueText="WeptAssigned"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55926" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001B" newValueText="WeApproved"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55931" changedEntityName="mantle.work.effort.WorkEffortParty"
                changedFieldName="statusId" pkPrimaryValue="TEST-001B" pkSecondaryValue="${workerResult.partyId}"
                pkRestCombinedValue="roleTypeId:'Assignee',fromDate:'${effectiveTime}'" newValueText="WeptAssigned"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            </entity-facade-xml>""").check()
        logger.info("TEST Milestones data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "record TimeEntries and complete Tasks"() {
        when:
        // get tasks In Progress
        ec.service.sync().name("mantle.work.TaskServices.update#Task").parameters([workEffortId:'TEST-001', statusId:'WeInProgress']).call()
        ec.service.sync().name("mantle.work.TaskServices.update#Task").parameters([workEffortId:'TEST-001A', statusId:'WeInProgress']).call()
        ec.service.sync().name("mantle.work.TaskServices.update#Task").parameters([workEffortId:'TEST-001B', statusId:'WeInProgress']).call()

        String comments = "Did stuff. These comments are longer in order to test comment truncation on invoicing as invoice item descriptions are limited to 255 characters so this has to be longer so tests will fail and people won't get paid and the world will end if comments that are too long are not handled adequately."
        // plain hours, nothing else
        ec.service.sync().name("mantle.work.TaskServices.add#TaskTime")
                .parameters([workEffortId:'TEST-001', partyId:workerResult.partyId, rateTypeEnumId:'RatpStandard', remainingWorkTime:3,
                             hours:6, fromDate:null, thruDate:null, breakHours:null, comments:comments]).call()
        // hours and break, no from/thru dates (determined automatically, thru based on now and from based on hours+break)
        ec.service.sync().name("mantle.work.TaskServices.add#TaskTime")
                .parameters([workEffortId:'TEST-001A', partyId:workerResult.partyId, rateTypeEnumId:'RatpStandard', remainingWorkTime:1,
                             hours:1.5, fromDate:null, thruDate:null, breakHours:0.5, comments:"Hours and break test, no from/thru dates"]).call()
        // break and from/thru dates, hours determined automatically
        ec.service.sync().name("mantle.work.TaskServices.add#TaskTime")
                .parameters([workEffortId:'TEST-001B', partyId:workerResult.partyId, rateTypeEnumId:'RatpStandard', remainingWorkTime:0.5,
                             hours:null, fromDate:"${startYear}-11-03 12:00:00", thruDate:"${startYear}-11-03 15:00:00", breakHours:1,
                             comments:"Break and from/thru dates test, hours calculated"]).call()
        // no charge time entry, test invoicing time with no amount and make sure hour quantity makes it through
        ec.service.sync().name("mantle.work.TaskServices.add#TaskTime")
                .parameters([workEffortId:'TEST-001B', partyId:workerResult.partyId, rateTypeEnumId:'RatpNoCharge', remainingWorkTime:0.5,
                             hours:4, fromDate:null, thruDate:null, breakHours:1,
                             comments:"No charge for this one because we like you"]).call()

        // complete tasks
        ec.service.sync().name("mantle.work.TaskServices.update#Task").parameters([workEffortId:'TEST-001', statusId:'WeComplete', resolutionEnumId:'WerCompleted']).call()
        ec.service.sync().name("mantle.work.TaskServices.update#Task").parameters([workEffortId:'TEST-001A', statusId:'WeComplete', resolutionEnumId:'WerCompleted']).call()
        ec.service.sync().name("mantle.work.TaskServices.update#Task").parameters([workEffortId:'TEST-001B', statusId:'WeComplete', resolutionEnumId:'WerCompleted']).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.work.effort.WorkEffort workEffortId="TEST-001" resolutionEnumId="WerCompleted" statusId="WeComplete"
                estimatedWorkTime="10" remainingWorkTime="3" actualWorkTime="6"/>
            <mantle.work.time.TimeEntry timeEntryId="55900" partyId="${workerResult.partyId}" rateTypeEnumId="RatpStandard"
                rateAmountId="${clientRateResult.rateAmountId}" vendorRateAmountId="${vendorRateResult.rateAmountId}"
                fromDate="${effectiveThruDate.time-(6*60*60*1000)}" thruDate="${effectiveThruDate.time}" hours="6" workEffortId="TEST-001"/>

            <mantle.work.effort.WorkEffort workEffortId="TEST-001A" resolutionEnumId="WerCompleted" statusId="WeComplete"
                estimatedWorkTime="2" remainingWorkTime="1" actualWorkTime="1.5"/>
            <mantle.work.time.TimeEntry timeEntryId="55901" partyId="${workerResult.partyId}" rateTypeEnumId="RatpStandard"
                rateAmountId="${clientRateResult.rateAmountId}" vendorRateAmountId="${vendorRateResult.rateAmountId}"
                fromDate="${effectiveThruDate.time-(2*60*60*1000)}" thruDate="${effectiveThruDate.time}" hours="1.5"
                breakHours="0.5" workEffortId="TEST-001A"/>

            <mantle.work.effort.WorkEffort workEffortId="TEST-001B" resolutionEnumId="WerCompleted" statusId="WeComplete"
                estimatedWorkTime="2" remainingWorkTime="0.5" actualWorkTime="6"/>
            <mantle.work.time.TimeEntry timeEntryId="55902" partyId="${workerResult.partyId}" rateTypeEnumId="RatpStandard"
                rateAmountId="${clientRateResult.rateAmountId}" vendorRateAmountId="${vendorRateResult.rateAmountId}"
                hours="2" breakHours="1" workEffortId="TEST-001B"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55932" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001" oldValueText="WeApproved"
                newValueText="WeInProgress" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55933" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001A" oldValueText="WeInPlanning"
                newValueText="WeInProgress" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55934" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001B" oldValueText="WeApproved"
                newValueText="WeInProgress" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55935" changedEntityName="mantle.work.effort.WorkEffort"
                changedByUserId="EX_JOHN_DOE" pkPrimaryValue="TEST-001" changedFieldName="remainingWorkTime"
                oldValueText="10" newValueText="3"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55936" changedEntityName="mantle.work.effort.WorkEffort"
                changedByUserId="EX_JOHN_DOE" pkPrimaryValue="TEST" changedFieldName="remainingWorkTime"
                oldValueText="14" newValueText="7"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55941" changedEntityName="mantle.work.effort.WorkEffort"
                changedByUserId="EX_JOHN_DOE" pkPrimaryValue="TEST-001" changedFieldName="resolutionEnumId"
                oldValueText="WerUnresolved" newValueText="WerCompleted"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55942" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001" oldValueText="WeInProgress"
                newValueText="WeComplete" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55943" changedEntityName="mantle.work.effort.WorkEffort"
                changedByUserId="EX_JOHN_DOE" pkPrimaryValue="TEST-001A" changedFieldName="resolutionEnumId"
                oldValueText="WerUnresolved" newValueText="WerCompleted"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55944" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001A" oldValueText="WeInProgress"
                newValueText="WeComplete" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55945" changedEntityName="mantle.work.effort.WorkEffort"
                changedByUserId="EX_JOHN_DOE" pkPrimaryValue="TEST-001B" changedFieldName="resolutionEnumId"
                oldValueText="WerUnresolved" newValueText="WerCompleted"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55946" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="TEST-001B" oldValueText="WeInProgress"
                newValueText="WeComplete" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

        </entity-facade-xml>""").check()
        logger.info("record TimeEntries and complete Tasks data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "create Request and Task for Request"() {
        when:
        Map createReqResult = ec.service.sync().name("mantle.request.RequestServices.create#Request")
                .parameters([clientPartyId:clientResult.partyId, assignToPartyId:workerResult.partyId, requestName:'Test Request 1',
                    description:'Description of Test Request 1', priority:7, requestTypeEnumId:'RqtSupport',
                    statusId:'ReqSubmitted', responseRequiredDate:startYear + '-11-15 15:00:00']).call()
        ec.service.sync().name("mantle.request.RequestServices.update#Request")
                .parameters([requestId:createReqResult.requestId, statusId:'ReqReviewed']).call()

        Map createReqTskResult = ec.service.sync().name("mantle.work.TaskServices.create#Task")
                .parameters([rootWorkEffortId:'TEST', workEffortName:'Test Request 1 Task',
                    estimatedCompletionDate:startYear + '-11-15', statusId:'WeApproved', assignToPartyId:workerResult.partyId,
                    priority:7, purposeEnumId:'WepTask', estimatedWorkTime:2, description:'']).call()
        ec.service.sync().name("create#mantle.request.RequestWorkEffort")
                .parameters([workEffortId:createReqTskResult.workEffortId, requestId:createReqResult.requestId]).call()
        ec.service.sync().name("mantle.work.TaskServices.update#Task")
                .parameters([workEffortId:createReqTskResult.workEffortId, statusId:'WeComplete',
                    resolutionEnumId:'WerCompleted']).call()

        // task completed, now complete request
        ec.service.sync().name("mantle.request.RequestServices.update#Request")
                .parameters([requestId:createReqResult.requestId, statusId:'ReqCompleted']).call()

        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.request.Request requestId="${createReqResult.requestId}" requestTypeEnumId="RqtSupport"
                statusId="ReqCompleted" requestName="Test Request 1" description="Description of Test Request 1" priority="7"
                requestResolutionEnumId="RrUnresolved" filedByPartyId="EX_JOHN_DOE"/>
            <mantle.request.RequestWorkEffort requestId="${createReqResult.requestId}"
                workEffortId="${createReqTskResult.workEffortId}"/>
            <mantle.request.RequestParty requestId="${createReqResult.requestId}" partyId="${workerResult.partyId}"
                roleTypeId="Assignee" fromDate="${effectiveTime}"/>
            <mantle.request.RequestParty requestId="${createReqResult.requestId}" partyId="${clientResult.partyId}"
                roleTypeId="Customer" fromDate="${effectiveTime}"/>
            <mantle.work.effort.WorkEffort workEffortId="${createReqTskResult.workEffortId}" rootWorkEffortId="TEST"
                workEffortTypeEnumId="WetTask" purposeEnumId="WepTask" resolutionEnumId="WerCompleted" statusId="WeComplete"
                priority="7" workEffortName="Test Request 1 Task"
                estimatedWorkTime="2" remainingWorkTime="2" timeUomId="TF_hr"/>
            <mantle.work.effort.WorkEffortParty workEffortId="${createReqTskResult.workEffortId}" partyId="${workerResult.partyId}"
                roleTypeId="Assignee" fromDate="${effectiveTime}" statusId="WeptAssigned"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55947" changedEntityName="mantle.request.Request"
                changedFieldName="statusId" pkPrimaryValue="55900" newValueText="ReqSubmitted"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55948" changedEntityName="mantle.request.Request"
                changedFieldName="statusId" pkPrimaryValue="55900" oldValueText="ReqSubmitted"
                newValueText="ReqReviewed" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55949" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="${createReqTskResult.workEffortId}" newValueText="WeApproved"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55954" changedEntityName="mantle.work.effort.WorkEffortParty"
                changedFieldName="statusId" pkPrimaryValue="${createReqTskResult.workEffortId}"
                pkSecondaryValue="${workerResult.partyId}"
                pkRestCombinedValue="roleTypeId:'Assignee',fromDate:'${effectiveTime}'" newValueText="WeptAssigned"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55956" changedEntityName="mantle.work.effort.WorkEffort"
                changedFieldName="statusId" pkPrimaryValue="${createReqTskResult.workEffortId}" oldValueText="WeApproved"
                newValueText="WeComplete" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55957" changedEntityName="mantle.request.Request"
                changedFieldName="statusId" pkPrimaryValue="55900" oldValueText="ReqReviewed"
                newValueText="ReqCompleted" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

        </entity-facade-xml>""").check()
        logger.info("create Request and Task for Request data check results: " + dataCheckErrors)

        then:
        dataCheckErrors.size() == 0
    }

    def "create Worker Time and Expense Invoice and record Payment"() {
        when:
        // create expense invoices and add items
        expInvResult = ec.service.sync().name("mantle.account.InvoiceServices.create#ProjectExpenseInvoice")
                .parameters([workEffortId:'TEST', fromPartyId:workerResult.partyId, invoiceDate:startYear + '-11-08']).call()
        ec.service.sync().name("create#mantle.account.invoice.InvoiceItem")
                .parameters([invoiceId:expInvResult.invoiceId, itemTypeEnumId:'ItemExpTravAir',
                    description:'United SFO-LAX', itemDate:startYear + '-11-02', quantity:1, amount:345.67]).call()
        ec.service.sync().name("create#mantle.account.invoice.InvoiceItem")
                .parameters([invoiceId:expInvResult.invoiceId, itemTypeEnumId:'ItemExpTravLodging',
                    description:'Fleabag Inn 2 nights', itemDate:startYear + '-11-04', quantity:1, amount:123.45]).call()
        // add worker/vendor time to the expense invoice
        ec.service.sync().name("mantle.account.InvoiceServices.create#ProjectInvoiceItems")
                .parameters([invoiceId:expInvResult.invoiceId, workerPartyId:workerResult.partyId,
                    ratePurposeEnumId:'RaprVendor', workEffortId:'TEST', thruDate:new Timestamp(effectiveTime + 1)]).call()
        // "submit" the expense/time invoice
        ec.service.sync().name("update#mantle.account.invoice.Invoice")
                .parameters([invoiceId:expInvResult.invoiceId, statusId:'InvoiceReceived']).call()

        // pay the invoice (345.67 + 123.45 + (13.5 * 40) = 1009.12)
        Map expPmtResult = ec.service.sync().name("mantle.account.PaymentServices.create#InvoicePayment")
                .parameters([invoiceId:expInvResult.invoiceId, statusId:'PmntDelivered', amount:'1009.12',
                    paymentInstrumentEnumId:'PiCompanyCheck', effectiveDate:startYear + '-11-10 12:00:00',
                    paymentRefNum:'1234', comments:'Delivered by Fedex']).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.invoice.Invoice invoiceId="${expInvResult.invoiceId}" invoiceTypeEnumId="InvoiceSales" fromPartyId="${workerResult.partyId}"
                toPartyId="${vendorResult.partyId}" statusId="InvoicePmtSent" invoiceDate="${startYear + '-11-08'}" currencyUomId="USD"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="01" itemTypeEnumId="ItemExpTravAir"
                quantity="1" amount="345.67" description="United SFO-LAX"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="02" itemTypeEnumId="ItemExpTravLodging"
                quantity="1" amount="123.45" description="Fleabag Inn 2 nights"/>

            <mantle.account.invoice.InvoiceItem invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="03" itemTypeEnumId="ItemTimeEntry"
                quantity="6" amount="40" itemDate="${effectiveThruDate.time}"/>
            <mantle.work.time.TimeEntry timeEntryId="55900" vendorInvoiceId="${expInvResult.invoiceId}" vendorInvoiceItemSeqId="03"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="04" itemTypeEnumId="ItemTimeEntry"
                quantity="1.5" amount="40" itemDate="${effectiveThruDate.time}"/>
            <mantle.work.time.TimeEntry timeEntryId="55901" vendorInvoiceId="${expInvResult.invoiceId}" vendorInvoiceItemSeqId="04"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="05" itemTypeEnumId="ItemTimeEntry"
                quantity="2" amount="40"/>
            <mantle.work.time.TimeEntry timeEntryId="55902" vendorInvoiceId="${expInvResult.invoiceId}" vendorInvoiceItemSeqId="05"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="06" itemTypeEnumId="ItemTimeEntry"
                quantity="4" amount="40" itemDate="${effectiveThruDate.time}"/>
            <mantle.work.time.TimeEntry timeEntryId="55903" vendorInvoiceId="${expInvResult.invoiceId}" vendorInvoiceItemSeqId="06"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55900" acctgTransTypeEnumId="AttPurchaseInvoice"
                organizationPartyId="${vendorResult.partyId}" transactionDate="${startYear + '-11-08'}" isPosted="Y" postedDate="${effectiveTime}"
                glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" otherPartyId="${workerResult.partyId}" invoiceId="${expInvResult.invoiceId}"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55900" acctgTransEntrySeqId="01" debitCreditFlag="D"
                amount="345.67" glAccountId="681100000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="01"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55900" acctgTransEntrySeqId="02" debitCreditFlag="D"
                amount="123.45" glAccountId="681100000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="02"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55900" acctgTransEntrySeqId="03" debitCreditFlag="D"
                amount="240" glAccountId="550000000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="03"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55900" acctgTransEntrySeqId="04" debitCreditFlag="D"
                amount="60" glAccountId="550000000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="04"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55900" acctgTransEntrySeqId="05" debitCreditFlag="D"
                amount="80" glAccountId="550000000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="05"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55900" acctgTransEntrySeqId="06" debitCreditFlag="D"
                amount="160" glAccountId="550000000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="06"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55900" acctgTransEntrySeqId="07" debitCreditFlag="C"
                amount="1009.12" glAccountTypeEnumId="GatAccountsPayable" glAccountId="212000000" reconcileStatusId="AterNot" isSummary="N"/>
            <mantle.work.effort.WorkEffortInvoice invoiceId="${expInvResult.invoiceId}" workEffortId="TEST"/>

            <mantle.account.payment.Payment paymentId="${expPmtResult.paymentId}" paymentTypeEnumId="PtInvoicePayment"
                fromPartyId="${vendorResult.partyId}" toPartyId="${workerResult.partyId}" paymentInstrumentEnumId="PiCompanyCheck"
                statusId="PmntDelivered" paymentRefNum="1234" comments="Delivered by Fedex" effectiveDate="${startYear + '-11-10 12:00:00'}"
                amount="1009.12" amountUomId="USD"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55901" acctgTransTypeEnumId="AttOutgoingPayment"
                organizationPartyId="${vendorResult.partyId}" transactionDate="${startYear + '-11-10 12:00:00'}" isPosted="Y"
                postedDate="${effectiveTime}" glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" otherPartyId="${workerResult.partyId}"
                paymentId="${expPmtResult.paymentId}"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55901" acctgTransEntrySeqId="01" debitCreditFlag="D"
                amount="1009.12" glAccountId="212000000" reconcileStatusId="AterNot" isSummary="N"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55901" acctgTransEntrySeqId="02" debitCreditFlag="C"
                amount="1009.12" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N"/>

            <mantle.account.payment.PaymentApplication paymentApplicationId="${expPmtResult.paymentApplicationId}"
                paymentId="${expPmtResult.paymentId}" invoiceId="${expInvResult.invoiceId}" amountApplied="1009.12"
                appliedDate="${startYear + '-11-10 12:00:00'}"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55958" changedEntityName="mantle.account.invoice.Invoice"
                changedFieldName="statusId" pkPrimaryValue="${expInvResult.invoiceId}" newValueText="InvoiceIncoming"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55959" changedEntityName="mantle.account.invoice.Invoice"
                changedFieldName="statusId" pkPrimaryValue="${expInvResult.invoiceId}" oldValueText="InvoiceIncoming"
                newValueText="InvoiceReceived" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55960" changedEntityName="mantle.account.invoice.Invoice"
                changedFieldName="statusId" pkPrimaryValue="${expInvResult.invoiceId}" oldValueText="InvoiceReceived"
                newValueText="InvoiceApproved" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55961" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55900" newValueText="N" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55962" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55900" oldValueText="N" newValueText="Y"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55963" changedEntityName="mantle.account.payment.Payment"
                changedFieldName="statusId" pkPrimaryValue="${expPmtResult.paymentId}" newValueText="PmntPromised"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55964" changedEntityName="mantle.account.payment.Payment"
                changedFieldName="statusId" pkPrimaryValue="${expPmtResult.paymentId}" oldValueText="PmntPromised"
                newValueText="PmntDelivered" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55966" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55901" newValueText="N" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55967" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55901" oldValueText="N" newValueText="Y"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

        </entity-facade-xml>""").check()
        logger.info("create Worker Time and Expense Invoice and record Payment data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "create Client Time and Expense Invoice and Finalize"() {
        when:
        clientInvResult = ec.service.sync().name("mantle.account.InvoiceServices.create#ProjectInvoiceItems")
                .parameters([ratePurposeEnumId:'RaprClient', workEffortId:'TEST', thruDate:new Timestamp(effectiveTime + 1), invoiceDate:startYear + '-11-08']).call()
        // this will trigger the GL posting
        ec.service.sync().name("update#mantle.account.invoice.Invoice")
                .parameters([invoiceId:clientInvResult.invoiceId, statusId:'InvoiceFinalized']).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.invoice.Invoice invoiceId="${clientInvResult.invoiceId}" invoiceTypeEnumId="InvoiceSales"
                fromPartyId="${vendorResult.partyId}" toPartyId="${clientResult.partyId}" statusId="InvoiceFinalized" invoiceDate="${startYear + '-11-08'}"
                currencyUomId="USD"/><!-- varies based on settings: description="Invoice for project Test Project [TEST]" -->
            <mantle.account.invoice.InvoiceItem invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="01"
                itemTypeEnumId="ItemTimeEntry" quantity="6" amount="60" itemDate="${effectiveThruDate.time}"/>
            <mantle.work.time.TimeEntry timeEntryId="55900" invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="01"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="02"
                itemTypeEnumId="ItemTimeEntry" quantity="1.5" amount="60" itemDate="${effectiveThruDate.time}"/>
            <mantle.work.time.TimeEntry timeEntryId="55901" invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="02"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="03"
                itemTypeEnumId="ItemTimeEntry" quantity="2" amount="60"/>
            <mantle.work.time.TimeEntry timeEntryId="55902" invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="03"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="04"
                itemTypeEnumId="ItemTimeEntry" quantity="4" amount="0" itemDate="${effectiveThruDate.time}"/>
            <mantle.work.time.TimeEntry timeEntryId="55903" invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="04"/>

            <mantle.account.invoice.InvoiceItem invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="05"
                itemTypeEnumId="ItemExpTravAir" quantity="1" amount="345.67" description="United SFO-LAX"/>
            <mantle.account.invoice.InvoiceItemAssoc invoiceItemAssocId="55900" invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="01"
                toInvoiceId="${clientInvResult.invoiceId}" toInvoiceItemSeqId="05" invoiceItemAssocTypeEnumId="IiatBillThrough" quantity="1" amount="345.67"/>
            <mantle.account.invoice.InvoiceItem invoiceId="${clientInvResult.invoiceId}" invoiceItemSeqId="06"
                itemTypeEnumId="ItemExpTravLodging" quantity="1" amount="123.45" description="Fleabag Inn 2 nights"/>
            <mantle.account.invoice.InvoiceItemAssoc invoiceItemAssocId="55901" invoiceId="${expInvResult.invoiceId}" invoiceItemSeqId="02"
                toInvoiceId="${clientInvResult.invoiceId}" toInvoiceItemSeqId="06" invoiceItemAssocTypeEnumId="IiatBillThrough" quantity="1" amount="123.45"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55902" acctgTransTypeEnumId="AttSalesInvoice"
                organizationPartyId="${vendorResult.partyId}" transactionDate="${startYear + '-11-08'}" isPosted="Y" postedDate="${effectiveTime}"
                glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" otherPartyId="${clientResult.partyId}" invoiceId="${clientInvResult.invoiceId}"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55902" acctgTransEntrySeqId="01" debitCreditFlag="C"
                amount="360" glAccountId="412000000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="01"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55902" acctgTransEntrySeqId="02" debitCreditFlag="C"
                amount="90" glAccountId="412000000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="02"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55902" acctgTransEntrySeqId="03" debitCreditFlag="C"
                amount="120" glAccountId="412000000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="03"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55902" acctgTransEntrySeqId="04" debitCreditFlag="C"
                amount="345.67" glAccountId="681100000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="05"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55902" acctgTransEntrySeqId="05" debitCreditFlag="C"
                amount="123.45" glAccountId="681100000" reconcileStatusId="AterNot" isSummary="N" invoiceItemSeqId="06"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55902" acctgTransEntrySeqId="06" debitCreditFlag="D"
                amount="1,039.12" glAccountTypeEnumId="GatAccountsReceivable" glAccountId="121000000" reconcileStatusId="AterNot" isSummary="N"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55965" changedEntityName="mantle.account.invoice.Invoice"
                changedFieldName="statusId" pkPrimaryValue="${expInvResult.invoiceId}" oldValueText="InvoiceApproved"
                newValueText="InvoicePmtSent" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55968" changedEntityName="mantle.account.invoice.Invoice"
                changedFieldName="statusId" pkPrimaryValue="${clientInvResult.invoiceId}" newValueText="InvoiceInProcess"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55969" changedEntityName="mantle.account.invoice.Invoice"
                changedFieldName="statusId" pkPrimaryValue="${expInvResult.invoiceId}" oldValueText="InvoicePmtSent"
                newValueText="InvoiceBilledThrough" changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55971" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55902" newValueText="N" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55972" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55902" oldValueText="N" newValueText="Y"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

        </entity-facade-xml>""").check()
        logger.info("create Client Time and Expense Invoice and Finalize data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }

    def "record Payment for Client Time and Expense Invoice"() {
        when:
        Map clientPmtResult = ec.service.sync().name("mantle.account.PaymentServices.create#InvoicePayment")
                .parameters([invoiceId:clientInvResult.invoiceId, statusId:'PmntDelivered', amount:1039.12,
                    paymentInstrumentEnumId:'PiCompanyCheck', effectiveDate:startYear + '-11-12 12:00:00', paymentRefNum:'54321']).call()

        // NOTE: this has sequenced IDs so is sensitive to run order!
        List<String> dataCheckErrors = ec.entity.makeDataLoader().xmlText("""<entity-facade-xml>
            <mantle.account.invoice.Invoice invoiceId="${clientInvResult.invoiceId}" statusId="InvoicePmtRecvd"/>
            <mantle.account.payment.Payment paymentId="${clientPmtResult.paymentId}" paymentTypeEnumId="PtInvoicePayment"
                fromPartyId="${clientResult.partyId}" toPartyId="${vendorResult.partyId}" paymentInstrumentEnumId="PiCompanyCheck"
                statusId="PmntDelivered" paymentRefNum="54321" amount="1,039.12" amountUomId="USD" effectiveDate="${startYear + '-11-12 12:00:00'}"/>
            <mantle.account.payment.PaymentApplication paymentApplicationId="${clientPmtResult.paymentApplicationId}"
                paymentId="${clientPmtResult.paymentId}" invoiceId="${clientInvResult.invoiceId}"
                amountApplied="1,039.12" appliedDate="${startYear + '-11-12 12:00:00'}"/>

            <mantle.ledger.transaction.AcctgTrans acctgTransId="55903" acctgTransTypeEnumId="AttIncomingPayment"
                organizationPartyId="${vendorResult.partyId}" transactionDate="${startYear + '-11-12 12:00:00'}" isPosted="Y" postedDate="${effectiveTime}"
                glFiscalTypeEnumId="GLFT_ACTUAL" amountUomId="USD" otherPartyId="${clientResult.partyId}" paymentId="${clientPmtResult.paymentId}"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55903" acctgTransEntrySeqId="01" debitCreditFlag="C"
                amount="1,039.12" glAccountId="121000000" reconcileStatusId="AterNot" isSummary="N"/>
            <mantle.ledger.transaction.AcctgTransEntry acctgTransId="55903" acctgTransEntrySeqId="02" debitCreditFlag="D"
                amount="1,039.12" glAccountId="111100000" reconcileStatusId="AterNot" isSummary="N"/>

            <moqui.entity.EntityAuditLog auditHistorySeqId="55976" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55903" newValueText="N" changedDate="${effectiveTime}"
                changedByUserId="EX_JOHN_DOE"/>
            <moqui.entity.EntityAuditLog auditHistorySeqId="55977" changedEntityName="mantle.ledger.transaction.AcctgTrans"
                changedFieldName="isPosted" pkPrimaryValue="55903" oldValueText="N" newValueText="Y"
                changedDate="${effectiveTime}" changedByUserId="EX_JOHN_DOE"/>

        </entity-facade-xml>""").check()
        logger.info("record Payment for Client Time and Expense Invoice data check results: ")
        for (String dataCheckError in dataCheckErrors) logger.info(dataCheckError)

        then:
        dataCheckErrors.size() == 0
    }
}
