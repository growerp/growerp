<#assign isMarketing = storeInfo.productStore.productStoreId == "100000">
<#-- brochure-only stores (no browse-root categories) get no shop/search/cart/login UI -->
<#assign hasCommerce = (browseRootCategoryInfo.subCategoryList)?has_content>
<header class="fixed top-0 inset-x-0 z-40">
    <nav class="l-glass bg-surface-container-lowest/40 border-b border-white/10">
        <div class="max-w-container mx-auto px-4 md:px-12 h-16 flex items-center justify-between gap-4">
            <!-- Logo and Brand -->
            <a href="/" class="flex items-center gap-3 shrink-0">
                <img src="/getLogo" alt="Home" class="h-9 w-9 object-contain rounded">
                <span class="font-display font-bold text-lg tracking-tight text-on-surface hidden sm:block">${storeInfo.productStore.storeName}</span>
            </a>

            <!-- Desktop navigation -->
            <div class="hidden md:flex items-center gap-6">
                <#if !isMarketing>
                    <#-- Shop Categories Dropdown -->
                    <#if hasCommerce>
                    <div class="relative">
                        <button type="button" data-menu-button="shopDropdown" aria-expanded="false"
                                class="flex items-center gap-1 font-label text-sm text-on-surface-variant hover:text-primary transition-colors">
                            <span class="material-symbols-outlined text-[18px]">shopping_bag</span>Shop
                            <span class="material-symbols-outlined text-[18px]">expand_more</span>
                        </button>
                        <div id="shopDropdown" data-dropdown-panel class="hidden absolute left-0 top-full mt-2 w-56 l-glass bg-surface-container/90 rounded-xl py-2 shadow-2xl">
                            <#list browseRootCategoryInfo.subCategoryList as category>
                                <a href="/category/${category.productCategoryId}" class="flex items-center gap-2 px-4 py-2 text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">
                                    <span class="material-symbols-outlined text-[16px]">sell</span>${category.categoryName}
                                </a>
                            </#list>
                        </div>
                    </div>
                    </#if>

                    <#-- Deals Button -->
                    <#if ((storeInfo.categoryByType.PsctPromotions.nbrOfProducts)!0) != 0>
                        <a href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}" class="flex items-center gap-1 font-label text-sm text-on-surface-variant hover:text-primary transition-colors">
                            <span class="material-symbols-outlined text-[18px]">local_fire_department</span>${storeInfo.categoryByType.PsctPromotions.categoryName}
                        </a>
                    </#if>
                </#if>

                <#-- Content Menu Items (both modes); marketing Apps link inserted before pricing -->
                <#list storeInfo.menu as topItem>
                <#if !topItem.title?has_content || topItem.path == 'home'><#continue></#if>
                <#if isMarketing && topItem.path == 'pricing'>
                    <a href="/modules" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">Apps</a>
                </#if>
                <#if topItem.items?has_content>
                <div class="relative">
                    <button type="button" data-menu-button="menuDropdown${topItem?index}" aria-expanded="false"
                            class="flex items-center gap-1 font-label text-sm text-on-surface-variant hover:text-primary transition-colors">
                        ${topItem.title!topItem.path}
                        <span class="material-symbols-outlined text-[18px]">expand_more</span>
                    </button>
                    <div id="menuDropdown${topItem?index}" data-dropdown-panel class="hidden absolute left-0 top-full mt-2 w-56 l-glass bg-surface-container/90 rounded-xl py-2 shadow-2xl">
                        <#list topItem.items as item>
                            <#if item.path??>
                            <a href="/content/${item.path}" class="block px-4 py-2 text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">${item.title!item.path}</a>
                            <#else>
                            <a href="/content/${topItem.path}#${item.anchor}" class="block px-4 py-2 text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">${item.text}</a>
                            </#if>
                        </#list>
                    </div>
                </div>
                <#else>
                    <#if topItem.path == 'obsidian'>
                        <a href="/${topItem.path}" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">
                    <#else>
                        <a href="/content/${topItem.path}" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">
                    </#if>
                        ${topItem.title!topItem.path}
                    </a>
                </#if>
                </#list>
            </div>

            <!-- Right block -->
            <div class="flex items-center gap-3">
                <#if isMarketing>
                    <#if (storeOwnerPartyId!'') != 'GROWERP'>
                    <a href="https://admin.growerp.com" class="hidden sm:inline-flex font-label text-sm text-on-surface hover:text-primary transition-colors">Sign In</a>
                    </#if>
                    <a href="https://admin.growerp.com" class="bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-5 py-2.5 rounded-lg l-glow transition-all active:scale-95 flex items-center gap-2">
                        Get Started
                        <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
                    </a>
                <#elseif hasCommerce>
                    <#-- Desktop search -->
                    <form id="form-search" class="hidden lg:flex items-center bg-surface-container-high/60 border border-white/10 rounded-lg px-3 py-1.5 focus-within:border-primary/50 transition-colors">
                        <input type="text" name="search" placeholder="Search products..."
                               class="bg-transparent outline-none text-sm text-on-surface placeholder:text-outline w-40">
                        <button type="submit" class="text-on-surface-variant hover:text-primary transition-colors flex items-center">
                            <span class="material-symbols-outlined text-[20px]">search</span>
                        </button>
                    </form>

                    <#-- User Account -->
                    <#if partyDetail??>
                        <div class="relative">
                            <button type="button" data-menu-button="accountDropdown" aria-expanded="false"
                                    class="flex items-center gap-1 font-label text-sm text-on-surface-variant hover:text-primary transition-colors">
                                <span class="material-symbols-outlined text-[22px]">account_circle</span>
                                <span class="hidden lg:inline">${partyDetail.firstName}</span>
                                <span class="material-symbols-outlined text-[18px]">expand_more</span>
                            </button>
                            <div id="accountDropdown" data-dropdown-panel class="hidden absolute right-0 top-full mt-2 w-56 l-glass bg-surface-container/90 rounded-xl py-2 shadow-2xl">
                                <div class="px-4 py-2 border-b border-white/10">
                                    <strong class="block text-sm text-on-surface">${partyDetail.firstName} ${partyDetail.lastName}</strong>
                                    <#if partyDetail.organizationName?has_content>
                                    <small class="block text-xs text-on-surface-variant">${partyDetail.organizationName}</small>
                                    </#if>
                                </div>
                                <a href="/d#/account" class="flex items-center gap-2 px-4 py-2 text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">
                                    <span class="material-symbols-outlined text-[18px]">settings</span>Account Settings
                                </a>
                                <a href="/d#/orders" class="flex items-center gap-2 px-4 py-2 text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">
                                    <span class="material-symbols-outlined text-[18px]">package_2</span>My Orders
                                </a>
                                <form method="get" action="/logOut" class="border-t border-white/10 mt-1 pt-1">
                                    <button id="logout" type="submit" class="w-full flex items-center gap-2 px-4 py-2 text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">
                                        <span class="material-symbols-outlined text-[18px]">logout</span>Logout
                                    </button>
                                </form>
                            </div>
                        </div>
                    <#else>
                        <a href="/d#/account/create/${storeInfo.productStore.organizationPartyId}" class="hidden sm:inline-flex font-label text-sm text-on-surface-variant hover:text-primary transition-colors">Register</a>
                        <a href="/d#/login/${storeInfo.productStore.organizationPartyId}" class="font-label text-sm text-on-surface hover:text-primary transition-colors">Log In</a>
                    </#if>

                    <#-- Shopping Cart -->
                    <#assign cartCount = 0>
                    <#if cartInfo.orderItemList??>
                        <#list cartInfo.orderItemList as item>
                            <#if item.itemTypeEnumId == "ItemProduct">
                                <#assign cartCount = cartCount + (item.quantity!1)>
                            </#if>
                        </#list>
                    </#if>
                    <#if cartCount gt 0>
                        <a href="/d#/checkout/${storeInfo.productStore.organizationPartyId}" class="relative flex items-center text-on-surface-variant hover:text-primary transition-colors">
                    <#else>
                        <a href="#" onclick="document.getElementById('emptyCartModal').showModal(); return false;" class="relative flex items-center text-on-surface-variant hover:text-primary transition-colors">
                    </#if>
                        <span class="material-symbols-outlined text-[24px]">shopping_cart</span>
                        <span id="cart-quantity" class="absolute -top-2 -right-2 min-w-[18px] h-[18px] px-1 flex items-center justify-center rounded-full bg-primary text-on-primary text-[11px] font-bold">${cartCount}</span>
                    </a>
                </#if>

                <!-- Mobile hamburger -->
                <button type="button" data-menu-button="mobileMenu" aria-expanded="false" aria-label="Toggle navigation"
                        class="md:hidden flex items-center text-on-surface hover:text-primary transition-colors">
                    <span class="material-symbols-outlined text-[26px]">menu</span>
                </button>
            </div>
        </div>

        <!-- Mobile menu panel -->
        <div id="mobileMenu" data-dropdown-panel class="hidden md:hidden border-t border-white/10 bg-surface-container-lowest/90 px-4 py-4 space-y-1">
            <#if isMarketing>
                <#list storeInfo.menu as topItem>
                <#if !topItem.title?has_content || topItem.path == 'home'><#continue></#if>
                <#if topItem.path == 'pricing'>
                    <a href="/modules" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">Apps</a>
                </#if>
                <a href="/content/${topItem.path}" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">${topItem.title!topItem.path}</a>
                </#list>
                <#if (storeOwnerPartyId!'') != 'GROWERP'>
                <a href="https://admin.growerp.com" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">Sign In</a>
                </#if>
            <#else>
                <#if hasCommerce>
                    <span class="block px-2 pt-2 pb-1 text-xs uppercase tracking-wider text-outline">Shop</span>
                    <#list browseRootCategoryInfo.subCategoryList as category>
                        <a href="/category/${category.productCategoryId}" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">${category.categoryName}</a>
                    </#list>
                </#if>
                <#if ((storeInfo.categoryByType.PsctPromotions.nbrOfProducts)!0) != 0>
                    <a href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">${storeInfo.categoryByType.PsctPromotions.categoryName}</a>
                </#if>
                <#list storeInfo.menu as topItem>
                <#if !topItem.title?has_content || topItem.path == 'home'><#continue></#if>
                <#if topItem.items?has_content>
                    <span class="block px-2 pt-2 pb-1 text-xs uppercase tracking-wider text-outline">${topItem.title!topItem.path}</span>
                    <#list topItem.items as item>
                        <#if item.path??>
                        <a href="/content/${item.path}" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">${item.title!item.path}</a>
                        <#else>
                        <a href="/content/${topItem.path}#${item.anchor}" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">${item.text}</a>
                        </#if>
                    </#list>
                <#else>
                    <#if topItem.path == 'obsidian'>
                        <a href="/${topItem.path}" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">
                    <#else>
                        <a href="/content/${topItem.path}" class="block px-2 py-2 rounded-lg font-label text-sm text-on-surface hover:bg-primary/10 hover:text-primary transition-colors">
                    </#if>
                        ${topItem.title!topItem.path}
                    </a>
                </#if>
                </#list>
                <#if hasCommerce>
                <form id="form-search-mobile" class="flex items-center bg-surface-container-high/60 border border-white/10 rounded-lg px-3 py-2 mt-3">
                    <input type="text" name="search" placeholder="Search products..."
                           class="bg-transparent outline-none text-sm text-on-surface placeholder:text-outline flex-1">
                    <button type="submit" class="text-on-surface-variant hover:text-primary transition-colors flex items-center">
                        <span class="material-symbols-outlined text-[20px]">search</span>
                    </button>
                </form>
                </#if>
            </#if>
        </div>
    </nav>
</header>

<#if !isMarketing && hasCommerce>
<!-- Empty Cart Dialog -->
<dialog id="emptyCartModal" class="l-glass max-w-sm w-[90vw] p-0">
    <div class="p-6">
        <div class="flex items-center gap-3 mb-4">
            <span class="material-symbols-outlined text-primary text-[32px]">shopping_cart</span>
            <h5 class="font-display font-semibold text-lg text-on-surface">Your Cart is Empty</h5>
        </div>
        <p class="text-sm text-on-surface-variant mb-6">Browse our products and add some items to your cart to get started!</p>
        <div class="flex justify-end">
            <button type="button" onclick="document.getElementById('emptyCartModal').close()"
                    class="bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-5 py-2.5 rounded-lg transition-all active:scale-95">
                Continue Shopping
            </button>
        </div>
    </div>
</dialog>
</#if>
