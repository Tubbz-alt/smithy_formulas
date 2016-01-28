class OctaveFormula < Formula
  homepage "https://ftp.gnu.org/"
  url "https://ftp.gnu.org/gnu/octave/octave-4.0.0.tar.xz"
  md5 "f3de0a0d9758e112f13ce1f5eaf791bf"

  depends_on "pcre"
  module_commands ["load pcre"]

  def install
    module_list
    system "CPPFLAGS=`pcre-config --cflags` LDFLAGS=`pcre-config --libs` ./configure --prefix=#{prefix}"
    system "make"
    system "make install"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    set PREFIX <%= @package.prefix %>

    prepend-path PATH             $PREFIX/bin
    prepend-path LD_LIBRARY_PATH  $PREFIX/lib/octave-4.0.0
    prepend-path MANPATH          $PREFIX/share/man
  MODULEFILE
end
