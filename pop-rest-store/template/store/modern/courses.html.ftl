<#-- Public course catalog (courseList) and course outline (course), see screen/store/courses.xml.
     Lesson content is not shown here: learners enroll and study in the app at /admin/. -->
<#assign up = urlPrefix!''>
<#function duration minutes><#if !(minutes??) || minutes == 0><#return ''></#if>
    <#if minutes lt 60><#return minutes + ' min'></#if>
    <#return (minutes / 60)?floor + ' h' + (minutes % 60 gt 0)?then(' ' + minutes % 60 + ' min', '')></#function>
<#macro price c><#if c.price?? && c.price gt 0>${ec.l10n.formatCurrency(c.price, c.priceUomId)}<#else>Free</#if></#macro>

<div class="max-w-container mx-auto px-4 md:px-12 pt-24 pb-8">
    <nav aria-label="breadcrumb" class="mb-6">
        <ol class="flex items-center gap-2 text-sm">
            <li><a href="${up}/" class="flex items-center gap-1 text-primary hover:text-primary/80 transition-colors">
                <span class="material-symbols-outlined text-[16px]">home</span>Home</a></li>
            <li class="text-outline">/</li>
            <#if course??>
                <li><a href="${up}/courses" class="text-primary hover:text-primary/80 transition-colors">Courses</a></li>
                <li class="text-outline">/</li>
                <li class="text-on-surface-variant" aria-current="page">${course.title}</li>
            <#else>
                <li class="text-on-surface-variant" aria-current="page">Courses</li>
            </#if>
        </ol>
    </nav>

<#if notFound!false>
    <div class="l-glass rounded-2xl p-12 text-center">
        <span class="material-symbols-outlined text-outline text-[64px] mb-3">school</span>
        <h4 class="font-display text-xl font-semibold text-on-surface mb-2">Course not found</h4>
        <a href="${up}/" class="inline-flex items-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-6 py-3 rounded-lg transition-all active:scale-95">
            <span class="material-symbols-outlined text-[18px]">home</span>Back to Home</a>
    </div>
<#elseif course??>
    <div class="flex flex-col md:flex-row gap-8">
        <div class="flex-1 min-w-0">
            <h1 class="font-display text-3xl font-bold text-on-surface mb-3">${course.title}</h1>
            <#if course.description?has_content><p class="text-on-surface-variant mb-6">${course.description}</p></#if>
            <#if course.objectives?has_content>
                <div class="l-glass rounded-2xl p-6 mb-6">
                    <h2 class="font-display font-semibold text-on-surface mb-2">What you will achieve</h2>
                    <p class="text-on-surface-variant">${course.objectives}</p>
                </div>
            </#if>
            <h2 class="font-display text-xl font-semibold text-on-surface mb-4">Course outline</h2>
            <ol class="space-y-4">
                <#list course.modules as module>
                    <li class="l-glass rounded-2xl p-5">
                        <h3 class="font-display font-semibold text-on-surface">${module?index + 1}. ${module.title}</h3>
                        <#if module.description?has_content><p class="text-sm text-on-surface-variant mt-1">${module.description}</p></#if>
                        <#if module.lessons?has_content>
                            <ul class="mt-3 space-y-1">
                                <#list module.lessons as lesson>
                                    <li class="flex items-center justify-between gap-4 text-sm text-on-surface-variant">
                                        <span class="flex items-center gap-2"><span class="material-symbols-outlined text-[16px] text-outline">lock</span>${lesson.title}</span>
                                        <span class="shrink-0">${duration(lesson.estimatedDuration!0)}</span>
                                    </li>
                                </#list>
                            </ul>
                        </#if>
                    </li>
                </#list>
            </ol>
        </div>
        <aside class="md:w-72 shrink-0">
            <div class="l-glass rounded-2xl p-6 md:sticky md:top-24 space-y-3">
                <#if course.coverImageUrl?has_content><img src="${course.coverImageUrl}" alt="${course.title}" class="w-full rounded-lg"></#if>
                <div class="text-primary font-semibold text-2xl"><@price course/></div>
                <ul class="text-sm text-on-surface-variant space-y-1">
                    <#if course.difficulty?has_content><li>Level: ${course.difficulty?capitalize}</li></#if>
                    <li>${course.moduleCount} modules, ${course.lessonCount} lessons</li>
                    <#if duration(course.estimatedDuration!0)?has_content><li>Duration: ${duration(course.estimatedDuration)}</li></#if>
                </ul>
                <a href="${up}/admin/" class="flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-6 py-3 rounded-lg l-glow transition-all active:scale-95">
                    <span class="material-symbols-outlined text-[18px]">school</span>Enroll</a>
                <p class="text-xs text-on-surface-variant">Log in or register in the app to enroll and start learning.</p>
            </div>
        </aside>
    </div>
<#else>
    <h1 class="font-display text-3xl font-bold text-on-surface mb-6">Courses</h1>
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <#list courseList as c>
            <a href="${up}/courses/${c.courseId}" class="group flex flex-col l-glass rounded-xl p-5 hover:border-primary/40 transition-all duration-300">
                <#if c.coverImageUrl?has_content>
                    <img src="${c.coverImageUrl}" alt="${c.title}" class="w-full aspect-video object-cover rounded-lg mb-3">
                </#if>
                <h2 class="font-display font-semibold text-on-surface mb-2 group-hover:text-primary transition-colors">${c.title}</h2>
                <#if c.description?has_content><p class="text-sm text-on-surface-variant line-clamp-3 mb-4">${c.description}</p></#if>
                <div class="mt-auto flex items-center justify-between text-sm">
                    <span class="text-on-surface-variant">${c.lessonCount} lessons<#if c.difficulty?has_content> · ${c.difficulty?capitalize}</#if></span>
                    <span class="text-primary font-semibold"><@price c/></span>
                </div>
            </a>
        </#list>
    </div>
</#if>
</div>
