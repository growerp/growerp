<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Welcome to ${storeInfo.productStore.storeName} - Your trusted online store">
    <meta name="theme-color" content="#1e293b">
    
    <title>${storeInfo.productStore.storeName}</title>
    
    <!-- Preconnect for performance -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    
    <!-- Google Fonts - Premium Typography -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Bootstrap 4 CSS -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.2/css/bootstrap.min.css" integrity="sha256-zVUlvIh3NEZRYa9X/qpNY8P1aBy0d4FrI7bhfZSZVwc=" crossorigin="anonymous" />
    
    <!-- Font Awesome 5 -->
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.9/css/all.css" integrity="sha384-5SOiIsAziJl6AWe0HWRKTXlfcSHKmYV4RBF18PPJ173Kzn7jzMyFuTtk8JA7QQG1" crossorigin="anonymous">
    
    <!-- Custom Store Styles -->
    <link rel="stylesheet" href="/components/styles/${storeInfo.productStore.productStoreId}.css">
    
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/assets/favicon.png" sizes="32x32"/>
    <link rel="apple-touch-icon" href="/assets/favicon.png">
    
    <#-- Google Analytics -->
    <#if storeInfo.settings.measurementId?has_content>
        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=${storeInfo.settings.measurementId}"></script>
        <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '${storeInfo.settings.measurementId}');
        </script>
    </#if>
    
    <!-- Critical CSS for above-the-fold content -->
    <style>
        /* Prevent FOUC */
        html { visibility: visible; opacity: 1; }
        
        /* Smooth scrolling */
        html { scroll-behavior: smooth; }
        
        /* Loading state */
        body { 
            opacity: 1;
            transition: opacity 0.3s ease;
        }
    </style>
</head>

<body>
    <div id="store-root">
        ${sri.renderSubscreen()}
    </div>

    <!-- JavaScript Libraries (using same versions as original) -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.1/umd/popper.min.js" integrity="sha256-/ijcOLwFf26xEYAjW75FizKVo5tnTYiQddPZoLUHHZ8=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.2/js/bootstrap.min.js" integrity="sha256-IeI0loa35pfuDxqZbGhQUiZmD2Cywv1/bdqiypGW46o=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/mouse0270-bootstrap-notify/3.1.7/bootstrap-notify.min.js" integrity="sha256-LlN0a0J3hMkDLO1mhcMwy+GIMbIRV7kvKHx4oCxNoxI=" crossorigin="anonymous"></script>

    <script>
        $(document).ready(function() {
            // Multi-item Carousel
            $('#recipeCarousel, #recipeCarousel1').carousel({
                interval: 10000
            });

            $('.carousel .carousel-item').each(function(){
                var next = $(this).next();
                if (!next.length) {
                    next = $(this).siblings(':first');
                }
                next.children(':first-child').clone().appendTo($(this));
        
                for (var i=0; i<2; i++) {
                    next=next.next();
                    if (!next.length) {
                        next = $(this).siblings(':first');
                    }
                    next.children(':first-child').clone().appendTo($(this));
                }
            });
            
            // Search Form Handler
            $("#form-search, #form-search-mobile").submit(function(event){
                event.preventDefault();
                var searchValue = $(this).find('input[name="search"]').val() || $(this).serializeArray()[0].value;
                if (searchValue && searchValue.trim()) {
                    window.location.href = "/search/" + encodeURIComponent(searchValue.trim());
                }
            });

            // Star Rating System
            var $starsLi = $('#stars li');
            $starsLi.on('mouseover', function() {
                var onStar = parseInt($(this).data('value'), 10);
                $(this).parent().children('li.star').each(function(e){
                    if (e < onStar) { $(this).addClass('hover'); } else { $(this).removeClass('hover'); } 
                });
            }).on('mouseout', function() {
                $(this).parent().children('li.star').each(function(e) { $(this).removeClass('hover'); });
            });
            
            $starsLi.on('click', function() {
               var onStar = parseInt($(this).data('value'), 10);
               $("#productRating").val(onStar);
               var stars = $(this).parent().children('li.star');
               for (i = 0; i < stars.length; i++) { $(stars[i]).removeClass('selected'); }
               for (i = 0; i < onStar; i++) { $(stars[i]).addClass('selected'); }
            });
            
            // Smooth scroll for anchor links
            $('a[href^="#"]').on('click', function(e) {
                var target = $(this.getAttribute('href'));
                if (target.length) {
                    e.preventDefault();
                    $('html, body').stop().animate({
                        scrollTop: target.offset().top - 80
                    }, 500);
                }
            });
        });
        
        // Register Flutter admin service worker early
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('/admin/flutter_service_worker.js', {
                    scope: '/admin/'
                }).then(registration => {
                    console.log('✅ Flutter Admin Service Worker registered with scope:', registration.scope);
                }).catch(error => {
                    console.log('ℹ️ Flutter Admin Service Worker registration failed (normal if /admin/ not deployed):', error.message);
                });
            });
        }
    </script>
    
    <#-- Additional Scripts from subpages -->
    <#if footerScriptText?has_content>${footerScriptText}</#if>
</body>
</html>
