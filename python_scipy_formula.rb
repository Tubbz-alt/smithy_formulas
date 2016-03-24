class PythonScipyFormula < Formula
  # Testing numpy:
  # module load python python_nose python_numpy python_scipy
  # python -c 'import nose, numpy, scipy; scipy.test()'

  homepage "http://www.scipy.org"
  url "http://downloads.sourceforge.net/project/scipy/scipy/0.15.1/scipy-0.15.1.tar.gz"
  additional_software_roots [ config_value("lustre-software-root")[hostname] ]

  supported_build_names "python2.7.3", "python2.7.5", "python3"

  params acml: false 
  params open_blas: false
  params mkl: false

  depends_on do
    case build_name
    when /acml/
      acml = true
      [ python_module_from_build_name, "python_numpy/1.9.2/*#{python_version_from_build_name}*", "cblas/20110120/*acml*" ]
    when /.*mkl.*/
      mkl = true
      [ python_module_from_build_name,"python_numpy/1.9.2/*#{python_version_from_build_name}*" ]
    when /openblas/
      open_blas = true
      [ python_module_from_build_name, "python_numpy/1.9.2/*#{python_version_from_build_name}*" ]
    end
  end

  module_commands do
    pe = "PE-"
    pe = "PrgEnv-" if cray_system?

    commands = [ "unload #{pe}gnu #{pe}pgi #{pe}cray #{pe}intel cray-libsci" ]
    commands << "load #{pe}gnu"
    commands << "swap gcc gcc/#{$1}" if build_name =~ /gnu([\d\.]+)/
    if acml == true
      commands << "load acml"
    elsif mkl == true
      commands << "load mkl"
    elsif open_blas == true
      commands << "load openblas"
    end

    commands << "unload python"
    commands << "load #{python_module_from_build_name}"
    commands << "load python_numpy/1.9.2"
    commands
  end

  concern for_version("0.13.0") do
    included do
      depends_on do
        [ python_module_from_build_name, "python_numpy/1.8.0/#{python_version_from_build_name}*" ]
      end

      module_commands do
        [ "unload python", "load #{python_module_from_build_name}", "load python_numpy/1.8.0" ]
      end
    end
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
    elsif open_blas == true
      ml_prefix = module_envionment_variable("openblas/dynamic/0.2.6", "BLASDIR");
      FileUtils.cp "#{ml_prefix}/libopenblasp-r0.2.6.a",   "#{prefix}/lib", verbose: true
      FileUtils.cp "#{ml_prefix}/libopenblasp-r0.2.6.so",  "#{prefix}/lib", verbose: true
      FileUtils.cp "#{ml_prefix}/libopenblas.so.0",  "#{prefix}/lib", verbose: true
    end
    if acml == true
      ml_prefix = module_environment_variable("acml", "ACML_BASE_DIR")
      ml_prefix += "/gfortran64"
    elsif open_blas == true
      ml_prefix = module_environment_variable("openblas/dynamic/0.2.6", "BLASDIR")
      ml_prefix += "/libopenblasp-r0.2.6.so"
    end

    ENV['CC']  = 'cc'
    ENV['CXX'] = 'CC'
    ENV['OPT'] = '-O3 -funroll-all-loops'

    inc_dirs = ""
    if acml == true
      inc_dirs = "#{cblas.prefix}/include"
    elsif open_blas == true
      inc_dirs = "#{ml_prefix}/include"
    end

      File.open("site.cfg", "w+") do |f|
        f.write <<-EOF.strip_heredoc
        [mkl]
        library_dirs = /opt/intel/composer_xe_2015.2.164/mkl/lib/intel64
        include_dirs = /opt/intel/composer_xe_2015.2.164/mkl/include
        lapack_libs = mkl_gf_lp64,mkl_sequential,mkl_core
        mkl_libs = mkl_gf_lp64,mkl_sequential,mkl_core,mkl_def, mkl_avx
        EOF
      end
    Dir.chdir "#{prefix}/source"
    system_python "setup.py config build_clib  build_ext  install --prefix=#{prefix}"
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
    conflict python_scipy
    prereq python_numpy
    prereq PrgEnv-gnu PE-gnu

    <%= python_module_build_list @package, @builds %>
    set PREFIX <%= @package.version_directory %>/$BUILD

    set LUSTREPREFIX #{additional_software_roots.first}/#{arch}/<%= @package.name %>/<%= @package.version %>/$BUILD

    prepend-path PYTHONPATH      $LUSTREPREFIX/lib/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $LUSTREPREFIX/lib64/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $PREFIX/lib/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $PREFIX/lib64/$LIBDIR/site-packages
  MODULEFILE
end

