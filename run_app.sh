#!/bin/bash

# 선생님 홈페이지 Django 앱 실행 스크립트

echo "🎓 선생님 홈페이지 시작 중..."
echo "=================================="

# 현재 디렉토리 확인
if [ ! -f "manage.py" ]; then
    echo "❌ Django 프로젝트 디렉토리가 아닙니다."
    echo "   manage.py 파일이 있는 디렉토리에서 실행해주세요."
    exit 1
fi

# 가상환경 확인 및 활성화
if [ ! -d "venv" ]; then
    echo "❌ 가상환경이 없습니다."
    echo "   python3 -m venv venv 명령으로 가상환경을 먼저 생성해주세요."
    exit 1
fi

echo "🔧 가상환경 활성화 중..."
source venv/bin/activate

# 필요한 패키지 설치 확인
echo "📦 패키지 설치 확인 중..."
pip install -q -r requirements.txt

# 데이터베이스 마이그레이션 확인
echo "🗃️  데이터베이스 마이그레이션 확인 중..."
python manage.py makemigrations --check --dry-run > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "⚠️  새로운 마이그레이션이 필요합니다. 마이그레이션을 실행합니다..."
    python manage.py makemigrations
    python manage.py migrate
else
    echo "✅ 데이터베이스가 최신 상태입니다."
fi

# 정적 파일 수집 (필요시)
if [ ! -d "static" ]; then
    mkdir static
fi

echo ""
echo "🚀 Django 개발 서버를 시작합니다..."
echo "=================================="
echo "📱 홈페이지: http://127.0.0.1:8000/"
echo "👨‍💼 관리자 페이지: http://127.0.0.1:8000/admin/"
echo ""
echo "관리자 계정:"
echo "  아이디: admin"
echo "  비밀번호: admin123"
echo ""
echo "서버를 중지하려면 Ctrl+C를 누르세요."
echo "=================================="
echo ""

# Django 서버 실행
python manage.py runserver 