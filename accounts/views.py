from django.shortcuts import render, redirect
from django.contrib.auth import login
from django.contrib.auth.forms import UserCreationForm
from django.contrib import messages
from django.urls import reverse_lazy
from django.views.generic import CreateView
from django.contrib.auth.views import LoginView, LogoutView


class CustomUserCreationForm(UserCreationForm):
    """커스텀 회원가입 폼"""
    class Meta:
        model = UserCreationForm.Meta.model
        fields = ('username', 'email', 'password1', 'password2')
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'].help_text = '150자 이하. 문자, 숫자, @/./+/-/_ 만 사용 가능합니다.'
        self.fields['email'].required = True
        self.fields['password1'].help_text = '8자 이상, 너무 흔한 비밀번호는 사용할 수 없습니다.'


class SignUpView(CreateView):
    """회원가입 뷰"""
    form_class = CustomUserCreationForm
    template_name = 'accounts/signup.html'
    success_url = reverse_lazy('accounts:login')
    
    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, '회원가입이 완료되었습니다! 로그인해주세요.')
        return response
    
    def dispatch(self, request, *args, **kwargs):
        # 이미 로그인된 사용자는 홈페이지로 리다이렉트
        if request.user.is_authenticated:
            return redirect('courses:home')
        return super().dispatch(request, *args, **kwargs)


class CustomLoginView(LoginView):
    """커스텀 로그인 뷰"""
    template_name = 'accounts/login.html'
    redirect_authenticated_user = True
    
    def form_valid(self, form):
        messages.success(self.request, f'{form.get_user().username}님, 환영합니다!')
        return super().form_valid(form)


class CustomLogoutView(LogoutView):
    """커스텀 로그아웃 뷰"""
    def dispatch(self, request, *args, **kwargs):
        if request.user.is_authenticated:
            messages.info(request, '로그아웃되었습니다.')
        return super().dispatch(request, *args, **kwargs)
