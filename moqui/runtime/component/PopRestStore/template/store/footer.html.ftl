<footer class="footer">
    <div class="container">
        <div class="row mb-5">
            <!-- Company Info -->
            <div class="col-lg-4 col-md-6 mb-4 mb-lg-0">
                <div class="d-flex align-items-center mb-3">
                    <img src="/getLogo" alt="Logo" style="width: 45px; height: 45px; border-radius: var(--radius-md); margin-right: 12px;">
                    <span style="font-family: 'Outfit', sans-serif; font-size: 1.5rem; font-weight: 700; color: #fff;">${storeInfo.productStore.storeName!''}</span>
                </div>
                <p style="color: rgba(255,255,255,0.7); font-size: 0.9rem; line-height: 1.7;">
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
                <h5 style="color: #fff; font-family: 'Outfit', sans-serif; font-weight: 600; font-size: 1rem; margin-bottom: 1.25rem;">Quick Links</h5>
                <ul class="footer-ul">
                    <li><a href="/" class="footer-a">Home</a></li>
                    <li><a href="/content/about" class="footer-a">About Us</a></li>
                    <li><a href="/content/contact" class="footer-a">Contact</a></li>
                    <li><a href="/content/help" class="footer-a">Help Center</a></li>
                </ul>
            </div>
            
            <!-- Customer Service -->
            <div class="col-lg-3 col-md-6 col-6 mb-4 mb-lg-0">
                <h5 style="color: #fff; font-family: 'Outfit', sans-serif; font-weight: 600; font-size: 1rem; margin-bottom: 1.25rem;">Customer Service</h5>
                <ul class="footer-ul">
                    <li><a href="/content/help#delivery-rates" class="footer-a">Delivery Rates</a></li>
                    <li><a href="/content/help#delivery" class="footer-a">Shipping Info</a></li>
                    <li><a href="/content/help#customer-pick-up" class="footer-a">Store Pickup</a></li>
                    <li><a href="/content/help#how-to-pay" class="footer-a">Payment Methods</a></li>
                </ul>
            </div>
            
            <!-- Contact Info -->
            <div class="col-lg-3 col-md-6">
                <h5 style="color: #fff; font-family: 'Outfit', sans-serif; font-weight: 600; font-size: 1rem; margin-bottom: 1.25rem;">Contact Us</h5>
                <ul class="footer-ul" style="font-size: 0.9rem;">
                    <li style="display: flex; align-items: flex-start;">
                        <i class="fas fa-map-marker-alt mr-3 mt-1" style="color: var(--primary-400);"></i>
                        <span style="color: rgba(255,255,255,0.7);">Your Address Here<br>City, Country</span>
                    </li>
                    <li style="display: flex; align-items: center;">
                        <i class="fas fa-phone mr-3" style="color: var(--primary-400);"></i>
                        <span style="color: rgba(255,255,255,0.7);">+1 234 567 890</span>
                    </li>
                    <li style="display: flex; align-items: center;">
                        <i class="fas fa-envelope mr-3" style="color: var(--primary-400);"></i>
                        <span style="color: rgba(255,255,255,0.7);">info@example.com</span>
                    </li>
                </ul>
            </div>
        </div>
        
        <!-- Bottom Bar -->
        <div class="row pt-4" style="border-top: 1px solid rgba(255,255,255,0.1);">
            <div class="col-md-6 text-center text-md-left mb-3 mb-md-0">
                <p style="margin: 0; color: rgba(255,255,255,0.5); font-size: 0.85rem;">
                    &copy; ${.now?string('yyyy')} ${storeInfo.productStore.storeName!''}. All rights reserved.
                </p>
            </div>
            <div class="col-md-6 text-center text-md-right">
                <p style="margin: 0; font-size: 0.85rem;">
                    <a href="https://www.moqui.org" target="_blank" style="color: var(--primary-400);">
                        <i class="fas fa-code mr-1"></i>Built with Moqui Framework
                    </a>
                    <span style="color: rgba(255,255,255,0.3); margin: 0 10px;">|</span>
                    <a href="https://www.growerp.com" target="_blank" style="color: var(--primary-400);">
                        Powered by GrowERP
                    </a>
                </p>
            </div>
        </div>
    </div>
</footer>
