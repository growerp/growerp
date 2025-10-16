<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${storeInfo.productStore.storeName}</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.2/css/bootstrap.min.css" integrity="sha256-zVUlvIh3NEZRYa9X/qpNY8P1aBy0d4FrI7bhfZSZVwc=" crossorigin="anonymous" />
    <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.0.9/css/all.css" integrity="sha384-5SOiIsAziJl6AWe0HWRKTXlfcSHKmYV4RBF18PPJ173Kzn7jzMyFuTtk8JA7QQG1" crossorigin="anonymous">
    <link rel="stylesheet" href="/components/styles/${storeInfo.productStore.productStoreId}.css">
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/assets/favicon.png" sizes="32x32"/>
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
</head>

<body>
    <div id="store-root">
        ${sri.renderSubscreen()}
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.3.1/jquery.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.1/umd/popper.min.js" integrity="sha256-/ijcOLwFf26xEYAjW75FizKVo5tnTYiQddPZoLUHHZ8=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.1.2/js/bootstrap.min.js" integrity="sha256-IeI0loa35pfuDxqZbGhQUiZmD2Cywv1/bdqiypGW46o=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/mouse0270-bootstrap-notify/3.1.7/bootstrap-notify.min.js" integrity="sha256-LlN0a0J3hMkDLO1mhcMwy+GIMbIRV7kvKHx4oCxNoxI=" crossorigin="anonymous"></script>
<script>
    $(document).ready(function() {
        $('#recipeCarousel').carousel({
            interval: 10000
        });

        $('.carousel .carousel-item').each(function(){
            var next = $(this).next();
            if (!next.length) {
                next = $(this).siblings(':first');
            }
            next.children(':first-child').clone().appendTo($(this));
    
            for (var i=0;i<2;i++) {
                next=next.next();
                if (!next.length) {
                    next = $(this).siblings(':first');
                }
                next.children(':first-child').clone().appendTo($(this));
            }
        });
        $("#form-search").submit(function(event){
            event.preventDefault();
            window.location.href = "/search/" + $(this).serializeArray()[0].value;
        });

        var $starsLi = $('#stars li');
        $starsLi.on('mouseover', function() {
            var onStar = parseInt($(this).data('value'), 10);
            $(this).parent().children('li.star').each(function(e){
                if (e < onStar) { $(this).addClass('hover'); } else { $(this).removeClass('hover'); } });
        }).on('mouseout', function() {
            $(this).parent().children('li.star').each(function(e) { $(this).removeClass('hover'); });
        });
        $starsLi.on('click', function() {
           var onStar = parseInt($(this).data('value'), 10);
           //the number of stars is assigned 
           $("#productRating").val(onStar);
           var stars = $(this).parent().children('li.star');
           for (i = 0; i < stars.length; i++) { $(stars[i]).removeClass('selected'); }
           for (i = 0; i < onStar; i++) { $(stars[i]).addClass('selected'); }
        });
    });
    
    // Register Flutter admin service worker early so it's ready when user navigates to /admin/
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
    <#-- for scripts/etc from d.xml or others, ie client rendered part of site that needs more JS -->
    <#if footerScriptText?has_content>${footerScriptText}</#if>
</body>
</html>
