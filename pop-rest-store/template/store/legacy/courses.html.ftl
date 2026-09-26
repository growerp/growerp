<#-- Public course catalog (courseList) and course outline (course), see screen/store/courses.xml.
     Lesson content is not shown here: learners enroll and study in the academy app at /academy/. -->
<#assign up = urlPrefix!''>
<#function duration minutes><#if !(minutes??) || minutes == 0><#return ''></#if>
    <#if minutes lt 60><#return minutes + ' min'></#if>
    <#return (minutes / 60)?floor + ' h' + (minutes % 60 gt 0)?then(' ' + minutes % 60 + ' min', '')></#function>
<#macro price c><#if c.price?? && c.price gt 0>${ec.l10n.formatCurrency(c.price, c.priceUomId)}<#else>Free</#if></#macro>

<div class="container" style="padding-top: 1.5rem;">
    <nav aria-label="breadcrumb">
        <ol class="breadcrumb" style="background: none; padding: 0; margin-bottom: 1.5rem;">
            <li class="breadcrumb-item"><a href="${up}/" style="color: var(--primary-600);"><i class="fas fa-home mr-1"></i>Home</a></li>
            <#if course??>
                <li class="breadcrumb-item"><a href="${up}/courses" style="color: var(--primary-600);">Courses</a></li>
                <li class="breadcrumb-item active" aria-current="page">${course.title}</li>
            <#else>
                <li class="breadcrumb-item active" aria-current="page">Courses</li>
            </#if>
        </ol>
    </nav>

<#if notFound!false>
    <div class="text-center py-5">
        <i class="fas fa-graduation-cap fa-3x mb-3" style="color: var(--neutral-400);"></i>
        <h4>Course not found</h4>
        <a href="${up}/" class="btn btn-primary mt-3"><i class="fas fa-home mr-1"></i>Back to Home</a>
    </div>
<#elseif course??>
    <div class="row">
        <div class="col-lg-8 col-12 mb-4">
            <h1 style="font-family: 'Outfit', sans-serif; font-weight: 700;">${course.title}</h1>
            <#if course.description?has_content><p style="color: var(--neutral-600);">${course.description}</p></#if>
            <#if course.objectives?has_content>
                <div class="card mb-4"><div class="card-body">
                    <h5 class="card-title">What you will achieve</h5>
                    <p class="card-text">${course.objectives}</p>
                </div></div>
            </#if>
            <h4 class="mb-3">Course outline</h4>
            <#list course.modules as module>
                <div class="card mb-3"><div class="card-body">
                    <h5 class="card-title">${module?index + 1}. ${module.title}</h5>
                    <#if module.description?has_content><p class="card-text" style="color: var(--neutral-600);">${module.description}</p></#if>
                    <#if module.lessons?has_content>
                        <ul class="list-unstyled mb-0">
                            <#list module.lessons as lesson>
                                <li class="d-flex justify-content-between">
                                    <span><i class="fas fa-lock mr-2" style="color: var(--neutral-400);"></i>${lesson.title}</span>
                                    <span>${duration(lesson.estimatedDuration!0)}</span>
                                </li>
                            </#list>
                        </ul>
                    </#if>
                </div></div>
            </#list>
        </div>
        <div class="col-lg-4 col-12">
            <div class="card" style="position: sticky; top: 100px;"><div class="card-body">
                <#if course.coverImageUrl?has_content><img src="${course.coverImageUrl}" alt="${course.title}" class="img-fluid rounded mb-3"></#if>
                <h3 style="color: var(--primary-600);"><@price course/></h3>
                <ul class="list-unstyled">
                    <#if course.difficulty?has_content><li>Level: ${course.difficulty?capitalize}</li></#if>
                    <li>${course.moduleCount} modules, ${course.lessonCount} lessons</li>
                    <#if duration(course.estimatedDuration!0)?has_content><li>Duration: ${duration(course.estimatedDuration)}</li></#if>
                </ul>
                <a href="/academy/?companyPartyId=${storeInfo.productStore.organizationPartyId}" class="btn btn-primary btn-block"><i class="fas fa-graduation-cap mr-1"></i>Enroll</a>
                <small class="d-block mt-2" style="color: var(--neutral-500);">Log in or register in the app to enroll and start learning.</small>
            </div></div>
        </div>
    </div>
<#else>
    <h1 class="mb-4" style="font-family: 'Outfit', sans-serif; font-weight: 700;">Courses</h1>
    <div class="row">
        <#list courseList as c>
            <div class="col-lg-4 col-md-6 col-12 mb-4">
                <a href="${up}/courses/${c.courseId}" class="card h-100" style="text-decoration: none; color: inherit;">
                    <#if c.coverImageUrl?has_content><img src="${c.coverImageUrl}" alt="${c.title}" class="card-img-top"></#if>
                    <div class="card-body d-flex flex-column">
                        <h5 class="card-title">${c.title}</h5>
                        <#if c.description?has_content><p class="card-text" style="color: var(--neutral-600);">${c.description}</p></#if>
                        <div class="mt-auto d-flex justify-content-between">
                            <span>${c.lessonCount} lessons<#if c.difficulty?has_content> · ${c.difficulty?capitalize}</#if></span>
                            <strong style="color: var(--primary-600);"><@price c/></strong>
                        </div>
                    </div>
                </a>
            </div>
        </#list>
    </div>
</#if>
</div>
