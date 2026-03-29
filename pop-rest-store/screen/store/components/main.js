/* This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License. */
var preLoginRoute = {};
var appObjects = {
    // see https://router.vuejs.org/en/essentials/history-mode.html
    // for route path expressions see https://router.vuejs.org/en/essentials/dynamic-matching.html AND https://github.com/vuejs/vue-router/blob/dev/examples/route-matching/app.js
    router: new VueRouter({
        // TODO sooner or later: base: storeConfig.basePath, mode: 'history',
        routes: [
            { path: "/login/:ownerPartyId/:step?", name: "login", component: storeComps.LoginPageTemplate, 
               beforeEnter: function(to, from, next){
                    preLoginRoute = from;
                    next();
               } },
            { path: "/checkout/:ownerPartyId/:step?", name: "checkout", component: storeComps.CheckOutPageTemplate },
            { path: "/checkout/success/:orderId", name: "successcheckout", component: storeComps.SuccessCheckOutTemplate },
            { path: "/orders/:orderId", name: "order", component: storeComps.CustomerOrderPageTemplate },
            { path: "/orders", name: "orders", component: storeComps.CustomerOrdersPageTemplate },
            { path: "/account", name: "account", component: storeComps.AccountPageTemplate },
            { path: "/account/create/:ownerPartyId", name: "createaccount", component: storeComps.CreateAccountPageTemplate },
            { path: "/resetPassword/:ownerPartyId", name: "resetPassword", component: storeComps.ResetPasswordTemplate },
            { path: "/", redirect: "/login/:ownerPartyId/:step?" }
        ]
    }),
    App: {
        name: "app",
        template: '<div id="app"><router-view></router-view></div>',
        data: function() { return {}; }, components: {}
    }
};

const fixIdScrolling = {
    watch: {
        $route: function(to, from) {
            const currentRoute = this.$router.currentRoute;
            const idToScrollTo = currentRoute.hash;
            this.$nextTick(function(){
                if (idToScrollTo && document.querySelector(idToScrollTo)) {
                    document.querySelector(idToScrollTo).scrollIntoView();
                }
            });
        },
    },
};
// TODO: leave this, reminder to use vue.min.js for production: Vue.config.productionTip = false;

var storeApp = new Vue({
    mixins: [fixIdScrolling],
    el: "#app",
    router: appObjects.router,
    // state: { categories: [], user: null },
    data: {
        storeComps: storeComps, storeConfig: storeConfig,
        storeInfo: storeInfo, categoryList: storeInfo.categoryList, categoryByType: storeInfo.categoryByType,
        preLoginRoute: null,
        // apiKey null unless user is logged in
        apiKey: null,
        // session token for all non-get requests when no user is logged in (no api_key is passed)
        moquiSessionToken: null,
        // userInfo null unless user is logged in, then has response from /customer/info
        customerInfo: storeInfo.customerInfo,
        cartInfo: null
    },
    template: "<App/>",
    components: { App:appObjects.App },
    mounted: function () {
        if (this.storeConfig.storeName && this.storeConfig.storeName.length) document.title = this.storeConfig.storeName;
        var storeInfo = this.storeInfo;
        if (storeInfo.apiKey && storeInfo.apiKey.length) { this.apiKey = storeInfo.apiKey; storeInfo.apiKey = null; }
        if (storeInfo.moquiSessionToken && storeInfo.moquiSessionToken.length) {
            this.moquiSessionToken = storeInfo.moquiSessionToken; storeInfo.moquiSessionToken = null; }
        if (storeInfo.customerInfo && storeInfo.customerInfo.partyId) {
            this.customerInfo = storeInfo.customerInfo; storeInfo.customerInfo = null; }
    }
});
