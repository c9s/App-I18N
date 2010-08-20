
# App::Po

## Description

App::Po tries to provide a general po management script for all frameworks |
applications. 

## Usage

create dictionary files for language:

	po lang zh_tw en

parse i18n strings:

	po parse bin lib static share/web/static/js ...

to initialize a system-side i18n database:

	po initdb 

