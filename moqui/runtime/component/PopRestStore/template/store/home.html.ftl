<#--div class="container-fluid features d-none d-sm-none d-md-block">
    <div class="d-flex justify-content-around container">
        <div class="feature">
            <div class="feature-icon"><i class="fa fa-gift" aria-hidden="true"></i></div>
            <div class="feature-info">
                <div class="title text-left">FAST SHIPPING</div>
                <div class="subtitle">Nationwide delivery within 3 days</div>
            </div>
        </div>
        <div class="feature">
            <div class="feature-icon"><i class="fa fa-fire" aria-hidden="true"></i></div>
            <div class="feature-info">
                <div class="title text-left">HOT DEALS</div>
                <div class="subtitle">New deals every week</div>
            </div>
        </div>
        <div class="feature">
            <div class="feature-icon"><i class="fa fa-lock" aria-hidden="true"></i></div>
            <div class="feature-info">
                <div class="title text-left">SECURE ORDERING</div>
                <div class="subtitle">Safe shopping guaranteed</div>
            </div>
        </div>
    </div>
</div-->
<div class="container">
    <#if promoProductList?has_content>
        <div class="text-left mt-3 modal-text">This Week's deals</div>
        <div class="carousel">
            <div class="container text-center my-3">
                <div class="row mx-auto my-auto">
                    <div id="recipeCarousel" class="carousel slide w-100" data-ride="carousel">
                        <div class="carousel-inner w-100" role="listbox">
                            <#list promoProductList as product>
                                <#if product?index == 0>
                                    <div class="carousel-item active">
                                <#else>
                                    <div class="carousel-item">
                                </#if>
                                    <div class="d-block col-lg-3 col-12">
                                        <a class="category-product" href="/product/${product.productId}">
                                            <figure class="figure">
                                                <#if product.mediumImageInfo??>
                                                    <img width="90%" class="figure-img img-fluid" src="/content/productImage/${product.mediumImageInfo.productContentId}">
                                                <#else>
                                                    <#if product.smallImageInfo??>
                                                        <img width="90%" class="figure-img img-fluid" src="/content/productImage/${product.smallImageInfo.productContentId}" >
                                                    </#if>
                                                </#if>
                                                <figcaption class="text-left title-product-text figure-caption">
                                                    ${product.productName}
                                                </figcaption>
                                                <figcaption class="text-left figure-caption">
                                                    <#if product.numberOfRatings??>
                                                        <#list 1..5 as x>
                                                            <span class="star-rating">
                                                                <#if (product.numberOfRatings >= x)>
                                                                    <i class="fas fa-star"></i>
                                                                <#else>
                                                                    <i class="far fa-star"></i>
                                                                </#if>  
                                                            </span>
                                                        </#list>
                                                    </#if>
                                                </figcaption>
                                                <figcaption class="text-primary text-left figure-caption">
                                                    <span class="product-price-text">${ec.l10n.formatCurrency(product.price,product.priceUomId)}</span>
                                                    <span class="product-last-price">
                                                        <#if product.listPrice??>
                                                            <del>${ec.l10n.formatCurrency(product.listPrice,product.priceUomId)}</del>
                                                        </#if>
                                                    </span>
                                                </figcaption>
                                            </figure>
                                        </a>
                                    </div>
                                </div>
                            </#list>
                        </div>
                        <a class="carousel-control-prev" href="#recipeCarousel" role="button" data-slide="prev">
                            <button type="button" class="carousel-prev"><i class="fas fa-arrow-left"></i></button>
                            <span class="sr-only">Previous</span>
                        </a>
                        <a class="carousel-control-next" href="#recipeCarousel" role="button" data-slide="next">
                            <button type="button" class="carousel-next"><i class="fas fa-arrow-right"></i></button>
                            <span class="sr-only">Next</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </#if>
    <#if promoProductList?has_content && featureProductList?has_content><hr/></#if>
    <#if featureProductList?has_content>
        <div class="text-left mt-3 modal-text">Featured</div>
        <div class="carousel">
            <div class="container text-center my-3">
                <div class="row mx-auto my-auto">
                    <div id="recipeCarousel1" class="carousel slide w-100" data-ride="carousel">
                        <div class="carousel-inner w-100" role="listbox">
                            <#list featureProductList as product>
                                <#if product?index == 0>
                                    <div class="carousel-item active">
                                <#else>
                                    <div class="carousel-item">
                                </#if>
                                    <div class="d-block col-lg-3 col-12">
                                        <a class="category-product" href="/product/${product.productId}">
                                            <figure class="figure">
                                                <#if product.mediumImageInfo??>
                                                    <img width="90%" class="figure-img img-fluid" src="/content/productImage/${product.mediumImageInfo.productContentId}">
                                                <#else>
                                                    <#if product.smallImageInfo??>
                                                        <img width="90%" class="figure-img img-fluid" src="/content/productImage/${product.smallImageInfo.productContentId}" >
                                                    </#if>
                                                </#if>
                                                <figcaption class="text-left title-product-text figure-caption">
                                                    ${product.productName}
                                                </figcaption>
                                                <figcaption class="text-left figure-caption">
                                                    <#if product.numberOfRatings??>
                                                        <#list 1..5 as x>
                                                            <span class="star-rating">
                                                                <#if (product.numberOfRatings >= x)>
                                                                    <i class="fas fa-star"></i>
                                                                <#else>
                                                                    <i class="far fa-star"></i>
                                                                </#if>  
                                                            </span>
                                                        </#list>
                                                    </#if>
                                                </figcaption>
                                                <figcaption class="text-primary text-left figure-caption">
                                                    <span class="product-price-text">${ec.l10n.formatCurrency(product.price,product.priceUomId)}</span>
                                                    <span class="product-last-price">
                                                        <#if product.listPrice??>
                                                            <del>${ec.l10n.formatCurrency(product.listPrice, product.priceUomId)}</del>
                                                        </#if>
                                                    </span>
                                                </figcaption>
                                            </figure>
                                        </a>
                                    </div>
                                </div>
                            </#list>
                        </div>
                        <a class="carousel-control-prev" href="#recipeCarousel1" role="button" data-slide="prev">
                            <button type="button" class="carousel-prev"><i class="fas fa-arrow-left"></i></button>
                            <span class="sr-only">Previous</span>
                        </a>
                        <a class="carousel-control-next" href="#recipeCarousel1" role="button" data-slide="next">
                            <button type="button" class="carousel-next"><i class="fas fa-arrow-right"></i></button>
                            <span class="sr-only">Next</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </#if>
    <br>
</div>
