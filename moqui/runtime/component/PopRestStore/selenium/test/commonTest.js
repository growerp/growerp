

const { By } = require('selenium-webdriver')
const axios = require('axios')
const { expect } = require('chai')
let wait = 2000;

// high level functions
let baseUrl = 'http://localhost:8080/rest/s1/growerp/100/';
async function getFreeEmail(email) { // template email with XXX to be replaced bt number
    let count = 0;
    let newEmail;
    let response;
    do {
        newEmail = email.replace('xxx', Math.floor(Math.random() * 999));
        response = await axios.get(
            baseUrl + 'CheckEmail?email=' + newEmail, {
            headers: { 'Content-Type': 'application/json' }
        });
        if (response.status != 200) return;
    } while (response.data.ok == true && ++count < 5);
    if (count != 5) return newEmail;
    return;
}
async function newCompany(firstName, lastName, email, companyName, currencyId) {
    let response = await axios.post(baseUrl + 'Register',
        {
            classificationId: 'AppAdmin',
            email: email,
            firstName: firstName,
            lastName: lastName,
            newPassword: 'qqqqqq9!'
        },
        {
            headers: { 'Content-Type': 'application/json' }
        });
    if (response.status != 200) return;

    await axios.post(baseUrl + 'Login',
        {
            classificationId: 'AppAdmin',
            username: email,
            password: 'qqqqqq9!'
        },
        {
            headers: { 'Content-Type': 'application/json' }
        });
    if (response.status != 200) return;

    response = await axios.post(baseUrl + 'Login',
        {
            classificationId: 'AppAdmin',
            username: email,
            password: 'qqqqqq9!',
            companyName: companyName,
            currencyId: currencyId,
            demoData: true,
            extraInfo: true
        },
        {
            headers: { 'Content-Type': 'application/json' }
        });
    if (response.status == 200) return response.data.authenticate;

}
async function setPaymentApiKey(apiKey, paymentKey) {
    let website = { stripeApiKey: paymentKey };

    response = await axios.patch(baseUrl + 'Website',
        {
            website
        },
        {
            headers: {
                'Content-Type': 'application/json',
                'api_key': apiKey
            }
        });
    if (response.status == 200) return response.data.website.id;

}
async function approveBackendOrder(apiKey, orderId) {
    let finDoc = {
        docType: "order", sales: true,
        orderId: orderId, statusId: 'FinDocApproved'
    };

    response = await axios.patch(baseUrl + 'FinDoc',
        {
            finDoc
        },
        {
            headers: {
                'Content-Type': 'application/json',
                'api_key': apiKey
            }
        });
    if (response.status == 200) return response.data.finDoc;

}
async function approveBackendShipment(apiKey, shipmentId) {
    let finDoc = {
        docType: "shipment", sales: true,
        shipmentId: shipmentId, statusId: 'FinDocApproved'
    };

    response = await axios.patch(baseUrl + 'FinDoc',
        {
            finDoc
        },
        {
            headers: {
                'Content-Type': 'application/json',
                'api_key': apiKey
            }
        });
    if (response.status == 200) return response.data.finDoc;

}
async function completeBackendShipment(apiKey, shipmentId) {
    let finDoc = {
        docType: "shipment", sales: true,
        shipmentId: shipmentId, statusId: 'FinDocCompleted'
    };
    response = await axios.patch(baseUrl + 'FinDoc',
        {
            finDoc
        },
        {
            headers: {
                'Content-Type': 'application/json',
                'api_key': apiKey
            }
        });
    if (response.status == 200) return response.data.finDoc;

}
async function login(driver, email) {
    await tapByLink(driver, "Log In")
    await enterTextByKey(driver, 'username', email)
    await enterTextByKey(driver, 'password', 'qqqqqq9!')
    await tapByKey(driver, "loginButton")
}
async function register(driver, firstName, lastName, email) {
    await tapByLink(driver, "Register")
    await enterTextByKey(driver, 'firstName', firstName)
    await enterTextByKey(driver, 'lastName', lastName)
    await enterTextByKey(driver, 'email', email)
    await tapByKey(driver, "create")
}
async function logout(driver, firstName, lastName) {
    await tapByLink(driver, firstName + ' ' + lastName)
    await tapByKey(driver, "logout")
}


// low level functions
function getCurrentTestData() {
    try {
        return require('../current_test_data.json')
    } catch (error) {
        return {};
    }
}
function saveCurrentTestData(testData) {
    const fs = require("fs");
    fs.writeFile("./current_test_data.json",
        JSON.stringify(testData), (error) => {
            if (error) console.log(error);
        });
}

async function enterTextByKey(driver, key, value) {
    let fieldName = await driver.findElement(By.id(key));
    fieldName.clear();
    fieldName.sendKeys(value)
}

async function tapByKey(driver, key) {
    await driver.findElement(By.id(key)).click()
    await driver.sleep(wait);
}
async function tapByLink(driver, text) {
    await driver.findElement(By.linkText(text)).click()
    await driver.sleep(wait);
}
async function getLinkTextById(driver, key) {
    var orderId = await driver.findElement(By.id(key)).getAttribute("innerHTML")
    return orderId.toString().replace(/\s+/g, '');
}
module.exports = {
    getFreeEmail,
    newCompany,
    register,
    setPaymentApiKey,
    login,
    logout,
    approveBackendOrder,
    approveBackendShipment,
    completeBackendShipment,
    // low
    getCurrentTestData,
    saveCurrentTestData,
    enterTextByKey,
    tapByKey,
    tapByLink,
    getLinkTextById
}