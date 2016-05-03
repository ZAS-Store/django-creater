#!/usr/bin/env bash

subject=$1

DJANGO_DEV_SERVER_HOST="127.0.0.1:8000"
PYENV_PATH="$HOME/.pyenv/libexec/pyenv"

POSTGRESQL_SERVICE_NAME="postgresql-9.4"
POSTGRESQL_SERVICE_NAME="postgresql"

# For RH based distros:
MYSQL_SERVICE_NAME="mysqld"

# For Debian based distros:
MYSQL_SERVICE_NAME="mysql"

# Entirely optional if you want a browser and editor to start up.
# BROWSER_PATH="/usr/bin/chromium-browser"
# EDITOR_PATH=~/bin/subl

MYSQL_SVC_RS_CMD="sudo service $MYSQL_SERVICE_NAME restart"
PG_SVC_RS_CMD="sudo service $POSTGRESQL_SERVICE_NAME restart"

function create_project {
    echo
    echo -n "Enter project name: "
    read project_name

    if [ -d $project_name ]
    then
        echo "A directory called '$project_name' already exists."
        echo "Exiting."
        exit 1
    fi

    echo "Project directory: ${project_name} being created."
    mkdir $project_name
    cd $project_name
}

function pyenv_not_installed {
    echo
    echo "Pyenv does not appear to be installed or is inaccessible"
    echo 'on your $PATH. You may need to run: . ~/.bash_profile (RHEL) '
    echo "or: . ~/.bashrc (Debian)."
    echo "Make sure pyenv is installed properly."
    echo "Exiting."
    cd ..
    rm -rf $project_name
    exit 1
}

function setup_python {
    echo
    if [ -f $PYENV_PATH ]
    then
        echo "Pyenv found ..."
        echo -n "Enter Python version for this project: "
        read python_version
        echo "Installing ${python_version} ..."
        pyenv install $python_version

        status=$?

        if [ "$status" == 127 ]
        then
            pyenv_not_installed
        elif [ "$status" == 2 ]
        then
            echo
            echo "Unable to properly install Python $python_version"
            echo "Ran # pyenv install $python_version when the error occurred."
            echo "Please investigate and retry."
            cd ..
            rm -rf $project_name
            exit 1
        fi

        pyenv global $python_version

        echo "Creating a virtualenv for this project ..."
        pyenv virtualenv $project_name
        pyenv local $project_name

    else
        pyenv_not_installed
    fi
}

function install_packages {
    echo
    echo "Installing Django and a database module of your choice."
    while [ 1 ]
    do
        echo
        echo "For databases you have the following options:"
        echo "-- mysqlclient (MySQL)"
        echo "-- psycopg2 (Postgresql)"
        echo "-- None (use builtin SQLite for now -- enter nothing)"
        echo
        echo -n ": "
        read db_type

        case $db_type in
            mysqlclient)
                break
            ;;
            psycopg2)
                break
            ;;
                "")
                break
            ;;
        esac
        echo
        echo "Type in either: mysqlclient, psycopg2 or press enter "
        echo "(for SQLite)..."
    done

    echo
    echo "First updating pip to make sure we're running with newest package..."

    pip install pip --upgrade

    pip install django $db_type

    if [ "$?" == 1 ]
    then
        if [ "$db_type" == "" ]
        then
            echo "INFO: SQLite selected. No db module needed."
        else
            found_db_type=$(pip freeze | grep $db_type|wc -l)
            if [ "$found_db_type" -gt 0 ]
            then
                echo "INFO: $db_type already installed."
            else
                echo "Unable to install django and/or $db_type module. "
                echo "For MySQL ensure you have mysql-server and mysql-devel installed."
                echo "For Postgresql ensure you have postgresql-server and postgresql-devel installed."
                echo "Please investigate. Exiting."
                cd ..
                rm -rfv $project_name
                exit 1
            fi
        fi
    fi

    pip freeze > requirements.txt

    echo $project_name > .python-version
}

function postgresql_issue {
    echo
    echo "There appears to be a problem with your Postgresql setup."
    echo "Check the following: "
    echo "* Correct postgresql service name "
    echo "* You have set up '$dbuser' with proper privileges and access."
    echo "Exiting."
    cd ..
    rm -rf $project_name
    exit 1
}

function setup_postgresql {
    echo
    echo "
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': '${dbname}',
        'USER': '${dbuser}',
        'PASSWORD': '${dbpasswd}',
        'HOST': '${dbhost}',
        'PORT': '${dbport}',
    }
}
" >> $project_name/$project_name/settings.py
    echo "Restarting database service ..."
    $PG_SVC_RS_CMD

    if [ "$?" == 127 ]
    then
        echo "ERROR: You don't appear to have privileges to restart the "
        echo "postgresql service. You may also need to install 'sudo'. "
        echo "Exiting."
        cd ..
        rm -rf $project_name
        exit 1
    fi

    if [ "$?" == 1 ]
    then
        postgresql_issue
    fi

    # Recreate database
    echo "Dropping database $dbname ..."
    sudo -iu postgres dropdb $dbname

    echo "Creating new database $dbname ..."
    sudo -iu postgres createdb -O $dbuser $dbname

    if [ "$?" == 1 ]
    then
        postgresql_issue
    fi
}

