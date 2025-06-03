#!/bin/bash

# Django 강의 플랫폼 EC2 배포 스크립트
# 작성자: AI Assistant
# 날짜: 2025-06-03

echo "🚀 Django 강의 플랫폼 EC2 배포를 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 프로젝트 디렉토리 설정
PROJECT_DIR="/home/ec2-user/video-teacher"
VENV_DIR="$PROJECT_DIR/venv"

# 1. 프로젝트 디렉토리로 이동
echo -e "${BLUE}📁 프로젝트 디렉토리로 이동 중...${NC}"
cd $PROJECT_DIR || {
    echo -e "${RED}❌ 프로젝트 디렉토리를 찾을 수 없습니다: $PROJECT_DIR${NC}"
    exit 1
}

# 2. 가상환경 활성화
echo -e "${BLUE}🐍 가상환경 활성화 중...${NC}"
source $VENV_DIR/bin/activate || {
    echo -e "${RED}❌ 가상환경 활성화 실패${NC}"
    exit 1
}

# 3. 의존성 설치
echo -e "${BLUE}📦 의존성 설치 중...${NC}"
pip install -r requirements.txt
pip install whitenoise gunicorn

# 4. 기존 데이터베이스 및 마이그레이션 정리
echo -e "${YELLOW}🗂️  기존 데이터베이스 및 마이그레이션 정리 중...${NC}"
rm -f db.sqlite3
rm -f courses/migrations/0003_add_lesson_share_fields.py
rm -f courses/migrations/0004_alter_lesson_is_public_shareable.py

# 5. settings.py 수정 (CSS 문제 해결)
echo -e "${BLUE}⚙️  Django 설정 파일 수정 중...${NC}"
cat > teacher_homepage/settings.py << 'EOF'
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'django-insecure-your-secret-key-here'

DEBUG = True

ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'courses',
    'accounts',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'teacher_homepage.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'teacher_homepage.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 'ko-kr'
TIME_ZONE = 'Asia/Seoul'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

STATICFILES_DIRS = []
if os.path.exists(os.path.join(BASE_DIR, 'static')):
    STATICFILES_DIRS.append(os.path.join(BASE_DIR, 'static'))

# Whitenoise 설정
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

LOGIN_URL = '/accounts/login/'
LOGIN_REDIRECT_URL = '/'
LOGOUT_REDIRECT_URL = '/'
EOF

# 6. 새로운 마이그레이션 생성 및 적용
echo -e "${BLUE}🔄 새로운 마이그레이션 생성 및 적용 중...${NC}"
python manage.py makemigrations
python manage.py migrate

# 7. 정적 파일 수집
echo -e "${BLUE}📁 정적 파일 수집 중...${NC}"
python manage.py collectstatic --noinput

# 8. 슈퍼유저 생성 (자동)
echo -e "${BLUE}👨‍💼 관리자 계정 생성 중...${NC}"
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('✅ 관리자 계정 생성 완료: admin/admin123')
else:
    print('ℹ️  관리자 계정이 이미 존재합니다.')
"

# 9. 샘플 데이터 생성
echo -e "${BLUE}📚 샘플 강의 데이터 생성 중...${NC}"
python manage.py shell -c "
from courses.models import Course, Chapter, Lesson
import secrets
import string

# 기존 데이터 삭제
Course.objects.all().delete()

print('📚 Django 강의 데이터 생성 중...')

# 토큰 생성 함수
def generate_token():
    return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(16))

# Django 강의 생성
course = Course.objects.create(
    title='Django 웹 개발 입문',
    description='Django를 이용한 웹 개발 기초부터 실전까지 완벽 마스터'
)

# 챕터 생성
chapter = Chapter.objects.create(
    course=course,
    title='Django 기초',
    order=1
)

