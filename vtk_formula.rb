class VtkFormula < Formula
  homepage "http://www.vtk.org"
  concern for_version("6.3.0") do
    included do
      url "http://www.vtk.org/files/release/6.3/VTK-6.3.0.tar.gz"
    end
  end

  concern for_version("7.0.0") do
    included do
      url "http://www.vtk.org/files/release/7.0/VTK-7.0.0.tar.gz"
    end
  end

  module_commands [
    "unload PrgEnv-pgi PrgEnv-cray PrgEnv-intel PrgEnv-gnu",
    "load PrgEnv-gnu",
    "load git",
    "load cmake",
    "load python",
    "load mesa",
    "load adios/1.9.0",
    "load cray-hdf5"
  ]

  def install
    module_list

    FileUtils.mkdir_p prefix+"/build"

    system "cmake ..",
      "-D CMAKE_INSTALL_PREFIX:STRING=#{prefix}",
      "-D CMAKE_C_COMPILER:STRING=cc",
      "-D CMAKE_CXX_COMPILER:STRING=CC",
      "-D CMAKE_Fortran_COMPILER:STRING=ftn",
      "-D QT_QMAKE_EXECUTABLE:PATH=/sw/xk6/qt4/4.8.5/sles11.3_gnu5.2.0/bin/qmake",
      "-D VTK_Group_Qt:BOOL=ON",
      "-D BUILD_SHARED_LIBS:BOOL=OFF",
      "-D VTK_RENDERING_BACKEND:STRING=OpenGL2",
      "-D VTK_OPENGL_HAS_OSMESA:BOOL=true",
      "-D VTK_USE_LARGE_DATA:BOOL=true",
      "-D VTK_USE_OFFSCREEN:BOOL=true",
      "-D Module_vtkIOADIOS:BOOL=true",
      "-D VTK_USE_X:BOOL=false",
      "-D BUILD_TESTING:BOOL=false",
      "-D CMAKE_BUILD_TYPE:STRING=Release",
      "-D VTKCompileTools_DIR=../source",
      "-D HDF5_IS_PARALLEL:BOOL=true",
      "../source"

    system "export HDF5_IS_PARALLEL=true; make -j4"
    system "make install"
  end

  modulefile do
  <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    set PREFIX <%= @package.prefix %>

    prepend-path PATH $PREFIX/bin
    prepend-path PYTHONPATH $PREFIX/lib/site-packages
    prepend-path PKG_CONFIG_PATH $PREFIX/lib/pkgconfig
  MODULEFILE
  end

end
