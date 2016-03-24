class NclFormula < Formula
  homepage "https://www.earthsystemgrid.org/dataset/ncl.630.1.html"
  url "file:///sw/sources/ncl/6.3.0/ncl_ncarg-6.3.0.Linux_RHEL6.4_x86_64_nodap_gcc472.tar.gz"

  def install
    module_list
  end

  modulefile <<-modulefile.strip_heredoc
#%Module
proc ModulesHelp { } {
   puts stderr "<%= @package.name %> <%= @package.version %>"
      puts stderr ""
      }
      # One line description
      module-whatis "<%= @package.name %> <%= @package.version %>"

      set PREFIX <%= @package.prefix %>/source

      # Helpful ENV Vars
      setenv NCL_DIR $PREFIX
      setenv NCL_LIB "-L$PREFIX/lib"
      setenv NCL_INC "-I$PREFIX/include"

      # Common Paths
      prepend-path PATH            $PREFIX/bin
      prepend-path LD_LIBRARY_PATH $PREFIX/lib
      prepend-path MANPATH         $PREFIX/share/man
      prepend-path INFOPATH        $PREFIX/info
      prepend-path PKG_CONFIG_PATH $PREFIX/lib/pkgconfig
      prepend-path PYTHONPATH      $PREFIX/lib/python2.7/site-packages
      prepend-path PERL5PATH       $PREFIX/lib/perl5/site_perl

      setenv NCARG_ROOT $PREFIX
      prepend-path PATH $PREFIX/bin

  modulefile
end
