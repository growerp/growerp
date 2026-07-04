<#assign inStock = false>
<#if (product.productTypeEnumId == "PtVirtual")!false>
    <#assign isVirtual = true >
<#else>
    <#assign isVirtual = false >
    <#if productAvailability.get(productId)!false><#assign inStock = true></#if>
</#if>

<div class="max-w-container mx-auto px-4 md:px-12 pt-24 pb-8">
    <!-- Breadcrumb Navigation -->
    <nav aria-label="breadcrumb" class="mb-4">
        <ol class="flex items-center gap-2 text-sm">
            <li>
                <a href="/" class="flex items-center gap-1 text-primary hover:text-primary/80 transition-colors">
                    <span class="material-symbols-outlined text-[16px]">home</span>Home
                </a>
            </li>
            <li class="text-outline">/</li>
            <li class="text-on-surface-variant" aria-current="page">${product.productName}</li>
        </ol>
    </nav>

    <!-- Success Alert -->
    <#if addedCorrect?? && addedCorrect == 'true'>
        <div class="l-glass !border-primary/40 bg-primary-container/20 rounded-xl px-5 py-4 mb-6 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3" role="alert">
            <div class="flex items-center gap-2 text-on-surface">
                <span class="material-symbols-outlined text-primary">check_circle</span>
                <span><strong>${product.productName}</strong> has been added to your cart!</span>
            </div>
            <a href="/d#/checkout/${storeInfo.productStore.organizationPartyId}" class="inline-flex items-center gap-1 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-4 py-2 rounded-lg transition-all active:scale-95">
                Checkout <span class="material-symbols-outlined text-[16px]">arrow_forward</span>
            </a>
        </div>
    </#if>

    <!-- Product Details -->
    <div class="grid grid-cols-12 gap-6">
        <!-- Product Thumbnails -->
        <div class="col-span-3 sm:col-span-2 lg:col-span-1 order-1">
            <div class="flex flex-col gap-2">
                <#assign imgDetail = false/>
                <#assign imgExists = false/>
                <#list product.contentList as img>
                    <#if img.productContentTypeEnumId == "PcntImageDetail">
                        <#assign imgDetail = true/>
                        <#if !imgContent??>
                            <#assign imgContent = img>
                        <#elseif (imgContent.sequenceNum!0) gt (img.sequenceNum!0)>
                            <#assign imgContent = img>
                        </#if>
                    </#if>
                    <#if img.productContentTypeEnumId == "PcntImageSmall">
                        <#assign imgExists = true/>
                        <img onClick="changeLargeImage('${img.productContentId}');"
                            class="w-full rounded-lg border border-white/10 cursor-pointer hover:border-primary/50 transition-colors bg-surface-container-high"
                            src="/content/productImage/${img.productContentId}"
                            alt="Product thumbnail">
                    </#if>
                </#list>
            </div>
        </div>

        <!-- Main Product Image -->
        <div class="col-span-9 sm:col-span-10 lg:col-span-5 order-2">
            <div class="l-glass rounded-2xl overflow-hidden">
                <img id="product-image-large" class="w-full h-auto object-contain bg-surface-container-high"
                    <#if imgDetail>onclick="document.getElementById('imageDialog').showModal();" style="cursor: zoom-in;"</#if>>
            </div>
        </div>

        <!-- Product Info -->
        <div class="col-span-12 lg:col-span-3 order-4 lg:order-3">
            <h1 class="font-display text-2xl font-bold text-on-surface leading-snug">${product.productName}</h1>

            <!-- Reviews Summary -->
            <div class="mt-2 mb-4">
                <#if reviewsList.productReviewList?size gt 0>
                    <span class="inline-flex items-center">
                        <#list 1..5 as x>
                            <span class="material-symbols-outlined icon-fill text-tertiary text-[18px]">star</span>
                        </#list>
                    </span>
                    <a href="#reviews" class="ml-2 text-sm text-primary hover:text-primary/80 transition-colors">
                        ${reviewsList.productReviewList?size} review<#if reviewsList.productReviewList?size gt 1>s</#if>
                    </a>
                <#else>
                    <span class="text-sm text-on-surface-variant/70 inline-flex items-center gap-1">
                        <span class="material-symbols-outlined text-[16px]">star</span>No reviews yet
                    </span>
                </#if>
            </div>

            <!-- Product Description -->
            <div class="prose-lumina">
                <#if product.descriptionLong??>
                    ${product.descriptionLong}
                <#elseif product.description??>
                    ${product.description}
                <#else>
                    <p class="text-on-surface-variant/60">No description available.</p>
                </#if>
            </div>
        </div>

        <!-- Add to Cart Card -->
        <div class="col-span-12 lg:col-span-3 order-3 lg:order-4">
            <form method="post" action="/product/addToCart" class="l-glass rounded-2xl p-6 lg:sticky lg:top-24 block">
                <!-- Save Badge -->
                <#if product.listPrice??>
                    <div class="inline-flex items-center gap-1 bg-tertiary/15 border border-tertiary/30 text-tertiary px-3 py-1.5 rounded-full font-label text-xs font-bold mb-4">
                        <span class="material-symbols-outlined text-[14px]">sell</span>SAVE ${ec.l10n.formatCurrency((product.listPrice - product.price)?string(",##0.00"), product.priceUomId)}
                    </div>
                </#if>

                <!-- Price Display -->
                <div class="mb-5">
                    <#if product.price?? && product.price gt 0>
                        <div class="font-display text-3xl font-bold text-primary">
                            ${ec.l10n.formatCurrency(product.price, product.priceUomId)}
                        </div>
                        <#if product.listPrice?? && product.listPrice gt product.price>
                            <div class="text-sm text-on-surface-variant/70">
                                was <del>${ec.l10n.formatCurrency(product.listPrice, product.priceUomId)}</del>
                            </div>
                        </#if>
                    <#elseif product.listPrice?? && product.listPrice gt 0>
                        <div class="font-display text-3xl font-bold text-primary">
                            ${ec.l10n.formatCurrency(product.listPrice, product.priceUomId)}
                        </div>
                    <#else>
                        <div class="font-display text-3xl font-bold text-primary">Free</div>
                    </#if>
                </div>

                <hr class="border-white/10 mb-5">

                <!-- Hidden Fields -->
                <input type="hidden" value="${product.productId}" name="productId" id="productId" />
                <input type="hidden" value="${product.priceUomId}" name="currencyUomId" />
                <input type="hidden" value="${ec.web.sessionToken}" name="moquiSessionToken"/>

                <!-- Quantity Selection -->
                <#if product.productTypeEnumId == 'PtAsset'>
                    <div class="mb-4">
                        <label class="block font-label text-sm font-semibold text-on-surface mb-1" for="quantity">Quantity</label>
                        <select class="w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors" name="quantity" id="quantity">
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
                    <div class="mb-4">
                        <label class="block font-label text-sm font-semibold text-on-surface mb-1" for="quantity">Quantity</label>
                        <input type="number" name="quantity" id="quantity" value="1" min="1"
                               class="w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors">
                    </div>
                </#if>
                <#if product.productTypeEnumId == 'PtFixedAssetUse'>
                    <div class="mb-4">
                        <label class="block font-label text-sm font-semibold text-on-surface mb-1" for="fromDate">Start Date</label>
                        <input type="date" name="fromDate" id="fromDate"
                               class="w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors">
                    </div>
                    <div class="mb-4">
                        <label class="block font-label text-sm font-semibold text-on-surface mb-1" for="quantity">Number of Days</label>
                        <input type="number" name="quantity" id="quantity" value="1" min="1"
                               class="w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors">
                    </div>
                </#if>

                <!-- Variant Selection -->
                <#if isVirtual>
                    <#assign featureTypes = variantsList.listFeatures.keySet()>
                    <#list featureTypes![] as featureType>
                        <div class="mb-4">
                            <label class="block font-label text-sm font-semibold text-on-surface mb-1" for="variantProduct${featureType?index}">${featureType.description!}</label>
                            <#assign variants = variantsList.listFeatures.get(featureType)>
                            <select class="w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors" id="variantProduct${featureType?index}" required>
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
                    <button id="cartAdd" type="submit"
                            class="w-full flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-semibold px-6 py-3.5 rounded-lg l-glow transition-all active:scale-95 mt-2">
                        <span class="material-symbols-outlined text-[20px]">shopping_cart</span>Add to Cart
                    </button>
                <#else>
                    <div class="text-center py-3">
                        <span class="inline-flex items-center gap-1 bg-surface-container-highest text-on-surface-variant px-6 py-3 rounded-lg font-label text-sm">
                            <span class="material-symbols-outlined text-[18px]">cancel</span>Out of Stock
                        </span>
                    </div>
                </#if>

                <!-- Trust Badges -->
                <div class="flex justify-around mt-5 text-xs text-on-surface-variant/80">
                    <span class="flex items-center gap-1"><span class="material-symbols-outlined text-primary text-[16px]">lock</span>Secure</span>
                    <span class="flex items-center gap-1"><span class="material-symbols-outlined text-primary text-[16px]">local_shipping</span>Fast Shipping</span>
                </div>
            </form>
        </div>
    </div>

    <hr class="my-12 border-white/10">

    <!-- Customer Reviews Section -->
    <div id="reviews" class="max-w-3xl mb-8">
        <h2 class="font-display text-2xl font-semibold text-on-surface mb-6 flex items-center gap-2">
            <span class="material-symbols-outlined text-primary text-[28px]">forum</span>Customer Reviews
        </h2>

        <#if reviewsList.productReviewList?size == 0>
            <div class="l-glass rounded-2xl p-10 text-center">
                <span class="material-symbols-outlined text-outline text-[48px] mb-3">chat_bubble</span>
                <p class="text-on-surface-variant">No reviews yet. Be the first to share your experience!</p>
            </div>
        <#else>
            <#list reviewsList.productReviewList as review>
                <div class="l-glass rounded-2xl p-6 mb-4">
                    <div class="flex justify-between items-start mb-2">
                        <span class="inline-flex items-center">
                            <#list 1..5 as x>
                                <#if (review.productRating >= x)>
                                    <span class="material-symbols-outlined icon-fill text-tertiary text-[18px]">star</span>
                                <#else>
                                    <span class="material-symbols-outlined text-tertiary text-[18px]">star</span>
                                </#if>
                            </#list>
                        </span>
                        <span class="text-xs text-on-surface-variant/70">${review.postedDateTime}</span>
                    </div>
                    <p class="text-on-surface leading-relaxed mb-2">"${review.productReview}"</p>
                    <div class="text-sm text-on-surface-variant flex items-center gap-1">
                        <span class="material-symbols-outlined text-[16px]">account_circle</span>
                        <#if review.postedAnonymous == "Y">
                            Anonymous
                        <#else>
                            ${review.userId}
                        </#if>
                    </div>
                </div>
            </#list>
        </#if>

        <button type="button" onclick="document.getElementById('reviewDialog').showModal();"
                class="inline-flex items-center gap-2 border border-primary/50 text-primary hover:bg-primary/10 font-label text-sm font-medium px-6 py-3 rounded-lg transition-colors mt-4">
            <span class="material-symbols-outlined text-[18px]">edit</span>Write a Review
        </button>
    </div>
