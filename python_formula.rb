class PythonFormula < Formula
  homepage "www.python.org/"

  depends_on "sqlite"

  module_commands ["unload python"]

  concern for_version("2.7.9") do
    included do
      url "https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz"
      md5 "5eebcaa0030dc4061156d3429657fb83"
    end
  end

  concern for_version("3.4.3") do
    included do
      url "https://www.python.org/ftp/python/3.4.3/Python-3.4.3.tgz"
      md5 "4281ff86778db65892c05151d5de738d"
    end
  end

  concern for_version("3.5.1") do
    included do
      url "https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tgz"
      md5 "be78e48cdfc1a7ad90efff146dce6cfe"
    end
  end

  def install
    module_list
    ENV["CPPFLAGS"] = "-I#{sqlite.prefix}/include"
    ENV["LDFLAGS"]  = "-L#{sqlite.prefix}/lib"
    system "./configure --prefix=#{prefix} --enable-shared"
    system "make"
    system "make install"

    if File.exist? "#{prefix}/bin/python3"
      system "cd #{prefix}/bin && ",
        "ln -snf python3 python ; ",
        "ln -snf pip3 pip ; ",
        "ln -snf pydoc3 pydoc ; ",
        "ln -snf idle3 idle ; "
    end
  end

  modulefile do
    <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    # One line description
    module-whatis "<%= @package.name %> <%= @package.version %>"

    conflict python

    set PREFIX <%= @package.prefix %>

    prepend-path PATH            $PREFIX/bin
    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path MANPATH         $PREFIX/share/man
    prepend-path PKG_CONFIG_PATH $PREFIX/lib/pkgconfig
    prepend-path PYTHONPATH      $PREFIX/lib/#{python_libdir(version)}/site-packages
    MODULEFILE
  end
end
