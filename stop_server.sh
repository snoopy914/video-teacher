#!/bin/bash

# Django 강의 플랫폼 서버 종료 스크립트

echo "🛑 Django 강의 플랫폼 서버를 종료합니다..."

# Gunicorn 프로세스 종료
echo "🔄 Gunicorn 프로세스 종료 중..."
pkill -f "gunicorn teacher_homepage.wsgi:application"

# Nginx 종료 (선택사항)
# echo "🌐 Nginx 종료 중..."
# brew services stop nginx

echo "✅ 서버가 종료되었습니다!" 