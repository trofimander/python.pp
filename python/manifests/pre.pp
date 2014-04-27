class pre($prefix="/usr/local") {
	package {["build-essential",
	          "libncursesw5-dev",
	          "libncurses5-dev",
                  "libreadline-gplv2-dev",
                  "libssl-dev",
                  "libsasl2-dev",
                  "libgdbm-dev",
                  "libbz2-dev",
                  "libc6-dev",
                  "libsqlite3-dev",
                  "tk-dev",
                  "zlibc",
                  "zlib1g",
                  "zlib1g-dev"]:
		ensure => installed,
		provider => apt
	}

	file {"$prefix":
		ensure => directory
	}
}

define source_install($tarball, $tmpdir, $flags) {
  file { "$tmpdir": ensure => directory }

  exec { "retrieve-$name":

    command => "wget $tarball",
    cwd => "$tmpdir",
    before => Exec["extract-$name"],
    notify => Exec["extract-$name"],
    creates => "$tmpdir/$name.tgz",
  }

  exec { "extract-$name":
    command => "tar -zxf $name.tgz",
    cwd => $tmpdir,
    creates => "$tmpdir/$name/README",
    require => Exec["retrieve-$name"],
    before => Exec["configure-$name"],
  }

  exec { "configure-$name":
    cwd => "$tmpdir/$name",
    command => "$tmpdir/$name/configure $flags --prefix=$prefix",
    require => Exec["extract-$name"],
    before => Exec["make-$name"],
  }

  exec { "make-$name":
    cwd => "$tmpdir/$name",
    command => "make && make install",
    require => Exec["configure-$name"],
  }
}
