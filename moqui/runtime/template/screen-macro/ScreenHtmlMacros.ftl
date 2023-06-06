<#--
This software is in the public domain under CC0 1.0 Universal plus a Grant of Patent License.

To the extent possible under law, the author(s) have dedicated all
copyright and related and neighboring rights to this software to the
public domain worldwide. This software is distributed without any
warranty.

You should have received a copy of the CC0 Public Domain Dedication
along with this software (see the LICENSE.md file). If not, see
<http://creativecommons.org/publicdomain/zero/1.0/>.
-->
<#-- NOTE: no empty lines before the first #macro otherwise FTL outputs empty lines-->
<#include "DefaultScreenMacros.html.ftl"/>
<#-- NOTE: no empty lines between the #include and the first #macro otherwise FTL outputs empty lines-->
<#macro container>
    <#assign divId><@nodeId .node/></#assign>
    <${.node["@type"]!"div"}<#if divId?has_content> id="${divId}"</#if><#if .node["@style"]?has_content> class="${ec.resource.expand(.node["@style"], "")}"</#if>>
    <#recurse>
    </${.node["@type"]!"div"}><!-- CONTAINER OVERRIDE EXAMPLE -->
</#macro>
