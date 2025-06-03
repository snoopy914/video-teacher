#!/bin/bash

# Django 강의 플랫폼 EC2 배포 스크립트
# 작성자: AI Assistant
# 날짜: 2025-06-03

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 에러 발생 시 스크립트 중단
set -e

echo -e "${BLUE}🚀 Django 강의 플랫폼 EC2 배포를 시작합니다...${NC}"

# 프로젝트 디렉토리로 이동
echo -e "${YELLOW}📁 프로젝트 디렉토리로 이동 중...${NC}"
cd /home/ec2-user/video-teacher

# Python3가 설치되어 있는지 확인
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python3가 설치되어 있지 않습니다.${NC}"
    echo -e "${YELLOW}📦 Python3 설치 중...${NC}"
    sudo dnf update -y
    sudo dnf install -y python3 python3-pip python3-devel
fi

# 가상환경 생성
echo -e "${YELLOW}🏗️  가상환경 생성 중...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✅ 가상환경이 생성되었습니다.${NC}"
else
    echo -e "${CYAN}ℹ️  가상환경이 이미 존재합니다.${NC}"
fi

# 가상환경 활성화
echo -e "${YELLOW}🐍 가상환경 활성화 중...${NC}"
source venv/bin/activate

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 가상환경이 활성화되었습니다.${NC}"
else
    echo -e "${RED}❌ 가상환경 활성화 실패${NC}"
    exit 1
fi

# pip 업그레이드
echo -e "${YELLOW}📦 pip 업그레이드 중...${NC}"
pip install --upgrade pip

# 추가 시스템 패키지 설치 (Pillow를 위한 의존성)
echo -e "${YELLOW}📦 시스템 의존성 설치 중...${NC}"
sudo dnf install -y libjpeg-turbo-devel zlib-devel gcc

# 기본 패키지들 먼저 설치
echo -e "${YELLOW}📦 기본 패키지 설치 중...${NC}"
pip install Django==4.2.7
pip install Pillow
pip install python-decouple
pip install whitenoise==6.6.0
pip install gunicorn==21.2.0

# requirements.txt가 있다면 추가 패키지 설치
if [ -f "requirements.txt" ]; then
    echo -e "${YELLOW}📦 requirements.txt에서 패키지 설치 중...${NC}"
    pip install -r requirements.txt
fi

# 문제가 있는 마이그레이션 파일 삭제
echo -e "${YELLOW}🗑️  기존 마이그레이션 파일 정리 중...${NC}"

# courses 앱의 커스텀 마이그레이션 파일들 모두 삭제 (초기 마이그레이션만 남김)
if [ -d "courses/migrations" ]; then
    # __init__.py와 0001_initial.py만 남기고 모든 마이그레이션 파일 삭제
    find courses/migrations -name "*.py" -not -name "__init__.py" -not -name "0001_initial.py" -delete
    echo -e "${GREEN}✅ 기존 커스텀 마이그레이션 파일들을 정리했습니다.${NC}"
fi

# accounts 앱의 커스텀 마이그레이션 파일들도 정리
if [ -d "accounts/migrations" ]; then
    find accounts/migrations -name "*.py" -not -name "__init__.py" -not -name "0001_initial.py" -delete
    echo -e "${GREEN}✅ accounts 앱 마이그레이션 파일들을 정리했습니다.${NC}"
fi

# 기존 데이터베이스 백업 및 삭제
if [ -f "db.sqlite3" ]; then
    echo -e "${YELLOW}💾 기존 데이터베이스 백업 중...${NC}"
    cp db.sqlite3 db.sqlite3.backup.$(date +%Y%m%d_%H%M%S)
    rm -f db.sqlite3
    echo -e "${GREEN}✅ 기존 데이터베이스를 백업하고 삭제했습니다.${NC}"
fi

# settings.py 완전히 재작성 (EC2용)
echo -e "${YELLOW}⚙️  settings.py 설정 중...${NC}"
cat > teacher_homepage/settings.py << 'EOF'
import os
from pathlib import Path
from decouple import config

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-your-secret-key-here')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True  # EC2에서 정적 파일 서빙을 위해 True로 설정

# EC2 환경을 위한 ALLOWED_HOSTS 설정
ALLOWED_HOSTS = ['*']

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'accounts',
    'courses',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # WhiteNoise 추가
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
        'DIRS': [BASE_DIR / 'templates'],
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

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Password validation
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

# Internationalization
LANGUAGE_CODE = 'ko-kr'
TIME_ZONE = 'Asia/Seoul'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# WhiteNoise 설정
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# staticfiles 디렉토리 설정
STATICFILES_DIRS = []

# 미디어 파일 설정
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# 로그인/로그아웃 설정
LOGIN_URL = '/accounts/login/'
LOGIN_REDIRECT_URL = '/'
LOGOUT_REDIRECT_URL = '/'
EOF

echo -e "${GREEN}✅ settings.py가 업데이트되었습니다.${NC}"

