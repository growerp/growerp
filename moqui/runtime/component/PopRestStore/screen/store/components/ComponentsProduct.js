storeComps.ProductImage = {
    name: "product-image",
    data: function() { return { content: {} } },
    methods: {
        getProductContent: function(){
            ProductService.getProductContent(this._props.productId, "PcntImageSmall").then(function (data) { 
                if(typeof(data.productContent) == 'undefined') {
                    ProductService.getProductContent(this._props.productId, "PcntImageMedium").then(function (data) { 
                        if(typeof(data.productContent) == 'undefined') {
                            ProductService.getProductContent(this._props.productId, "PcntImageLarge").then(function (data) {
                                this.content = data.productContent;
                            }.bind(this));
                        } else{ this.content = data.productContent; }
                    }.bind(this));
                } else { this.content = data.productContent; }
            }.bind(this));
        },
        getProductImage: function() {
            if(this.content == null || typeof(this.content.productContentId) == 'undefined') return null;
            return storeConfig.productImageLocation + this.content.productContentId;
        }
    },
    props: ["productId"],
    mounted: function() {
        this.getProductContent();
    }
};
storeComps.ProductImageTemplate = getPlaceholderRoute("template_client_productImage", "ProductImage", storeComps.ProductImage.props);

