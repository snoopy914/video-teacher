from django.urls import path
from . import views

app_name = 'courses'

urlpatterns = [
    path('', views.home, name='home'),
    path('courses/', views.course_list, name='course_list'),
    path('courses/<int:course_id>/', views.course_detail, name='course_detail'),
    path('lessons/<int:lesson_id>/', views.lesson_detail, name='lesson_detail'),
    
    # 레슨 뷰어 (공유용)
    path('viewer/<str:share_token>/', views.lesson_viewer, name='lesson_viewer'),
    path('api/lessons/<int:lesson_id>/toggle-share/', views.toggle_lesson_share, name='toggle_lesson_share'),
    
    # 노트 관련 URL
    path('api/notes/create/', views.create_note, name='create_note'),
    path('api/notes/<uuid:note_id>/', views.manage_note, name='manage_note'),
    path('api/lessons/<int:lesson_id>/notes/', views.get_lesson_notes, name='get_lesson_notes'),
    path('notes/<uuid:note_id>/', views.NoteDetailView.as_view(), name='note_detail'),
] 