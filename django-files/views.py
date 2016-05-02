
from __future__ import absolute_import

from django.contrib.auth.decorators import login_required
from django.shortcuts import render
from PROJECT.settings import LOGIN_URL


@login_required(login_url=LOGIN_URL)
def index(request):
    return render(
        request,
        'common/index.html',
    )
