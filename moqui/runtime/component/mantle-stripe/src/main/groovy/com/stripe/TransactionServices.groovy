package com.stripe

import com.stripe.Stripe
import com.stripe.model.Charge
import com.stripe.model.Refund
import com.stripe.exception.StripeException
import com.stripe.exception.CardException

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
}