class PythonMatplotlibFormula < Formula
  homepage "http://matplotlib.org/"

  supported_build_names /python.*numpy.*gnu.*/

  concern for_version("1.4.3") do
    included do
      url "https://pypi.python.org/packages/source/m/matplotlib/matplotlib-1.4.3.tar.gz"
      md5 "86af2e3e3c61849ac7576a6f5ca44267"
    end
  end

  concern for_version("1.4.0") do
    included do
      url "https://downloads.sourceforge.net/project/matplotlib/matplotlib/matplotlib-1.4.0/matplotlib-1.4.0.tar.gz"
    end
  end

  depends_on do
    python_module_from_build_name
  end

  #chose not to build with [ "python_pygtk" ]
  module_commands do
    pe = "PE-"
    pe = "PrgEnv-" if cray_system?

    commands = [ "unload #{pe}gnu #{pe}pgi #{pe}cray #{pe}intel" ]
    commands << "load #{pe}gnu"
    commands << "swap gcc gcc/#{$1}" if build_name =~ /gnu([\d\.]+)/
    commands << "unload python"
    commands << "load #{python_module_from_build_name}"
    commands << "load python_numpy"
    commands << "load python_pygtk" unless arch == "xc30"
    commands << "load python_nose"
    commands << "load python_setuptools"
    commands
  end

  def install
    module_list

    unless (build_name =~ /python3.3/) || (Smithy::Config.arch = "xc30")
      File.open("setup.cfg", "w+") do |f|
        f.write <<-EOF.strip_heredoc

	  [gui_support]
	  gtk = True
	  #gtkagg = auto
	  #tkagg = auto
	  #macosx = auto
	  #windowing = auto
	  gtk3cairo = False
	  gtk3agg = False

	  [rc_options]
	  backend = GTK
        EOF
      end
    end

    FileUtils.mkdir_p "#{prefix}/lib"

    ENV['CC']  = 'gcc'
    ENV['CXX'] = 'g++'
    ENV['OPT'] = '-O3 -funroll-all-loops'

    if build_name.include? "libsci"
      ENV['CC']  = 'cc'
      ENV['CXX'] = 'CC'
      snos_libs = module_environment_variable("gcc", "LD_LIBRARY_PATH")
      FileUtils.cp "#{snos_libs}/libstdc++.so.6", "#{prefix}/lib", verbose: true
    end

    system_python "setup.py install --prefix=#{prefix} --compile"
  end

  def test
    module_list
    Dir.chdir prefix
    system "PYTHONPATH=$PYTHONPATH:#{prefix}/lib/#{python_libdir(current_python_version)}/site-packages",
      "LD_LIBRARY_PATH=#{prefix}/lib:$LD_LIBRARY_PATH",
      "python -c 'import nose, matplotlib; matplotlib.test()'"

    notice_warn <<-EOF.strip_heredoc
      Testing matplotlib manually:
      module load python python_nose python_numpy python_matplotlib
      python -c 'import nose, matplotlib; matplotlib.test()'
    EOF
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    # One line description
    module-whatis "<%= @package.name %> <%= @package.version %>"

    prereq python
    module load python_numpy
    <%= Smithy::Config.arch == "xc30" ? "" : "module load python_pygtk" %>
    prereq python_numpy

    <%= python_module_build_list @package, @builds %>
    set PREFIX <%= @package.version_directory %>/$BUILD

    prepend-path PYTHONPATH      $PREFIX/lib/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $PREFIX/lib64/$LIBDIR/site-packages
  MODULEFILE
end
