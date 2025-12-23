<#assign inStock = false>
<#if (product.productTypeEnumId == "PtVirtual")!false>
    <#assign isVirtual = true >
<#else>
    <#assign isVirtual = false >
    <#if productAvailability.get(productId)!false><#assign inStock = true></#if>
</#if>

<!-- Breadcrumb Navigation -->
<div class="container mt-4">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb" style="background: none; padding: 0; margin: 0;">
            <li class="breadcrumb-item">
                <a href="/" class="customer-link" style="color: var(--primary-600);">
                    <i class="fas fa-home mr-1"></i>Home
                </a>
            </li>
            <li class="breadcrumb-item active" aria-current="page" style="color: var(--neutral-500);">
                ${product.productName}
            </li>
        </ol>
    </nav>
</div>

<!-- Success Alert -->
<div class="container">
    <#if addedCorrect?? && addedCorrect == 'true'>
        <div class="alert mt-3 mb-4" role="alert" style="background: linear-gradient(135deg, var(--success), #059669); color: white; border: none; border-radius: var(--radius-md); padding: 1rem 1.5rem;">
            <div class="d-flex align-items-center justify-content-between">
                <div>
                    <i class="fas fa-check-circle mr-2"></i>
                    <strong>${product.productName}</strong> has been added to your cart!
                </div>
                <a href="/d#/checkout/${storeInfo.productStore.organizationPartyId}" class="btn btn-light btn-sm" style="font-weight: 600;">
                    Checkout <i class="fas fa-arrow-right ml-1"></i>
                </a>
            </div>
        </div>
    </#if>
</div>

