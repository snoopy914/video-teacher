#!/bin/bash

# Django 강의 플랫폼 서버 시작 스크립트

echo "🚀 Django 강의 플랫폼 서버를 시작합니다..."

# 프로젝트 디렉토리로 이동
cd /Users/aa/Documents/020_homepage_teacher

# 가상환경 활성화
source venv/bin/activate

echo "📦 정적 파일 수집 중..."
python manage.py collectstatic --noinput

echo "🔄 데이터베이스 마이그레이션 확인..."
python manage.py migrate

echo "🌟 Gunicorn으로 Django 서버 시작..."
gunicorn teacher_homepage.wsgi:application \
    --bind 127.0.0.1:8000 \
    --workers 3 \
    --timeout 60 \
    --access-logfile /Users/aa/Documents/020_homepage_teacher/logs/access.log \
    --error-logfile /Users/aa/Documents/020_homepage_teacher/logs/error.log \
    --daemon

echo "✅ 서버가 시작되었습니다!"
echo "🌐 접속 주소: http://localhost"
echo "⚙️  관리자 페이지: http://localhost/admin"
echo "📋 로그 확인: tail -f logs/access.log logs/error.log" 