<nav class="navbar navbar-expand-md navbar-dark bg-dark">
    <div class="d-flex flex-column moqui-navbar" style="background: transparent;">
        <div class="container d-flex flex-row main-navbar justify-content-between">
            <!-- Logo and Brand -->
            <a href="/" class="navbar-brand d-none d-sm-flex align-items-center">
                <img class="moqui-dynamic" src="/getLogo" alt="Home">
                <span class="navbar-title">${storeInfo.productStore.storeName}</span>
            </a>
            <a class="navbar-brand d-flex d-sm-none align-items-center" href="/">
                <img class="moqui-dynamic" src="/getLogo" alt="Home" style="width: 40px; height: 40px;">
                <span class="navbar-title">${storeInfo.productStore.storeName}</span>
            </a>
            
            <!-- Mobile Toggle -->
            <button class="navbar-toggler collapsed" type="button" data-toggle="collapse" data-target="#nav_collapse1"
                aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
        </div>
        
        <!-- Navigation Menu -->
        <div id="nav_collapse1" class="container navbar-collapse collapse">
            <ul class="navbar-nav">
                <#-- Shop Categories Dropdown -->
                <#if browseRootCategoryInfo.subCategoryList?has_content>
                <li class="nav-item dropdown">
                    <a class="nav-link" href="#" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        <i class="fas fa-shopping-bag mr-1"></i>Shop <i class="fas fa-chevron-down icon-down"></i>
                    </a>
                    <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
                        <#list browseRootCategoryInfo.subCategoryList as category>
                            <a class="dropdown-item item-color" href="/category/${category.productCategoryId}">
                                <i class="fas fa-tag mr-2"></i>${category.categoryName}
                            </a>
                        </#list>
                    </div>
                </li>
                </#if>
                
                <#-- Deals Button -->
                <#if storeInfo.categoryByType.PsctPromotions.nbrOfProducts != 0>
                    <a class="nav-link" href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}">
                        <i class="fas fa-fire mr-1"></i>${storeInfo.categoryByType.PsctPromotions.categoryName}
                    </a>
                </#if>

                <#-- Content Menu Items -->
                <#list storeInfo.menu as topItem>
                <#if !topItem.title?has_content || topItem.title?lower_case?starts_with('home')><#continue></#if>
                <#if topItem.items?has_content>
                <li class="nav-item dropdown">
                    <a class="nav-link" href="#" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        ${topItem.title!topItem.path} <i class="fas fa-chevron-down icon-down"></i>
                    </a>
                    <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
                    <#list topItem.items as item>
                        <a class="dropdown-item item-color" href="/content/${topItem.path}#${item.anchor}">${item.text}</a>
                    </#list>
                    </div>
                </li>
                <#else>
                    <#if topItem.path == 'obsidian'>
                        <a class="nav-link" href="/${topItem.path}">
                    <#else>    
                        <a class="nav-link" href="/content/${topItem.path}">
                    </#if>
                        ${topItem.title!topItem.path}
                    </a>
                </#if>
                </#list>
            </ul>

            <!-- Right Aligned Nav Items -->
            <#if storeInfo.productStore.productStoreId != "100000">
            <ul class="navbar-nav ml-auto align-items-center">
                <#-- User Account Dropdown -->
                <#if partyDetail??>
                    <li class="nav-item dropdown">
                        <a class="nav-link d-flex align-items-center" href="#" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                            <span class="user-avatar mr-2">
                                <i class="fas fa-user-circle fa-lg"></i>
                            </span>
                            <span class="d-none d-lg-inline">${partyDetail.firstName}</span>
                            <i class="fas fa-chevron-down icon-down ml-1"></i>
                        </a>
                        <div class="dropdown-menu dropdown-menu-right" aria-labelledby="navbarDropdownMenuLink">
                            <div class="dropdown-header">
                                <strong>${partyDetail.firstName} ${partyDetail.lastName}</strong>
                                <#if partyDetail.organizationName?has_content>
                                <small class="d-block text-muted">${partyDetail.organizationName}</small>
                                </#if>
                            </div>
                            <div class="dropdown-divider"></div>
                            <a class="dropdown-item item-color" href="/d#/account">
                                <i class="fas fa-cog mr-2"></i>Account Settings
                            </a>
                            <a class="dropdown-item item-color" href="/d#/orders">
                                <i class="fas fa-box mr-2"></i>My Orders
                            </a>
                            <div class="dropdown-divider"></div>
                            <form method="get" action="/logOut">
                                <button id="logout" type="submit" class="dropdown-item item-color">
                                    <i class="fas fa-sign-out-alt mr-2"></i>Logout
                                </button>
                            </form>
                        </div>
                    </li>
                <#else>
                    <li class="nav-item">
                        <a href="/d#/account/create/${storeInfo.productStore.organizationPartyId}" class="nav-link">
                            <i class="fas fa-user-plus mr-1"></i>Register
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="/d#/login/${storeInfo.productStore.organizationPartyId}" class="nav-link">
                            <i class="fas fa-sign-in-alt mr-1"></i>Log In
                        </a>
                    </li>
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
                <li class="nav-item">
                    <#if cartCount gt 0>
                        <a class="nav-link cart-link" href="/d#/checkout/${storeInfo.productStore.organizationPartyId}">
                    <#else>
                        <a class="nav-link cart-link pointer" data-toggle="modal" data-target="#emptyCartModal">
                    </#if>
                        <span class="cart-icon-wrapper">
                            <i class="fas fa-shopping-cart"></i>
                            <span class="cart-quantity" id="cart-quantity">${cartCount}</span>
                        </span>
                        <span class="d-none d-md-inline ml-1">Cart</span>
                    </a>
                </li>
                
                <#-- Admin Link -->
                <li class="nav-item">
                    <a href="/admin/" class="nav-link admin-link" title="Administration Panel">
                        <i class="fas fa-cogs"></i>
                        <span class="d-none d-lg-inline ml-1">Admin</span>
                    </a>
                </li>
                
                <#-- Mobile Search -->
                <li class="nav-item d-block d-sm-block d-md-none mt-3">
                    <form id="form-search-mobile" class="search-input">
                        <input type="text" placeholder="Search products..." name="search">
                        <button class="search-button" type="submit">
                            <i class="fa fa-search"></i>
                        </button>
                    </form>
                </li>
            </ul>
            </#if>
        </div>
    </div>
</nav>

<!-- Empty Cart Modal -->
<div class="modal fade" id="emptyCartModal" tabindex="-1" role="dialog" aria-labelledby="emptyCartModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <div class="d-flex align-items-center">
                    <i class="fas fa-shopping-cart fa-2x mr-3" style="color: var(--primary-500);"></i>
                    <h5 class="modal-title mb-0" id="emptyCartModalLabel">Your Cart is Empty</h5>
                </div>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p class="mb-0">Browse our products and add some items to your cart to get started!</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-continue" data-dismiss="modal">Continue Shopping</button>
            </div>
        </div>
    </div>
</div>