</div>

<!-- Review Dialog -->
<dialog id="reviewDialog" class="l-glass max-w-md w-[92vw] p-0">
    <form id="product-review-form" method="post" action="/product/addReview" class="p-6">
        <div class="flex items-center justify-between mb-5">
            <h5 class="font-display font-semibold text-lg text-on-surface flex items-center gap-2">
                <span class="material-symbols-outlined icon-fill text-tertiary">star</span>Write a Review
            </h5>
            <button type="button" onclick="document.getElementById('reviewDialog').close()" aria-label="Close"
                    class="text-on-surface-variant hover:text-on-surface transition-colors flex items-center">
                <span class="material-symbols-outlined">close</span>
            </button>
        </div>

        <input type="hidden" value="${ec.web.sessionToken}" name="moquiSessionToken">
        <input type="hidden" value="${productId}" name="productId">
        <input type="hidden" value="1" name="productRating" id="productRating">

        <div class="mb-5">
            <label class="block font-label text-sm font-semibold text-on-surface mb-2">Your Rating</label>
            <div id="stars" class="flex justify-center gap-1 py-2">
                <span class="star material-symbols-outlined icon-fill text-outline text-[32px] cursor-pointer transition-colors" data-value="1">star</span>
                <span class="star material-symbols-outlined icon-fill text-outline text-[32px] cursor-pointer transition-colors" data-value="2">star</span>
                <span class="star material-symbols-outlined icon-fill text-outline text-[32px] cursor-pointer transition-colors" data-value="3">star</span>
                <span class="star material-symbols-outlined icon-fill text-outline text-[32px] cursor-pointer transition-colors" data-value="4">star</span>
                <span class="star material-symbols-outlined icon-fill text-outline text-[32px] cursor-pointer transition-colors" data-value="5">star</span>
            </div>
        </div>

        <div class="mb-6">
            <label class="block font-label text-sm font-semibold text-on-surface mb-2" for="productReview">Your Review</label>
            <textarea rows="4" name="productReview" id="productReview"
                      placeholder="Share your experience with this product..."
                      class="w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors resize-none placeholder:text-outline"></textarea>
        </div>

        <div class="flex justify-end gap-3">
            <button type="button" onclick="document.getElementById('reviewDialog').close()"
                    class="font-label text-sm text-on-surface-variant hover:text-on-surface px-4 py-2.5 transition-colors">Cancel</button>
            <button id="addReview" type="submit"
                    class="inline-flex items-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-5 py-2.5 rounded-lg transition-all active:scale-95">
                <span class="material-symbols-outlined text-[16px]">send</span>Submit Review
            </button>
        </div>
    </form>
