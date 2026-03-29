<div class="container" style="padding-top: 1.5rem;">
    <!-- Breadcrumb Navigation -->
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb" style="background: none; padding: 0; margin-bottom: 1.5rem;">
            <li class="breadcrumb-item">
                <a href="/" class="customer-link" style="color: var(--primary-600);">
                    <i class="fas fa-home mr-1"></i>Home
                </a>
            </li>
            <li class="breadcrumb-item active" aria-current="page" style="color: var(--neutral-500);">
                <i class="fas fa-search mr-1"></i>Search Results
            </li>
        </ol>
    </nav>
    
    <div class="row">
        <!-- Sidebar Filters -->
        <div class="col-lg-3 col-md-4 col-12 mb-4">
            <div class="customer-menu" style="position: sticky; top: 100px;">
                <h5 style="font-family: 'Outfit', sans-serif; font-weight: 600; color: var(--neutral-800); margin-bottom: 1.25rem;">
                    <i class="fas fa-filter mr-2" style="color: var(--primary-500);"></i>Refine Search
                </h5>
                
                <ul class="deals-ul" style="border-left: 2px solid var(--neutral-200); padding-left: 1rem;">
                    <#if (storeInfo.categoryByType.PsctSearch.productCategoryId)??>
                        <li class="mb-2">
                            <a href="/category/${storeInfo.categoryByType.PsctSearch.productCategoryId}" 
                                class="d-flex align-items-center" style="color: var(--neutral-600);">
                                <i class="fas fa-th mr-2" style="width: 18px;"></i>All Products
                            </a>
                        </li>
                    </#if>
                    <#if (storeInfo.categoryByType.PsctPromotions.productCategoryId)??>
                        <li class="mb-2">
                            <a href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}" 
                                class="d-flex align-items-center" style="color: var(--neutral-600);">
                                <i class="fas fa-fire mr-2" style="width: 18px; color: var(--accent-500);"></i>Deals
                            </a>
                        </li>
                    </#if>
                    <#if (storeInfo.categoryByType.PsctNewProducts.productCategoryId)??>
                        <li class="mb-2">
                            <a href="/category/${storeInfo.categoryByType.PsctNewProducts.productCategoryId}" 
                                class="d-flex align-items-center" style="color: var(--neutral-600);">
                                <i class="fas fa-tag mr-2" style="width: 18px; color: var(--success);"></i>New Arrivals
                            </a>
                        </li>
                    </#if>
                    <#if (storeInfo.categoryByType.PsctFeatured.productCategoryId)??>
                        <li class="mb-2">
                            <a href="/category/${storeInfo.categoryByType.PsctFeatured.productCategoryId}" 
                                class="d-flex align-items-center" style="color: var(--neutral-600);">
                                <i class="fas fa-star mr-2" style="width: 18px; color: var(--gold);"></i>Best Sellers
                            </a>
                        </li>
                    </#if>
                </ul>
                
                <hr style="margin: 1.25rem 0; border-color: var(--neutral-200);">
                
                <h6 style="font-weight: 600; color: var(--neutral-500); text-transform: uppercase; font-size: 0.75rem; letter-spacing: 1px; margin-bottom: 1rem;">
                    Categories
                </h6>
                <ul class="deals-ul" style="padding-left: 0;">
                    <#list browseRootCategoryInfo.subCategoryList as category>
                        <li class="mb-2">
                            <a href="/category/${category.productCategoryId}" 
                                class="d-flex align-items-center" style="color: var(--neutral-600); transition: all 0.2s ease;">
                                <i class="fas fa-chevron-right mr-2" style="font-size: 0.7rem; color: var(--primary-400);"></i>
                                ${category.categoryName}
                            </a>
                        </li>
                    </#list>
                </ul>
            </div>
        </div>
        
        <!-- Search Results -->
        <div class="col-lg-9 col-md-8 col-12">
            <!-- Search Header -->
            <div class="mb-4">
                <h1 class="customer-orders-title" style="font-size: 2rem;">
                    <i class="fas fa-search mr-2" style="color: var(--primary-500);"></i>Search Results
                </h1>
                <#if searchParameter??>
                    <p style="color: var(--neutral-500); margin-top: 0.5rem;">
                        Showing results for "<strong style="color: var(--neutral-700);">${searchParameter}</strong>"
                    </p>
                </#if>
            </div>
            
            <!-- Results Bar -->
            <div class="deals-sellers mb-4" style="padding: 1rem 1.5rem; border-radius: var(--radius-md);">
                <div class="d-flex justify-content-between align-items-center">
                    <span class="deals-sortby-text">
                        <i class="fas fa-box-open mr-2" style="color: var(--primary-500);"></i>
                        <strong>${productListCount!0}</strong> product<#if (productListCount!0) != 1>s</#if> found
                    </span>
                </div>
            </div>
            
            <!-- Product Grid -->
            <div class="row">
                <#if productList?has_content>
                    <#list productList as localProd>
                        <div class="col-lg-4 col-md-6 col-6 mb-4">
                            <a href="/product/${localProd.productId}" class="category-product">
                                <figure class="figure" style="margin: 0;">
                                    <!-- Product Image -->
                                    <div class="product-image-wrapper" style="overflow: hidden; border-radius: var(--radius-md); background: #fff;">
                                        <#if localProd.mediumImageInfo?? || localProd.smallImageInfo??>
                                            <#assign img = localProd.smallImageInfo! localProd.mediumImageInfo>
                                            <img class="figure-img img-fluid w-100"
                                                src="/content/productImage/${img.productContentId}"
                                                alt="${localProd.productName}"
                                                style="aspect-ratio: 1; object-fit: cover;">
                                        <#else>
                                            <div class="placeholder-image d-flex align-items-center justify-content-center" 
                                                style="aspect-ratio: 1; background: var(--neutral-100);">
                                                <i class="fas fa-image fa-3x" style="color: var(--neutral-300);"></i>
                                            </div>
                                        </#if>
                                    </div>
                                    
                                    <!-- Product Info -->
                                    <figcaption class="text-left title-product-text figure-caption mt-3" style="min-height: 48px;">
                                        ${localProd.productName}
                                    </figcaption>
                                    
                                    <!-- Price -->
                                    <figcaption class="text-left figure-caption mt-2">
                                        <#if localProd.price?? && localProd.price gt 0>
                                            <span class="product-price-text">${ec.l10n.formatCurrency(localProd.price, localProd.priceUomId)}</span>
                                            <#if localProd.listPrice?? && localProd.listPrice gt localProd.price>
                                                <span class="product-last-price ml-2">
                                                    <del>${ec.l10n.formatCurrency(localProd.listPrice, localProd.priceUomId)}</del>
                                                </span>
                                            </#if>
                                        <#elseif localProd.listPrice?? && localProd.listPrice gt 0>
                                            <span class="product-price-text">${ec.l10n.formatCurrency(localProd.listPrice,localProd.priceUomId)}</span>
                                        <#else>
                                            <span class="product-price-text">Free</span>
                                        </#if>
                                    </figcaption>
                                </figure>
                            </a>
                        </div>
                    </#list>
                <#else>
                    <div class="col-12">
                        <div class="text-center py-5" style="background: var(--neutral-50); border-radius: var(--radius-lg);">
                            <i class="fas fa-search fa-4x mb-3" style="color: var(--neutral-300);"></i>
                            <h4 style="color: var(--neutral-500);">No results found</h4>
                            <p style="color: var(--neutral-400);">Try a different search term or browse our categories.</p>
                            <a href="/" class="btn btn-continue mt-2">
                                <i class="fas fa-home mr-2"></i>Back to Home
                            </a>
                        </div>
                    </div>
                </#if>
            </div>
            
            <!-- Pagination -->
            <#if productListCount?? && productListPageSize?? && productListCount gt 0 && productListPageSize gt 0>
                <#if productListCount gt 5>
                    <nav aria-label="Page navigation" class="mt-4">
                        <ul class="pagination justify-content-center">
                            <li class="page-item <#if pageIndex?number == 0>disabled</#if>">
                                <a class="page-link" href="/search/${searchParameter}?pageIndex=${pageIndex?number - 1}" 
                                    style="border-radius: var(--radius-md) 0 0 var(--radius-md); border-color: var(--neutral-200);">
                                    <i class="fas fa-chevron-left mr-1"></i>Previous
                                </a>
                            </li>
                            <#list 0..((productListCount/ productListPageSize) - 1)?floor as n>
                                <li class="page-item <#if pageIndex?number == n>active</#if>">
                                    <a class="page-link" href="/search/${searchParameter}?pageIndex=${n}" 
                                        style="border-color: var(--neutral-200); <#if pageIndex?number == n>background: var(--primary-500); border-color: var(--primary-500);</#if>">
                                        ${n + 1}
                                    </a>
                                </li>
                            </#list>
                            <li class="page-item <#if productListCount == productListPageRangeHigh>disabled</#if>">
                                <a class="page-link" href="/search/${searchParameter}?pageIndex=${pageIndex?number + 1}" 
                                    style="border-radius: 0 var(--radius-md) var(--radius-md) 0; border-color: var(--neutral-200);">
                                    Next<i class="fas fa-chevron-right ml-1"></i>
                                </a>
                            </li>
                        </ul>
                    </nav>
                </#if>
            </#if>
        </div>
    </div>
</div>