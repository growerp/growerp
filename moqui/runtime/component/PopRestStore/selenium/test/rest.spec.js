const axios = require('axios')
const { expect } = require('chai')

describe("Get GrowERP ping", async () => {
    it("Get Ping", async () => {
        const response = await axios.get('http://localhost:8080/rest/s1/growerp/100/Ping', { //calling the get API
            headers: {
                'Content-Type': 'application/json',
            }
        });
        console.log(response.data);
        expect(response.status).equals(200); //asserting if the response code is 200
    })
})