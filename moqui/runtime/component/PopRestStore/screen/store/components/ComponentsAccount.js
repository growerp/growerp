/* This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License. */
var STORE_COUNTRY = "THA";
var ACCOUNT_CREATED = "accountCreated";
var ACCOUNT_UPDATED = "accountUpdated";


storeComps.LoginPage = {
    name: "login",
    data: function () {
        var user = { ownerPartyId: this.$route.params.ownerPartyId, username: this.$root.username, password: "" };
        if (window.location.href.indexOf("localhost") >= 0) {
            user.username = this.$root.username ? this.$root.username : 'test1@example.com'
            user.password = 'qqqqqq9!';
        }
        return {
            ownerPartyId: this.$route.params.ownerPartyId,
            homePath: "", user: user, loginErrormessage: "", responseMessage: "",
            passwordInfo: { username: "", oldPassword: "", newPassword: "", newPasswordVerify: "" },
            axiosConfig: {
                headers: {
                    "Content-Type": "application/json;charset=UTF-8", "Access-Control-Allow-Origin": "*",
                    "moquiSessionToken": this.$root.moquiSessionToken
                }
            }
        };
    },
    computed: {
        apiKey: function () { return this.$root.apiKey }
    },
    methods: {
        login: function () {
            if (this.user.username.length < 3 || this.user.password.length < 3) {
                this.loginErrormessage = "You must type a valid Username and Password";
                return;
            }
            LoginService.login(this.user, this.axiosConfig).then(function (data) {
                if (data.forcePasswordChange == true) {
                    this.showModal('modal');
                } else {
                    this.$root.apiKey = data.apiKey;
                    this.$root.moquiSessionToken = data.moquiSessionToken;
                    if (preLoginRoute.name == null || preLoginRoute.name == "createaccount") {
                        this.$router.push({ name: "account" });
                    } else {
                        this.$router.push({ name: preLoginRoute.name });
                    }
                }
            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.loginErrormessage = error.response.data.errors;
            }.bind(this));
        },
        checkLoginState: function () {
            FB.login(function (response) {
                if (response && response.status == 'connected') {
                    $.ajax({
                        type: "GET",
                        url: 'https://graph.facebook.com/v3.3/me?fields=id,first_name,last_name,email',
                        data: { 'access_token': response.authResponse.accessToken },
                        success: function (result) {
                            var userData = {
                                firstName: result.first_name,
                                lastName: result.last_name,
                                email: result.email
                            };
                            LoginService.loginFB(userData, this.axiosConfig).then(function (data) {
                                this.$root.moquiSessionToken = data.moquiSessionToken;

                                if (!data.apiKey) {
                                    window.location.reload();
                                } else {
                                    this.$root.apiKey = data.apiKey;
                                    this.$router.push({ name: "account" });
                                }
                            }.bind(this));
                        }.bind(this),
                        error: function (error) { console.error(error) }
                    });
                } else {
                    console.error(response);
                }
            }.bind(this), { scope: 'public_profile,email' });
        },
        changePassword: function (event) {
            event.preventDefault();

            var hasNumber = '(?=.*[0-9])';
            // var hasLowercaseChar = '(?=.*[a-z])';
            // var hasUppercaseChar = '(?=.*[A-Z])';
            var hasSpecialChar = '(?=.*[\\W_])';
            var expreg = new RegExp('^' + hasNumber /* + hasLowercaseChar + hasUppercaseChar */ + hasSpecialChar + '.{8,35}$');

            if (this.passwordInfo.username == null || this.passwordInfo.username.trim() == "") {
                this.responseMessage = "You must enter a valid username";
                return;
            }

            if (!expreg.test(this.passwordInfo.newPassword)) {
                this.responseMessage = "The password must have at least 8 characters, including a special character and a number.";
                return;
            }

            if (this.passwordInfo.newPassword !== this.passwordInfo.newPasswordVerify) {
                this.responseMessage = "Passwords do not match";
                return;
            }
            CustomerService.updateCustomerPassword(this.passwordInfo, this.axiosConfig).then(function (data) {
                this.user.username = this.passwordInfo.username;
                this.user.password = this.passwordInfo.newPassword;
                this.login();
            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.responseMessage = error.response.data.errors;
            }.bind(this));
        },
        showModal: function (modalId) { $('#' + modalId).modal('show'); },
    },
    mounted: function () {
        if (this.$root.apiKey != null) {
            if (localStorage.redirect == 'checkout') {
                localStorage.removeItem("redirect");
                this.$router.push({ name: 'checkout' });
            } else {
                this.$router.push({ name: 'account' });
            }
        }
    },
};
storeComps.LoginPageTemplate = getPlaceholderRoute("template_client_login", "LoginPage");

