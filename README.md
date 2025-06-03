# 🎓 선생님 홈페이지 (Teacher Homepage)

Django 기반의 온라인 강의 플랫폼으로, 강의-챕터-레슨 구조와 유튜브 동영상 통합, 실시간 노트 기능을 제공합니다.

## ✨ 주요 기능

### 📚 강의 관리
- **계층적 구조**: 강의 → 챕터 → 레슨의 체계적인 구성
- **유튜브 통합**: 각 레슨에 유튜브 동영상 임베드
- **관리자 인터페이스**: 강의 콘텐츠 쉽게 관리
- **반응형 디자인**: 모든 디바이스에서 최적화된 UI

### 👥 사용자 시스템
- **회원가입/로그인**: 완전한 사용자 인증 시스템
- **권한 관리**: 강사와 학생 역할 구분
- **프로필 관리**: 사용자별 개별 설정

### 📝 스마트 노트 기능
- **실시간 노트**: Alt+C 키보드 단축키로 현재 동영상 시점에 노트 추가
- **타임스탬프 연동**: 노트 클릭시 해당 동영상 시점으로 자동 이동
- **공유 시스템**: 노트마다 고유 URL로 다른 사용자와 공유 가능
- **개인/공개 설정**: 노트를 비공개 또는 공개로 설정
- **유튜브 API**: 정확한 재생 시간 추적 및 제어

### 🎥 동영상 기능
- **YouTube API 통합**: 정확한 재생 시간 제어
- **자동 시작**: 공유된 노트에서 특정 시점부터 재생
- **반응형 플레이어**: 모든 화면 크기에 맞춤

## 🚀 설치 및 실행

### 자동 설치 (권장)

```bash
# 저장소 클론
git clone [repository-url]
cd 020_homepage_teacher

# 자동 설정 스크립트 실행
chmod +x setup.sh
./setup.sh

# 서버 실행
./run_app.sh
```

### 수동 설치

```bash
# Python 가상환경 생성 및 활성화
python3 -m venv venv
source venv/bin/activate  # Mac/Linux
# 또는
venv\Scripts\activate     # Windows

# 의존성 설치
pip install -r requirements.txt

# 데이터베이스 마이그레이션
python manage.py makemigrations
python manage.py migrate

# 관리자 계정 생성
python manage.py createsuperuser

# 개발 서버 실행
python manage.py runserver
```

## 🔧 시스템 요구사항

- **Python**: 3.9 이상
- **Django**: 5.2.1
- **데이터베이스**: SQLite (기본), PostgreSQL/MySQL 지원
- **운영체제**: macOS, Linux, Windows
- **브라우저**: Chrome, Firefox, Safari, Edge (최신 버전)

## 📋 사전 설정된 계정

### 관리자 계정
```
사용자명: admin
비밀번호: admin123
역할: 슈퍼유저 (모든 권한)
```

### 테스트 학생 계정
```
사용자명: student
비밀번호: student123
역할: 일반 사용자 (노트 작성 가능)
```

## 📖 사용 방법

### 1. 기본 접속
- 웹브라우저에서 `http://localhost:8000` 접속
- 홈페이지에서 강의 목록 확인

### 2. 회원가입 및 로그인
- 우상단 "회원가입" 버튼 클릭
- 정보 입력 후 계정 생성
- "로그인" 버튼으로 로그인

### 3. 강의 수강
- 강의 목록에서 원하는 강의 선택
- 챕터별로 구성된 레슨 확인
- 레슨 클릭으로 동영상 시청

### 4. 노트 기능 사용

#### 노트 작성
1. 로그인 후 동영상이 있는 레슨 접속
2. 동영상 시청 중 **Alt+C** 키 입력
3. 현재 재생 시점의 타임스탬프가 자동 설정됨
4. 노트 내용 작성
5. 공개/비공개 설정 선택 후 저장

#### 노트 활용
- **시점 이동**: 노트의 타임스탬프 클릭시 해당 시점으로 자동 이동
- **공유**: 공개 노트는 고유 URL로 다른 사용자와 공유 가능
- **관리**: 본인 노트는 수정/삭제 가능

### 5. 관리자 기능
- `/admin/` 접속으로 관리자 패널 이용
- 강의, 챕터, 레슨, 노트 관리
- 사용자 권한 관리

## 🏗️ 프로젝트 구조

