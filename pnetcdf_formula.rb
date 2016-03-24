class PnetcdfFormula < Formula
  homepage "http://trac.mcs.anl.gov/projects/parallel-netcdf/wiki/Download"
  #url "http://cucis.ece.northwestern.edu/projects/PnetCDF/Release/parallel-netcdf-1.4.1.tar.bz2"
  url "http://cucis.ece.northwestern.edu/projects/PnetCDF/Release/parallel-netcdf-1.6.1.tar.gz"
  sha1 "62a094eb952f9d1e15f07d56e535052604f1ac34"

 module_commands do
    commands = [ "purge" ]
    pe = "PrgEnv-" if cray_system?
    pe = "PE-" if !cray_system?
    case build_name
    when /gnu/
      commands << "load #{pe}gnu"
      commands << "swap gcc gcc/#{$1}" if build_name =~ /gnu([\d\.]+)/
    when /pgi/
      commands << "load #{pe}pgi"
      commands << "swap pgi pgi/#{$1}" if build_name =~ /pgi([\d\.]+)/
    when /intel/
      commands << "load #{pe}intel"
      commands << "swap intel intel/#{$1}" if build_name =~ /intel([\d\.]+)/
    end
    commands << "load openmpi"
    commands
  end

  def install
    module_list

    case build_name
    when /gnu/
      ENV["CC"]  = "gcc"
      ENV["CXX"] = "g++"
      ENV["F77"] = "gfortran"
      ENV["FC"]  = "gfortran"
      ENV["F9X"] = "gfortran"
    when /pgi/
      ENV["CC"]  = "pgcc"
      ENV["CXX"] = "pgCC"
      ENV["F77"] = "pgf77"
      ENV["FC"]  = "pgf90"
      ENV["F9X"]  = "pgf90"
    when /intel/
      ENV["CC"]  = "icc"
      ENV["CXX"] = "icpc"
      ENV["F77"] = "ifort"
      ENV["FC"]  = "ifort"
      ENV["F9X"]  = "ifort"
    end

    #hdf5_prefix = module_environment_variable("hdf5/1.8.11", "HDF5_DIR")
    #szip_prefix = module_environment_variable("szip/2.1", "SZIP_DIR")

    #ENV["CPPFLAGS"] = "-I#{hdf5_prefix}/include -I#{szip_prefix}/include"
    #ENV["LDFLAGS"]  = "-L#{hdf5_prefix}/lib     -L#{szip_prefix}/lib -lhdf5 -lhdf5_hl -lsz -lz -lm"

    system "echo $CPPFLAGS"
    system "echo $LDFLAGS"
    system "./configure --prefix=#{prefix}"
      #"--enable-shared",
      #"--enable-static",
      #"--enable-fortran",
      #"--enable-cxx"
    system "make clean"
    system "make"
    system "make install"
  end

  modulefile do
    <<-MODULEFILE.strip_heredoc
    #%Module

    proc ModulesHelp { } {
       puts stderr "Sets up environment to use pnetcdf <%= @package.version %>"
    }

    <% if @builds.size > 1 %>
    <%= module_build_list @package, @builds, :prgenv_prefix => #{module_is_available?("PrgEnv-gnu") ? '"PrgEnv-"' : '"PE-"'} %>

    set PREFIX <%= @package.version_directory %>/$BUILD
    <% else %>
    set PREFIX <%= @package.prefix %>
    <% end %>

    setenv PARALLEL_NETCDF_LIB   "-I${PREFIX}/include -L${PREFIX}/lib -lpnetcdf"
    setenv PARALLEL_NETCDF_DIR "${PREFIX}"
    setenv PNETCDF_LIB   "-I${PREFIX}/include -L${PREFIX}/lib -lpnetcdf"
    setenv PNETCDF_DIR "${PREFIX}"

    prepend-path PATH             $PREFIX/bin
    prepend-path LD_LIBRARY_PATH  $PREFIX/lib
    prepend-path LIBRARY_PATH     $PREFIX/lib
    prepend-path INCLUDE_PATH     $PREFIX/include
    prepend-path MANPATH          $PREFIX/share/man
    MODULEFILE
  end
end
