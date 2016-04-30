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

## How do I run it?

```bash
./django-creater.sh project
```

## Dependencies:

* Python (of course!)
* [Pyenv](http://fgimian.github.io/blog/2014/04/20/better-python-version-and-environment-management-with-pyenv/)
* Python virtualenv
* The database server of your choice (Postgresql or MySQL)

## Supported:

* Ubuntu 14.04
