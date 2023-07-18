package com.stripe

import com.stripe.Stripe
import com.stripe.exception.StripeException
import com.stripe.model.Customer

import org.moqui.context.ExecutionContext

class CustomerServices {
    static Map sendStoreRequest (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def creditCardInfo = ec.context.creditCardInfo
        def customerInfo = ec.context.customerInfo

        Stripe.apiKey = secretKey

        def tokenResponse = TokenServices.generateToken(ec).responseMap
        if (!tokenResponse.token) return ['responseMap':tokenResponse] // passing the error info back up to caller

        customerInfo.source = tokenResponse.token.id

        def responseMap = [:]

        try {
            def customer = Customer.create(customerInfo)

            responseMap.customer = customer
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (StripeException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map sendUpdateRequest (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def customerId = ec.context.customerId
        def creditCardInfo = ec.context.creditCardInfo
        def customerInfo = ec.context.customerInfo

        Stripe.apiKey = secretKey

        def tokenResponse = TokenServices.generateToken(ec).responseMap
        if (tokenResponse.token) customerInfo.source = tokenResponse.token.id
        else ec.logger.warn("In CustomerServices.sendUpdateRequest(), unable to generate token from the given credit card info. Just going to update the other customer info that was given.(Token error: ${tokenResponse.errorInfo.reasonMessage}")

        def responseMap = [:]

        try {
            def customer = Customer.retrieve(customerId)
            customer.update(customerInfo)

            responseMap.customer = customer
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (StripeException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }

    static Map sendDeleteRequest (ExecutionContext ec) {
        def secretKey = ec.context.secretKey
        def customerId = ec.context.customerId

        Stripe.apiKey = secretKey

        def responseMap = [:]

        try {
            def customer = Customer.retrieve(customerId)
            customer.delete()

            responseMap.customer = customer
            responseMap.errorInfo = ['responseCode':'1'] // '1' = success

        } catch (StripeException e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':e.getCode(),'reasonMessage':e.getMessage(),'exception':e]
        } catch (Exception e) {
            responseMap.errorInfo = ['responseCode':'3','reasonCode':'','reasonMessage':e.getMessage(),'exception':e]
        }

        return ['responseMap':responseMap]
    }
}