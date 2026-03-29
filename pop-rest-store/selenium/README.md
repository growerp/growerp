# Selenium website testing

To make this work within vscode, you have to load this directory as the root.

To run tests:
Use vsCode run configurations: run -> open configurations

Please note the Stripe key in the test/stripeKey file. if entered the test will communicate with Stripe.

if modules are missing load them:
    if axios missing: npm install axios --save

if you get the message:  InvalidArgumentError: binary is not a Firefox executable
    make sure you have executed: npm install selenium-webdriver


to run all tests:
    npm run  testHotel && \
    npm run testAdmin1 && \
    npm run testAdmin2 && \
    npm run testAdmin3 