<!-- Product Details -->
<div class="container container-text">
    <div class="row mt-3">
        <!-- Product Thumbnails -->
        <div class="col-lg-1 col-md-2 col-sm-3 col-3 order-1 order-lg-1">
            <div class="product-thumbnails">
                <#assign imgDetail = false/>
                <#assign imgExists = false/>
                <#list product.contentList as img>
                    <#if img.productContentTypeEnumId == "PcntImageDetail">
                        <#assign imgDetail = true/>
                        <#if imgContent??>
                            <#assign imgContent = img>
                        <#else>
                            <#if imgContent.sequenceNum > img.sequenceNum>
                                <#assign imgContent = img>
                            </#if>
                        </#if>
                    </#if>
                    <#if img.productContentTypeEnumId == "PcntImageSmall">
                        <#assign imgExists = true/>
                        <img onClick="changeLargeImage('${img.productContentId}');"
                            class="figure-img img-fluid product-img mb-2"
                            src="/content/productImage/${img.productContentId}"
                            alt="Product thumbnail"
                            style="border-radius: var(--radius-md); cursor: pointer; transition: all 0.2s ease;">
                    </#if>
                </#list>
            </div>
        </div>
        
        <!-- Main Product Image -->
        <div class="col-lg-5 col-md-5 col-sm-9 col-9 order-2 order-lg-2">
            <div class="product-image-container" style="position: relative; overflow: hidden; border-radius: var(--radius-lg); background: #fff; box-shadow: var(--shadow-md);">
                <img id="product-image-large" class="product-img-select" style="width: 100%; height: auto;"
                    <#if imgDetail>data-toggle="modal" data-target="#modal2"</#if>>
            </div>
        </div>
        
        <!-- Product Info -->
        <div class="col-lg-3 col-md-5 col-12 order-4 order-lg-3 mt-4 mt-lg-0">
            <h1 class="product-title" style="font-size: 1.75rem; line-height: 1.3;">${product.productName}</h1>
            
            <!-- Reviews Summary -->
            <div class="product-reviews-summary mt-2 mb-3">
                <#if reviewsList.productReviewList?size gt 0>
                    <span class="star-rating">
                        <#list 1..5 as x>
                            <i class="fas fa-star" style="color: var(--gold);"></i>
                        </#list>
                    </span>
                    <a href="#reviews" class="ml-2" style="color: var(--primary-600); font-size: 0.9rem;">
                        ${reviewsList.productReviewList?size} review<#if reviewsList.productReviewList?size gt 1>s</#if>
                    </a>
                <#else>
                    <span style="color: var(--neutral-400); font-size: 0.9rem;">
                        <i class="far fa-star mr-1"></i>No reviews yet
                    </span>
                </#if>
            </div>
            
            <!-- Product Description -->
            <div class="product-description" style="color: var(--neutral-600); line-height: 1.7;">
                <#if product.descriptionLong??>
                    ${product.descriptionLong}
                <#elseif product.description??>
                    ${product.description}
                <#else>
                    <p style="color: var(--neutral-400);">No description available.</p>
                </#if>
            </div>
        </div>
        
        <!-- Add to Cart Card -->
        <div class="col-lg-3 col-12 order-3 order-lg-4 mt-4 mt-lg-0">
            <form class="card cart-div" method="post" action="/product/addToCart" style="position: sticky; top: 100px;">
                <div class="card-body">
                    <!-- Save Badge -->
                    <#if product.listPrice??>
                        <div class="save-badge mb-3" style="display: inline-block; background: linear-gradient(135deg, var(--gold-light), var(--gold)); color: var(--neutral-900); padding: 0.5rem 1rem; border-radius: var(--radius-full); font-weight: 700; font-size: 0.85rem;">
                            <i class="fas fa-tag mr-1"></i>SAVE ${ec.l10n.formatCurrency((product.listPrice - product.price)?string(",##0.00"), product.priceUomId)}
                        </div>
                    </#if>
                    
                    <!-- Price Display -->

                    <div class="price-section mb-4">
                        <#if product.price?? && product.price gt 0>
                            <div class="price-text" style="font-size: 2rem; font-weight: 700; color: var(--accent-600);">
                                ${ec.l10n.formatCurrency(product.price, product.priceUomId)}
                            </div>
                            <#if product.listPrice?? && product.listPrice gt product.price>
                                <div style="color: var(--neutral-400); font-size: 0.9rem;">
                                    <span>was </span>
                                    <del>${ec.l10n.formatCurrency(product.listPrice, product.priceUomId)}</del>
                                </div>
                            </#if>
                        <#elseif product.listPrice?? && product.listPrice gt 0>
                             <div class="price-text" style="font-size: 2rem; font-weight: 700; color: var(--accent-600);">
                                ${ec.l10n.formatCurrency(product.listPrice, product.priceUomId)}
                            </div>
                        <#else>
                             <div class="price-text" style="font-size: 2rem; font-weight: 700; color: var(--accent-600);">
                                Free
                            </div>
                        </#if>
                    </div>
                    
                    <hr style="border-color: var(--neutral-200);">
                    
                    <!-- Hidden Fields -->
                    <input type="hidden" value="${product.productId}" name="productId" id="productId" />
                    <input type="hidden" value="${product.priceUomId}" name="currencyUomId" />
                    <input type="hidden" value="${ec.web.sessionToken}" name="moquiSessionToken"/>
                    
                    <!-- Quantity Selection -->
                    <#if product.productTypeEnumId == 'PtAsset'>
                        <div class="form-group">
                            <label style="font-weight: 600; color: var(--neutral-700);">Quantity</label>
                            <select class="form-control" name="quantity" id="quantity" style="border-radius: var(--radius-md); border-color: var(--neutral-300);">
                                <#if productQuantity.productQuantity??>
                                    <#list 1..productQuantity.productQuantity as x>
                                        <option value="${x}">${x}</option>
                                    </#list>
                                <#else>
                                    <option value="0">0</option>
                                </#if>
                            </select>
                        </div>
                    </#if>
                    <#if product.productTypeEnumId == 'PtService'>
                        <div class="form-group">
                            <label style="font-weight: 600; color: var(--neutral-700);">Quantity</label>
                            <input type="number" name="quantity" id="quantity" value="1" min="1" class="form-control" style="border-radius: var(--radius-md);">
                        </div>
                    </#if>
                    <#if product.productTypeEnumId == 'PtFixedAssetUse'>
                        <div class="form-group">
                            <label style="font-weight: 600; color: var(--neutral-700);">Start Date</label>
                            <input type="date" name="fromDate" id="fromDate" class="form-control" style="border-radius: var(--radius-md);">
                        </div>
                        <div class="form-group">
                            <label style="font-weight: 600; color: var(--neutral-700);">Number of Days</label>
                            <input type="number" name="quantity" id="quantity" value="1" min="1" class="form-control" style="border-radius: var(--radius-md);">
                        </div>
                    </#if>
                    
                    <!-- Variant Selection -->
                    <#if isVirtual>
                        <#assign featureTypes = variantsList.listFeatures.keySet()>
                        <#list featureTypes![] as featureType>
                            <div class="form-group">
                                <label style="font-weight: 600; color: var(--neutral-700);">${featureType.description!}</label>
                                <#assign variants = variantsList.listFeatures.get(featureType)>
                                <select class="form-control" id="variantProduct${featureType?index}" required style="border-radius: var(--radius-md);">
                                    <option value="" disabled selected>Select an option</option>
                                    <#list variants![] as variant>
                                        <option value="${variant.abbrev!}">${variant.description!}</option>
                                    </#list>
                                </select>
                            </div>
                        </#list>
                    </#if>
                    
                    <!-- Add to Cart Button -->
                    <#if inStock || product.requireInventory == 'N'>
                        <button onclick="onClickAddButton();" id="cartAdd" class="btn btn-block mt-3" type="submit" 
                            style="background: linear-gradient(135deg, var(--accent-500), var(--accent-600)); color: white; border: none; border-radius: var(--radius-md); padding: 0.875rem 1.5rem; font-weight: 600; font-size: 1rem; transition: all 0.2s ease;">
                            <i class="fas fa-shopping-cart mr-2"></i>Add to Cart
                        </button>
                    <#else>
                        <div class="text-center py-3">
                            <span class="badge badge-secondary" style="font-size: 1rem; padding: 0.75rem 1.5rem; background: var(--neutral-400);">
                                <i class="fas fa-times-circle mr-1"></i>Out of Stock
                            </span>
                        </div>
                    </#if>
                    
                    <!-- Trust Badges -->
                    <div class="trust-badges mt-4 text-center" style="color: var(--neutral-500); font-size: 0.8rem;">
                        <div class="d-flex justify-content-around">
                            <span><i class="fas fa-lock mr-1" style="color: var(--success);"></i>Secure</span>
                            <span><i class="fas fa-truck mr-1" style="color: var(--primary-500);"></i>Fast Shipping</span>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>
    
    <hr style="margin: 3rem 0; border-color: var(--neutral-200);">
