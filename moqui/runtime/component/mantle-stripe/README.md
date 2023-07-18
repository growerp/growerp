## Mantle Stripe Integration

forked from https://github.com/akasiri/mantle-stripe

Upgraded the stripe sdk and fixed several errors in the well organized component: thank you for creating it!

Up to now I tested authorization and capture, without using the customer services.


Moqui component for Stripe. Integrates with Mantle payment processing. Currently supports Auth/Capture/Release/Refund operations along with adding and removing PaymentMethods from Stripe. Interacts with the Stripe API via the Stripe java library. Adapted from the AuthorizeDotNet component https://github.com/moqui/AuthorizeDotNet

To add this component to Moqui just clone this repo into your `runtime/component/` directory.

    $ git clone https://github.com/akasiri/mantle-stripe

##### To use:
1. In `data/StripeDemoData.xml` add the secretKey from Stripe into the `<Stripe.PaymentGatewayStripe />` record
    > secretKey="**sk_test_...**"

2. Load the record along with the other configuration data found in `data/`
    > $ ./gradlew build
    > $ ./gradlew load

3. You're ready to go!

##### Example usage:
    <entity-make-value entity-name="mantle.account.payment.Payment" value-field="payment"/>
    <set field="paymentId" from="payment.payementId"/>
    <set field="paymentGatewayConfigId" value="StripeDemo"/>
    
    <service-call name="Stripe.StripePaymentServices.authorize#Payment" in-map="context"/>
    <service-call name="Stripe.StripePaymentServices.capture#Payment" in-map="context"/>

##### Notes:

1. If you want to automatically add newly created cards to Stripe set the _preferenceValue_ in date/StripeDemoData.xml to **true** in this record:

    > <moqui.security.UserGroupPreference userGroupId="ALL_USERS" preferenceKey="StripeEnabled" preferenceValue="**true**"/>


2. I chose to keep the authors from AuthorizeDotNet in the AUTHORS file because a lot of the original functionality came from there.
