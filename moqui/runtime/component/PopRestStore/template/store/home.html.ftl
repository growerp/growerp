<!-- Hero Features Bar -->
<div class="container-fluid features d-none d-md-block" style="background: linear-gradient(135deg, #00b4a2 0%, #00a394 100%); padding: 1.25rem 0;">
    <div class="d-flex justify-content-around container">
        <div class="feature">
            <div class="feature-icon"><i class="fas fa-truck" aria-hidden="true"></i></div>
            <div class="feature-info">
                <div class="title text-left">FAST SHIPPING</div>
                <div class="subtitle">Free delivery on orders over $50</div>
            </div>
        </div>
        <div class="feature">
            <div class="feature-icon"><i class="fas fa-percent" aria-hidden="true"></i></div>
            <div class="feature-info">
                <div class="title text-left">WEEKLY DEALS</div>
                <div class="subtitle">New promotions every week</div>
            </div>
        </div>
        <div class="feature">
            <div class="feature-icon"><i class="fas fa-shield-alt" aria-hidden="true"></i></div>
            <div class="feature-info">
                <div class="title text-left">SECURE CHECKOUT</div>
                <div class="subtitle">100% protected payments</div>
            </div>
        </div>
        <div class="feature">
            <div class="feature-icon"><i class="fas fa-headset" aria-hidden="true"></i></div>
            <div class="feature-info">
                <div class="title text-left">24/7 SUPPORT</div>
                <div class="subtitle">Here to help anytime</div>
            </div>
        </div>
    </div>
</div>

