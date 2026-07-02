    <#if !ec.web.getPathInfoList()?has_content>
        <#assign top = storeInfo.menu1?filter(p -> p.title?lower_case == 'home')>
    <#else>
        <#assign top = storeInfo.menu1?filter(p -> p.path ==  ec.web.getPathInfo()[1])>
    </#if>
            </div>
        </div>
    </div>