function mysql_issue {
    echo
    echo "There appears to be a problem with your MySQL service."
    echo "Check to see if it's starting. Also keep in mind that "
    echo "this script expects the MySQL root user to have a password."
    echo "Exiting."
    cd ..
    rm -rf $project_name
    exit 1
}

function setup_mysql {
    echo
    echo "
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': '${dbname}',
        'USER': '${dbuser}',
        'PASSWORD': '${dbpasswd}',
        'HOST': '${dbhost}',
        'PORT': '${dbport}',
    }
}
" >> $project_name/$project_name/settings.py

    echo "Restarting database service ..."
    $MYSQL_SVC_RS_CMD

    if [ "$?" == 127 ]
    then
        echo "ERROR: You don't appear to have privileges to restart the "
        echo "mysqld service. You may also need to install 'sudo'. "
        echo "Exiting."
        cd ..
        rm -rf $project_name
        exit 1
    fi

    echo "Dropping database $dbname ..."
    echo "Enter the MySQL root password below ..."
    mysql -u root -p -h $dbhost -e "drop database ${dbname}"

    if [ "$?" == 1 ]
    then
        echo " ... continuing ..."
    fi

    echo "Creating new database $dbname ..."
    echo "Enter the MySQL root password below ..."
    mysql -u root -p -h $dbhost -e "create database ${dbname}; grant all privileges on $dbname.* to '${dbuser}'@'${dbhost}' identified by '${dbpasswd}'"

    if [ "$?" == 1 ]
    then
        mysql_issue
    fi
}

function create_django_project {
    echo
    echo "Creating Django project '$project_name' ..."
    django-admin.py startproject $project_name

    mkdir -p $project_name/static/css $project_name/static/img $project_name/static/js

    echo "
STATICFILES_DIRS = (
os.path.join(BASE_DIR, 'static'),
)
    " >> $project_name/$project_name/settings.py

    if [ "$db_type" != "" ]
    then
        echo
        echo "INFO: Keep in mind that if you are using Unix sockets "
        echo "as a connection, use 127.0.0.1 as the hostname."
        echo "Enter your database server hostname: "
        read dbhost

        echo "Enter your database server port: "
        read dbport

        echo "Enter your database name: "
        read dbname

        echo "Enter your database username: "
        read dbuser

        echo "Enter your database password: "
        read dbpasswd
    fi

    if [ "$db_type" == "psycopg2" ]
    then
        echo "Setting up Postgresql ..."
        setup_postgresql
    fi

    if [ "$db_type" == "mysqlclient" ]
    then
        echo "Setting up MySQL ..."
        setup_mysql
    fi
}

function create_main_app {
    cd $project_name
    echo "Enter name of your main app: "
    read app_name
    ./manage.py startapp $app_name
    cd ..
    echo "
INSTALLED_APPS.append('$app_name')

LOGIN_REDIRECT_URL='/'
LOGIN_URL='/login/'

" >> $project_name/$project_name/settings.py

    wget https://raw.githubusercontent.com/hseritt/django-creater/master/django-files/urls.py

    echo "

from django.conf.urls import include

urlpatterns.append(
    url(r'^', include('$app_name.urls')),
)
" >> $project_name/$project_name/urls.py

    sed -e s/APP_NAME\./$app_name\./ urls.py > urls.tmp.py
    mv urls.tmp.py urls.py

    mv urls.py $project_name/$app_name/.
    mkdir -p $project_name/$app_name/templates/$app_name
    wget https://raw.githubusercontent.com/hseritt/django-creater/master/django-files/login.html
    mv login.html $project_name/$app_name/templates/$app_name/.
    wget https://raw.githubusercontent.com/hseritt/django-creater/master/django-files/index.html
    mv index.html $project_name/$app_name/templates/$app_name/.
    wget https://raw.githubusercontent.com/hseritt/django-creater/master/django-files/views.py

    sed -e s/PROJECT\./$project_name\./ views.py > views.tmp.py
    mv views.tmp.py views.py

    sed -e s/APP_NAME\./$app_name\./ views.py > views.tmp.py
    mv view.tmp.py views.py

    mv -f views.py $project_name/$app_name/.
}

function setup_django {
    echo
    cd $project_name
    ./manage.py makemigrations
    ./manage.py migrate

    echo "Creating a super user for Django admin: "
    ./manage.py createsuperuser

    echo "Now starting the Django dev server:"
    ./manage.py runserver $DJANGO_DEV_SERVER_HOST

    $EDITOR_PATH . 2>/dev/null

    $BROWSER_PATH "http://localhost:8000/admin/" 2>/dev/null
}

function usage {
    echo "  USAGE:"
    echo "  ./django-creater [project]"
    exit 1
}

case $subject in
    project)
        create_project
        setup_python
        install_packages
        create_django_project
        create_main_app
        setup_django
        ;;
    "")
        usage
        ;;

esac