storeComps.ResetPasswordPage = {
    name: "reset-password",
    data: function () {
        return {
            ownerPartyId: this.$route.params.ownerPartyId,
            homePath: "", data: { username: "" },
            passwordInfo: { username: "", oldPassword: "", newPassword: "", newPasswordVerify: "" },
            nextStep: 0, responseMessage: "",
            axiosConfig: {
                headers: {
                    "Content-Type": "application/json;charset=UTF-8", "Access-Control-Allow-Origin": "*",
                    "moquiSessionToken": this.$root.moquiSessionToken
                }
            }
        };
    },
    methods: {
        resetPassword: function (event) {
            event.preventDefault();
            LoginService.resetPassword(this.data, this.axiosConfig).then(function (data) {
                this.nextStep = 1;
                this.responseMessage = "";
            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.responseMessage = error.response.data.errors;
            }.bind(this));
        },
        changePassword: function (event) {
            event.preventDefault();

            var hasNumber = '(?=.*[0-9])';
            // var hasLowercaseChar = '(?=.*[a-z])';
            // var hasUppercaseChar = '(?=.*[A-Z])';
            var hasSpecialChar = '(?=.*[\\W_])';
            var expreg = new RegExp('^' + hasNumber /* + hasLowercaseChar + hasUppercaseChar */ + hasSpecialChar + '.{8,35}$');

            if (!expreg.test(this.passwordInfo.newPassword)) {
                this.responseMessage = "The password must have at least 8 characters, including a special character and a number.";
                return;
            }

            if (this.passwordInfo.newPassword !== this.passwordInfo.newPasswordVerify) {
                this.responseMessage = "Passwords do not match";
                return;
            }
            this.passwordInfo.username = this.data.username;
            CustomerService.updateCustomerPassword(this.passwordInfo, this.axiosConfig).then(function (data) {
                this.responseMessage = data.messages;
                this.login();
            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.responseMessage = error.response.data.errors;
            }.bind(this));
        },
        login: function () {
            var user = { username: this.passwordInfo.username, password: this.passwordInfo.newPassword };
            LoginService.login(user, this.axiosConfig).then(function (data) {
                this.$root.apiKey = data.apiKey;
                this.$root.moquiSessionToken = data.moquiSessionToken;
                this.$router.push({ name: 'account' });
            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.errorMessage = error.response.data.errors;
            }.bind(this));
        }
    },
    mounted: function () {
        this.$nextTick(function () {
            this.nextStep = this.$route.query.step ? this.$route.query.step : 0;
            if (this.nextStep == 2) {
                this.data.username = this.$route.query.username ? this.$route.query.username : "";
            }
        });
    }
};
storeComps.ResetPasswordTemplate = getPlaceholderRoute("template_client_resetPassword", "ResetPasswordPage");