# static 디렉토리가 있다면 제거 (경고 메시지 방지)
if [ -d "static" ]; then
    rm -rf static
fi

# 새로운 마이그레이션 생성
echo -e "${YELLOW}🔄 새로운 마이그레이션 생성 중...${NC}"
python manage.py makemigrations

# 마이그레이션 적용
echo -e "${YELLOW}🔄 데이터베이스 마이그레이션 적용 중...${NC}"
python manage.py migrate

# 정적 파일 수집
echo -e "${YELLOW}📦 정적 파일 수집 중...${NC}"
python manage.py collectstatic --noinput

# 관리자 계정 생성
echo -e "${YELLOW}👤 관리자 계정 생성 중...${NC}"
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('✅ 관리자 계정이 생성되었습니다 (admin/admin123)')
else:
    print('ℹ️  관리자 계정이 이미 존재합니다')
"

# 샘플 데이터 생성
echo -e "${YELLOW}📚 샘플 데이터 생성 중...${NC}"
python manage.py shell -c "
import string
import secrets
from django.contrib.auth import get_user_model
from courses.models import Course, Chapter, Lesson

User = get_user_model()

# 기존 데이터 확인
if Course.objects.exists():
    print('ℹ️  샘플 데이터가 이미 존재합니다')
else:
    # admin 사용자 가져오기
    admin_user = User.objects.get(username='admin')
    
    # Django 강의 생성
    course = Course.objects.create(
        title='Django 웹 개발 입문',
        description='Django를 이용한 웹 개발 기초부터 실전까지',
        instructor=admin_user  # instructor 필드 추가
    )

    # 챕터 생성
    chapter = Chapter.objects.create(
        course=course,
        title='Django 기초',
        order=1
    )

    # 공유 토큰 생성 함수
    def generate_share_token():
        return ''.join(secrets.choice(string.ascii_letters + string.digits) for _ in range(16))

    # 레슨들 생성
    lessons = [
        'Django 소개와 설치',
        '첫 번째 Django 프로젝트',
        'Django 모델 기초',
        '마이그레이션과 데이터베이스'
    ]

    for i, lesson_title in enumerate(lessons, 1):
        Lesson.objects.create(
            chapter=chapter,
            title=lesson_title,
            content=f'{lesson_title}에 대한 상세한 설명입니다.',
            youtube_url='https://www.youtube.com/embed/dQw4w9WgXcQ',
            order=i,
            is_public_shareable=True,
            share_token=generate_share_token()
        )

    print('✅ 샘플 데이터 생성 완료!')
"

# EC2 서버 시작 스크립트 생성
echo -e "${YELLOW}📝 EC2 서버 시작 스크립트 생성 중...${NC}"
cat > start_ec2_server.sh << 'EOF'
#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Django 강의 플랫폼 서버를 시작합니다...${NC}"

# 프로젝트 디렉토리로 이동
cd /home/ec2-user/video-teacher

# 가상환경 활성화
source venv/bin/activate

# 정적 파일 수집
echo -e "${YELLOW}📦 정적 파일 수집 중...${NC}"
python manage.py collectstatic --noinput

# 데이터베이스 마이그레이션 확인
echo -e "${YELLOW}🔄 데이터베이스 마이그레이션 확인...${NC}"
python manage.py migrate

# EC2 인스턴스의 퍼블릭 IP 가져오기
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo -e "${GREEN}🌟 Gunicorn으로 Django 서버 시작...${NC}"

# 백그라운드에서 Gunicorn 시작
nohup gunicorn teacher_homepage.wsgi:application --bind 0.0.0.0:8000 --workers 3 > gunicorn.log 2>&1 &

echo -e "${GREEN}✅ 서버가 시작되었습니다!${NC}"
echo -e "${BLUE}🌐 외부 접속 주소: http://${EC2_IP}:8000${NC}"
echo -e "${PURPLE}⚙️  관리자 페이지: http://${EC2_IP}:8000/admin${NC}"
echo -e "${CYAN}👤 관리자 계정: admin / admin123${NC}"
echo -e "${YELLOW}📋 로그 확인: tail -f gunicorn.log${NC}"
echo -e "${YELLOW}🛑 서버 중지: pkill -f gunicorn${NC}"
EOF

chmod +x start_ec2_server.sh

echo -e "${GREEN}🎉 EC2 배포가 완료되었습니다!${NC}"
echo -e "${BLUE}📍 다음 명령어로 서버를 시작하세요:${NC}"
echo -e "${YELLOW}   ./start_ec2_server.sh${NC}"
echo ""
echo -e "${CYAN}🔧 유용한 명령어들:${NC}"
echo -e "${YELLOW}   서버 상태 확인: ps aux | grep gunicorn${NC}"
echo -e "${YELLOW}   서버 중지: pkill -f gunicorn${NC}"
echo -e "${YELLOW}   로그 보기: tail -f gunicorn.log${NC}"
EOF 