</dialog>

<!-- Image Detail Dialog -->
<dialog id="imageDialog" class="l-glass max-w-3xl w-[92vw] p-0">
    <div class="p-4">
        <div class="flex items-center justify-between mb-3">
            <h5 class="font-display font-semibold text-on-surface flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">image</span>Product Image
            </h5>
            <button type="button" onclick="document.getElementById('imageDialog').close()" aria-label="Close"
                    class="text-on-surface-variant hover:text-on-surface transition-colors flex items-center">
                <span class="material-symbols-outlined">close</span>
            </button>
        </div>
        <div class="text-center">
            <#if imgContent?? && imgContent.productContentId??>
                <img class="max-w-full max-h-[80vh] mx-auto rounded-lg" src="/content/productImage/${imgContent.productContentId}" alt="Product Image">
            </#if>
        </div>
    </div>
</dialog>

<script>
    var prodImageUrl = "/content/productImage/";
    var productImageLarge = document.getElementById("product-image-large");
    var baseProductId = "${product.productId}";

    function changeLargeImage(productContentId) {
        productImageLarge.src = prodImageUrl + productContentId;
        productImageLarge.style.opacity = '0.7';
        setTimeout(function() { productImageLarge.style.opacity = '1'; }, 150);
    }

    // Default image
    <#if product.contentList?has_content && imgExists>
        changeLargeImage("${product.contentList[0].productContentId}");
    <#else>
        productImageLarge.src = "/assets/default.png";
    </#if>

    // Review star-rating input
    (function() {
        var stars = document.querySelectorAll('#stars .star');
        stars.forEach(function(star) {
            star.addEventListener('click', function() {
                var value = parseInt(star.getAttribute('data-value'), 10);
                document.getElementById('productRating').value = value;
                stars.forEach(function(s, i) {
                    if (i < value) {
                        s.classList.remove('text-outline');
                        s.classList.add('text-tertiary');
                    } else {
                        s.classList.remove('text-tertiary');
                        s.classList.add('text-outline');
                    }
                });
            });
        });
    })();

    <#if isVirtual>
    // Variant selection: build the variant product id and put it in the form's hidden productId
    // so the selected variant (not the virtual parent) is added to the cart
    (function() {
        var productAvailability = ${productAvailability?replace('=',':')};
        var variantIdList = [];
        var cartAddButton = document.getElementById('cartAdd');

        function updateVariantProductId() {
            var productVariantId = baseProductId;
            if (typeof(variantIdList[1]) != 'undefined') {
                productVariantId = productVariantId + '_' + variantIdList[1] + '_' + variantIdList[0];
            } else if (typeof(variantIdList[0]) != 'undefined') {
                productVariantId = productVariantId + '_' + variantIdList[0];
            }
            document.getElementById('productId').value = productVariantId;
            if (cartAddButton) {
                if (productAvailability[productVariantId] === false) {
                    cartAddButton.disabled = true;
                    cartAddButton.classList.add('opacity-50');
                } else {
                    cartAddButton.disabled = false;
                    cartAddButton.classList.remove('opacity-50');
                }
            }
        }

        <#list 0..variantsList.listFeatures.keySet()?size - 1 as x>
        document.getElementById('variantProduct${x}').addEventListener('change', function() {
            variantIdList[${x}] = this.value;
            updateVariantProductId();
        });
        </#list>
    })();
    </#if>
</script>
