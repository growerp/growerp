<#assign inStock = false>
<#if (product.productTypeEnumId == "PtVirtual")!false>
    <#assign isVirtual = true >
<#else>
    <#assign isVirtual = false >
    <#if productAvailability.get(productId)!false><#assign inStock = true></#if>
</#if>
<div class="container mt-2">
    <a class="customer-link" href="/">Home <i class="fas fa-angle-right"></i></a>
    <a class="customer-link">${product.productName}</a>
</div>
<div class="container container-text mt-1">
    <#if addedCorrect?? && addedCorrect == 'true'>
        <div class="alert alert-primary mt-3 mb-3" role="alert">
            <i class="far fa-check-square"></i> You added ${product.productName} to your shopping cart.
            <a class="float-right" href="/d#/checkout/${storeInfo.productStore.organizationPartyId}">Go to Checkout <i class="fas fa-arrow-right"></i></a>
        </div>
    </#if>
    <#--  <div class="row d-flex justify-content-center">
        <img id="spinner" class="product-spinner" src="/assets/spinner.gif">
    </div>  -->
    <div class="row mt-2">
        <div class="col col-lg-1 col-sm-4 col-4">
            <div>
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
                            class="figure-img img-fluid product-img"
                            src="/content/productImage/${img.productContentId}"
                            alt="Product Image">
                    </#if>
                </#list>
            </div>
        </div>
        <div class="col col-lg-4 col-sm-8 col-8">
            <img id="product-image-large" class="product-img-select" 
                <#if imgDetail>data-toggle="modal" data-target="#modal2"</#if>>
        </div>
        <div class="col col-lg-4 col-sm-12 col-12">
            <p>
                <span class="product-title">${product.productName}</span>
                <br>
                <span class="product-review-text">${reviewsList.productReviewList?size} reviews</span>
                <hr style="margin-top: -10px;">
                <br>
                <!--<#list 1..5 as x>
                    <span class="star-rating">
                        <i class="fas fa-star"></i>
                    </span>
                </#list> -->
            </p>
            <div class="product-description">
                <#if product.descriptionLong??>
                    ${product.descriptionLong}
                </#if>
            </div>
        </div>
        <div class="col col-lg-3">
            <form class="card cart-div" method="post" action="/product/addToCart">
                <div>
                    <#if product.listPrice??>
                        <span class="save-circle" v-if="product.listPrice">
                            <span class="save-circle-title">SAVE</span>
                            <span class="save-circle-text">${ec.l10n.formatCurrency((product.listPrice - product.price)?string(",##0.00"), product.priceUomId)}</span>
                        </span>
                    </#if>
                    <div class="form-group col">
                        <div class="cart-form-price">
                            <p>
                                <span class="price-text">${ec.l10n.formatCurrency(product.price, product.priceUomId)}</span> 
                                <#if product.listPrice??>
                                    <span>
                                        <span class="product-listprice-text">was</span>
                                        <del>${ec.l10n.formatCurrency(product.listPrice, product.priceUomId)}</del>
                                    </span>
                                </#if>
                            </p>
                        </div>
                        <hr class="product-hr" style="margin-top: -5px;">
                        <#--
                        <span class="product-description">On sale until midnight or until stocks last.</span>
                        <hr class="product-hr">
                        -->
                    </div>
                    <div class="form-group col">
                        <input type="hidden" value="${product.pseudoId}" name="productId" id="productId" />
                        <input type="hidden" value="${product.priceUomId}" name="currencyUomId" />
                        <input type="hidden" value="${ec.web.sessionToken}" name="moquiSessionToken"/>
                        <span class="product-description">Quantity</span>
                        <#if product.productTypeEnumId == 'PtAsset'>
                            <select class="form-control text-gdark" name="quantity" id="quantity">
                                <#if productQuantity.productQuantity??>
                                    <#list 1..productQuantity.productQuantity as x>
                                        <option value="${x}">${x}</option>
                                    </#list>
                                <#else>
                                    <option value="0">0</option>
                                </#if>
                            </select>
                        </#if>
                        <#if product.productTypeEnumId == 'PtService'>
                            <input type="text" name="quantity" id="quantity" value="1">
                        </#if>
                    </div>
                    <#if isVirtual>
                        <div class="form-group col">
                            <#assign featureTypes = variantsList.listFeatures.keySet()>
                            <#assign arrayIds = [] />
                            <#list featureTypes![] as featureType>
                                ${featureType.description!}
                                <#assign variants = variantsList.listFeatures.get(featureType)>
                                <select class="form-control" id="variantProduct${featureType?index}" required>
                                    <option value="" disabled selected>
                                        Select an Option 
                                    </option>
                                    <#list variants![] as variant>
                                        <option value="${variant.abbrev!}">
                                            ${variant.description!} 
                                        </option>
                                    </#list>
                                </select>
                            </#list>
                        </div>
                    </#if>
                </div>
                <#if inStock || product.requireInventory == 'N'>
                    <button onclick="onClickAddButton();" id="cartAdd" class="btn cart-form-btn col" type="submit" onclick="">
                        <i class="fa fa-shopping-cart"></i> Add to Cart
                    </button>
                <#else>
                    <h5 class="text-center">Out of Stock</h5>
                </#if>
            </form>
        </div>
    </div>
    <hr>
