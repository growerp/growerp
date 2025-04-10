const { Builder, By, Key, until } = require('selenium-webdriver');
const assert = require('assert');
const { enterTextByKey,
  tapByKey,
  tapByLink,
  getLinkTextById,
  getFreeEmail,
  newCompany,
  setPaymentApiKey,
  approveBackendOrder,
  approveBackendShipment,
  completeBackendShipment,
  getPayment,
  logout,
  login,
  getCurrentTestData,
  saveCurrentTestData,
  deleteCurrentTestData,
} = require('./commonTest.js');

let wait = 1000;

describe('Hotel website order process', function () {
  this.timeout(600000000)
  let driver;
  let vars;
  let email = "testxxx@example.com";
  let currentTestData;
  before(function () {
    vars = require('../test_data.json');
  })
  beforeEach(async function () {
    currentTestData = getCurrentTestData();
  })

  deleteCurrentTestData();
  it('Hotel new company & website', async function () {

    if (currentTestData.auth == null) {
      // this test not yet run....
      var newEmail = await getFreeEmail(email);
      assert.notEqual(email, null, "Could not find free email!");

      // create company
      var auth = await newCompany(
        vars.admin.firstName,
        vars.admin.lastName,
        newEmail,
        vars.company.name,
        vars.company.currencyId,
        'AppHotel');
      // console.log(auth);
      assert.notEqual(auth, null, "create new company error");

      // insert stripeKey
      var config = require('./stripeKey.js');
      await setPaymentApiKey(auth.apiKey, config.stripeKey);
      const fs = require("fs");

      saveCurrentTestData({ auth })
    }
  })
  it('create order', async function () {

    if (currentTestData.orderId == null) {
      driver = await new Builder().forBrowser('firefox').build()
      assert.notEqual(email, null, "Could not find free email!");
      await driver.get('http://' + currentTestData.auth.company.hostName)
      await driver.manage().window().setRect({ width: 1230, height: 861 })
      await driver.findElement(By.css("#recipeCarousel .carousel-item:nth-child(1) > .d-block:nth-child(" + "1" + ") .figure-img")).click()
      await driver.findElement(By.id("cartAdd")).click()
      await tapByKey(driver, "cartAdd");
      await tapByKey(driver, "cart-quantity");
      var newEmail = await getFreeEmail(email);
      await tapByKey(driver, "createAccount");
      await enterTextByKey(driver, 'firstName', vars.user.firstName)
      await enterTextByKey(driver, 'lastName', vars.user.lastName)
      await enterTextByKey(driver, 'email', newEmail)
      await tapByKey(driver, "create")
      currentTestData["email"] = newEmail;
      saveCurrentTestData(currentTestData);
      // login
      await enterTextByKey(driver, 'username', currentTestData.email)
      await enterTextByKey(driver, 'password', 'qqqqqq9!')
      await tapByKey(driver, "loginButton")
      // checkout
      await tapByKey(driver, "checkOut")
      // address
      await tapByKey(driver, "newAddress")
      await enterTextByKey(driver, 'name', 'qqq')
      await enterTextByKey(driver, 'attention', 'qqq')
      await enterTextByKey(driver, 'address1', 'qqq')
      await enterTextByKey(driver, 'city', 'qqq')
      await enterTextByKey(driver, 'postalcode', '333333')
      await tapByKey(driver, "updateAddress")
      await tapByKey(driver, "addressCheckmark")
      await tapByKey(driver, "contAddress")
      /// method
      await tapByKey(driver, "contSM")
      // CC
      await tapByKey(driver, "addCreditCard")
      await enterTextByKey(driver, 'nameCard', 'qqqq')
      await enterTextByKey(driver, 'card', '4242 4242 4242 4242')
      await driver.findElement(By.id("month")).sendKeys("05")
      await driver.findElement(By.id("year")).sendKeys("2025")
      await driver.findElement(By.id("address")).sendKeys("qqq, qqq, qqqqq")
      await tapByKey(driver, "updateCC")
      // CVV
      await enterTextByKey(driver, 'cvv', '111')
      await tapByKey(driver, "contCC")
      // place order
      await tapByKey(driver, "placeOrder")
      orderId = await getLinkTextById(driver, "orderId")
      await tapByKey(driver, "keepShopping")
      await logout(driver, vars.user.firstName, vars.user.lastName)
      currentTestData["orderId"] = orderId;
      currentTestData["email"] = newEmail;
      saveCurrentTestData(currentTestData);
      await driver.quit();
    }
  })
  it('process order in the backend', async function () {

    if (currentTestData.payment == null) {

      var order = await approveBackendOrder(
        currentTestData.auth.apiKey, currentTestData.orderId);
      //console.log(order)
      currentTestData["order"] = order;
      var shipment = await approveBackendShipment(
        currentTestData.auth.apiKey, order.shipmentId);
      //console.log(shipment)
      shipment = await completeBackendShipment(
        currentTestData.auth.apiKey, order.shipmentId);
      //console.log(shipment)
      currentTestData["shipment"] = shipment;

      var payment = await getPayment(currentTestData.auth.apiKey, currentTestData.order.paymentId);
      currentTestData["payment"] = payment;
      //console.log(payment);
      if (payment.grandTotal != 0)
        assert.equal(payment.gatewayResponses.filter(el =>
          el.paymentOperation == "Capture" && el.resultSuccess == true).length, 1,
          "no succesfull gateway capture found");

      saveCurrentTestData(currentTestData);
    }

  })
  it('check website order complete', async function () {
    driver = await new Builder().forBrowser('firefox').build()
    await driver.get('http://' + currentTestData.auth.company.hostName)
    await login(driver, currentTestData.email)
    await tapByLink(driver, vars.user.firstName + ' ' + vars.user.lastName)
    await tapByLink(driver, "My Orders")
    await tapByLink(driver, "Order #" + currentTestData.orderId)
    let text = "Order Status: OrderCompleted"
    var bodyText = await driver.findElement(By.css("body")).getText();
    assert.equal(bodyText.includes(text), true, text + " not found on page");
    await logout(driver, vars.user.firstName, vars.user.lastName)
    await driver.quit();
    deleteCurrentTestData();
  })

})
