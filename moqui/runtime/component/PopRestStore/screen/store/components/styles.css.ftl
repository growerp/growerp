/* $theme-colors: ( "primary": #05c3d5, "danger": #de6232, "dark": #333333 ); */

#store-root { font-family: "Aveni", Helvetica, Arial, sans-serif; color: #2c3e50;
    -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale; }

/* General, Bootstrap Overrides */
a:hover { text-decoration: none; }

.modal-title { color: #666666; font-size: 2em; }
.modal-text { color: #666666; }
.modal-text-required { color: #e4845e; }

.btn-continue { background-color: #04c3d5; color: #fff; height: 45px; width: 150px; }

.customer-link { color: #1ec9d9 !important; cursor: pointer; margin-right: 10px; }
.customer-link i { margin-left: 10px; color: #e7e7e7; }

/* Navbar */
.moqui-navbar { width: 100%; background: ${HeaderFooterBg!"#333333"}; text-align: center !important; }
.bg-dark { background: ${HeaderFooterBg!"#333333"} !important; }
.moqui-navbar .moqui-logo { width: 50px; height: 50; margin-top: 10px; margin-right: 30px;}
.moqui-logo1 { margin-top: -30px; margin-left: -10px; }

.moqui-dynamic { width: 60px; margin-top: -20px; margin-left: -10px; margin-right: 30px; }

.navbar-dark .navbar-nav .nav-link { color: ${HeaderFooterText!"#fff"}; }
.navbar-title { margin-top: 10px; margin-left: -20px; display: inline-block; font-size: 2em; color: ${HeaderFooterText!"#fff"}; font-weight: bold; }
.navbar-pop-title { color: #999999; font-size: 1.1em; display: inline-block; }
.navbar-pop-subtitle { display: inline-block; font-size: 0.9em; color: #999999; margin-top: -5px; }

.search-input { width: 70%; margin-left: 45px; position: relative; }
.search-input input { border: none; border-radius: 10px; padding: 10px; width: 100%; height: 40px; text-indent: 10px; }
.search-input input::placeholder{ color:#8c8c8c; }
.search-input .search-button { background: #05c3d5;border: none; border-top-right-radius: 10px; border-bottom-right-radius: 10px;
    height: 100%; padding: 3px 15px; margin-left: -4px; color: #fff; cursor: pointer; position: absolute; top: 0; right: 0;
    font-size: 1.5em; line-height: 0; }

.cart-quantity { width: 20px; height: 20px; font-size: 0.8em; background-color: #dd6231; border-radius: 50%;
    display: inline-block; position: absolute; justify-content: center; align-items: center;
    margin-left: -10px; margin-top: -5px;
}
.item-color { color: #36cfdd !important; cursor: pointer; }

/* Footer */

.footer { background-color: ${HeaderFooterBg!"#fff"}; color: #fff; padding: 30px; position: relative; width: 100%; bottom: 0px;}
.footer p { font-size: 0.8em; color: #04c3d5; }
.footer-ul { list-style-type: none; font-size: 0.8em; }
.footer-ul li { margin-top: 10px; cursor: pointer; }
.footer-follow-text { color: #8d8d8d; }
.footer-icons { font-size: 1.9em; margin-right: 10px; }
.footer-a { color: ${HeaderFooterBg!"#fff"} !important; }

/* Home/Landing */
.features { background: #05c3d5; color: #fff; padding-top: 10px; }
.features .feature { display: flex; }
.features .feature .feature-icon { font-size: 2.5em; margin-top: -5px; }
.features .feature .feature-info { padding: 5px; }
.features .feature .feature-info .subtitle { margin-top: -5px; font-size: 0.7em; }

.category-product { color: #05c3d5 }
.star-rating { color: #ffed00; }

.carousel-inner .carousel-item.active,
.carousel-inner .carousel-item-next,
.carousel-inner .carousel-item-prev { display: flex; }

.carousel-inner .carousel-item-right.active,
.carousel-inner .carousel-item-next { transform: translateX(25%); }

.carousel-inner .carousel-item-left.active, 
.carousel-inner .carousel-item-prev { transform: translateX(-25%); }
  
.carousel-inner .carousel-item-right,
.carousel-inner .carousel-item-left{ transform: translateX(0); }

.carousel-prev, .carousel-next { font-size: 0; line-height: 0; background-color: #04c3d5; 
    position: absolute; top: 50%; display: inline-block; width: 40px; height: 40px; padding: 0; 
    -webkit-transform: translate(0, -50%); -ms-transform: translate(0, -50%); transform: translate(0, -50%); 
    cursor: pointer; color: white; font-size: 2em; border: none; outline: none; border-radius: 50%;
}

.carousel-next { right: -25px; float: right; }

.carousel-prev { left: -25px; z-index: -10000; }

.carousel .carousel-control-prev,
.carousel .carousel-control-next {
width: 20px;
  height: 20px;
  background-color: none;
  top: calc(-20% -25%);
  opacity: .8;
}

.card-1 { display: inline-block; }

.figure-img { border:1px solid #f5f5f5; }

/* Category, Search */
.deals-ul { list-style-type: none; font-size: 1em; margin-left: -40px; }
.deals-ul li { margin-top: 5px; cursor: pointer; }
.deals-ul i { margin-right: 5px; }

.deals-subtitle { color: #a3a3a3; font-size: 0.8em; }
.deals-sellers { background-color: #ccf2f6; height: 40px; align-items: center; display: flex; border-radius: 5px; }
.deals-sortby-text { color: #666666; }
.deals-sortby-text i { margin-right: 10px; font-size: 1.2em; }

/* Product */
.container-text { text-align: left; }

.product-title { color: #666666; font-size: 2.5em; }
.product-star { margin-top: -30px; }
.product-img { cursor: pointer; margin-bottom: 15px !important; }
.product-img:hover { border: 1px solid #b2b2b2; padding: 5px; }
.product-img-select { width: 100%; height: auto; cursor: pointer; }

.product-description { color:#666666 !important; font-size: 0.9em; }
.product-listprice-text { font-size: 0.7em; }
.product-hr { height: 1px; background-color: #d3d3d3; }
.product-cate-text { color: #1ec9d9; }

.review { margin-top: 30px; }
.review-text-size { font-size: 0.9em; }
.review-date { color: #999999; }
.review-text { margin-top: 5px; display: inline-block; color: #666666; }
.review-btn { margin-top: 30px; width: 180px; }

.product-success-text { color: #666666; font-size: 1em; margin-left: 30px; margin-top: 30px; display: inline-block; margin-bottom: 30px; }
.product-checkout-text { color: #1ec9d9 !important; font-size: 1.2em; font-weight: 300; cursor: pointer; margin-right: 15px; margin-top: 5px; }

.product-price-text { color: #dd6231; font-size: 1.2em; }
.product-last-price { color:#666666; font-size: 1.2em; }

.save-circle { background-color: #ffed00; border-radius: 50%; width: 65px; height: 65px; text-align: center; justify-content: center;
    display: flex; align-items: center; font-size: 0.8em; position: absolute; margin-left:70%; margin-top: -10px; }
.save-circle-text { font-size: 0.9em; display: inline-block; position: absolute; margin-top: 8px; }
.save-circle-title { font-size: 0.9em; display: inline-block; position: absolute; margin-top: -8px; }

/* Product Review */
.rating-stars ul { list-style-type:none; padding:0; -moz-user-select:none; -webkit-user-select:none; }
.rating-stars ul > li.star { display:inline-block; cursor: pointer; }
.rating-stars ul > li.star > i.fa { font-size:1em; color:#ccc; }
.rating-stars ul > li.star.hover > i.fa { color:#ffed00; }
.rating-stars ul > li.star.selected > i.fa { color:#ffed00; }
.text-area-review { resize: none; }

/* Checkout */
.change-info { font-size: 0.9em !important; margin-top: 7px; }

.hr { background-color: #666666; height: 1px; margin-top: -10px; }
.hr-active { background-color: #dd6231; height: 1px; margin-top: -10px; }
.hr-complete { background-color: #04c3d5; height: 1px; margin-top: -10px; }

.order-navbar { height: 85px; }
.order-navbar-title { position: absolute; display: inline-block; font-size: 2.3em; color: ${HeaderFooterText!"#fff"}; margin-left: -10px; margin-top: 5px; font-weight: bold; }
.order-navbar-circle { width: 40px; height: 40px; color: #999999; border: 1px solid #999999; border-radius: 50%;
    text-align: center; display: flex; justify-content: center; align-items: center; font-size: 1.5em; }
.order-navbar-circle-red { color: #fff; background-color: #dd6231; border: none; }
.order-navbar-circle-blue { color: #fff; background-color: #04c3d5; border: none; }
.order-navbar-hr { background-color: #666666; height: 1px; margin-top: 1.2rem; }
.order-navbar-text { position: absolute; margin-top: 30px; font-size: 0.6em; }
.order-navbar-text-red { color: #dd6231; }
.order-navbar-text-blue { color: #04c3d5; }

.order-title { font-size: 1.6em; color: #666666; }
.order-link-text { color: #04c3d5; cursor: pointer; }
.order-link-text:hover { color: #04c3d5; }
.btn-keep-shoping:hover { color: #fff; }
.order-text-color { color: #666666; }
.order-status { color: #dd6231; }

.input-quantity { text-align:center; }
.div-total { color: #666666; }

.cart-div { background-color: #e7e7e7; border: none; }
.cart-form-price { text-align: left; margin-top: 15px; overflow: hidden; color: #686868; }
.price-text { color: #de7045; font-size: 1.6em; }
.cart-form-btn { background-color: #dd6231; color: #fff; bottom: -50px; position: absolute;}

.title-product-text { color:#10c6d7; }
.title-check-text { cursor: pointer; margin-top: 15px; }
.title-cart-item { color: #666666 !important; margin-top: 15px; font-size: 1.2em; }

.step-active .circle { color: #fff; background-color: #dd6231; width: 25px; height: 25px; position: absolute; text-align: center; border-radius: 50%; border: none; }
.step-active .text-address { margin-left: 30px; color: #dd6231; font-size: 1.2em; }
.step-complete .circle { color: #fff; background-color: #04c3d5; width: 25px; height: 25px; position: absolute; text-align: center; border-radius: 50%; border: none; }
.step-complete .text-address { margin-left: 30px; color: #04c3d5; font-size: 1.2em; }

.circle { color: #666666; width: 25px; height: 25px; position: absolute; text-align: center; display: flex;
    justify-content: center; align-items: center; border-radius: 50%; border: 1px solid #666666; }

.text-address { margin-left: 30px; color: #666666; font-size: 1.2em; }
.item-text-desc { color: #04c3d5 !important; }

.item-title-text { font-size: 0.8em; }
.order-hr { margin-top: -1px; }
.order-address { margin-top: -5px !important; }
.order-billing-address { margin-top: 30px; }

.container-input { display: block; position: relative; padding-left: 35px; margin-bottom: 12px; margin-top: 2px; color: #666666;
    cursor: pointer; font-size: 1em; user-select: none; }
.container-input input { position: absolute; opacity: 0; }

.checkmark { position: absolute; top: 3px; left: 10px; height: 15px; width: 15px; background-color: #fff;
    border: 1px solid #666666; border-radius: 50%; display: flex; justify-content: center; align-items: center; }
.container-input:hover input ~ .checkmark { background-color: #ccc; }
.container-input input:checked ~ .checkmark { background-color: #e7e7e7; }
.checkmark:after { content: ""; position: absolute; display: none; }
.container-input input:checked ~ .checkmark:after { display: block; }
.container-input .checkmark:after { width: 9px; height: 9px; border-radius: 50%; background: #666666; }
.div-checkmark { background-color: #e7e7e7; border-radius: 5px; padding-top: 10px;}

.span-color span{ color: #adadad !important; }

.phone-icon { transform: rotate(100deg); }
.edit-icon { color: #04c3d5; display: inline-block; right: 40px; margin-top: -85px; position: absolute; cursor: pointer; font-size: 0.8em; }
.delete-icon { color: #04c3d5; display: inline-block; right: 20px; margin-top: -85px; position: absolute; cursor: pointer; font-size: 0.8em; }
.icon-margin-top { margin-top: -70px; }

.link-text { font-size: 0.9em; color: #666666; }
.item-actions { color: #04c3d5; cursor: pointer; font-size: 0.8em; margin-left: 15px; }
.last-price { color: #666666; margin-top: -15px; font-size: 0.9em; }
.text-add { color: #3ad0de !important; cursor: pointer; font-size: 0.9em; margin-top: 10px; margin-right: 17px; }

.address-text { color: #666666; font-size: 0.9em; margin-left: 10px; cursor: pointer; }
.div-billing-address { margin-left: 30px; }
.ul-customer-order { list-style-type: none; margin-left: -25px; }

.btn-place-order { background-color: #dd6231; color: #fff; }
.div-place-order { color: #666666 !important; margin-top: 50px; }
.place-order-total { color: #dd6231 !important; }
.place-order-text { margin-top: -15px; }

.container-input1 { position: relative; margin-left: 5px; margin-right: 10px; margin-bottom: 12px; cursor: pointer; font-size: 1em;
    -webkit-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; }
.container-input1 input { position: absolute; opacity: 0; cursor: pointer; }
.container-input1 input:checked ~ .checkmark-input { background-color: #fff; }
.container-input1 input:checked ~ .checkmark-input:after { display: block; }
.container-input1 .checkmark-input:after { left: 9px; top: 5px; width: 5px; height: 10px; border: solid #04c3d5; border-width: 0 3px 3px 0;
    -webkit-transform: rotate(45deg); -ms-transform: rotate(45deg); transform: rotate(45deg); }

.checkmark-input { position: absolute; top: 0; left: 0; height: 15px; width: 15px; border-radius: 3px; border:1px solid #999999; }
.checkmark-input:after { content: ""; position: absolute; display: none; margin-left: -5px; margin-top: -4px; }

.loader { border: 16px solid #f3f3f3; /* Light grey */ border-top: 16px solid #3498db; /* Blue */
    border-radius: 50%; width: 120px; height: 120px; position: absolute; z-index: 1000;
    vertical-align: middle; animation: spin 2s linear infinite; margin-top: 15%; margin-left: 30%;
}
@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

.body-padding { padding-left: 6rem !important; padding-right: 6rem !important; }
/* Account, Order History */
.account-subtitle { font-size: 1.5em; }
.account-hr { margin-top: -20px; }
/* .account-btn { width: 100%; } */

.account-back-top { color: #1ec9d9 !important; float: right; margin-top: -40px; cursor: pointer; font-size: 0.9em; }
.account-div-container { padding: 10px; }

.left-menu-heading {font-size: 1.1rem; color: #8AC8BE; padding-top: 0.7rem;}
.breakline { border-top: 2px solid #8AC8BE; opacity: 0.3; }
.router-link-active { color: #5FB846; }

.span-description { display: block; margin-top: -5px; }
.span-link { color: #1ec9d9; cursor: pointer; }
.span-link-container { font-size: 0.9em; display: inline-block; margin-left: 35px; }

.color-tab { color: #797979; }

.customer-menu { color: #1ec9d9 !important; border: 1px solid #999999; padding: 15px }
.customer-menu a { color: #1ec9d9 !important; }

.customer-orders-ul { list-style-type: none; font-size: 1em; margin-left: -25px; }
.customer-orders-ul li { margin-top: 5px; cursor: pointer; }

.customer-orders-title { font-size: 2.5em; color: #666666; }

.customer-orders-hr { margin-top: -2px; }
.customer-orders-id { border-radius: 10px 0 0 10px; background-color: #e7e7e7; height: 90px; width: 180px; padding-top: 5px; padding-left: 15px; }
.customer-orders-text { font-size: 1em; color: #1ec9d9; display: inline-block; cursor: pointer; }
.customer-text-date { display: inline-block; font-size: 0.9em; color: #555; }

.order-product-description { display: inline-block; color: #373737; font-size: 0.9em; font-weight: bold; margin-left: -20px; }
.order-product-status { color: #dd6231; font-size: 0.9em; margin-left: -20px; }
.order-product-total { display: inline-block; color: #373737; font-weight: 500; position: absolute; right: 25px; bottom: 50px; }

.orders-back-text { color: #1ec9d9; float: right; cursor: pointer; font-size: 0.9em;}

/* Login, Reset Password, Create Account */
.btn-login { background-color: #04c3d5; color: #fff; height: 45px; }
.btn-create-account { background-color: #dd6231; color: #fff; height: 45px; }
.login-form, .new-customer { color: #666666; }
.login-forgot { float: right; color: #04c3d5; font-size: 0.8em; }

.split { height: 300px; width: 1px; background-color: #bfbfbf; }
.split-reset { height: 90px; width: 1px; background-color: #bfbfbf; }
.split-account { margin-top: 40px; height: 120px; width: 1.5px; float: right; background-color: #bfbfbf; }

.account-container { color: #666666; }
.sign-in { color: #04c3d5; margin-top: -15px; cursor: pointer; }
.already-text { margin-top: 80px; }
.reset-text { color: #848484; margin-left: -40px; }
.reset-link { color: #30cedc; }
.reset-link:hover { color: #30cedc; }

.next-step { cursor: pointer; font-size: 0.8em; color: #a8a8a8; }

/* utilities, empty page: simple CSS spinner, to use: <div class="spinner"><div>Loading…</div></div> */
@keyframes spin { to { transform: rotate(1turn); } }
.spinner { position: relative; display: inline-block; width: 5em; height: 5em; margin: 0 0; font-size: 12px; text-indent: 999em;
    overflow: hidden; animation: spin 1s infinite steps(8); }
.spinner.small { font-size: 6px; } .spinner.large { font-size: 18px; }
.spinner:before, .spinner:after, .spinner > div:before, .spinner > div:after { content: ''; position: absolute;
    top: 0; left: 2.25em; /* (container width - part width)/2  */ width: 0.5em; height: 1.5em; border-radius: 0.2em;
    background: #eee; box-shadow: 0 3.5em #eee; /* container height - part height */ transform-origin: 50% 2.5em; /* container height / 2 */ }
.spinner:before { background: #555; } .spinner:after { transform: rotate(-45deg); background: #777; }
.spinner > div:before { transform: rotate(-90deg); background: #999; }
.spinner > div:after { transform: rotate(-135deg); background: #bbb; }

/* Forms */
.form-heading { line-height: 1; font-size: 1.25rem; margin-bottom: 0; }
.form-text-align { padding: 0 0.5rem; } 

.input-border { border-style: solid; border-color: rgb(206, 212, 218); border-width: 0 0 1px 0; border-radius: 0; box-shadow: none; }
.input-border:hover { border-style: solid; border-color: #80bdff; border-width: 0 0 2px 0; border-radius: 0; box-shadow: none; }
.input-border:focus { border-style: solid; border-color: #80bdff; border-width: 0 0 2px 0; border-radius: 0; box-shadow: none; }

.input-text { line-height: 1; padding: .375rem .5rem; }

.response-text { color: #dc3545; }

/* Global */
.pointer { cursor: pointer; }

.selected-card-cvv input{
    opacity: 1;
}
.checkout-payment-methods-list .delete-icon{
    margin-top: 10px;
}