</div>

<div class="container mb-5">
    <span class="modal-text">Customer Reviews</span>
	<#list reviewsList.productReviewList as review>
  	<div class="review">
        <span class="modal-text">"${review.productReview}"</span>
        <br>
        <span class="star-rating review-text-size">
    		<#list 1..5 as x>
    			<#if (review.productRating >= x)>
					<i class="fas fa-star"></i>
                <#else>
					<i class="far fa-star"></i>
                </#if>
            </#list>
        </span>
        <span class="review-date review-text-size">
    		Reviewed by
    		<#if review.postedAnonymous == "Y">
    			Anonymous
            <#else>
                ${review.userId}
            </#if>
    		on ${review.postedDateTime}
    	</span>
        <br>
        <span class="review-text review-text-size">
            ${review.productReview}
        </span>
    </div>
    </#list>
    <br>
    <#if reviewsList.productReviewList?size == 0>
       <p class="review-message">There are no reviews yet. Be the first.</p>
    </#if>
    <button data-toggle="modal" data-target="#modal1" class="btn btn-continue review-btn">Write a Review</button>
</div>
<div class="modal fade" id="modal1">
    <div class="modal-dialog" role="document">
        <form class="modal-content" id="product-review-form" method="post" action="/product/addReview">
            <div class="modal-header">
                <h5 class="modal-title">Add an Review</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
            </div>
            <div class="modal-body">
                <input type="hidden" value="${ec.web.sessionToken}" name="moquiSessionToken" id="moquiSessionToken">
                <input type="hidden" value="${productId}" name="productId" id="productId">
                <input type="hidden" value="1" name="productRating" id="productRating">
                <label>Rating</label>
                <div class='rating-stars text-center'>
                    <ul id='stars'>
                        <li class='star' data-value='1'><i class='fa fa-star fa-fw'></i></li>
                        <li class='star' data-value='2'><i class='fa fa-star fa-fw'></i></li>
                        <li class='star' data-value='3'><i class='fa fa-star fa-fw'></i></li>
                        <li class='star' data-value='4'><i class='fa fa-star fa-fw'></i></li>
                        <li class='star' data-value='5'><i class='fa fa-star fa-fw'></i></li>
                    </ul>
                </div>
                <br>
                <label>Comments</label>
                <textarea class="form-control text-area-review" rows="5" name="productReview" id="productReview"></textarea>
            </div>
            <div class="modal-footer">
                <button class="btn btn-continue" id="addReview" type="submit">Add Review</button>
                <a data-dismiss="modal" class="btn btn-link">Or Cancel</a>
            </div>
        </form>
    </div>
</div>
<div class="modal fade" id="modal2">
    <div class="modal-dialog" role="document">
        <div class="modal-content" id="product-review-form">
            <div class="modal-header">
                <h5 class="modal-title">Image Detail</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
            </div>
            <div class="modal-body">
                <#if imgContent.productContentId??>
                    <img width="100%" height="200px" class="figure-img img-fluid product-img"
                        src="/content/productImage/${imgContent.productContentId}" alt="Product Image">
                </#if>
            </div>
            <div class="modal-footer">
                <a data-dismiss="modal" class="btn btn-link">Close</a>
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

    function changeLargeImage(productContentId) { $productImageLarge.src = prodImageUrl + productContentId; }
    //Default image
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
