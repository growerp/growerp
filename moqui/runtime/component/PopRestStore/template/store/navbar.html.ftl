<nav class="navbar navbar-expand-md navbar-dark bg-dark">
    <div class="d-flex flex-column moqui-navbar">
        <div class="container d-flex flex-row main-navbar">         
            <#--  This renders the logo dynamically for the main store  -->
            <a href="/" class="navbar-brand d-none d-sm-block">
                <img height="60px" class="moqui-dynamic" src="/getLogo" alt="Home">
                <span class="font-italic navbar-title">${storeInfo.productStore.storeName}</span>
            </a>
             <a class="navbar-brand d-block d-sm-none" href="/">
                <span class="font-italic navbar-title">${storeInfo.productStore.storeName}...</span>
            </a>
            <button class="navbar-toggler collapsed" type="button" data-toggle="collapse" data-target="#nav_collapse1"
                aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>
            <!--div class="navbar-collapse collapse">
                <form id="form-search" class="search-input" action="#">
                    <input type="text" placeholder="Search..." name="search" id="search" value="${(searchParameter!'')?html}">
                    <button class="search-button" type="submit">
                        <i class="fa fa-search"></i>
                    </button>
                </form>
                <!--ul class="navbar-nav ml-auto">
                    <div class="text-secondary">
                        <span class="navbar-pop-title">Interesting for you?</span>
                        <span class="text-center navbar-pop-subtitle">Quality 100% Guaranted</span>
                    </div>
                </ul-->
            </div-->
        </div>
        <div id="nav_collapse1" class="container navbar-collapse collapse">
            <ul class="navbar-nav">
              <#if browseRootCategoryInfo.subCategoryList?has_content>
                <li class="nav-item dropdown">
                    <a class="nav-link" href="#" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Shop <i class="fas fa-angle-down icon-down"></i></a>
                    
                    <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
                        <#list browseRootCategoryInfo.subCategoryList as category>
                            <a class="dropdown-item item-color" href="/category/${category.productCategoryId}">
                                ${category.categoryName}
                            </a>
                        </#list>
                    </div>
                </li>
              </#if>
                <#-- deals button -->
                <#if storeInfo.categoryByType.PsctPromotions.nbrOfProducts != 0>
                    <a class="nav-link" href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}">
                        ${storeInfo.categoryByType.PsctPromotions.categoryName}
                    </a>
                </#if>

                <#-- top menu items from content markdown -->
                <#list storeInfo.menu as topItem>
                <#if !topItem.title?has_content || topItem.title?lower_case?starts_with('home')><#continue></#if>
                <#if topItem.items?has_content>
                <li class="nav-item dropdown">
                    <a class="nav-link" href="#" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                        ${topItem.title!topItem.path}<i class="fas fa-angle-down icon-down"></i>
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

            <!-- Right aligned nav items -->
            <ul class="navbar-nav ml-auto">
                <#if partyDetail??>
                    <li class="nav-item dropdown">
                        <a class="nav-link" href="#" id="navbarDropdownMenuLink" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                            <i class="fas fa-user"></i>
                            ${partyDetail.firstName} ${partyDetail.lastName} ${partyDetail.organizationName!} <i class="fas fa-angle-down icon-down"></i>
                        </a>
                        <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
                            <a class="dropdown-item item-color" href="/d#/account">Account Settings</a>
                            <a class="dropdown-item item-color" href="/d#/orders">My Orders</a>
                            <div role="separator" class="dropdown-divider"></div>
                            <form method="get" action="/logOut">
                                <button id="logout" type="submit" class="dropdown-item item-color">Logout</button>
                            </form>
                        </div>
                    </li>
                <#else>
                    <li class="nav-item">
                        <a href="/d#/account/create/${storeInfo.productStore.organizationPartyId}" class="nav-link">Register</a>
                    </li>
                    <li class="nav-item">
                        <a href="/d#/login/${storeInfo.productStore.organizationPartyId}" class="nav-link"><i class="fas fa-user"></i> Log In</a>
                    </li>
                </#if>

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
                        <a class="nav-link" href="/d#/checkout/${storeInfo.productStore.organizationPartyId}">
                    <#else>
                        <a class="nav-link pointer" data-toggle="modal" data-target="#emptyCartModal">
                    </#if>
                        <span class="cart-quantity" id="cart-quantity">

                            ${cartCount}
                        </span>
                        <i class="fa fa-shopping-cart"></i>  
                        Cart
                    </a>
                </li>
                <li class="nav-item d-block d-sm-block d-md-none">
                    <div class="search-input">
                        <input type="text" placeholder="Search...">
                        <button class="search-button">
                            <i class="fa fa-search"></i>
                        </button>
                    </div>
                </li>
            </ul>
        </div>
    </div>
</nav>
<div class="modal fade" id="emptyCartModal" tabindex="-1" role="dialog" aria-labelledby="emptyCartModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title justify-content-center" id="emptyCartModalLabel">Your cart is empty.</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
                </button>
            </div>
        <div class="modal-body">
            Add a product to your cart (or a few!) before going to the check out.
        </div>
        <div class="modal-footer">
            <button type="button" class="btn btn-info" data-dismiss="modal">Close</button>
        </div>
        </div>
    </div>
</div>
</div>
