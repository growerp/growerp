package com.stripe

import com.stripe.Stripe
import com.stripe.model.Charge
import com.stripe.model.Refund
import com.stripe.exception.StripeException
import com.stripe.exception.CardException
import com.stripe.model.PaymentIntent
import com.stripe.param.PaymentIntentListParams
import java.time.LocalDate
import java.time.ZoneOffset // Import the class directly
import com.stripe.model.Balance

import org.moqui.context.ExecutionContext

class TransactionServices {
    static Map sendAuthorizeRequest (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def creditCardInfo = ec.context.creditCardInfo
        def transactionInfo = ec.context.transactionInfo
        Stripe.apiKey = secretKey

        def tokenResponse = TokenServices.generateToken(ec).responseMap
        if (!tokenResponse.token) return ['responseMap':tokenResponse] // passing the error info back up to caller

        transactionInfo.source = tokenResponse.token.id

        // Optionally add customer info if provided
        def customerInfo = ec.context.customerInfo // expects a Map with keys: id, email, name, phone
        if (customerInfo) {
            if (customerInfo.id) transactionInfo.customer = customerInfo.id
            if (customerInfo.email) transactionInfo.receipt_email = customerInfo.email
            // Add name and phone as metadata if present
            if (!transactionInfo.metadata) transactionInfo.metadata = [:]
            if (customerInfo.name) transactionInfo.metadata['customer_name'] = customerInfo.name
            if (customerInfo.phone) transactionInfo.metadata['customer_phone'] = customerInfo.phone
        }

        // Optionally add line items as metadata if provided
        def lineItems = ec.context.lineItems // expects a List<Map> with keys: description, amount, productNumber
        if (lineItems && lineItems instanceof List && !lineItems.isEmpty()) {
            if (!transactionInfo.metadata) transactionInfo.metadata = [:]
            lineItems.eachWithIndex { item, idx ->
                transactionInfo.metadata["lineItem_${idx+1}_description"] = item.description ?: ''
                transactionInfo.metadata["lineItem_${idx+1}_amount"] = item.amount ?: ''
                if (item.productNumber) transactionInfo.metadata["lineItem_${idx+1}_productNumber"] = item.productNumber
            }
        }

        def responseMap = [:]

        try {
            def charge = Charge.create(transactionInfo)

            responseMap.charge = charge
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (CardException e) {
            responseMap.errorInfo = ['responseCode':'2','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (StripeException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map sendCaptureRequest (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def chargeId = ec.context.chargeId
        def amount = ec.context.amount as BigDecimal
        amount = (amount * 100).longValue()

        // Optional: line items array, each item is a map with description, amount, and optional product number
        def lineItems = ec.context.lineItems // expects a List<Map> with keys: description, amount, productNumber

        Stripe.apiKey = secretKey

        def responseMap = [:]

        try {
            def charge = Charge.retrieve(chargeId)
            def captureParams = ['amount': amount]

            // If line items are provided, add them to the captureParams as metadata
            if (lineItems && lineItems instanceof List && !lineItems.isEmpty()) {
                def metadata = [:]
                lineItems.eachWithIndex { item, idx ->
                    metadata["lineItem_${idx+1}_description"] = item.description ?: ''
                    metadata["lineItem_${idx+1}_amount"] = item.amount ?: ''
                    if (item.productNumber) metadata["lineItem_${idx+1}_productNumber"] = item.productNumber
                }
                captureParams['metadata'] = metadata
            }

            charge.capture(captureParams)

            responseMap.charge = charge
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (StripeException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map sendRefundRequest (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def chargeId = ec.context.chargeId
        def amount = ec.context.amount

        amount = amount.toInteger() * 100 // dollars to cents needed because stripe records USD amounts by the smallest division (cents)

        Stripe.apiKey = secretKey

        def responseMap = [:]

        try {
            def refund
            if (amount != null) refund = Refund.create(['charge':chargeId,'amount':amount])
            else refund = Refund.create(['charge':chargeId])

            responseMap.refund = refund
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (StripeException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map getStripePayments (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def startDate = ec.context.startDate

        // 1. Configure your Stripe API Key
        Stripe.apiKey = secretKey

        try {
            println "Attempting to retrieve Stripe account balance..."
            Balance balance = Balance.retrieve()
            println "Successfully retrieved balance. Available: ${balance.getAvailable().get(0).getAmount() / 100.0} ${balance.getAvailable().get(0).getCurrency()}"
        } catch (StripeException e) {
            println "Error retrieving balance: ${e.getMessage()}"
            println "Please verify your Stripe secret key."
            return ['responseMap':[:]]
        }

        // 2. Define the date after which you want to retrieve payments
        def parsedDate = LocalDate.parse(startDate.substring(0,10))
        println "Searching for payments on or after: ${parsedDate}"
        def startTimestamp = parsedDate.atStartOfDay(ZoneOffset.UTC).toEpochSecond()

        def responseMap = [:]

        try {
            // 3. Build the parameter map for the API call
            def params = [
                'created': ['gte': startTimestamp],
                'limit': 100
            ]

            println "\n--- Found Payments ---"
            int paymentCount = 0

            // 4. Retrieve the Charges and iterate through them
            for (Charge charge : Charge.list(params).autoPagingIterable()) {
                if ("succeeded".equals(charge.getStatus())) {
                    paymentCount++
                    // 5. Process each payment
                    def amount = charge.getAmount() / 100.0
                    def createdDate = new Date(charge.getCreated() * 1000)

                    println "------------------------"
                    println "Payment ID:    ${charge.getId()}"
                    println "Status:        ${charge.getStatus()}"
                    println "Amount:        ${String.format('%.2f', amount)} ${charge.getCurrency().toUpperCase()}"
                    println "Created Date:  ${createdDate.toGMTString()}"
                    println "Description:   ${charge.getDescription() ?: 'N/A'}"

                    // Retrieve and print line items (metadata)
                    def metadata = charge.getMetadata()
                    if (metadata && !metadata.isEmpty()) {
                        println "Line Items:"
                        metadata.each { k, v ->
                            if (k.startsWith('lineItem_')) println "  ${k}: ${v}"
                        }
                    } else {
                        println "No line items for this charge."
                    }

                    // Retrieve and print related customer information
                    try {
                        def customerId = charge.getCustomer()
                        if (customerId) {
                            def customer = com.stripe.model.Customer.retrieve(customerId)
                            println "Customer ID:   ${customer.getId()}"
                            println "Customer Email: ${customer.getEmail() ?: 'N/A'}"
                            println "Customer Name:  ${customer.getName() ?: 'N/A'}"
                            println "Customer Phone: ${customer.getPhone() ?: 'N/A'}"
                        } else {
                            println "No customer information for this charge."
                        }
                    } catch (Exception e) {
                        println "Error retrieving customer info: ${e.getMessage()}"
                    }
                }
            }

            if (paymentCount == 0) {
                println "No successful payments found after the specified date."
            } else {
                 println "\n------------------------"
                 println "Total successful payments found: ${paymentCount}"
            }


        }catch (StripeException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

}