</div>

<!-- Customer Reviews Section -->
<div class="container mb-5" id="reviews">
    <div class="row">
        <div class="col-lg-8">
            <h2 class="modal-text mb-4">
                <i class="fas fa-comments mr-2" style="color: var(--primary-500);"></i>Customer Reviews
            </h2>
            
            <#if reviewsList.productReviewList?size == 0>
                <div class="text-center py-5" style="background: var(--neutral-50); border-radius: var(--radius-lg);">
                    <i class="far fa-comment-dots fa-3x mb-3" style="color: var(--neutral-300);"></i>
                    <p style="color: var(--neutral-500);">No reviews yet. Be the first to share your experience!</p>
                </div>
            <#else>
                <#list reviewsList.productReviewList as review>
                    <div class="review mb-4" style="background: white; padding: 1.5rem; border-radius: var(--radius-lg); box-shadow: var(--shadow-sm);">
                        <div class="d-flex justify-content-between align-items-start mb-2">
                            <div>
                                <span class="star-rating">
                                    <#list 1..5 as x>
                                        <#if (review.productRating >= x)>
                                            <i class="fas fa-star" style="color: var(--gold);"></i>
                                        <#else>
                                            <i class="far fa-star" style="color: var(--gold);"></i>
                                        </#if>
                                    </#list>
                                </span>
                            </div>
                            <span class="review-date" style="color: var(--neutral-400); font-size: 0.85rem;">
                                ${review.postedDateTime}
                            </span>
                        </div>
                        <p class="review-text mb-2" style="color: var(--neutral-700); line-height: 1.6;">"${review.productReview}"</p>
                        <div class="reviewer" style="color: var(--neutral-500); font-size: 0.85rem;">
                            <i class="fas fa-user-circle mr-1"></i>
                            <#if review.postedAnonymous == "Y">
                                Anonymous
                            <#else>
                                ${review.userId}
                            </#if>
                        </div>
                    </div>
                </#list>
            </#if>
            
            <button data-toggle="modal" data-target="#modal1" class="btn btn-continue review-btn mt-3">
                <i class="fas fa-pen mr-2"></i>Write a Review
            </button>
        </div>
    </div>