# 레슨들 생성
lessons_data = [
    {
        'title': 'Django 소개와 설치',
        'content': '''Django는 파이썬으로 만들어진 무료 오픈소스 웹 프레임워크입니다.
        
주요 특징:
• MTV (Model-Template-View) 패턴
• ORM (Object-Relational Mapping) 지원
• 강력한 관리자 인터페이스
• 보안 기능 내장
• 확장성과 재사용성

설치 방법:
pip install django==4.2.7''',
        'video_url': 'https://www.youtube.com/embed/dQw4w9WgXcQ'
    },
    {
        'title': '첫 번째 Django 프로젝트',
        'content': '''Django 프로젝트를 생성하고 기본 구조를 이해해봅시다.
        
프로젝트 생성:
django-admin startproject myproject

앱 생성:
python manage.py startapp myapp

기본 구조:
• settings.py: 프로젝트 설정
• urls.py: URL 라우팅
• models.py: 데이터베이스 모델
• views.py: 비즈니스 로직
• templates/: HTML 템플릿''',
        'video_url': 'https://www.youtube.com/embed/dQw4w9WgXcQ'
    },
    {
        'title': 'Django 모델 기초',
        'content': '''Django 모델을 사용하여 데이터베이스와 상호작용하는 방법을 학습합니다.
        
모델 정의:
class Post(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

주요 필드 타입:
• CharField: 짧은 문자열
• TextField: 긴 텍스트
• DateTimeField: 날짜와 시간
• ForeignKey: 외래키 관계
• ManyToManyField: 다대다 관계''',
        'video_url': 'https://www.youtube.com/embed/dQw4w9WgXcQ'
    },
    {
        'title': '마이그레이션과 데이터베이스',
        'content': '''Django 마이그레이션 시스템을 통해 데이터베이스 스키마를 관리합니다.
        
마이그레이션 생성:
python manage.py makemigrations

마이그레이션 적용:
python manage.py migrate

주요 명령어:
• showmigrations: 마이그레이션 상태 확인
• sqlmigrate: SQL 쿼리 확인
• migrate --fake: 가짜 마이그레이션 적용
• dbshell: 데이터베이스 셸 접근''',
        'video_url': 'https://www.youtube.com/embed/dQw4w9WgXcQ'
    }
]

for i, lesson_data in enumerate(lessons_data, 1):
    lesson = Lesson.objects.create(
        chapter=chapter,
        title=lesson_data['title'],
        content=lesson_data['content'],
        video_url=lesson_data['video_url'],
        order=i,
        is_public_shareable=True,
        share_token=generate_token()
    )
    print(f'✅ 레슨 생성: {lesson.title} (토큰: {lesson.share_token})')

print(f'✅ 총 {len(lessons_data)}개의 레슨이 생성되었습니다!')
print('🎯 관리자 페이지에서 강의를 확인할 수 있습니다.')
"

# 10. 서버 시작 스크립트 생성
echo -e "${BLUE}🔧 서버 시작 스크립트 생성 중...${NC}"
cat > start_ec2_server.sh << 'EOF'
#!/bin/bash
cd /home/ec2-user/video-teacher
source venv/bin/activate
echo "🚀 Django 서버를 시작합니다..."
echo "🌐 접속 주소: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
echo "⚙️  관리자 페이지: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/admin"
echo "👨‍💼 관리자 계정: admin / admin123"
echo ""
python manage.py runserver 0.0.0.0:8000
EOF

chmod +x start_ec2_server.sh

# 11. 배포 완료 메시지
echo -e "${GREEN}🎉 배포가 완료되었습니다!${NC}"
echo ""
echo -e "${YELLOW}📋 배포 정보:${NC}"
echo -e "  • 프로젝트 위치: ${PROJECT_DIR}"
echo -e "  • 데이터베이스: SQLite (새로 생성됨)"
echo -e "  • 정적 파일: WhiteNoise로 서빙"
echo -e "  • 관리자 계정: admin / admin123"
echo -e "  • 샘플 강의: 4개 레슨 포함"
echo ""
echo -e "${YELLOW}🌐 접속 정보:${NC}"
echo -e "  • 메인 사이트: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
echo -e "  • 관리자 페이지: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/admin"
echo ""
echo -e "${BLUE}🚀 서버 시작 방법:${NC}"
echo -e "  ./start_ec2_server.sh"
echo ""
echo -e "${GREEN}✅ 모든 준비가 완료되었습니다!${NC}" 