storeComps.AccountPage = {
    name: "account-page",
    data: function () {
        return {
            homePath: "", customerInfo: {}, passwordInfo: {}, shippingAddressList: [],
            countriesList: [], regionsList: [], localeList: [], timeZoneList: [],
            shippingAddress: {}, addressOption: "", customerPaymentMethods: [],
            paymentAddressOption: {}, paymentOption: "", paymentMethod: {},
            responseMessage: "",
            toNameErrorMessage: "", countryErrorMessage: "", addressErrorMessage: "",
            cityErrorMessage: "", stateErrorMessage: "", postalCodeErrorMessage: "", contactNumberErrorMessage: "",
            isUpdate: false, message: { state: "", message: "" },
            axiosConfig: {
                headers: {
                    "Content-Type": "application/json;charset=UTF-8", "Access-Control-Allow-Origin": "*",
                    "api_key": this.$root.apiKey, "moquiSessionToken": this.$root.moquiSessionToken
                }
            }
        };
    },
    methods: {
        getCustomerInfo: function () {
            CustomerService.getCustomerInfo(this.axiosConfig)
                .then(function (data) { this.setCustomerInfo(data); }.bind(this));
        },
        getCustomerAddresses: function () {
            CustomerService.getShippingAddresses(this.axiosConfig)
                .then(function (data) { this.shippingAddressList = data.postalAddressList; }.bind(this));
        },
        getCustomerPaymentMethods: function () {
            CustomerService.getPaymentMethods(this.axiosConfig)
                .then(function (data) {
                    this.customerPaymentMethods = data.methodInfoList.filter(function (method) {
                        return method.isCreditCard
                    });
                }.bind(this));
        },

        resetData: function () {
            this.paymentMethod = {};
            this.shippingAddress = {};
            this.paymentAddressOption = {};
            this.isUpdate = false;
            this.shippingAddress.countryGeoId = 'THA';
        },
        updateCustomerInfo: function () {
            if (this.customerInfo.username == null || this.customerInfo.username.trim() === "") {
                this.message.state = 2;
                this.message.message = "Please provide username";
                return;
            }
            if (this.customerInfo.firstName == null || this.customerInfo.firstName.trim() === ""
                || this.customerInfo.lastName == null || this.customerInfo.lastName.trim() === "") {
                this.message.state = 2;
                this.message.message = "Please provide first and last name";
                return;
            }
            if (this.customerInfo.emailAddress == null || this.customerInfo.emailAddress.trim() === "") {
                this.message.state = 2;
                this.message.message = "Please provide a valid email address";
                return;
            }
            CustomerService.updateCustomerInfo(this.customerInfo, this.axiosConfig).then(function (data) {
                this.setCustomerInfo(data.customerInfo);
                this.message.state = 1;
                this.message.message = "Correct! Your data has been updated.";
                var event = new CustomEvent(ACCOUNT_UPDATED, {
                    detail: {
                        "firstName": this.customerInfo.firstName.trim(), "lastName": this.customerInfo.lastName.trim(),
                        "emailAddress": this.customerInfo.emailAddress.trim()
                    }
                });
                window.dispatchEvent(event);
            }.bind(this));
        },
        setCustomerInfo: function (data) {
            this.customerInfo.username = data.username;
            this.customerInfo.partyId = data.partyId;
            this.customerInfo.firstName = data.firstName;
            this.customerInfo.lastName = data.lastName;
            this.customerInfo.emailAddress = data.emailAddress;
            this.customerInfo.companyName = data.companyName;
            this.customerInfo.companyPartyId = data.companyPartyId;
            //        this.customerInfo.contactMechId = data.telecomNumber ? data.telecomNumber.contactMechId : "";
            //        this.customerInfo.contactNumber = data.telecomNumber ? data.telecomNumber.contactNumber : "";
        },
        updateCustomerPassword: function (event) {
            event.preventDefault();

            var hasNumber = '(?=.*[0-9])';
            // var hasLowercaseChar = '(?=.*[a-z])';
            // var hasUppercaseChar = '(?=.*[A-Z])';
            var hasSpecialChar = '(?=.*[\\W_])';
            var expreg = new RegExp('^' + hasNumber /* + hasLowercaseChar + hasUppercaseChar */ + hasSpecialChar + '.{8,35}$');

            if (!expreg.test(this.passwordInfo.newPassword)) {
                this.responseMessage = "The password must have at least 8 characters, including a special character and a number.";
                return;
            }

            if (this.passwordInfo.newPassword !== this.passwordInfo.newPasswordVerify) {
                this.responseMessage = "Passwords do not match";
                return;
            }

            this.passwordInfo.userId = this.customerInfo.userId;

            CustomerService.updateCustomerPassword(this.passwordInfo, this.axiosConfig).then(function (data) {
                this.responseMessage = data.messages.replace("null", this.customerInfo.username);
                this.passwordInfo = {};
            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.responseMessage = "An error occurred: " + error.response.data.errors;
            }.bind(this));
        },
        scrollTo: function (refName) {
            if (refName == null) {
                window.scrollTo(0, 0);
            } else {
                var element = this.$refs[refName];
                var top = element.offsetTop;
                window.scrollTo(0, top);
            }
        },
        deletePaymentMethod: function (paymentMethodId) {
            CustomerService.deletePaymentMethod(paymentMethodId, this.axiosConfig).then(function (data) {
                this.getCustomerPaymentMethods();
                this.hideModal("modal5");
            }.bind(this));
        },
        deleteShippingAddress: function (contactMechId, contactMechPurposeId) {
            CustomerService.deleteShippingAddress(contactMechId, contactMechPurposeId, this.axiosConfig).then(function (data) {
                this.getCustomerAddresses();
                this.hideModal("modal4");
            }.bind(this));
        },
        getCountries: function () { GeoService.getCountries().then(function (data) { this.countriesList = data.resultList; }.bind(this)); },
        getRegions: function (geoId) { GeoService.getRegions(geoId).then(function (data) { this.regionsList = data.resultList; }.bind(this)); },
        getLocale: function () { GeoService.getLocale().then(function (data) { this.localeList = data.localeStringList; }.bind(this)); },
        getTimeZone: function () { GeoService.getTimeZone().then(function (data) { this.timeZoneList = data.timeZoneList; }.bind(this)); },
        selectAddress: function (address) {
            this.shippingAddress = {};
            this.shippingAddress.address1 = address.postalAddress.address1;
            this.shippingAddress.address2 = address.postalAddress.address2;
            this.shippingAddress.toName = address.postalAddress.toName;
            this.shippingAddress.city = address.postalAddress.city;
            this.shippingAddress.countryGeoId = address.postalAddress.countryGeoId;
            //            this.shippingAddress.contactNumber = address.telecomNumber.contactNumber;
            this.shippingAddress.postalCode = address.postalAddress.postalCode;
            this.shippingAddress.stateProvinceGeoId = address.postalAddress.stateProvinceGeoId;
            this.shippingAddress.postalContactMechId = address.postalContactMechId;
            //            this.shippingAddress.telecomContactMechId = address.telecomContactMechId;
            this.shippingAddress.postalContactMechPurposeId = address.postalContactMechPurposeId;
            this.shippingAddress.attnName = address.postalAddress.attnName;
            this.responseMessage = "";
        },

        selectPaymentMethod: function (method) {
            this.paymentMethod = {};
            this.paymentMethod.paymentMethodId = method.paymentMethodId;
            this.paymentMethod.paymentMethodTypeEnumId = method.paymentMethod.PmtCreditCard;
            this.paymentMethod.cardNumber = method.creditCard.cardNumber;
            this.paymentMethod.titleOnAccount = method.paymentMethod.titleOnAccount;
            this.paymentMethod.expireMonth = method.expireMonth;
            this.paymentMethod.expireYear = method.expireYear;
            this.paymentMethod.postalContactMechId = method.paymentMethod.postalContactMechId;
            //            this.paymentMethod.telecomContactMechId = method.paymentMethod.telecomContactMechId;

            this.paymentMethod.address1 = method.postalAddress.address1;
            this.paymentMethod.address2 = method.postalAddress.address2;
            this.paymentMethod.toName = method.postalAddress.toName;
            this.paymentMethod.city = method.postalAddress.city;
            this.paymentMethod.countryGeoId = method.postalAddress.countryGeoId;
            //            this.paymentMethod.contactNumber = method.telecomNumber ? method.telecomNumber.contactNumber : "";
            this.paymentMethod.postalCode = method.postalAddress.postalCode;
            this.paymentMethod.stateProvinceGeoId = method.postalAddress.stateProvinceGeoId;

            this.getRegions(STORE_COUNTRY);
            this.getCountries();

            this.paymentMethod.cardSecurityCode = "";
            this.responseMessage = "";
        },
        hideModal: function (modalid) { $('#' + modalid).modal('hide'); },

        onAddressCancel: function () {
            this.hideModal("addressModal");
        },

        onAddressUpserted: function (address) {
            this.getCustomerAddresses();
            this.hideModal("addressModal");
        },

        onCreditCardCancel: function () {
            this.hideModal("creditCardModal");
        },

        onCreditCardSet: function () {
            this.getCustomerPaymentMethods();
            this.hideModal("creditCardModal");
        }
    },
    mounted: function () {
        if (this.$root.apiKey == null) {
            this.$router.push({ name: 'login' });
        } else {
            this.homePath = storeConfig.homePath;
            this.getCustomerInfo();
            this.getCustomerAddresses();
            this.getCustomerPaymentMethods();
            this.getCountries();
            this.getRegions(STORE_COUNTRY);
            this.getLocale();
            this.getTimeZone();
            this.onAddressUpserted();
        }
    }
};
storeComps.AccountPageTemplate = getPlaceholderRoute("template_client_account", "AccountPage");

