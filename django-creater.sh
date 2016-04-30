#!/usr/bin/env bash

subject=$1

PYENV_PATH=~/.pyenv/libexec/pyenv
BROWSER_PATH="/usr/bin/chromium-browser"
EDITOR_PATH=~/bin/subl

MYSQL_SVC_RS_CMD="sudo service mysqld restart"
PG_SVC_RS_CMD="sudo service postgresql-9.4 restart"

function create_project {
    echo
    echo "Enter project name: "
    read project_name

    if [ -d $project_name ]
    then
        echo "A directory called $project_name already exists."
        echo "Exiting."
        exit 1
    fi

    echo "Project directory: ${project_name} being created."
    mkdir $project_name
    cd $project_name
}

function pyenv_not_installed {
    echo "Pyenv does not appear to be installed or is inaccessible"
    echo 'on your $PATH.'
    echo "Make sure it's installed properly."
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
        echo "Enter Python version for this project: "
        read python_version
        echo "Installing ${python_version} ..."
        pyenv install $python_version
        if [ "$?" == 127 ]
        then
            pyenv_not_installed
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
    echo "Ok... we are going to install Django and a database module of your choice right now."
    while [ 1 ]
    do
        echo "For databases you have the following options:"
        echo "-- mysqlclient (MySQL)"
        echo "-- psycopg2 (Postgresql)"
        echo "-- None (use builtin SQLite for now -- enter nothing)"
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

        echo "Type in either: mysqlclient, psycopg2 or nothing (for SQLite)..."
    done

    echo "First updating pip to make sure we're running with newest package..."
    pip install pip --upgrade

    pip install django $db_type

    if [ "$?" == 1 ]
    then
        echo "Unable to install django and/or $db_type module. Please investigate."
        cd ..
        rm -rfv $project_name
        exit 1
    fi

    pip freeze > requirements.txt

    echo $project_name > .python-version
}

function postgresql_issue {
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
        echo "postgresql service. Exiting."
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
        echo "mysqld service. Exiting."
        cd ..
        rm -rf $project_name
        exit 1
    elif [ "$?" == 1 ]
    then
        echo "Trying 'mysqld' instead."
        sudo service mysqld restart
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
    django-admin.py startproject $project_name

    mkdir -p $project_name/static/css $project_name/static/img $project_name/static/js

    echo "
STATICFILES_DIRS = (
os.path.join(BASE_DIR, 'static'),
)
    " >> $project_name/$project_name/settings.py

    if [ "$db_type" != "" ]
    then

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

function setup_django {
    echo
    cd $project_name
    ./manage.py makemigrations
    ./manage.py migrate

    echo "Creating a super user for Django admin: "
    ./manage.py createsuperuser

    echo "Now starting the Django dev server:"
    ./manage.py runserver

    #$EDITOR_PATH .

    #$BROWSER_PATH "http://localhost:8000/admin/"
}

case $subject in
    project)
        create_project
        setup_python
        install_packages
        create_django_project
        setup_django
    ;;

esac