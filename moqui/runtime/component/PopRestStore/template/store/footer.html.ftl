<footer class="footer">
    <div class="container">
        <div class="row mb-5">
            <!-- Company Info -->
            <div class="col-lg-4 col-md-6 mb-4 mb-lg-0">
                <div class="d-flex align-items-center mb-3">
                    <img src="/getLogo" alt="Logo" class="footer-logo">
                    <span class="footer-brand-name">${storeInfo.productStore.storeName!''}</span>
                </div>
                <p class="footer-description">
                    Your trusted partner for quality products and exceptional service. We're committed to delivering excellence with every order.
                </p>
                <div class="social-links mt-4">
                    <span class="footer-follow-text d-block mb-3">FOLLOW US</span>
                    <a href="#" class="footer-icon-link"><i class="fab fa-twitter footer-icons"></i></a>
                    <a href="#" class="footer-icon-link"><i class="fab fa-facebook footer-icons"></i></a>
                    <a href="#" class="footer-icon-link"><i class="fab fa-instagram footer-icons"></i></a>
                    <a href="#" class="footer-icon-link"><i class="fab fa-youtube footer-icons"></i></a>
                    <a href="#" class="footer-icon-link"><i class="fab fa-linkedin footer-icons"></i></a>
                </div>
            </div>
            
            <!-- Quick Links -->
            <div class="col-lg-2 col-md-6 col-6 mb-4 mb-lg-0">
                <h5 class="footer-heading">Quick Links</h5>
                <ul class="footer-ul">
                    <li><a href="/" class="footer-a">Home</a></li>
                    <li><a href="/content/about" class="footer-a">About Us</a></li>
                    <li><a href="/content/contact" class="footer-a">Contact</a></li>
                    <li><a href="/content/help" class="footer-a">Help Center</a></li>
                </ul>
            </div>
            
            <!-- Customer Service -->
            <div class="col-lg-3 col-md-6 col-6 mb-4 mb-lg-0">
                <h5 class="footer-heading">Customer Service</h5>
                <ul class="footer-ul">
                    <li><a href="/content/help#delivery-rates" class="footer-a">Delivery Rates</a></li>
                    <li><a href="/content/help#delivery" class="footer-a">Shipping Info</a></li>
                    <li><a href="/content/help#customer-pick-up" class="footer-a">Store Pickup</a></li>
                    <li><a href="/content/help#how-to-pay" class="footer-a">Payment Methods</a></li>
                </ul>
            </div>
            
            <!-- Contact Info -->
            <div class="col-lg-3 col-md-6">
                <h5 class="footer-heading">Contact Us</h5>
                <ul class="footer-ul footer-contact">
                    <li class="footer-contact-item">
                        <i class="fas fa-map-marker-alt mr-3 mt-1 footer-contact-icon"></i>
                        <span class="footer-contact-text">Your Address Here<br>City, Country</span>
                    </li>
                    <li class="footer-contact-item">
                        <i class="fas fa-phone mr-3 footer-contact-icon"></i>
                        <span class="footer-contact-text">+1 234 567 890</span>
                    </li>
                    <li class="footer-contact-item">
                        <i class="fas fa-envelope mr-3 footer-contact-icon"></i>
                        <span class="footer-contact-text">info@example.com</span>
                    </li>
                </ul>
            </div>
        </div>
        
        <!-- Bottom Bar -->
        <div class="row pt-4 footer-bottom">
            <div class="col-md-6 text-center text-md-left mb-3 mb-md-0">
                <p class="footer-copyright">
                    &copy; ${.now?string('yyyy')} ${storeInfo.productStore.storeName!''}. All rights reserved.
                </p>
            </div>
            <div class="col-md-6 text-center text-md-right">
                <p class="footer-credits">
                    <a href="https://www.moqui.org" target="_blank" class="footer-credit-link">
                        <i class="fas fa-code mr-1"></i>Built with Moqui Framework
                    </a>
                    <span class="footer-separator">|</span>
                    <a href="https://www.growerp.com" target="_blank" class="footer-credit-link">
                        Powered by GrowERP
                    </a>
                </p>
            </div>
        </div>
    </div>
</footer>
