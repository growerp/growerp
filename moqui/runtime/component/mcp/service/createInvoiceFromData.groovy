import org.moqui.context.ExecutionContext
import groovy.json.JsonOutput

def ec = context.getExecutionContext()

try {
    def invoiceData = context.get("invoiceData")

    // 1. Get the company of the current user
    def sessionCompanyResult = ec.service.sync().name("growerp.userCompany.get#SessionCompany").call()
    if (sessionCompanyResult.get("company") == null) {
        ec.getMessage().addError("Could not determine the company for the current user.")
        return
    }
    def companyPartyId = sessionCompanyResult.get("company").partyId

    // 2. Find the supplier party ID from the supplier name
    def supplierName = invoiceData.supplier
    def partyList = ec.entity.find("mantle.party.PartyAndNameDetail")
            .condition("groupName", supplierName)
            .list()
    if (partyList.isEmpty()) {
        ec.getMessage().addError("Supplier not found: " + supplierName)
        return
    }
    def supplierPartyId = partyList.get(0).partyId

    // 3. Prepare invoice items
    def invoiceItems = []
    for (def item in invoiceData.items) {
        invoiceItems.add([
            "invoiceItemTypeEnumId": "InitPurchase",
            "description": item.description,
            "quantity": item.quantity,
            "amount": item.unitPrice
        ])
    }

    // 4. Call the create#Invoice service
    def createInvoiceResult = ec.service.sync().name("mantle.account.InvoiceServices.create#Invoice")
        .parameters([
            "invoiceTypeEnumId": "InvoicePurchase",
            "statusId": "InvoiceInProcess",
            "partyIdFrom": supplierPartyId,
            "partyIdTo": companyPartyId,
            "invoiceDate": invoiceData.invoiceDate,
            "invoiceMessage": "Invoice created from uploaded image.",
            "invoiceItems": invoiceItems
        ])
        .call()

    if (createInvoiceResult.get("invoiceId") == null) {
        ec.getMessage().addError("Failed to create invoice: " + createInvoiceResult.get("errors"))
        return
    }

    // 5. Return the created invoice
    def invoice = ec.entity.find("mantle.account.invoice.InvoiceHeader")
            .condition("invoiceId", createInvoiceResult.get("invoiceId"))
            .one()

    def invoiceMap = invoice.getMap()
    invoiceMap.invoiceDate = invoiceMap.invoiceDate?.toString()
    invoiceMap.postedDate = invoiceMap.postedDate?.toString()
    invoiceMap.paidDate = invoiceMap.paidDate?.toString()
    invoiceMap.dueDate = invoiceMap.dueDate?.toString()

    context.put("stringResult", JsonOutput.toJson(invoiceMap))

} catch (Exception e) {
    ec.getMessage().addError("An error occurred while creating the invoice: " + e.getMessage())
}