```
020_homepage_teacher/
├── teacher_homepage/           # 메인 프로젝트 설정
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── courses/                    # 강의 앱
│   ├── models.py              # 강의, 챕터, 레슨, 노트 모델
│   ├── views.py               # 뷰 로직
│   ├── urls.py                # URL 패턴
│   ├── admin.py               # 관리자 설정
│   └── templates/             # 템플릿 파일들
├── accounts/                   # 사용자 인증 앱
│   ├── views.py               # 회원가입/로그인 뷰
│   ├── urls.py                # 인증 URL
│   └── templates/             # 인증 관련 템플릿
├── static/                     # 정적 파일
├── media/                      # 업로드된 미디어 파일
├── requirements.txt            # Python 의존성
├── setup.sh                   # 자동 설정 스크립트
├── run_app.sh                 # 서버 실행 스크립트
└── README.md                  # 프로젝트 문서
```

## 🎯 핵심 모델

### Course (강의)
- 제목, 설명, 강사, 썸네일
- 공개/비공개 설정
- 생성/수정 일시

### Chapter (챕터)
- 강의에 속함
- 제목, 설명, 순서
- 계층적 구조 지원

### Lesson (레슨)
- 챕터에 속함
- 제목, 설명, 유튜브 URL, 내용
- 동영상 길이, 순서

### Note (노트)
- 사용자별 개별 노트
- 레슨 특정 시점(타임스탬프)에 연결
- 공개/비공개 설정
- UUID 기반 고유 공유 URL

## 🔑 API 엔드포인트

### 노트 관련 API
```
POST /api/notes/create/              # 노트 생성
PUT  /api/notes/<uuid>/              # 노트 수정
DELETE /api/notes/<uuid>/            # 노트 삭제
GET  /api/lessons/<id>/notes/        # 레슨의 노트 목록
GET  /notes/<uuid>/                  # 노트 공유 페이지
```

### 페이지 URL
```
/                                    # 홈페이지
/courses/                           # 강의 목록
/courses/<id>/                      # 강의 상세
/lessons/<id>/                      # 레슨 상세
/lessons/<id>/?t=<timestamp>        # 특정 시점부터 레슨 시작
/accounts/signup/                   # 회원가입
/accounts/login/                    # 로그인
/accounts/logout/                   # 로그아웃
/admin/                            # 관리자 패널
```

## 🎨 기술 스택

### Backend
- **Django 5.2.1**: 웹 프레임워크
- **Python 3.9+**: 프로그래밍 언어
- **SQLite**: 기본 데이터베이스

### Frontend
- **Bootstrap 5**: UI 프레임워크
- **JavaScript (ES6+)**: 클라이언트 사이드 로직
- **YouTube IFrame API**: 동영상 제어
- **Font Awesome**: 아이콘

### 주요 라이브러리
- **Pillow**: 이미지 처리
- **python-decouple**: 환경 변수 관리

## 🚨 문제 해결

### 일반적인 문제

1. **Pillow 설치 오류 (Mac M1/M2)**
   ```bash
   # Homebrew로 필요한 라이브러리 설치
   brew install libjpeg libpng libtiff
   pip install Pillow
   ```

2. **포트 충돌**
   ```bash
   # 다른 포트로 실행
   python manage.py runserver 8001
   ```

3. **마이그레이션 오류**
   ```bash
   # 마이그레이션 파일 재생성
   python manage.py makemigrations --empty courses
   python manage.py migrate
   ```

4. **정적 파일 로딩 문제**
   ```bash
   # 정적 파일 수집
   python manage.py collectstatic
   ```

## 🛠️ 개발 가이드

### 새로운 기능 추가
1. 모델 변경 시 마이그레이션 실행
2. 관리자 인터페이스에 새 모델 등록
3. URL 패턴 추가
4. 템플릿 생성 또는 수정
5. 정적 파일 업데이트

### 코드 스타일
- Django 기본 컨벤션 준수
- 한국어 주석 및 변수명 사용
- Bootstrap 클래스 활용한 반응형 디자인

## 📝 주요 특징

### 키보드 단축키
- **Alt + C**: 현재 동영상 시점에 노트 추가

### 스마트 기능
- 타임스탬프 클릭으로 동영상 시점 이동
- 노트 공유를 위한 고유 URL 생성
- 반응형 YouTube 플레이어
- 실시간 노트 동기화

## 🎉 샘플 데이터

프로젝트에는 "Django 웹 개발 완전정복" 샘플 강의가 포함되어 있습니다:

- **Chapter 1**: Django 기초 (2개 레슨, 유튜브 동영상 포함)
- **Chapter 2**: 모델과 데이터베이스 (2개 레슨)

## 📞 지원 및 피드백

문제가 발생하거나 개선 사항이 있으시면 이슈를 등록해 주세요.

---

**🎯 이제 Alt+C를 눌러 동영상 학습과 동시에 노트를 작성해보세요!** 