storeComps.CreateAccountPage = {
    name: "create-account",
    data: function () {
        var accountInfo = {};
        if (window.location.href.indexOf("localhost") >= 0) {
            accountInfo = { firstName: 'John', lastName: 'Denver', emailAddress: 'test1@example.com' };
            if (this.$root.username) accountInfo.emailAddres = this.$root.username;
            accountInfo.newPassword = 'qqqqqq9!';
        }
        accountInfo.ownerPartyId = this.$route.params.ownerPartyId;
        return {
            homePath: "", accountInfo: accountInfo, confirmPassword: "", errorMessage: "",
            axiosConfig: {
                headers: {
                    "Content-Type": "application/json;charset=UTF-8", "Access-Control-Allow-Origin": "*",
                    "moquiSessionToken": this.$root.moquiSessionToken
                }
            }
        };
    },
    methods: {
        createAccount: function (event) {
            event.preventDefault();
            var emailValidation = /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;
            var hasNumber = '(?=.*[0-9])';
            // var hasLowercaseChar = '(?=.*[a-z])';
            // var hasUppercaseChar = '(?=.*[A-Z])';
            var hasSpecialChar = '(?=.*[\\W_])';
            var expreg = new RegExp('^' + hasNumber /* + hasLowercaseChar + hasUppercaseChar */ + hasSpecialChar + '.{8,35}$');

            if (this.accountInfo.firstName == null || this.accountInfo.firstName.trim() === ""
                || this.accountInfo.lastName == null || this.accountInfo.lastName.trim() === ""
                || this.accountInfo.emailAddress == null || this.accountInfo.emailAddress.trim() === "") {
                this.errorMessage = "Verify the required fields";
                return;
            }

            if (!emailValidation.test(this.accountInfo.emailAddress)) {
                this.errorMessage = "Insert a valid email.";
                return;
            }
            this.$root.username = this.accountInfo.emailAddress;
            LoginService.createAccount(this.accountInfo, this.axiosConfig).then(function (data) {
                var event = new CustomEvent(ACCOUNT_CREATED, {
                    detail: {
                        "firstName": this.accountInfo.firstName.trim(),
                        "lastName": this.accountInfo.lastName.trim(),
                        "emailAddress": this.accountInfo.emailAddress.trim()
                    }
                });
                window.dispatchEvent(event);
                this.$router.push({ name: 'login' });
            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.errorMessage = "An error occurred: " + error.response.data.errors;
            }.bind(this));
        },
        login: function (userName, password) {
            var user = { username: userName, password: password };
            LoginService.login(user, this.axiosConfig).then(function (data) {
                this.$root.apiKey = data.apiKey;
                this.$root.moquiSessionToken = data.moquiSessionToken;
                if (localStorage.redirect == 'checkout') {
                    localStorage.removeItem("redirect");
                    this.$router.push({ name: 'checkout' });
                } else {
                    this.$router.push({ name: 'account' });
                }

            }.bind(this)).catch(function (error) {
                if (!!error.response.headers.moquisessiontoken) {
                    this.axiosConfig.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                    this.$root.moquiSessionToken = error.response.headers.moquisessiontoken;
                }
                this.errorMessage = error.response.data.errors;
            }.bind(this));
        }
    },
    mounted: function () {
        // If this user is logged in, send to account
        if (this.$root.apiKey != null) {
            this.$router.push({ name: 'account' });
        } else {
            this.homePath = storeConfig.homePath;
        }
    },
};
storeComps.CreateAccountPageTemplate = getPlaceholderRoute("template_client_accountCreate", "CreateAccountPage");

