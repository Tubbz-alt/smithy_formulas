class CdoFormula < Formula
  homepage "https://code.zmaw.de/projects/cdo"
  url "https://code.zmaw.de/attachments/download/10198/cdo-1.6.9.tar.gz"
  md5 "bf0997bf20e812f35e10188a930e24e2"
  
 
  module_commands do
    [ "load cray-netcdf" ]
  end

#  depends_on ["cray-netcdf"]

  def install
    ENV["CC"]      = "gcc"
    ENV["CXX"]     = "g++"
    netcdf_dir = ENV['NETCDF_DIR']
    system "./configure --with-netcdf=#{netcdf_dir} --prefix=#{prefix}"
    system "make"
    system "make install"
  end

  modulefile do
    <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    set PREFIX <%= @package.prefix %>
 
    setenv CDO_DIR "${PREFIX}"

    prepend-path PATH      $PREFIX/bin
    prepend-path MANPATH   $PREFIX/share/man
    MODULEFILE
  end
end
