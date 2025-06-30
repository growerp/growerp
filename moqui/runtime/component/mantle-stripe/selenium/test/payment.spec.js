const { Builder, By, Key, until } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

(async function paymentTest() {
    let driver;
    try {
        let options = new chrome.Options();
        options.addArguments('--headless');
        options.addArguments('--no-sandbox');
        options.addArguments('--disable-dev-shm-usage');
        
        driver = await new Builder()
            .forBrowser('chrome')
            .usingServer('http://selenium-hub:4444/wd/hub')
            .setChromeOptions(options)
            .build();
        
        await driver.get('http://host.docker.internal:8080/stripe_payment');

        await driver.findElement(By.id('firstName')).sendKeys('John');
        await driver.findElement(By.id('lastName')).sendKeys('Doe');
        await driver.findElement(By.id('email')).sendKeys('john.doe@example.com');
        await driver.findElement(By.id('coupon')).sendKeys('BLACKFRIDAY');
        
        await driver.switchTo().frame(0);
        const cardElement = await driver.findElement(By.css('input[name="cardnumber"]'));
        await cardElement.sendKeys('4242', Key.TAB, '4242', Key.TAB, '4242', Key.TAB, '4242');
        await driver.findElement(By.css('input[name="exp-date"]')).sendKeys('12 / 25');
        await driver.findElement(By.css('input[name="cvc"]')).sendKeys('123');
        await driver.switchTo().defaultContent();

        await driver.findElement(By.id('submit')).click();

    } catch (e) {
        console.error(e);
    } finally {
        if (driver) {
            await driver.quit();
        }
    }
})();