<div class="container" style="padding-top: 2rem;">
    <#-- This Week's Deals Section -->
    <#if promoProductList?has_content>
        <div class="section-header mb-4">
            <h2 class="modal-text mb-0">
                <i class="fas fa-fire-alt mr-2" style="color: #ff8870;"></i>
                This Week's Deals
            </h2>
            <p class="text-muted mt-2">Don't miss out on these exclusive offers</p>
        </div>
        
        <div class="row">
            <#list promoProductList as product>
                <#if product?index < 4>
                <div class="col-lg-3 col-md-4 col-sm-6 col-12 mb-4">
                    <a class="category-product" href="/product/${product.productId}">
                        <div class="figure" style="background: #fff; border-radius: 12px; padding: 1rem; box-shadow: 0 2px 8px rgba(0,0,0,0.08); transition: all 0.25s ease;">
                            <div class="product-image-wrapper text-center" style="height: 180px; display: flex; align-items: center; justify-content: center;">
                                <#if product.mediumImageInfo??>
                                    <img style="max-height: 160px; max-width: 100%; object-fit: contain;" class="img-fluid" src="/content/productImage/${product.mediumImageInfo.productContentId}" alt="${product.productName}">
                                <#else>
                                    <#if product.smallImageInfo??>
                                        <img style="max-height: 160px; max-width: 100%; object-fit: contain;" class="img-fluid" src="/content/productImage/${product.smallImageInfo.productContentId}" alt="${product.productName}">
                                    <#else>
                                        <div class="placeholder-image d-flex align-items-center justify-content-center" style="height: 160px; width: 100%; background: #f1f5f9; border-radius: 8px;">
                                            <i class="fas fa-image fa-3x" style="color: #cbd5e1;"></i>
                                        </div>
                                    </#if>
                                </#if>
                            </div>
                            <div class="product-info mt-3">
                                <h6 class="title-product-text mb-2" style="color: #334155; font-weight: 600; font-size: 0.95rem; min-height: 40px;">
                                    ${product.productName}
                                </h6>
                                <#if product.numberOfRatings??>
                                <div class="star-rating mb-2">
                                    <#list 1..5 as x>
                                        <#if (product.numberOfRatings >= x)>
                                            <i class="fas fa-star" style="color: #f59e0b; font-size: 0.85rem;"></i>
                                        <#else>
                                            <i class="far fa-star" style="color: #f59e0b; font-size: 0.85rem;"></i>
                                        </#if>
                                    </#list>
                                </div>
                                </#if>
                                <div class="price-section">
                                    <#if product.price?? && product.price gt 0>
                                        <span class="product-price-text" style="color: #e6715a; font-size: 1.15rem; font-weight: 700;">${ec.l10n.formatCurrency(product.price,product.priceUomId)}</span>
                                        <#if product.listPrice?? && product.listPrice gt product.price>
                                            <span class="product-last-price ml-2" style="color: #94a3b8; font-size: 0.9rem;">
                                                <del>${ec.l10n.formatCurrency(product.listPrice,product.priceUomId)}</del>
                                            </span>
                                        </#if>
                                    <#elseif product.listPrice?? && product.listPrice gt 0>
                                        <span class="product-price-text" style="color: #e6715a; font-size: 1.15rem; font-weight: 700;">${ec.l10n.formatCurrency(product.listPrice,product.priceUomId)}</span>
                                    <#else>
                                        <span class="product-price-text" style="color: #e6715a; font-size: 1.15rem; font-weight: 700;">Free</span>
                                    </#if>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>
                </#if>
            </#list>
        </div>
        
        <#if promoProductList?size gt 4>
        <div class="text-center mt-2 mb-4">
            <#if (storeInfo.categoryByType.PsctPromotions.productCategoryId)??>
                <a href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}" class="btn btn-outline-primary" style="border-color: #00b4a2; color: #00b4a2;">
                    View All Deals <i class="fas fa-arrow-right ml-2"></i>
                </a>
            </#if>
        </div>
        </#if>
    </#if>
    
    <#-- Separator -->
    <#if promoProductList?has_content && featureProductList?has_content>
        <hr style="margin: 2rem 0; border-color: #e2e8f0;">
    </#if>
    
    <#-- Featured Products Section -->
    <#if featureProductList?has_content>
        <div class="section-header mb-4">
            <h2 class="modal-text mb-0">
                <i class="fas fa-star mr-2" style="color: #f59e0b;"></i>
                Featured Products
            </h2>
            <p class="text-muted mt-2">Handpicked selections just for you</p>
        </div>
        
        <div class="row">
            <#list featureProductList as product>
                <#if product?index < 4>
                <div class="col-lg-3 col-md-4 col-sm-6 col-12 mb-4">
                    <a class="category-product" href="/product/${product.productId}">
                        <div class="figure" style="background: #fff; border-radius: 12px; padding: 1rem; box-shadow: 0 2px 8px rgba(0,0,0,0.08); transition: all 0.25s ease;">
                            <div class="product-image-wrapper text-center" style="height: 180px; display: flex; align-items: center; justify-content: center;">
                                <#if product.mediumImageInfo??>
                                    <img style="max-height: 160px; max-width: 100%; object-fit: contain;" class="img-fluid" src="/content/productImage/${product.mediumImageInfo.productContentId}" alt="${product.productName}">
                                <#else>
                                    <#if product.smallImageInfo??>
                                        <img style="max-height: 160px; max-width: 100%; object-fit: contain;" class="img-fluid" src="/content/productImage/${product.smallImageInfo.productContentId}" alt="${product.productName}">
                                    <#else>
                                        <div class="placeholder-image d-flex align-items-center justify-content-center" style="height: 160px; width: 100%; background: #f1f5f9; border-radius: 8px;">
                                            <i class="fas fa-image fa-3x" style="color: #cbd5e1;"></i>
                                        </div>
                                    </#if>
                                </#if>
                            </div>
                            <div class="product-info mt-3">
                                <h6 class="title-product-text mb-2" style="color: #334155; font-weight: 600; font-size: 0.95rem; min-height: 40px;">
                                    ${product.productName}
                                </h6>
                                <#if product.numberOfRatings??>
                                <div class="star-rating mb-2">
                                    <#list 1..5 as x>
                                        <#if (product.numberOfRatings >= x)>
                                            <i class="fas fa-star" style="color: #f59e0b; font-size: 0.85rem;"></i>
                                        <#else>
                                            <i class="far fa-star" style="color: #f59e0b; font-size: 0.85rem;"></i>
                                        </#if>
                                    </#list>
                                </div>
                                </#if>
                                <div class="price-section">
                                    <#if product.price?? && product.price gt 0>
                                        <span class="product-price-text" style="color: #e6715a; font-size: 1.15rem; font-weight: 700;">${ec.l10n.formatCurrency(product.price,product.priceUomId)}</span>
                                        <#if product.listPrice?? && product.listPrice gt product.price>
                                            <span class="product-last-price ml-2" style="color: #94a3b8; font-size: 0.9rem;">
                                                <del>${ec.l10n.formatCurrency(product.listPrice,product.priceUomId)}</del>
                                            </span>
                                        </#if>
                                    <#elseif product.listPrice?? && product.listPrice gt 0>
                                        <span class="product-price-text" style="color: #e6715a; font-size: 1.15rem; font-weight: 700;">${ec.l10n.formatCurrency(product.listPrice,product.priceUomId)}</span>
                                    <#else>
                                        <span class="product-price-text" style="color: #e6715a; font-size: 1.15rem; font-weight: 700;">Free</span>
                                    </#if>
                                </div>
                            </div>
                        </div>
                    </a>
                </div>
                </#if>
            </#list>
        </div>
        
        <#if featureProductList?size gt 4>
        <div class="text-center mt-2 mb-4">
            <#if (storeInfo.categoryByType.PsctFeatured.productCategoryId)??>
                <a href="/category/${storeInfo.categoryByType.PsctFeatured.productCategoryId}" class="btn btn-outline-primary" style="border-color: #00b4a2; color: #00b4a2;">
                    View All Featured <i class="fas fa-arrow-right ml-2"></i>
                </a>
            </#if>
        </div>
        </#if>
    </#if>
    
    <#-- Spacer -->
    <div style="height: 3rem;"></div>
</div>
