from django.db import models
from django.contrib.auth.models import User
from django.urls import reverse
import re
import uuid
import secrets


class Course(models.Model):
    """강의 모델"""
    title = models.CharField(max_length=200, verbose_name="강의명")
    description = models.TextField(verbose_name="설명")
    instructor = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="강사")
    thumbnail = models.ImageField(upload_to='course_thumbnails/', null=True, blank=True, verbose_name="썸네일")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="생성일")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="수정일")
    is_published = models.BooleanField(default=False, verbose_name="공개여부")
    
    class Meta:
        verbose_name = "강의"
        verbose_name_plural = "강의"
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title
    
    def get_chapter_count(self):
        """이 강의의 챕터 수"""
        return self.chapters.count()
    
    def get_total_lessons(self):
        """이 강의의 총 레슨 수"""
        total = 0
        for chapter in self.chapters.all():
            total += chapter.lessons.count()
        return total
    
    def get_published_chapters(self):
        """공개된 챕터들 (순서대로)"""
        return self.chapters.all().order_by('order')


class Chapter(models.Model):
    """챕터 모델"""
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='chapters', verbose_name="강의")
    title = models.CharField(max_length=200, verbose_name="챕터명")
    description = models.TextField(blank=True, verbose_name="설명")
    order = models.PositiveIntegerField(default=0, verbose_name="순서")
    
    class Meta:
        verbose_name = "챕터"
        verbose_name_plural = "챕터"
        ordering = ['course', 'order']
        unique_together = ['course', 'order']  # 같은 강의 내에서 순서 중복 방지
    
    def __str__(self):
        return f"[{self.course.title}] {self.order}. {self.title}"
    
    def get_lesson_count(self):
        """이 챕터의 레슨 수"""
        return self.lessons.count()
    
    def get_ordered_lessons(self):
        """순서대로 정렬된 레슨들"""
        return self.lessons.all().order_by('order')
    
    def get_next_lesson_order(self):
        """다음 레슨의 순서 번호"""
        last_lesson = self.lessons.order_by('-order').first()
        return (last_lesson.order + 1) if last_lesson else 1
    
    def save(self, *args, **kwargs):
        # 순서가 설정되지 않은 경우 자동으로 다음 순서 설정
        if not self.order:
            last_chapter = Chapter.objects.filter(course=self.course).order_by('-order').first()
            self.order = (last_chapter.order + 1) if last_chapter else 1
        super().save(*args, **kwargs)


class Lesson(models.Model):
    """레슨 모델"""
    chapter = models.ForeignKey(Chapter, on_delete=models.CASCADE, related_name='lessons', verbose_name="챕터")
    title = models.CharField(max_length=200, verbose_name="레슨명")
    description = models.TextField(blank=True, verbose_name="설명")
    youtube_url = models.URLField(blank=True, verbose_name="유튜브 URL")
    content = models.TextField(blank=True, verbose_name="내용")
    order = models.PositiveIntegerField(default=0, verbose_name="순서")
    duration = models.DurationField(null=True, blank=True, verbose_name="영상 길이")
    
    # 공유 뷰어 기능
    share_token = models.CharField(max_length=32, blank=True, null=True, verbose_name="공유 토큰")
    is_public_shareable = models.BooleanField(default=True, verbose_name="공개 공유 가능")
    
    class Meta:
        verbose_name = "레슨"
        verbose_name_plural = "레슨"
        ordering = ['chapter__course', 'chapter__order', 'order']
        unique_together = ['chapter', 'order']  # 같은 챕터 내에서 순서 중복 방지
    
    def __str__(self):
        return f"[{self.chapter.course.title}] {self.chapter.title} - {self.order}. {self.title}"
    
    def get_course(self):
        """이 레슨이 속한 강의"""
        return self.chapter.course
    
    def get_youtube_embed_url(self):
        """유튜브 URL을 임베드 URL로 변환"""
        if not self.youtube_url:
            return None
        
        # 유튜브 URL에서 video ID 추출
        youtube_regex = r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})'
        match = re.search(youtube_regex, self.youtube_url)
        
        if match:
            video_id = match.group(1)
            return f"https://www.youtube.com/embed/{video_id}?enablejsapi=1"  # JS API 활성화
        
        return None
    
    def get_youtube_video_id(self):
        """유튜브 비디오 ID 추출"""
        if not self.youtube_url:
            return None
        
        youtube_regex = r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})'
        match = re.search(youtube_regex, self.youtube_url)
        
        if match:
            return match.group(1)
        return None
    
    def get_previous_lesson(self):
        """이전 레슨"""
        return Lesson.objects.filter(
            chapter=self.chapter,
            order__lt=self.order
        ).order_by('-order').first()
    
    def get_next_lesson(self):
        """다음 레슨"""
        return Lesson.objects.filter(
            chapter=self.chapter,
            order__gt=self.order
        ).order_by('order').first()
    
    def generate_share_token(self):
        """공유 토큰 생성"""
        if not self.share_token:
            self.share_token = secrets.token_urlsafe(16)
            self.save(update_fields=['share_token'])
        return self.share_token
    
    def get_share_url(self):
        """공유 뷰어 URL"""
        if not self.share_token:
            self.generate_share_token()
        return reverse('courses:lesson_viewer', kwargs={'share_token': self.share_token})
    
    def get_absolute_share_url(self, request=None):
        """절대 공유 URL"""
        share_url = self.get_share_url()
        if request:
            return request.build_absolute_uri(share_url)
        return share_url
    
    def save(self, *args, **kwargs):
        # 순서가 설정되지 않은 경우 자동으로 다음 순서 설정
        if not self.order:
            last_lesson = Lesson.objects.filter(chapter=self.chapter).order_by('-order').first()
            self.order = (last_lesson.order + 1) if last_lesson else 1
        
        # 공개 공유가 가능하고 토큰이 없으면 자동 생성
        if self.is_public_shareable and not self.share_token:
            self.share_token = secrets.token_urlsafe(16)
        
        super().save(*args, **kwargs)


class Note(models.Model):
    """유튜브 스타일 공유 노트 모델"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name="작성자")
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='notes', verbose_name="레슨")
    timestamp = models.PositiveIntegerField(verbose_name="타임스탬프(초)", help_text="동영상 재생 시간(초)")
    content = models.TextField(verbose_name="노트 내용")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="생성일")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="수정일")
    
    class Meta:
        verbose_name = "공유 노트"
        verbose_name_plural = "공유 노트"
        ordering = ['lesson', 'timestamp']
        indexes = [
            models.Index(fields=['lesson', 'timestamp']),
            models.Index(fields=['lesson', '-created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.lesson.title} ({self.get_timestamp_display()})"
    
    def get_timestamp_display(self):
        """타임스탬프를 MM:SS 형식으로 표시"""
        minutes = self.timestamp // 60
        seconds = self.timestamp % 60
        return f"{minutes:02d}:{seconds:02d}"
    
    def get_absolute_url(self):
        """노트의 공유 URL"""
        return reverse('courses:note_detail', kwargs={'note_id': self.id})
    
    def get_lesson_url_with_timestamp(self):
        """타임스탬프와 함께 레슨 URL"""
        return f"{reverse('courses:lesson_detail', kwargs={'lesson_id': self.lesson.id})}?t={self.timestamp}"
