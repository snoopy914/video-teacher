from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from .models import Course, Chapter, Lesson, Note


class LessonInline(admin.TabularInline):
    model = Lesson
    extra = 0  # 기본으로 추가되는 빈 폼 수를 0으로 설정
    fields = ('title', 'description', 'youtube_url', 'order')
    readonly_fields = ('id',)
    ordering = ('order',)
    
    def get_queryset(self, request):
        # 현재 챕터에 속한 레슨들만 표시
        qs = super().get_queryset(request)
        return qs.order_by('order')


class ChapterInline(admin.StackedInline):  # TabularInline에서 StackedInline으로 변경
    model = Chapter
    extra = 0
    fields = ('title', 'description', 'order')
    readonly_fields = ('id', 'lesson_count')
    ordering = ('order',)
    
    def lesson_count(self, obj):
        if obj.pk:
            return obj.lessons.count()
        return 0
    lesson_count.short_description = '레슨 수'
    
    def get_queryset(self, request):
        # 현재 강의에 속한 챕터들만 표시
        qs = super().get_queryset(request)
        return qs.order_by('order')


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ['title', 'instructor', 'chapter_count', 'total_lessons', 'is_published', 'created_at']
    list_filter = ['is_published', 'created_at', 'instructor']
    search_fields = ['title', 'description']
    readonly_fields = ['created_at', 'updated_at', 'chapter_count', 'total_lessons']
    
    fieldsets = (
        ('기본 정보', {
            'fields': ('title', 'description', 'thumbnail', 'is_published')
        }),
        ('강사 정보', {
            'fields': ('instructor',)
        }),
        ('통계', {
            'fields': ('chapter_count', 'total_lessons', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    inlines = [ChapterInline]
    
    def chapter_count(self, obj):
        return obj.chapters.count()
    chapter_count.short_description = '챕터 수'
    
    def total_lessons(self, obj):
        total = 0
        for chapter in obj.chapters.all():
            total += chapter.lessons.count()
        return total
    total_lessons.short_description = '총 레슨 수'
    
    def save_model(self, request, obj, form, change):
        if not change:  # 새로 생성할 때
            obj.instructor = request.user
        super().save_model(request, obj, form, change)


@admin.register(Chapter)
class ChapterAdmin(admin.ModelAdmin):
    list_display = ['title', 'course', 'order', 'get_lesson_count']
    list_filter = ['course', 'course__instructor']
    search_fields = ['title', 'description', 'course__title']
    readonly_fields = ['lesson_count']
    ordering = ['course', 'order']
    
    fieldsets = (
        ('챕터 정보', {
            'fields': ('course', 'title', 'description', 'order')
        }),
        ('통계', {
            'fields': ('lesson_count',),
            'classes': ('collapse',)
        }),
    )
    
    inlines = [LessonInline]
    
    def lesson_count(self, obj):
        return obj.lessons.count()
    lesson_count.short_description = '레슨 수'
    
    def get_lesson_count(self, obj):
        return obj.get_lesson_count()
    get_lesson_count.short_description = '레슨 수'
    
    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "course":
            # 강의 선택 시 현재 사용자가 강사인 강의만 표시
            kwargs["queryset"] = Course.objects.filter(instructor=request.user)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = [
        'title', 
        'chapter', 
        'order', 
        'get_share_status',
        'get_share_link'
    ]
    list_filter = [
        'is_public_shareable',
        'chapter__course',
        'chapter__course__instructor'
    ]
    search_fields = ['title', 'description', 'content', 'chapter__title']
    readonly_fields = ['share_token']
    
    fieldsets = (
        ('기본 정보', {
            'fields': ('chapter', 'title', 'description', 'order')
        }),
        ('콘텐츠', {
            'fields': ('content', 'youtube_url', 'duration')
        }),
        ('공유 설정', {
            'fields': ('is_public_shareable', 'share_token'),
            'description': '레슨을 외부에 공유할 수 있도록 설정합니다.'
        })
    )
    
    actions = ['enable_sharing', 'disable_sharing', 'generate_share_tokens']
    
    def get_share_status(self, obj):
        if obj.is_public_shareable:
            return format_html(
                '<span style="color: green; font-weight: bold;">✅ 공유 중</span>'
            )
        else:
            return format_html(
                '<span style="color: red;">❌ 비공개</span>'
            )
    get_share_status.short_description = '공유 상태'
    
    def get_share_link(self, obj):
        if obj.is_public_shareable and obj.share_token:
            share_url = obj.get_share_url()
            return format_html(
                '<a href="{}" target="_blank" style="color: blue;">🔗 뷰어로 보기</a>',
                share_url
            )
        elif obj.is_public_shareable and not obj.share_token:
            return format_html(
                '<span style="color: orange;">⚠️ 토큰 생성 필요</span>'
            )
        else:
            return format_html(
                '<span style="color: gray;">-</span>'
            )
    get_share_link.short_description = '공유 링크'
    
    def enable_sharing(self, request, queryset):
        updated = 0
        for lesson in queryset:
            lesson.is_public_shareable = True
            if not lesson.share_token:
                lesson.generate_share_token()
            lesson.save()
            updated += 1
        
        self.message_user(
            request, 
            f'{updated}개 레슨의 공유가 활성화되었습니다.'
        )
    enable_sharing.short_description = '선택된 레슨 공유 활성화'
    
    def disable_sharing(self, request, queryset):
        updated = queryset.update(is_public_shareable=False)
        self.message_user(
            request, 
            f'{updated}개 레슨의 공유가 비활성화되었습니다.'
        )
    disable_sharing.short_description = '선택된 레슨 공유 비활성화'
    
    def generate_share_tokens(self, request, queryset):
        updated = 0
        for lesson in queryset:
            if not lesson.share_token:
                lesson.generate_share_token()
                lesson.save()
                updated += 1
        
        self.message_user(
            request, 
            f'{updated}개 레슨에 공유 토큰이 생성되었습니다.'
        )
    generate_share_tokens.short_description = '공유 토큰 생성'


@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ['get_lesson_title', 'user', 'timestamp_display', 'created_at']
    list_filter = ['lesson__chapter__course', 'created_at', 'user']
    search_fields = ['content', 'lesson__title', 'user__username']
    readonly_fields = ['created_at', 'updated_at']
    
    def get_lesson_title(self, obj):
        return f'{obj.lesson.chapter.title} - {obj.lesson.title}'
    get_lesson_title.short_description = '레슨'
    
    def timestamp_display(self, obj):
        return obj.get_timestamp_display()
    timestamp_display.short_description = '타임스탬프'


# Admin 사이트 커스터마이징
admin.site.site_header = "선생님 홈페이지 관리"
admin.site.site_title = "선생님 홈페이지"
admin.site.index_title = "강의 관리 시스템"
