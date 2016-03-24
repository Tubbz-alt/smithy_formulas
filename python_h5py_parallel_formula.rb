class PythonH5pyParallelFormula < Formula
  homepage "http://www.h5py.org/"
  url "https://pypi.python.org/packages/source/h/h5py/h5py-2.4.0.tar.gz"
  md5 "80c9a94ae31f84885cc2ebe1323d6758"

  supported_build_names /python.*_hdf5-parallel.*/

  params hdf5_module_name: cray_system? ? "cray-hdf5" : "hdf5-parallel"

  concern for_version("2.5.0") do
    included do
      url "https://pypi.python.org/packages/source/h/h5py/h5py-2.5.0.tar.gz"
      md5 "6e4301b5ad5da0d51b0a1e5ac19e3b74"
    end
  end

  concern for_version("2.2.0") do
    included do
      url "http://h5py.googlecode.com/files/h5py-2.2.0.tar.gz"
      sha1 "65e5d6cc83d9c1cb562265a77a46def22e9e6593"
    end
  end

  depends_on do
    [ python_module_from_build_name,
      "python_numpy/*" ]
  end

  module_commands do
    pe = "PE-"
    pe = "PrgEnv-" if module_is_available?("PrgEnv-gnu")

    commands = [ "unload #{pe}gnu #{pe}pgi #{pe}cray #{pe}intel" ]

    commands << "load #{pe}gnu"
    commands << "swap gcc gcc/#{$1}" if build_name =~ /gnu([\d\.]+)/

    commands << "unload python"
    commands << "load #{python_module_from_build_name}"
    commands << "load python_numpy"
    commands << "load python_cython"
    commands << "load python_mpi4py"
    commands << "load szip"

    commands << "load #{hdf5_module_name}"
    commands << "swap #{hdf5_module_name} #{hdf5_module_name}/#{$1}" if build_name =~ /hdf5([\d\.]+)/
    commands
  end

  def install
    module_list

    hdf5_prefix = module_environment_variable(hdf5_module_name, "HDF5_DIR")

    ENV["CPPFLAGS"] = "-I#{hdf5_prefix}/include"
    ENV["LDFLAGS"]  = "-L#{hdf5_prefix}/lib"
    ENV["cc"] = "mpicc" if !cray_system?
    ENV["CC"] = "mpiCC" if !cray_system?

    system_python "setup.py configure --mpi"
    system_python "setup.py install --prefix=#{prefix} --compile"
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

    prereq python
    module load #{hdf5_module_name}
    prereq #{hdf5_module_name}
    module load python_numpy
    prereq python_numpy

    <%= python_module_build_list @package, @builds %>
    set PREFIX <%= @package.version_directory %>/$BUILD

    prepend-path PYTHONPATH      $PREFIX/lib/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $PREFIX/lib64/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $LUSTREPREFIX/lib/$LIBDIR/site-packages
    prepend-path PYTHONPATH      $LUSTREPREFIX/lib64/$LIBDIR/site-packages

    prepend-path PATH            $PREFIX/bin
    prepend-path LD_LIBRARY_PATH $PREFIX/lib
    prepend-path LD_LIBRARY_PATH $PREFIX/lib64
    prepend-path LD_LIBRARY_PATH $LUSTREPREFIX/lib
    prepend-path LD_LIBRARY_PATH $LUSTREPREFIX/lib64
    prepend-path MANPATH         $PREFIX/share/man
    MODULEFILE
  end
end
