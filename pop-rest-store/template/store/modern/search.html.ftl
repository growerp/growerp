<div class="max-w-container mx-auto px-4 md:px-12 pt-24 pb-8">
    <!-- Breadcrumb Navigation -->
    <nav aria-label="breadcrumb" class="mb-6">
        <ol class="flex items-center gap-2 text-sm">
            <li>
                <a href="/" class="flex items-center gap-1 text-primary hover:text-primary/80 transition-colors">
                    <span class="material-symbols-outlined text-[16px]">home</span>Home
                </a>
            </li>
            <li class="text-outline">/</li>
            <li class="text-on-surface-variant flex items-center gap-1" aria-current="page">
                <span class="material-symbols-outlined text-[16px]">search</span>Search Results
            </li>
        </ol>
    </nav>

    <div class="flex flex-col md:flex-row gap-8">
        <!-- Sidebar Filters -->
        <aside class="md:w-64 shrink-0">
            <div class="l-glass rounded-2xl p-6 md:sticky md:top-24">
                <h5 class="font-display font-semibold text-on-surface mb-4 flex items-center gap-2">
                    <span class="material-symbols-outlined text-primary text-[20px]">filter_list</span>Refine Search
                </h5>
                <ul class="space-y-1 border-l border-white/10 pl-3">
                    <#if (storeInfo.categoryByType.PsctSearch.productCategoryId)??>
                        <li>
                            <a href="/category/${storeInfo.categoryByType.PsctSearch.productCategoryId}"
                               class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-on-surface-variant hover:text-primary transition-colors">
                                <span class="material-symbols-outlined text-[18px]">apps</span>All Products
                            </a>
                        </li>
                    </#if>
                    <#if (storeInfo.categoryByType.PsctPromotions.productCategoryId)??>
                        <li>
                            <a href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}"
                               class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-on-surface-variant hover:text-primary transition-colors">
                                <span class="material-symbols-outlined text-[18px]">local_fire_department</span>Deals
                            </a>
                        </li>
                    </#if>
                    <#if (storeInfo.categoryByType.PsctNewProducts.productCategoryId)??>
                        <li>
                            <a href="/category/${storeInfo.categoryByType.PsctNewProducts.productCategoryId}"
                               class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-on-surface-variant hover:text-primary transition-colors">
                                <span class="material-symbols-outlined text-[18px]">new_releases</span>New Arrivals
                            </a>
                        </li>
                    </#if>
                    <#if (storeInfo.categoryByType.PsctFeatured.productCategoryId)??>
                        <li>
                            <a href="/category/${storeInfo.categoryByType.PsctFeatured.productCategoryId}"
                               class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-on-surface-variant hover:text-primary transition-colors">
                                <span class="material-symbols-outlined text-[18px]">star</span>Best Sellers
                            </a>
                        </li>
                    </#if>
                </ul>

                <hr class="my-5 border-white/10">

                <h6 class="font-label text-xs font-semibold text-outline uppercase tracking-widest mb-3">Categories</h6>
                <ul class="space-y-1">
                    <#list browseRootCategoryInfo.subCategoryList as category>
                        <li>
                            <a href="/category/${category.productCategoryId}"
                               class="flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm text-on-surface-variant hover:text-primary transition-colors">
                                <span class="material-symbols-outlined text-primary/60 text-[14px]">chevron_right</span>${category.categoryName}
                            </a>
                        </li>
                    </#list>
                </ul>
            </div>
        </aside>

        <!-- Search Results -->
        <div class="flex-1 min-w-0">
            <h1 class="font-display text-3xl font-bold text-on-surface mb-1 flex items-center gap-2">
                <span class="material-symbols-outlined text-primary text-[32px]">search</span>Search Results
            </h1>
            <#if searchParameter??>
                <p class="text-on-surface-variant mb-4">
                    Showing results for "<strong class="text-on-surface">${searchParameter}</strong>"
                </p>
            </#if>

            <!-- Results Bar -->
            <div class="l-glass rounded-xl px-5 py-3 mb-6 flex items-center gap-2 text-sm text-on-surface-variant">
                <span class="material-symbols-outlined text-primary text-[18px]">package_2</span>
                <strong class="text-on-surface">${productListCount!0}</strong> product<#if (productListCount!0) != 1>s</#if> found
            </div>

            <#if productList?has_content>
                <div class="grid grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
                    <#list productList as localProd>
                        <a href="/product/${localProd.productId}" class="group block l-glass rounded-xl p-3 hover:border-primary/40 transition-all duration-300">
                            <div class="aspect-square rounded-lg overflow-hidden bg-surface-container-high flex items-center justify-center mb-3">
                                <#if localProd.mediumImageInfo?? || localProd.smallImageInfo??>
                                    <#assign img = localProd.smallImageInfo! localProd.mediumImageInfo>
                                    <img class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                                        src="/content/productImage/${img.productContentId}"
                                        alt="${localProd.productName}">
                                <#else>
                                    <span class="material-symbols-outlined text-outline text-[48px]">image</span>
                                </#if>
                            </div>
                            <h6 class="text-sm font-medium text-on-surface line-clamp-2 min-h-[2.5rem] mb-1 group-hover:text-primary transition-colors">${localProd.productName}</h6>
                            <div class="flex items-baseline gap-2">
                                <#if localProd.price?? && localProd.price gt 0>
                                    <span class="text-primary font-semibold text-base">${ec.l10n.formatCurrency(localProd.price, localProd.priceUomId)}</span>
                                    <#if localProd.listPrice?? && localProd.listPrice gt localProd.price>
                                        <span class="text-on-surface-variant text-sm line-through">${ec.l10n.formatCurrency(localProd.listPrice, localProd.priceUomId)}</span>
                                    </#if>
                                <#elseif localProd.listPrice?? && localProd.listPrice gt 0>
                                    <span class="text-primary font-semibold text-base">${ec.l10n.formatCurrency(localProd.listPrice,localProd.priceUomId)}</span>
                                <#else>
                                    <span class="text-primary font-semibold text-base">Free</span>
                                </#if>
                            </div>
                        </a>
                    </#list>
                </div>
            <#else>
                <div class="l-glass rounded-2xl p-12 text-center">
                    <span class="material-symbols-outlined text-outline text-[64px] mb-3">search_off</span>
                    <h4 class="font-display text-xl font-semibold text-on-surface mb-2">No results found</h4>
                    <p class="text-on-surface-variant mb-6">Try a different search term or browse our categories.</p>
                    <a href="/" class="inline-flex items-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-6 py-3 rounded-lg transition-all active:scale-95">
                        <span class="material-symbols-outlined text-[18px]">home</span>Back to Home
                    </a>
                </div>
            </#if>

            <!-- Pagination -->
            <#if productListCount?? && productListPageSize?? && productListCount gt 0 && productListPageSize gt 0>
                <#if productListCount gt 5>
                    <nav aria-label="Page navigation" class="mt-8">
                        <ul class="flex items-center justify-center gap-1 flex-wrap">
                            <li>
                                <a href="/search/${searchParameter}?pageIndex=${pageIndex?number - 1}"
                                   class="flex items-center gap-1 px-3 py-2 rounded-lg border border-white/10 text-sm text-on-surface-variant hover:border-primary/40 hover:text-primary transition-colors <#if pageIndex?number == 0>pointer-events-none opacity-40</#if>">
                                    <span class="material-symbols-outlined text-[16px]">chevron_left</span>Previous
                                </a>
                            </li>
                            <#list 0..((productListCount/ productListPageSize) - 1)?floor as n>
                                <li>
                                    <a href="/search/${searchParameter}?pageIndex=${n}"
                                       class="flex items-center justify-center min-w-[38px] px-3 py-2 rounded-lg border text-sm transition-colors <#if pageIndex?number == n>bg-primary border-primary text-on-primary font-semibold<#else>border-white/10 text-on-surface-variant hover:border-primary/40 hover:text-primary</#if>">
                                        ${n + 1}
                                    </a>
                                </li>
                            </#list>
                            <li>
                                <a href="/search/${searchParameter}?pageIndex=${pageIndex?number + 1}"
                                   class="flex items-center gap-1 px-3 py-2 rounded-lg border border-white/10 text-sm text-on-surface-variant hover:border-primary/40 hover:text-primary transition-colors <#if productListCount == productListPageRangeHigh>pointer-events-none opacity-40</#if>">
                                    Next<span class="material-symbols-outlined text-[16px]">chevron_right</span>
                                </a>
                            </li>
                        </ul>
                    </nav>
                </#if>
            </#if>
        </div>
    </div>
</div>
