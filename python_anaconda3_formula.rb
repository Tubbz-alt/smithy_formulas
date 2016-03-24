class PythonAnaconda3Formula < Formula
  homepage "https://www.continuum.io"
  url "none"

  def install
    module_list
    system "wget https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda3-2.3.0-Linux-x86_64.sh"
    system "bash Anaconda3-2.3.0-Linux-x86_64.sh -b -f -p #{prefix}"
    system "chmod 700 #{prefix}/bin/conda*"
    system "chmod 700 #{prefix}/bin/pip*"
    system "mv #{prefix}/bin/conda* #{prefix}"
    system "mv #{prefix}/bin/pip* #{prefix}"
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    # One line description
    module-whatis "<%= @package.name %> <%= @package.version %>"
    
    set PREFIX <%= @package.version_directory %>/<%= @package.build_name %>
    
    prepend-path PATH            $PREFIX/bin
  MODULEFILE

end
