sudo apt-get install build-essential
sudo apt-get install libncursesw5-dev
sudo apt-get install libreadline-gplv2-dev
sudo apt-get install libssl-dev
sudo apt-get install libgdbm-dev
sudo apt-get install libbz2-dev
sudo apt-get install libc6-dev
sudo apt-get install libsqlite3-dev
sudo apt-get install tk-dev

class python {
  define source_install($tarball, $tmpdir, $flags) {
    case $ensure {
      present: {
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
    }
  }
  
  define install ($pref="/usr/local", $tmpdir = "/tmp/tmpPython$version", $executable_name = "python", $from_source=false) {
    if ($name =~ /^(\d)\.(\d)\.(\d)/) {
        $short_version = "$1.$2"
    } else {
        fail("name be a version in format X.X.X for example 2.7.3")
    }


    $binary="$executable_name$short_version"

    Exec { path => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin" }
    include pre

    if ($from_source) {
      $flags = "LDFLAGS=-L/usr/lib/x86_64-linux-gnu"
      
      source_install { "Python-$name":
        tarball => "http://python.org/ftp/python/$version/Python-$version.tgz",
        tmpdir => $tmpdir,
        flags => $flags,
        require => Class["pre"],
      }
      $prefix = $pref
    } else {
      $prefix = "/usr/local"
      package { "python$short_version":
        ensure => installed,
        provider => apt,
      }
    }
  }

  define configure ($pref="/usr", $pipversion="1.1", $executable_name="python") {
      if ($name =~ /^Python-(\d)\.(\d)/) {
              $short_version = "$1.$2"
          } else {
              fail("name be a short version in format X.X for example 2.7")
       }

       $tmpdir = "/tmp/tmpPython$short_version"


      $binary="$executable_name$short_version"

      Exec { path => "/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin" }
      include pre

      file { "$tmpdir": ensure => directory }

      exec { "retrieve-distribute-$short_version":
        command => "wget http://python-distribute.org/distribute_setup.py",
        cwd => $tmpdir,
        require => Class["pre"],
      }

      exec { "retrieve-pip-$short_version":
        command => "wget http://pypi.python.org/packages/source/p/pip/pip-$pipversion.tar.gz",
        cwd => $tmpdir,
        require => Class["pre"],
        before => Exec["extract-pip-$short_version"],
        creates => "$tmpdir/pip-$pipversion"
      }

      exec { "extract-pip-$short_version":
        command => "tar -zxf pip-$pipversion.tar.gz",
        cwd => $tmpdir,
        creates => "$tmpdir/pip-$pipversion",
        require => Exec["retrieve-pip-$short_version"],
      }

      exec { "install-distribute-$short_version":
        command =>"$pref/bin/$binary $tmpdir/distribute_setup.py",
        cwd => $tmpdir,
        require => [
                    Exec["retrieve-distribute-$short_version"],
                    ],
        before => Exec["install-pip-$short_version"],
        creates => "$pref/bin/pip-$short_version",
        logoutput => true,
      }

      exec { "install-pip-$short_version":
        command => "$pref/bin/$binary $tmpdir/pip-$pipversion/setup.py install --install-scripts=$pref/bin",
        cwd => "$tmpdir/pip-$pipversion",
        creates => "$pref/bin/pip-$short_version",
        require => [
                    Exec["extract-pip-$short_version"],
                    Exec["install-distribute-$short_version"]
                    ],
        before => Pip["virtualenv-$short_version"]
      }

      if ($short_version == "2.5") {
        $venv_version="virtualenv==1.9.1" #The latest virtualenv supporting Python 2.5
      } else {
        $venv_version="virtualenv"
      }
      pip { "virtualenv-$short_version":
        prefix => $pref,
        ensure => present,
        short_version => $short_version,
        command => $venv_version,
        install_scripts => "$pref/bin",
        require => Exec["install-pip-$short_version"],
      }
    }

  define pip($prefix="/usr", $ensure, $short_version="2.6", $command=undef, $install_scripts=undef) {
    case $ensure {
      present: {
        if (file_exists("$prefix/bin/pip$short_version")) {
          $pip_file="$prefix/bin/pip$short_version"
        } else {
          $pip_file="$prefix/bin/pip-$short_version"
        }
        if ($install_scripts) {
          exec { "pip-uninstall-$name":
                command => "$pip_file uninstall -y $command",
                timeout => "-1",
                returns => [0, 1],
                before => Exec["pip-install-$name"],
          }
          exec { "pip-install-$name":
                command => "$pip_file install --install-option=\"--install-scripts=$install_scripts\" $command",
                timeout => "-1",
                logoutput => true,
                require => Exec["pip-uninstall-$name"],
          }
        } else
        {
          exec { "pip-install-$name":
                command => "$pip_file install $command",
                timeout => "-1",
                logoutput => true,
          }
        }

      }
    }
  }

  define easy_install($prefix="/usr", $ensure, $executable="python", $short_version="2.6", $command=undef, $tmpdir="/tmp") {
    case $ensure {
      present: {
        exec { "retrieve-ez_setup-$name":
            command => "/usr/bin/wget http://peak.telecommunity.com/dist/ez_setup.py",
          #command => "wget http://python-distribute.org/distribute_setup.py",
          cwd  => $tmpdir,
          logoutput => true,
          creates => "$tmpdir/ez_setup.py",
        }
        exec { "ez_setup-$name":
          command => "$prefix/bin/$executable $tmpdir/ez_setup.py",
          creates => "$prefix/bin/easy_install",
          require => Exec["retrieve-ez_setup-$name"],
        }
              exec { "easy_install-$name":
                    command => "$prefix/bin/easy_install $command",
                      timeout => "-1",
                      logoutput => true,
          require => Exec["ez_setup-$name"],
              }
        }
    }
  }

  define virtualenv($prefix="/usr", $short_version="2.6", $libraries = undef) {
    exec {$name:
      command => "$prefix/bin/virtualenv-$short_version --no-site-packages $name",
      creates => "$name/bin/python",
      logoutput => true,
    }

    if $libraries {
       pip {"virtualenv in $name":
            prefix => $name,
            short_version => $short_version,
            ensure => present,
            require => Exec[$name],
            command => $libraries
       }
    }
  }
}


