class PythonNumpyFormula < Formula
  # Testing numpy:
  # module load python python_nose python_numpy
  # python -c 'import nose, numpy; numpy.test()'

  homepage "http://www.numpy.org/"
  additional_software_roots [ config_value("lustre-software-root")[hostname] ]

  supported_build_names /python.*_acml_gnu.*|python.*_craylibsci_gnu.*|python.*_mkl_gnu.*/

  concern for_version("1.8.0") do
    included do
      url "http://downloads.sourceforge.net/project/numpy/NumPy/1.8.0/numpy-1.8.0.tar.gz"
    end
  end

  concern for_version("1.9.2") do
    included do
      url "http://downloads.sourceforge.net/project/numpy/NumPy/1.9.2/numpy-1.9.2.tar.gz"
    end
  end

  params acml: false 
  params cray_libsci: false 
  params mkl: false 

  depends_on do
    case build_name
    when /acml/
      acml = true
      [ python_module_from_build_name, "cblas/20110120/*acml*" ]
    when /craylibsci/
      cray_libsci = true
      [ python_module_from_build_name ]
    when /mkl/
      mkl = true
      [ python_module_from_build_name ]
    end
  end

  module_commands do
    pe = "PE-"
    pe = "PrgEnv-" if cray_system?

    commands = [ "unload #{pe}gnu #{pe}pgi #{pe}cray #{pe}intel" ]
    commands << "load #{pe}gnu"
    commands << "swap gcc gcc/#{$1}" if build_name =~ /gnu([\d\.]+)/

    if acml == true
      commands << "load acml"
    elsif cray_libsci == true
      commands << "load cray-libsci"
    end
    commands << "unload python"
    commands << "load #{python_module_from_build_name}"

    commands
  end

  def install
    module_list
    ml_prefix = ""

    FileUtils.mkdir_p "#{prefix}/lib"
    if acml == true
      ml_prefix = module_environment_variable("acml", "ACML_BASE_DIR")
      ml_prefix += "/gfortran64"
      FileUtils.cp "#{cblas.prefix}/lib/libcblas.a", "#{prefix}/lib", verbose: true
      FileUtils.cp "#{ml_prefix}/lib/libacml.a",   "#{prefix}/lib", verbose: true
      FileUtils.cp "#{ml_prefix}/lib/libacml.so",  "#{prefix}/lib", verbose: true
    elsif cray_libsci == true
      ml_prefix = module_environment_variable("cray-libsci", "CRAY_LIBSCI_PREFIX_DIR")
      FileUtils.cp "#{ml_prefix}/lib/libsci_gnu.a",   "#{prefix}/lib", verbose: true
      FileUtils.cp "#{ml_prefix}/lib/libsci_gnu.so",  "#{prefix}/lib", verbose: true
    end


    ENV['CC']  = 'cc'
    ENV['CXX'] = 'CC'
    ENV['OPT'] = '-O3 -funroll-all-loops'

    inc_dirs = ""
    if acml == true
      inc_dirs = "#{cblas.prefix}/include"
    elsif cray_libsci == true
      inc_dirs = "#{ml_prefix}/include"
    end
    if mkl == true
      File.open("site.cfg", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          [mkl]
          library_dirs = /opt/intel/composer_xe_2015.2.164/mkl/lib/intel64
          include_dirs = /opt/intel/composer_xe_2015.2.164/mkl/include
          lapack_libs = mkl_gf_lp64,mkl_gnu_thread,mkl_core
          mkl_libs = mkl_gf_lp64,mkl_gnu_thread,mkl_core

          [fftw]
          libraries = fftw3
          library_dirs = /opt/fftw/3.3.0.1/x86_64/lib
          include_dirs = /opt/fftw/3.3.0.1/x86_64/include
          EOF
      end
    else
      File.open("site.cfg", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          [blas]
          blas_libs = cblas, acml
          library_dirs = #{prefix}/lib
          include_dirs = #{inc_dirs}

          [lapack]
          language = f77
          lapack_libs = acml
          library_dirs = #{ml_prefix}/lib
          include_dirs = #{ml_prefix}/include

          [fftw]
          libraries = fftw3
          library_dirs = /opt/fftw/3.3.0.1/x86_64/lib
          include_dirs = /opt/fftw/3.3.0.1/x86_64/include
        EOF
      end
    end

    system "cat site.cfg"

    if build_name =~ /python3/
      system "python3 setup.py build"
      system "python3 setup.py install --prefix=#{prefix} --compile"
    else
      system_python "setup.py build"
      system_python "setup.py install --prefix=#{prefix} --compile"
    end
  end

  modulefile do
    <<-MODULEFILE
      #%Module
      proc ModulesHelp { } {
         puts stderr "<%= @package.name %> <%= @package.version %>"
         puts stderr ""
      }
      # One line description
      module-whatis "<%= @package.name %> <%= @package.version %>"

      prereq PrgEnv-gnu PE-gnu
      prereq python
      conflict python_numpy

      <%= python_module_build_list @package, @builds %>
      set PREFIX <%= @package.version_directory %>/$BUILD

      set LUSTREPREFIX #{additional_software_roots.first}/#{arch}/<%= @package.name %>/<%= @package.version %>/$BUILD

      prepend-path LD_LIBRARY_PATH $LUSTREPREFIX/lib
      prepend-path LD_LIBRARY_PATH $LUSTREPREFIX/lib64
      prepend-path PYTHONPATH      $LUSTREPREFIX/lib/$LIBDIR/site-packages
      prepend-path PYTHONPATH      $LUSTREPREFIX/lib64/$LIBDIR/site-packages

      prepend-path PATH            $PREFIX/bin
      prepend-path LD_LIBRARY_PATH $PREFIX/lib
      prepend-path LD_LIBRARY_PATH $PREFIX/lib64
      prepend-path LD_LIBRARY_PATH /opt/gcc/4.8.2/snos/lib64
      prepend-path LD_LIBRARY_PATH /ccs/compilers/gcc/rhel6-x86_64/4.8.2/lib
      prepend-path LD_LIBRARY_PATH /ccs/compilers/gcc/rhel6-x86_64/4.8.2/lib64
      prepend-path MANPATH         $PREFIX/share/man

      prepend-path PYTHONPATH      $PREFIX/lib/$LIBDIR/site-packages
      prepend-path PYTHONPATH      $PREFIX/lib64/$LIBDIR/site-packages
    MODULEFILE
  end
end