storeComps.CustomerOrderPage = {
    name: "customerorder-page",
    data: function () {
        return {
            homePath: "", ordersList: [], orderList: {}, currencyFormat: "",
            axiosConfig: {
                headers: {
                    "Content-Type": "application/json;charset=UTF-8", "Access-Control-Allow-Origin": "*",
                    "api_key": this.$root.apiKey, "moquiSessionToken": this.$root.moquiSessionToken
                }
            }
        };
    },
    methods: {
        getCustomerOrderById: function () {
            CustomerService.getCustomerOrderById(this.$route.params.orderId, this.axiosConfig).then(function (data) {
                this.orderList = data;
                this.currencyFormat = Intl.NumberFormat('en-US', { style: 'currency', currency: data.orderHeader.currencyUomId });
            }.bind(this));
        },
        getExpectedArrivalDate: function (tt) {
            var date = moment(tt);
            var newdate = new Date(date);

            newdate.setDate(newdate.getDate() + 7);

            var dd = newdate.getDate();
            var mm = newdate.getMonth();
            var yy = newdate.getFullYear();
            months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

            var newDATE = dd + ' ' + months[mm] + ', ' + yy.toString().substring(2);
            return newDATE;
        },
        formatDate: function (dateArg) {
            return moment(dateArg).format('Do MMM, YY');
        }
    },
    mounted: function () {
        if (this.$root.apiKey == null) {
            this.$router.push({ name: 'login' });
        } else {
            this.getCustomerOrderById();
            this.homePath = storeConfig.homePath;
        }
    }
};
storeComps.CustomerOrderPageTemplate = getPlaceholderRoute("template_client_orderDetail", "CustomerOrderPage");

