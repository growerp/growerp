package com.paypal

import org.moqui.context.ExecutionContext
import com.paypal.api.payments.*
import com.paypal.base.rest.APIContext
import com.paypal.base.rest.PayPalRESTException

class TransactionServices {
    static Map sendAuthorizeRequest (ExecutionContext ec) {
        def paypalGatewayInfoMap = ec.context.paypalGatewayInfoMap
        def creditCardInfo = ec.context.creditCardInfo
        def transactionInfo = ec.context.transactionInfo

        def clientId = paypalGatewayInfoMap.clientId
        def clientSecret = paypalGatewayInfoMap.clientSecret
        def mode = "sandbox" // Or "live"

        def responseMap = [:]

        try {
            APIContext apiContext = new APIContext(clientId, clientSecret, mode)

            Amount amount = new Amount()
            amount.setCurrency(transactionInfo.currency)
            amount.setTotal(transactionInfo.amount.toString())

            Transaction transaction = new Transaction()
            transaction.setDescription("Payment description")
            transaction.setAmount(amount)

            List<Transaction> transactions = new ArrayList<Transaction>()
            transactions.add(transaction)

            FundingInstrument fundingInstrument = new FundingInstrument()
            CreditCard card = new CreditCard()
            card.setNumber(creditCardInfo.number)
            card.setType(creditCardInfo.type)
            card.setExpireMonth(creditCardInfo.exp_month as Integer)
            card.setExpireYear(creditCardInfo.exp_year as Integer)
            card.setCvv2(creditCardInfo.cvc)
            card.setFirstName(creditCardInfo.firstName)
            card.setLastName(creditCardInfo.lastName)
            fundingInstrument.setCreditCard(card)

            Payer payer = new Payer()
            payer.setPaymentMethod("credit_card")
            payer.setFundingInstruments(Arrays.asList(fundingInstrument))

            Payment payment = new Payment()
            payment.setIntent("authorize")
            payment.setPayer(payer)
            payment.setTransactions(transactions)

            RedirectUrls redirectUrls = new RedirectUrls()
            redirectUrls.setCancelUrl("http://localhost:8080/cancel")
            redirectUrls.setReturnUrl("http://localhost:8080/return")
            payment.setRedirectUrls(redirectUrls)

            Payment createdPayment = payment.create(apiContext)

            responseMap.payment = createdPayment
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (PayPalRESTException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getDetails().getName(),'reasonMessage':e.getDetails().getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map sendCaptureRequest (ExecutionContext ec) {
        def paypalGatewayInfoMap = ec.context.paypalGatewayInfoMap
        def chargeId = ec.context.chargeId
        def amount = ec.context.amount as BigDecimal

        def clientId = paypalGatewayInfoMap.clientId
        def clientSecret = paypalGatewayInfoMap.clientSecret
        def mode = "sandbox" // Or "live"

        def responseMap = [:]

        try {
            APIContext apiContext = new APIContext(clientId, clientSecret, mode)

            Authorization authorization = Authorization.get(apiContext, chargeId)

            Amount captureAmount = new Amount()
            captureAmount.setCurrency(authorization.getAmount().getCurrency())
            captureAmount.setTotal(amount.toString())

            Capture capture = new Capture()
            capture.setAmount(captureAmount)
            capture.setIsFinalCapture(true)

            Capture createdCapture = authorization.capture(apiContext, capture)

            responseMap.capture = createdCapture
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (PayPalRESTException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getDetails().getName(),'reasonMessage':e.getDetails().getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map sendRefundRequest (ExecutionContext ec) {
        def paypalGatewayInfoMap = ec.context.paypalGatewayInfoMap
        def chargeId = ec.context.chargeId
        def amount = ec.context.amount as BigDecimal

        def clientId = paypalGatewayInfoMap.clientId
        def clientSecret = paypalGatewayInfoMap.clientSecret
        def mode = "sandbox" // Or "live"

        def responseMap = [:]

        try {
            APIContext apiContext = new APIContext(clientId, clientSecret, mode)

            Capture capture = Capture.get(apiContext, chargeId)

            Amount refundAmount = new Amount()
            refundAmount.setCurrency(capture.getAmount().getCurrency())
            refundAmount.setTotal(amount.toString())

            Refund refund = new Refund()
            refund.setAmount(refundAmount)

            Refund createdRefund = capture.refund(apiContext, refund)

            responseMap.refund = createdRefund
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (PayPalRESTException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getDetails().getName(),'reasonMessage':e.getDetails().getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map sendReleaseRequest (ExecutionContext ec) {
        def paypalGatewayInfoMap = ec.context.paypalGatewayInfoMap
        def chargeId = ec.context.chargeId

        def clientId = paypalGatewayInfoMap.clientId
        def clientSecret = paypalGatewayInfoMap.clientSecret
        def mode = "sandbox" // Or "live"

        def responseMap = [:]

        try {
            APIContext apiContext = new APIContext(clientId, clientSecret, mode)

            Authorization authorization = Authorization.get(apiContext, chargeId)
            authorization.void(apiContext)

            responseMap.authorization = authorization
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (PayPalRESTException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getDetails().getName(),'reasonMessage':e.getDetails().getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }
}
