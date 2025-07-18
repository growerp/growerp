<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Checkout</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: #f8f9fa;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .checkout-container {
            background-color: #ffffff;
            padding: 11px 32px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            width: 100%;
            max-width: 350px;
        }
        h1 {
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 5px;
        }
        h2 {
            font-size: 16px;
            font-weight: 600;
            margin-top: 9px;
            margin-bottom: 4px;
            color: #333;
        }
        .form-group {
            margin-bottom: 4px;
        }
        .form-row {
            display: flex;
            gap: 15px;
        }
        .form-row .form-group {
            width: 100%;
        }
        label {
            display: block;
            font-size: 14px;
            color: #6c757d;
            margin-bottom: 5px;
        }
        input[type="text"], input[type="email"], select {
            width: 100%;
            padding: 4px;
            border: 1px solid #ced4da;
            border-radius: 6px;
            box-sizing: border-box;
            font-size: 16px;
        }
        input[type="radio"] {
            width: 16px;
            height: 16px;
            box-sizing: border-box;
        }
        input::placeholder {
            color: #adb5bd;
        }
        .coupon-section {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .coupon-section input {
            flex-grow: 1;
        }
        .remove-btn {
            background-color: #e9ecef;
            color: #0d6efd;
            border: none;
            padding: 4px 18px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: 500;
        }
        .coupon-status {
            font-size: 14px;
            color: #28a745;
            margin-top: 5px;
        }
        .payment-methods {
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 7px 20px;
            background-color: #f8f9fa;
        }
        .payment-options {
            display: flex;
            gap: 20px;
            margin-bottom: 15px;
        }
        .payment-option {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 16px;
        }
        .card-details {
            background-color: #ffffff;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            padding: 7px 20px;
        }
        .secure-checkout {
            font-size: 14px;
            color: #28a745;
            margin-bottom: 7px;
        }
        .card-number-group {
            position: relative;
        }
        .card-icons {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            display: flex;
            gap: 4px;
        }
        .card-icons img {
            height: 20px;
        }
        .order-summary {
            margin-top: 12px;
        }
        .summary-item {
            display: flex;
            justify-content: space-between;
            font-size: 16px;
            margin-bottom: 5px;
        }
        .summary-item.total {
            font-weight: bold;
            font-size: 20px;
            margin-top: 7px;
            color: #0d6efd;
        }
        .place-order-btn {
            width: 100%;
            background-color: #0d6efd;
            color: white;
            padding: 8px;
            border: none;
            border-radius: 8px;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 10px;
        }
    </style>
</head>
<body>

    <div class="checkout-container">
        <h1>Checkout</h1>
        <!-- Payment result message -->
        <#if resultMessage?? && resultMessage != "">
          <#if result?string == "true">
            <p style="font-weight: bold; color: green; margin-bottom: 10px; padding: 10px; border-radius: 5px;">
              ${resultMessage}
            </p>
          <#else>
            <p style="font-weight: bold; color: red; margin-bottom: 10px; padding: 10px; border-radius: 5px;">
              ${resultMessage}
            </p>
          </#if>
        </#if>
        <p id="ccError" style="display:none; color:red; font-weight:bold; margin-bottom:10px;"></p>
        <form id="checkoutForm" method="post" action="/checkoutOnePage/payOnePage" onsubmit="return validateCreditCard();">
    <script>
    function getCardType(number) {
        number = number.replace(/\D/g, '');
        if (/^4[0-9]{12}(?:[0-9]{3})?$/.test(number)) return 'Visa';
        if (/^5[1-5][0-9]{14}$/.test(number)) return 'MasterCard';
        if (/^3[47][0-9]{13}$/.test(number)) return 'Amex';
        if (/^6(?:011|5[0-9]{2})[0-9]{12}$/.test(number)) return 'Discover';
        return '';
    }

    function updateCardType() {
        var ccInput = document.getElementById('card-number');
        var ccTypeInput = document.getElementById('creditCardType');
        var type = getCardType(ccInput.value);
        ccTypeInput.value = type;
    }

    document.addEventListener('DOMContentLoaded', function() {
        var ccInput = document.getElementById('card-number');
        ccInput.addEventListener('input', updateCardType);
        updateCardType();
    });

    function luhnCheck(cardNumber) {
        var sum = 0;
        var shouldDouble = false;
        for (var i = cardNumber.length - 1; i >= 0; i--) {
            var digit = parseInt(cardNumber.charAt(i));
            if (isNaN(digit)) return false;
            if (shouldDouble) {
                digit *= 2;
                if (digit > 9) digit -= 9;
            }
            sum += digit;
            shouldDouble = !shouldDouble;
        }
        return (sum % 10) === 0;
    }

    function validateCreditCard() {
        var ccInput = document.getElementById('card-number');
        var ccError = document.getElementById('ccError');
        var ccValue = ccInput.value.replace(/\s+/g, '');
        var ccTypeInput = document.getElementById('creditCardType');
        var type = getCardType(ccValue);
        ccTypeInput.value = type;
        if (!luhnCheck(ccValue)) {
            ccError.textContent = 'Invalid credit card number.';
            ccError.style.display = 'block';
            ccInput.focus();
            return false;
        } else {
            ccError.style.display = 'none';
            return true;
        }
    }
    </script>
            <section>
                <h2>Contact</h2>
                <div class="form-row">
                    <div class="form-group">
                        <input type="text" id="first-name" name="firstName" placeholder="First Name" required value="${firstName!}">
                    </div>
                    <div class="form-group">
                        <input type="text" id="last-name" name="lastName" placeholder="Last Name" required value="${lastName!}">
                    </div>
                </div>
                <div class="form-group">
                    <input type="email" id="email" name="email" placeholder="Email Address" required value="${email!}">
                </div>
            </section>

            <!--section>
                <h2>Coupon Code</h2>
                <div class="coupon-section">
                    <input type="text" id="coupon-code" name="couponCode" value="${couponCode!}" placeholder="Enter coupon code" required>
                </div>
            </section-->

            <section>
                <h2>Payment Methods</h2>
                <div class="payment-methods">
                    <#--div class="payment-options">
                        <div class="payment-option">
                            <input type="radio" id="card" name="paymentMethod" value="card" checked>
                            <label for="card">Card & More</label>
                        </div>
                        <div class="payment-option">
                            <input type="radio" id="paypal" name="paymentMethod" value="paypal">
                            <label for="paypal">PayPal</label>
                        </div>
                    </div-->
                    <div class="card-details">
                        <#--p class="secure-checkout">🔒 Secure, 1-click checkout with Link ✓</p-->
                        <div class="form-group">
                            <label for="card-number">Card number</label>
                            <div class="card-number-group">
                                <input type="text" id="card-number" name="creditCardNumber" placeholder="" required value="${creditCardNumber!}">
                                <div class="card-icons">
                                   <img src="https://img.icons8.com/color/48/visa.png" alt="Visa">
                                   <img src="https://img.icons8.com/color/48/mastercard.png" alt="Mastercard">
                                   <img src="https://img.icons8.com/color/48/amex.png" alt="Amex">
                                </div>
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="name-on-card">Name on Card</label>
                            <input type="text" id="name-on-card" name="nameOnCard" placeholder="Full Name" required value="${nameOnCard!}">
                        </div>
                        <div class="form-row">
                            <div class="form-group">
                                <label for="expiry-month">Expiration month</label>
                                <input type="text" id="expiry-month" name="expireMonth" placeholder="MM" required value="${expireMonth!}">
                            </div>
                            <div class="form-group">
                                <label for="expiry-year">Expiration year</label>
                                <input type="text" id="expiry-year" name="expireYear" placeholder="YY" required value="${expireYear!}">
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="cvc">Security code</label>
                            <input type="text" id="cvc" name="cVC" placeholder="CVC" required value="${cVC!}">
                        </div>
                        <#--div class="form-group">
                            <label for="country">Country</label>
                            <select id="country" name="country">
                                <option value="thailand" selected>Thailand</option>
                                <option value="usa">United States</option>
                                <option value="uk">United Kingdom</option>
                            </select>
                        </div-->
                    </div>
                </div>
            </section>

            <section class="order-summary">
                <h2>Order Summary</h2>
                <#--div class="summary-item">
                    <span>Subtotal:</span>
                    <span>$150.00</span>
                </div>
                <div class="summary-item">
                    <span>Discounts:</span>
                    <span>-$53.00</span>
                </div-->
                <div class="summary-item total">
                    <span>TOTAL:</span>
                    <span>$${amount!}</span>
                </div>
            </section>

            <input type="hidden" id="currencyId" name="currencyId" value="USD">
            <input type="hidden" id="creditCardType" name="creditCardType" value="${creditCardType!}">
            <input type="hidden" id="amount" name="amount" value="${amount!}">
            <button class="place-order-btn">Place Order Now</button>
        </form>
    </div>

</body>
</html>
