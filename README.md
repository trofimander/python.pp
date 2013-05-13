python.pp
=========

Puppet scripts for installing Python and configuring virtual environments


##Usage

See examples for details.


###python::install

Installs python 

####Arguments
name - Python-X.Y.Z (e.g. Python-2.7.3)

pref - path prefix where python should be installed (default /usr/local)

from_source - if true then install from sources (downloaded automaticly), false - install from ubuntu package

###python::configure

Configures python to be ready for creating virtual environments and installing new packages, namely downloads and installs
distribute, pip and virtualenv.

####Arguments

name - Python-X.Y.Z (e.g. Python-2.7.3)

pref - path prefix where python should be installed (default /usr/local)

pipversion - version of PIP (default 1.1)


###python:pip

Installs package to selected interpreter/virtualenv.

####Arguments

prefix - path prefix where desired interpreter is located (default /usr/local)

short_version - 2 first digit of version of python whose corresponding pip shuold be used

####Example

If you want to install package Django 1.5 to /usr/opt/python2.6 then you write 
    python:pip{"installing django":
      prefix=>"/usr/opt/python2.6",
      short_version=>2.6,
    }





