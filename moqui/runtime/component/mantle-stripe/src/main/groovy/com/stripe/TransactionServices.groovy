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

        Stripe.apiKey = secretKey

        def responseMap = [:]

        try {
            def charge = Charge.retrieve(chargeId)
            if (amount != null) charge.capture(['amount':amount])
            else charge.capture()

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

        static Map getIncomingPayments (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def startDate = ec.context.startDate
        def tokenResponse = TokenServices.generateToken(ec).responseMap
        if (!tokenResponse.token) return ['responseMap':tokenResponse] // passing the error info back up to caller

        // 1. Configure your Stripe API Key
        // IMPORTANT: Replace "sk_test_..." with your actual Stripe secret key.
        // It's best practice to load this from an environment variable or a config file.
        Stripe.apiKey = secretKey

        // 2. Define the date after which you want to retrieve payments
        // This will fetch payments created on or after January 1, 2024
        println "Fetching payments created on or after: ${startDate}"

        // 3. Convert the date to a Unix timestamp (in seconds)
        // The Stripe API uses Unix timestamps for date-based filtering.
        def startTimestamp = startDate.atStartOfDay(ZoneOffset.UTC).toEpochSecond()

        def responseMap = [:]

        try {
            // 4. Build the parameter map for the API call
            // We use 'created[gte]' which means "created greater than or equal to" the timestamp.
            def params = PaymentIntentListParams.builder()
                .setCreated(
                    PaymentIntentListParams.Created.builder()
                        .setGte(startTimestamp)
                        .build()
                )
                // You can add other filters here, e.g., limiting the number of results per page.
                .setLimit(100L) // Fetch up to 100 payments per API call
                .build()

            println "\n--- Found Payments ---"
            int paymentCount = 0

            // 5. Retrieve the PaymentIntents and iterate through them
            // The .autoPagingIterable() method handles pagination for you automatically.
            // It will make subsequent API calls as needed to fetch all matching payments.
            for (PaymentIntent paymentIntent : PaymentIntent.list(params).autoPagingIterable()) {
                // We are only interested in successful payments.
                if ("succeeded".equals(paymentIntent.getStatus())) {
                    paymentCount++
                    // 6. Process each payment
                    // Convert amount from cents to a displayable format (e.g., dollars)
                    def amount = paymentIntent.getAmount() / 100.0
                    // Convert the creation timestamp back to a human-readable date
                    def createdDate = new Date(paymentIntent.getCreated() * 1000)

                    println "------------------------"
                    println "Payment ID:    ${paymentIntent.getId()}"
                    println "Status:        ${paymentIntent.getStatus()}"
                    println "Amount:        ${String.format('%.2f', amount)} ${paymentIntent.getCurrency().toUpperCase()}"
                    println "Created Date:  ${createdDate.toGMTString()}"
                    println "Description:   ${paymentIntent.getDescription() ?: 'N/A'}"
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