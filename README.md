
# App::Po

## Description

App::Po borrows some good stuff from Jifty::I18N and tries to provide a general
po management script for all frameworks | applications. 

## Usage

create dictionary files for language:

	po lang zh_tw en

parse i18n strings:

	po parse bin lib static share/web/static/js ...

start a web server to edit po file:

    po server -f po/en.po

start a web server to edit po file of specified language:

    po server --lang en

extract message from files and start a web server:

    po server --dir lib --dir share/static --lang en

## **UNDERCONSTRUCTION**

to initialize a system-side i18n database:

	po initdb 

to start a web interface to edit/approve messages.

	po server
