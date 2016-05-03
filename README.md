# django-creater

A simple script to create a Django project for you.

## What does it do?

Does the following:

```bash
./django-creater.sh project
```

* Creates a project directory (main directory to house the Django project directory).

* Installs Python version needed for your project using pyenv.

*  Creates a virtualenv for your project.

* Installs either mysqlclient or psycopg2 Python modules with Pip.

* Installs the Django module.

* Creates the database in either Postgresql or MySQL (requires that you have the authorization to do so).

* Sets database settings for your Django project and also sets up static directory (subdirectories [css, img, js] and STATICFILES_DIRS entry in project settings).

* Runs makemigrations and migrate for auth model.

## How do I install it?

```bash
 wget https://raw.githubusercontent.com/hseritt/django-creater/master/django-creater.sh
 chmod +x django-creater.sh
```

## How do I run it?

```bash
./django-creater.sh project
```

## Dependencies:

* Python (of course!)
* [Pyenv](http://fgimian.github.io/blog/2014/04/20/better-python-version-and-environment-management-with-pyenv/)
* Python virtualenv (with recent versions of pyenv virtualenv is included).
* The database server of your choice (Postgresql or MySQL) or you can use SQLite if you choose not to use a standard database server.

## Supported:

* Ubuntu 14.04
* CentOS 6

## FAQs

* How do I set up Postgresql server for Django? Please see [this](https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-django-application-on-ubuntu-14-04).

* How do I set up MySQL server for Django? Please see [this](http://www.marinamele.com/taskbuster-django-tutorial/install-and-configure-mysql-for-django).