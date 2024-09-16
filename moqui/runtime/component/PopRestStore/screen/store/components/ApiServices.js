var GeoService = {
  getCountries: function () { return axios.get("/rest/s1/pop/geos").then(function (response) { return response.data; }); },
  getRegions: function (geoId) { return axios.get("/rest/s1/pop/geos/" + geoId + "/regions").then(function (response) { return response.data; }); },
  getLocale: function () { return axios.get("/rest/s1/pop/locale").then(function (response) { return response.data; }); },
  getTimeZone: function () { return axios.get("/rest/s1/pop/timeZone").then(function (response) { return response.data; }); }
};

var LoginService = {
  login: function (user, headers) { return axios.post("/rest/s1/pop/login", user, headers).then(function (response) { return response.data; }); },
  loginFB: function (user, headers) { return axios.post("/rest/s1/pop/loginFB", user, headers).then(function (response) { return response.data; }); },
  createAccount: function (account, headers) {
    account.classificationId = 'AppEcommerceShop';
    account.user = {
      email: account.emailAddress, firstName: account.firstName, lastName: account.lastName,
      userGroupId: 'GROWERP_M_CUSTOMER', companyName: account.companyName,
      loginName: account.emailAddress, password: account.password,
    }
    return axios.post("/rest/s1/growerp/100/RegisterWebsite", account, headers).then(function (response) { return response.data; });
  },
  logout: function () { return axios.get("/rest/s1/pop/logout").then(function (response) { return response.data; }); },
  resetPassword: function (username, headers) { return axios.post("/rest/s1/pop/resetPassword", username, headers).then(function (response) { return response.data; }); }
};

var CustomerService = {
  getShippingAddresses: function (headers) {
    const t = new Date().getTime();
    return axios.get("/rest/s1/pop/customer/shippingAddresses?timeStamp=" + t, headers).then(function (response) { return response.data; });
  },
  addShippingAddress: function (address, headers) {
    return axios.put("/rest/s1/pop/customer/shippingAddresses", address, headers).then(function (response) { return response.data; });
  },
  getPaymentMethods: function (headers) {
    const t = new Date().getTime();
    return axios.get("/rest/s1/pop/customer/paymentMethods?timeStamp=" + t, headers).then(function (response) { return response.data; });
  },
  addPaymentMethod: function (paymentMethod, headers) {
    return axios.put("/rest/s1/pop/customer/paymentMethods", paymentMethod, headers).then(function (response) { return response.data; });
  },
  getCustomerOrders: function (headers) {
    return axios.get("/rest/s1/pop/customer/orders", headers).then(function (response) { return response.data; })
  },
  getCustomerOrderById: function (orderId, headers) {
    return axios.get("/rest/s1/pop/customer/orders/" + orderId, headers).then(function (response) { return response.data; });
  },
  getCustomerInfo: function (headers) {
    return axios.get("/rest/s1/pop/customer/info").then(function (response) { return response.data; });
  },
  updateCustomerInfo: function (customerInfo, headers) {
    return axios.put("/rest/s1/pop/customer/updateInfo", customerInfo, headers).then(function (response) { return response.data; });
  },
  updateCustomerPassword: function (customerInfo, headers) {
    return axios.put("/rest/s1/pop/customer/updatePassword", customerInfo, headers).then(function (response) { return response.data; });
  },
  deletePaymentMethod: function (paymentMethodId, headers) {
    return axios.delete("/rest/s1/pop/customer/paymentMethods/" + paymentMethodId, headers).then(function (response) { return response.data; });
  },
  deleteShippingAddress: function (contactMechId, contactMechPurposeId, headers) {
    return axios.delete("/rest/s1/pop/customer/shippingAddresses?contactMechId=" + contactMechId + "&contactMechPurposeId=" + contactMechPurposeId, headers)
      .then(function (response) { return response.data; });
  }
};

var ProductService = {
  getFeaturedProducts: function () {
    return axios.get("/rest/s1/pop/categories/PopcAllProducts/products").then(function (response) { return response.data.productList; });
  },
  getProductBySearch: function (searchTerm, pageIndex, pageSize, categoryId) {
    var params = "term=" + searchTerm + "&pageIndex=" + pageIndex + "&pageSize=" + pageSize;
    if (categoryId && categoryId.length) params += "&productCategoryId=" + categoryId;
    return axios.get("/rest/s1/pop/products/search?" + params).then(function (response) { return response.data; });
  },
  getProductsByCategory: function (categoryId, pageIndex, pageSize) {
    var params = "?pageIndex=" + pageIndex + "&pageSize=" + pageSize;
    return axios.get("/rest/s1/pop/categories/" + categoryId + "/products" + params).then(function (response) { return response.data; });
  },
  getCategoryInfoById: function (categoryId) {
    return axios.get("/rest/s1/pop/categories/" + categoryId + "/info").then(function (response) { return response.data; });
  },
  getSubCategories: function (categoryId) {
    return axios.get("/rest/s1/pop/categories/" + categoryId + "/info").then(function (response) { return response.data.subCategoryList; });
  },
  getProduct: function (productId) {
    return axios.get("/rest/s1/pop/products/" + productId).then(function (response) { return response.data; });
  },
  getProductContent: function (productId, contentTypeEnumId) {
    return axios.get("/rest/s1/pop/products/content?productId=" + productId + "&productContentTypeEnumId=" + contentTypeEnumId)
      .then(function (response) { return response.data; });
  },
  addProductCart: function (product, headers) {
    return axios.post("/rest/s1/pop/cart/add", product, headers).then(function (response) { return response.data; });
  },
  getCartInfo: function (headers) {
    const t = new Date().getTime();
    return axios.get("/rest/s1/pop/cart/info?timeStamp=" + t, headers).then(function (response) { return response.data; });
  },
  addCartBillingShipping: function (data, headers) {
    return axios.post("/rest/s1/pop/cart/billingShipping", data, headers).then(function (response) { return response.data; });
  },
  getCartShippingOptions: function (headers) {
    return axios.get("/rest/s1/pop/cart/shippingOptions", headers).then(function (response) { return response.data; });
  },
  placeCartOrder: function (data, headers) {
    return axios.post("/rest/s1/pop/cart/place", data, headers).then(function (response) { return response.data; });
  },
  updateProductQuantity: function (data, headers) {
    return axios.post("/rest/s1/pop/cart/updateProductQuantity", data, headers).then(function (response) { return response.data; });
  },
  deleteOrderProduct: function (orderId, orderItemSeqId, headers) {
    return axios.delete("/rest/s1/pop/cart/deleteOrderItem?orderId=" + orderId + "&orderItemSeqId=" + orderItemSeqId, headers)
      .then(function (response) { return response.data; });
  },
  addPromoCode: function (data, headers) {
    return axios.post("/rest/s1/pop/cart/promoCode", data, headers).then(function (response) { return response.data; });
  },
  deletePromoCode: function (data, headers) {
    return axios.delete("/rest/s1/pop/cart/promoCode", { data: data, headers: headers })
      .then(function (response) { return response.data; });
  }
};
