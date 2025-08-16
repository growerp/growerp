# Currency Conversion Services

This document describes the currency conversion functionality added to the Stripe payment component. These services use **Stripe's Exchange Rate API** to get real-time currency conversion rates.

## Services Added

### 1. `convert#Currency` (Low-level conversion service)

**Location**: `com.stripe.TransactionServices.convertCurrency()`  
**Service Name**: `Stripe.StripePaymentServices.convert#Currency`

This is a low-level service that performs currency conversion using Stripe's Exchange Rate API.

#### Input Parameters:
- `secretKey` (String, required): Stripe secret key for API access
- `amount` (BigDecimal, required): The amount to convert
- `fromCurrencyUomId` (String, required): Source currency UOM ID (e.g., 'USD', 'EUR')
- `toCurrencyUomId` (String, required): Target currency UOM ID (e.g., 'EUR', 'GBP', 'JPY')
- `exchangeRate` (BigDecimal, optional): Manual exchange rate (if not provided, fetches from Stripe API)
- `roundingMode` (String, default 'HALF_UP'): Rounding mode for the result

#### Output Parameters:
- `convertedAmount` (BigDecimal): The converted amount in target currency
- `responseMap` (Map): Contains conversion details and error information

#### Example Usage:
```xml
<!-- Using Stripe's live exchange rates -->
<service-call name="Stripe.StripePaymentServices.convert#Currency" 
    in-map="[secretKey: 'sk_test_...', amount: 100.00, fromCurrencyUomId: 'USD', toCurrencyUomId: 'EUR']" 
    out-map="conversionResult"/>

<!-- Using a manual exchange rate -->
<service-call name="Stripe.StripePaymentServices.convert#Currency" 
    in-map="[secretKey: 'sk_test_...', amount: 100.00, fromCurrencyUomId: 'USD', toCurrencyUomId: 'EUR', exchangeRate: 0.85]" 
    out-map="conversionResult"/>
```

### 2. `convert#PaymentAmount` (High-level payment conversion service)

**Service Name**: `Stripe.StripePaymentServices.convert#PaymentAmount`

This is a higher-level service that can convert payment amounts using Stripe's Exchange Rate API. It automatically retrieves Stripe credentials from the payment gateway configuration.

#### Input Parameters:
- `paymentGatewayConfigId` (String, optional): Payment gateway config ID to get Stripe credentials
- `paymentId` (String, optional): Payment ID to get amount from
- `amount` (BigDecimal, optional): Amount to convert (required if paymentId not provided)
- `fromCurrencyUomId` (String, optional): Source currency (required if paymentId not provided)
- `toCurrencyUomId` (String, required): Target currency UOM ID
- `exchangeRate` (BigDecimal, optional): Manual exchange rate (if not provided, uses Stripe API)
- `roundingMode` (String, default 'HALF_UP'): Rounding mode

#### Output Parameters:
- `convertedAmount` (BigDecimal): Converted amount
- `originalAmount` (BigDecimal): Original amount before conversion
- `fromCurrencyUomId` (String): Source currency used
- `toCurrencyUomId` (String): Target currency used
- `exchangeRateUsed` (BigDecimal): Exchange rate that was applied
- `conversionSuccessful` (Boolean): Whether conversion succeeded
- `errorMessage` (String): Error message if conversion failed

#### Example Usage:
```xml
<!-- Convert a specific payment to EUR using Stripe's current rates -->
<service-call name="Stripe.StripePaymentServices.convert#PaymentAmount" 
    in-map="[paymentId: 'PAYMENT123', toCurrencyUomId: 'EUR']" 
    out-map="paymentConversion"/>

<!-- Convert an arbitrary amount using custom gateway config -->
<service-call name="Stripe.StripePaymentServices.convert#PaymentAmount" 
    in-map="[amount: 250.00, fromCurrencyUomId: 'USD', toCurrencyUomId: 'GBP', 
             paymentGatewayConfigId: 'MY_STRIPE_CONFIG']" 
    out-map="amountConversion"/>
```

## Stripe Exchange Rate API Integration

### How It Works
1. **Real-time Rates**: When no manual exchange rate is provided, the service calls Stripe's Exchange Rate API to get current conversion rates
2. **Rate Caching**: Stripe caches rates and updates them regularly (typically every few minutes)
3. **Supported Currencies**: Supports all currencies that Stripe supports for international payments
4. **Rate Source**: Uses the same rates that Stripe uses for international charge conversions

### API Details
- **Endpoint**: Uses Stripe's `ExchangeRate.retrieve(source_currency)` API
- **Rate Format**: Returns rates as BigDecimal values (e.g., 0.8543 for USD to EUR)
- **Update Frequency**: Stripe updates rates multiple times per day based on market conditions

## Implementation Details

### Currency Rounding
- The conversion automatically applies appropriate decimal precision based on the target currency
- Uses Java's `Currency.getInstance()` to determine the standard fraction digits for each currency
- Falls back to 2 decimal places if currency lookup fails

### Error Handling
- Returns structured error information in the `responseMap`
- Response codes: '1' = success, '3' = error
- Specific error codes:
  - 'MISSING_PARAMS': Required parameters missing
  - 'MISSING_SECRET_KEY': Stripe secret key not provided
  - 'EXCHANGE_RATE_NOT_AVAILABLE': Currency pair not supported by Stripe
  - 'STRIPE_EXCHANGE_RATE_ERROR': Error fetching rate from Stripe API
  - 'STRIPE_API_ERROR': General Stripe API error
  - 'CONVERSION_ERROR': General conversion error

### Authentication
- Requires valid Stripe secret key (test or live)
- Uses existing Stripe gateway configuration from GrowERP
- Falls back to default gateway config if none specified

## Use Cases

1. **International Payment Processing**: Convert payment amounts for international Stripe transactions with real-time rates
2. **Multi-Currency Reporting**: Convert payments to a standard reporting currency using current market rates
3. **Dynamic Pricing**: Show prices in customer's local currency using current exchange rates
4. **Payment Reconciliation**: Convert foreign payments to local currency for accounting with accurate rates
5. **Rate Checking**: Get current exchange rates for business planning and pricing decisions

## Supported Currencies

This service supports all currencies that Stripe supports, including but not limited to:
- Major currencies: USD, EUR, GBP, JPY, CAD, AUD, CHF
- Regional currencies: SEK, NOK, DKK, PLN, CZK, HUF
- Emerging markets: BRL, MXN, INR, SGD, HKD, and many more

## Rate Accuracy and Reliability

- **Source**: Rates come directly from Stripe's financial data providers
- **Accuracy**: Same rates used for actual Stripe payment processing
- **Reliability**: Stripe's infrastructure ensures high availability
- **Consistency**: Rates are consistent with Stripe's payment conversion rates

## Notes

- **API Limits**: Subject to Stripe's API rate limits (typically very generous for exchange rate calls)
- **Network Dependency**: Requires internet connection to fetch live rates
- **Fallback**: Always provide manual exchange rates for critical operations as fallback
- **Testing**: Use Stripe test keys during development; live rates are available with test keys
- **Cost**: Exchange rate API calls are typically free with Stripe accounts
