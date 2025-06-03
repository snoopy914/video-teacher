from django.shortcuts import render, get_object_or_404
from django.http import HttpResponse, JsonResponse
from django.contrib.auth.decorators import login_required
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.views.generic import DetailView
from django.db import models
from .models import Course, Chapter, Lesson, Note
import json


def home(request):
    """홈페이지"""
    courses = Course.objects.filter(is_published=True)
    return render(request, 'courses/home.html', {'courses': courses})


def course_list(request):
    """강의 목록"""
    courses = Course.objects.filter(is_published=True)
    return render(request, 'courses/course_list.html', {'courses': courses})


def course_detail(request, course_id):
    """강의 상세 페이지"""
    course = get_object_or_404(Course, id=course_id, is_published=True)
    chapters = course.chapters.all()
    return render(request, 'courses/course_detail.html', {
        'course': course,
        'chapters': chapters
    })


def lesson_detail(request, lesson_id):
    """레슨 상세 페이지"""
    lesson = get_object_or_404(Lesson, id=lesson_id)
    chapter = lesson.chapter
    course = chapter.course
    
    # 레슨의 모든 노트 가져오기 (타임스탬프 순으로 정렬)
    lesson_notes = Note.objects.filter(lesson=lesson).order_by('timestamp')
    
    # URL에서 타임스탬프 파라미터 가져오기
    start_time = request.GET.get('t', 0)
    
    return render(request, 'courses/lesson_detail.html', {
        'lesson': lesson,
        'chapter': chapter,
        'course': course,
        'lesson_notes': lesson_notes,
        'start_time': start_time,
        'is_viewer_mode': False,
    })


def lesson_viewer(request, share_token):
    """레슨 뷰어 페이지 (공유용)"""
    lesson = get_object_or_404(Lesson, share_token=share_token, is_public_shareable=True)
    chapter = lesson.chapter
    course = chapter.course
    
    # 레슨의 모든 노트 가져오기 (타임스탬프 순으로 정렬)
    lesson_notes = Note.objects.filter(lesson=lesson).order_by('timestamp')
    
    # URL에서 타임스탬프 파라미터 가져오기
    start_time = request.GET.get('t', 0)
    
    return render(request, 'courses/lesson_viewer.html', {
        'lesson': lesson,
        'chapter': chapter,
        'course': course,
        'lesson_notes': lesson_notes,
        'start_time': start_time,
        'is_viewer_mode': True,
    })


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def toggle_lesson_share(request, lesson_id):
    """레슨 공유 상태 토글"""
    lesson = get_object_or_404(Lesson, id=lesson_id)
    
    # 강사 또는 관리자만 공유 설정 가능
    if not (request.user == lesson.chapter.course.instructor or request.user.is_staff):
        return JsonResponse({'success': False, 'error': '권한이 없습니다.'})
    
    # 공유 상태 토글
    lesson.is_public_shareable = not lesson.is_public_shareable
    
    # 공유 토큰이 없으면 생성
    if lesson.is_public_shareable and not lesson.share_token:
        lesson.generate_share_token()
    
    lesson.save()
    
    return JsonResponse({
        'success': True,
        'is_shareable': lesson.is_public_shareable,
        'share_url': lesson.get_absolute_share_url(request) if lesson.is_public_shareable else None
    })


@login_required
@require_http_methods(["POST"])
@csrf_exempt
def create_note(request):
    """노트 생성"""
    try:
        data = json.loads(request.body)
        lesson_id = data.get('lesson_id')
        timestamp = data.get('timestamp')
        content = data.get('content')
        
        lesson = get_object_or_404(Lesson, id=lesson_id)
        
        note = Note.objects.create(
            user=request.user,
            lesson=lesson,
            timestamp=timestamp,
            content=content
        )
        
        return JsonResponse({
            'success': True,
            'note': {
                'id': str(note.id),
                'timestamp': note.timestamp,
                'timestamp_display': note.get_timestamp_display(),
                'content': note.content,
                'author': note.user.username,
                'share_url': note.get_absolute_url(),
                'created_at': note.created_at.strftime('%Y-%m-%d %H:%M:%S')
            }
        })
    except Exception as e:
        return JsonResponse({'success': False, 'error': str(e)})


@login_required
@require_http_methods(["PUT", "DELETE"])
@csrf_exempt
def manage_note(request, note_id):
    """노트 수정/삭제"""
    note = get_object_or_404(Note, id=note_id, user=request.user)
    
    if request.method == 'PUT':
        try:
            data = json.loads(request.body)
            note.content = data.get('content', note.content)
            note.save()
            
            return JsonResponse({
                'success': True,
                'note': {
                    'id': str(note.id),
                    'timestamp': note.timestamp,
                    'timestamp_display': note.get_timestamp_display(),
                    'content': note.content,
                    'author': note.user.username,
                    'share_url': note.get_absolute_url(),
                    'updated_at': note.updated_at.strftime('%Y-%m-%d %H:%M:%S')
                }
            })
        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})
    
    elif request.method == 'DELETE':
        note.delete()
        return JsonResponse({'success': True})


class NoteDetailView(DetailView):
    """노트 상세 뷰 (공유용)"""
    model = Note
    template_name = 'courses/note_detail.html'
    context_object_name = 'note'
    pk_url_kwarg = 'note_id'
    
    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        note = self.object
        context['lesson'] = note.lesson
        context['chapter'] = note.lesson.chapter
        context['course'] = note.lesson.chapter.course
        return context


@require_http_methods(["GET"])
def get_lesson_notes(request, lesson_id):
    """레슨의 노트 목록 조회"""
    lesson = get_object_or_404(Lesson, id=lesson_id)
    
    # 모든 공유 노트를 타임스탬프 순으로 조회
    notes = Note.objects.filter(lesson=lesson).order_by('timestamp')
    
    notes_data = []
    for note in notes:
        notes_data.append({
            'id': str(note.id),
            'timestamp': note.timestamp,
            'timestamp_display': note.get_timestamp_display(),
            'content': note.content,
            'is_own': note.user == request.user if request.user.is_authenticated else False,
            'author': note.user.username,
            'share_url': note.get_absolute_url(),
            'created_at': note.created_at.strftime('%Y-%m-%d %H:%M:%S')
        })
    
    return JsonResponse({'notes': notes_data})
