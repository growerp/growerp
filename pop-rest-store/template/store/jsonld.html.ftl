<#--
This software is in the public domain under CC0 1.0 Universal plus a
Grant of Patent License.

To the extent possible under law, the author(s) have dedicated all
copyright and related and neighboring rights to this software to the
public domain worldwide. This software is distributed without any
warranty.

You should have received a copy of the CC0 Public Domain Dedication
along with this software (see the LICENSE.md file). If not, see
<http://creativecommons.org/publicdomain/zero/1.0/>.

Shared schema.org structured data, included by the modern and legacy root.html.ftl at the end of
the body so the values set by the subscreen actions (product, productList) are available.
The page type comes from seoPageType, never from which data happens to be in the context.
-->
<#assign base = siteBaseUrl!"">
<#assign storeName = (storeInfo.productStore.storeName)!"">
<#assign pageUrl = pageCanonicalUrl!base>
<#assign pageType = seoPageType!"">
<script type="application/ld+json">
{"@context":"https://schema.org","@graph":[
{"@type":"Organization","@id":"${base}#organization",
 "name":"${((organization.organizationName)!storeName)?json_string}",
 "url":"${base}/","logo":"${base}/getLogo"
 <#if companyPostalAddress??>,"address":{"@type":"PostalAddress"
   <#if companyPostalAddress.address1?has_content>,"streetAddress":"${companyPostalAddress.address1?json_string}"</#if>
   <#if companyPostalAddress.city?has_content>,"addressLocality":"${companyPostalAddress.city?json_string}"</#if>
   <#if companyPostalAddress.postalCode?has_content>,"postalCode":"${companyPostalAddress.postalCode?json_string}"</#if>
   <#if companyPostalAddress.countryGeoId?has_content>,"addressCountry":"${companyPostalAddress.countryGeoId?json_string}"</#if>}</#if>
 <#if companyPhone??>,"telephone":"${((companyPhone.countryCode)!'')}${((companyPhone.areaCode)!'')}${((companyPhone.contactNumber)!'')}"</#if>
 <#if companyEmailMech?? && (companyEmailMech.infoString)?has_content>,"email":"${companyEmailMech.infoString?json_string}"</#if>},
{"@type":"WebSite","@id":"${base}#website","url":"${base}/","name":"${storeName?json_string}",
 "publisher":{"@id":"${base}#organization"},
 "potentialAction":{"@type":"SearchAction",
   "target":{"@type":"EntryPoint","urlTemplate":"${base}/search/{search_term_string}"},
   "query-input":"required name=search_term_string"}}
<#if pageType == "product" && (product.productName)?has_content>
,{"@type":"Product","name":"${product.productName?json_string}",
  "sku":"${((product.pseudoId)!(product.productId)!'')?json_string}",
  <#if (product.description)?has_content>"description":"${product.description?json_string}",</#if>
  "brand":{"@id":"${base}#organization"},
  "offers":{"@type":"Offer","url":"${pageUrl}"
   <#if (product.price)??>,"price":"${product.price?c}"</#if>
   <#if (currencyUomId!'')?has_content>,"priceCurrency":"${currencyUomId?json_string}"</#if>
   ,"availability":"https://schema.org/<#if (inStock!false)>InStock<#else>OutOfStock</#if>"}}
<#elseif pageType == "category">
,{"@type":"CollectionPage","@id":"${pageUrl}","url":"${pageUrl}",
  "name":"${((pageTitle!storeName))?json_string}","isPartOf":{"@id":"${base}#website"}}
 <#if productList??>
,{"@type":"ItemList","itemListElement":[<#list productList as listProduct><#if listProduct_index gte 30><#break></#if>
  {"@type":"ListItem","position":${listProduct_index + 1},"url":"${base}/product/${listProduct.productId}",
   "name":"${((listProduct.productName)!'')?json_string}"}<#sep>,</#sep></#list>]}
 </#if>
<#elseif pageType == "content" || pageType == "home">
,{"@type":"WebPage","@id":"${pageUrl}","url":"${pageUrl}",
  "name":"${((pageTitle!storeName))?json_string}",
  <#if (pageDescription!'')?has_content>"description":"${pageDescription?json_string}",</#if>
  "isPartOf":{"@id":"${base}#website"},"inLanguage":"en"}
 <#if seoBreadcrumbs??>
,{"@type":"BreadcrumbList","itemListElement":[<#list seoBreadcrumbs as crumb>
  {"@type":"ListItem","position":${crumb_index + 1},"name":"${crumb.title?json_string}","item":"${base}${crumb.url}"}<#sep>,</#sep></#list>]}
 </#if>
</#if>
]}
</script>