storeComps.CustomerOrdersPage = {
    name: "customerorders-page",
    data: function () {
        return {
            homePath: "", ordersList: [], listProduct: [], currencyFormat: "",
            axiosConfig: {
                headers: {
                    "Content-Type": "application/json;charset=UTF-8", "Access-Control-Allow-Origin": "*",
                    "api_key": this.$root.apiKey, "moquiSessionToken": this.$root.moquiSessionToken
                }
            }
        };
    },
    methods: {
        getCustomerOrders: function () {
            CustomerService.getCustomerOrders(this.axiosConfig).then(function (data) {
                this.ordersList = data.orderInfoList;
                this.currencyFormat = Intl.NumberFormat('en-US', { style: 'currency', currency: this.ordersList[0].currencyUomId });
                this.getCustomerOrderById();
            }.bind(this));
        },
        getCustomerOrderById: function () {
            for (var x in this.ordersList) {
                CustomerService.getCustomerOrderById(this.ordersList[x].orderId, this.axiosConfig).then(function (data) {
                    this.currencyFormat = Intl.NumberFormat('en-US', { style: 'currency', currency: data.orderHeader.currencyUomId });
                    var product = {
                        "orderId": data.orderItemList[0].orderId,
                        "listProduct": data.orderItemList
                    };
                    this.listProduct.push(product);
                }.bind(this));
            }
        },
        scrollTo: function (refName) {
            if (refName == null) {
                window.scrollTo(0, 0);
            } else {
                var element = this.$refs[refName];
                var top = element.offsetTop;
                window.scrollTo(0, top);
            }
        },
        formatDate: function (date) {
            return moment(date).format('Do MMM, YY');
        }
    },
    mounted: function () {
        if (this.$root.apiKey == null) {
            this.$router.push({ name: 'login' });
        } else {
            this.getCustomerOrders();
            this.homePath = storeConfig.homePath;
        }
    }
};
storeComps.CustomerOrdersPageTemplate = getPlaceholderRoute("template_client_orderHistory", "CustomerOrdersPage");
