#!/bin/bash

# 선생님 홈페이지 Django 프로젝트 초기 설정 스크립트

echo "🎓 선생님 홈페이지 초기 설정"
echo "=================================="

# Python 버전 확인
echo "🐍 Python 버전 확인 중..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3가 설치되어 있지 않습니다."
    echo "   Python 3.8 이상을 설치해주세요."
    exit 1
fi

python3 --version

# 가상환경 생성
if [ ! -d "venv" ]; then
    echo "🔧 가상환경 생성 중..."
    python3 -m venv venv
else
    echo "✅ 가상환경이 이미 존재합니다."
fi

# 가상환경 활성화
echo "🔧 가상환경 활성화 중..."
source venv/bin/activate

# 패키지 설치
echo "📦 필요한 패키지 설치 중..."
pip install --upgrade pip
pip install -r requirements.txt

# 데이터베이스 마이그레이션
echo "🗃️  데이터베이스 초기화 중..."
python manage.py makemigrations
python manage.py migrate

# 관리자 계정 확인
echo "👨‍💼 관리자 계정 확인 중..."
python manage.py shell -c "
from django.contrib.auth.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('✅ 관리자 계정이 생성되었습니다.')
else:
    print('✅ 관리자 계정이 이미 존재합니다.')
"

# 정적 파일 디렉토리 생성
if [ ! -d "static" ]; then
    mkdir static
    echo "📁 static 디렉토리 생성 완료"
fi

if [ ! -d "media" ]; then
    mkdir media
    echo "📁 media 디렉토리 생성 완료"
fi

echo ""
echo "🎉 설정이 완료되었습니다!"
echo "=================================="
echo "이제 다음 명령어로 서버를 실행할 수 있습니다:"
echo ""
echo "  ./run_app.sh"
echo ""
echo "또는"
echo ""
echo "  source venv/bin/activate"
echo "  python manage.py runserver"
echo ""
echo "관리자 계정 정보:"
echo "  아이디: admin"
echo "  비밀번호: admin123"
echo "==================================" 