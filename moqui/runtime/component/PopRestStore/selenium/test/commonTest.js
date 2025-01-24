

import { By } from 'selenium-webdriver'
let wait = 2000;

export async function enterTextByKey(driver, key, value) {
    let fieldName = await driver.findElement(By.id(key));
    fieldName.clear();
    fieldName.sendKeys(value)
}

export async function tapByKey(driver, key) {
    await driver.findElement(By.id(key)).click()
    await driver.sleep(wait);
}