</div>

<!-- Review Modal -->
<div class="modal fade" id="modal1">
    <div class="modal-dialog modal-dialog-centered" role="document">
        <form class="modal-content" id="product-review-form" method="post" action="/product/addReview">
            <div class="modal-header">
                <h5 class="modal-title">
                    <i class="fas fa-star mr-2" style="color: var(--gold);"></i>Write a Review
                </h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <input type="hidden" value="${ec.web.sessionToken}" name="moquiSessionToken" id="moquiSessionToken">
                <input type="hidden" value="${productId}" name="productId" id="productId">
                <input type="hidden" value="1" name="productRating" id="productRating">
                
                <div class="form-group">
                    <label style="font-weight: 600;">Your Rating</label>
                    <div class='rating-stars text-center py-2'>
                        <ul id='stars' style="padding: 0; margin: 0;">
                            <li class='star' data-value='1' style="display: inline-block; cursor: pointer;"><i class='fas fa-star fa-2x' style="color: var(--neutral-300);"></i></li>
                            <li class='star' data-value='2' style="display: inline-block; cursor: pointer;"><i class='fas fa-star fa-2x' style="color: var(--neutral-300);"></i></li>
                            <li class='star' data-value='3' style="display: inline-block; cursor: pointer;"><i class='fas fa-star fa-2x' style="color: var(--neutral-300);"></i></li>
                            <li class='star' data-value='4' style="display: inline-block; cursor: pointer;"><i class='fas fa-star fa-2x' style="color: var(--neutral-300);"></i></li>
                            <li class='star' data-value='5' style="display: inline-block; cursor: pointer;"><i class='fas fa-star fa-2x' style="color: var(--neutral-300);"></i></li>
                        </ul>
                    </div>
                </div>
                
                <div class="form-group">
                    <label style="font-weight: 600;">Your Review</label>
                    <textarea class="form-control" rows="4" name="productReview" id="productReview" 
                        placeholder="Share your experience with this product..." 
                        style="border-radius: var(--radius-md); resize: none;"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-link" data-dismiss="modal" style="color: var(--neutral-500);">Cancel</button>
                <button class="btn btn-continue" id="addReview" type="submit">
                    <i class="fas fa-paper-plane mr-1"></i>Submit Review
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Image Detail Modal -->
<div class="modal fade" id="modal2">
    <div class="modal-dialog modal-lg modal-dialog-centered" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">
                    <i class="fas fa-image mr-2" style="color: var(--primary-500);"></i>Product Image
                </h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body text-center">
                <#if imgContent.productContentId??>
                    <img class="img-fluid" src="/content/productImage/${imgContent.productContentId}" 
                        alt="Product Image" style="border-radius: var(--radius-md); max-height: 80vh;">
                </#if>
            </div>
        </div>
    </div>
</div>

<script>
    var prodImageUrl = "/content/productImage/";
    var $productImageLarge = document.getElementById("product-image-large");

    document.body.onload = function() {
        <#if isVirtual>
            var productAvailability = ${productAvailability?replace('=',':')};
            var variantIdList = [];
            <#list 0..variantsList.listFeatures.keySet()?size - 1  as x>
                $('#variantProduct${x}').on('change', function() {
                    var productVariantId = $('#productId').val();
                    variantIdList[${x}] = this.value;
                    if(typeof(variantIdList[1]) != 'undefined') {
                        productVariantId = productVariantId + '_' + variantIdList[1] + '_' + variantIdList[0];
                    } else {
                        productVariantId = productVariantId + '_' + variantIdList[0];
                    }
                });
            </#list>
        </#if> 
    }

    function onClickAddButton() {
        $('#spinner').show();
    }

    function changeLargeImage(productContentId) { 
        $productImageLarge.src = prodImageUrl + productContentId; 
        // Add click feedback
        $productImageLarge.style.opacity = '0.7';
        setTimeout(function() {
            $productImageLarge.style.opacity = '1';
        }, 150);
    }
    
    // Default image
    <#if product.contentList?has_content && imgExists>
        changeLargeImage("${product.contentList[0].productContentId}");
    <#else>
        $productImageLarge.src = "/assets/default.png";
    </#if>
    
    function setStarNumber(number) {
        var productRating = document.getElementById("productRating");
        productRating.value = number;
    }
</script>
