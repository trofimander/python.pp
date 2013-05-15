include python

python::virtualenv {"$envs_path/python25":
        short_version => "2.5",
}

python::virtualenv {"$envs_path/django13":
        short_version => "2.6",
        libraries => "django==1.3 nose pytest ipython==0.11",
}

python::virtualenv {"$envs_path/django14":
	short_version => "2.7",
	libraries => "django==1.4",
}


python::virtualenv {"$envs_path/ipython12":
	short_version => "2.7",
	libraries => "ipython==0.12",
}

python::virtualenv {"$envs_path/python32":
        short_version => "3.2",
        libraries => "ipython==0.12 django==1.5",
}

python::virtualenv {"$envs_path/jython2.5":
	prefix => $jython_path,
        short_version => "2.5",
}

