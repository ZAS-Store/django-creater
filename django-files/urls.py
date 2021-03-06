from __future__ import absolute_import

from django.conf.urls import url
from django.contrib.auth.views import login
from django.contrib.auth.views import logout
from APP_NAME.views import index

urlpatterns = [
    url(
        regex=r'^$',
        view=index,
        name='index'
    ),
    url(
        regex=r'^login/$',
        view=login,
        kwargs={'template_name': 'APP_NAME/login.html'},
        name='login'
    ),
    url(
        regex=r'^logout/$',
        view=logout,
        kwargs={'next_page': '/'},
        name='logout'
    ),
]
