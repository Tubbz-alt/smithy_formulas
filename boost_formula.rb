class BoostFormula < Formula
  homepage "http://www.boost.org/"

  concern for_version("1.49.0") do
    included do
      url "http://sourceforge.net/projects/boost/files/boost/1.49.0/boost_1_49_0.tar.bz2"
    end
  end
  
  concern for_version("1.57.0") do
    included do
      url "http://sourceforge.net/projects/boost/files/boost/1.57.0/boost_1_57_0.tar.bz2"
    end
  end

  concern for_version("1.58.0") do
    included do
      url "http://hivelocity.dl.sourceforge.net/project/boost/boost/1.58.0/boost_1_58_0.tar.bz2"
      sha1 "2fc96c1651ac6fe9859b678b165bd78dc211e881"
    end
  end

  concern for_version("1.55.0") do
    included do
      url "http://softlayer-ams.dl.sourceforge.net/project/boost/boost/1.55.0/boost_1_55_0.tar.bz2"
      sha1 "cef9a0cc7084b1d639e06cd3bc34e4251524c840"
    end
  end

  concern for_version("1.54.0") do
    included do
      url "http://downloads.sourceforge.net/project/boost/boost/1.54.0/boost_1_54_0.tar.bz2"
      sha256 "047e927de336af106a24bceba30069980c191529fd76b8dff8eb9a328b48ae1d"
    end
  end

  concern for_version("1.53.0") do
    included do
      url "http://downloads.sourceforge.net/project/boost/boost/1.53.0/boost_1_53_0.tar.bz2"
      sha1 "e6dd1b62ceed0a51add3dda6f3fc3ce0f636a7f3"
    end
  end

  concern for_version("1.60.0") do
    included do
      url "http://downloads.sourceforge.net/project/boost/boost/1.60.0/boost_1_60_0.tar.bz2"
      sha1 "7f56ab507d3258610391b47fef6b11635861175a"
    end
  end

  


  depends_on do
    case build_name
    when /python27/
      [ "bzip2", "python/2.7.9" ]
    when /python343/
      [ "bzip2", "python/3.4.3" ]
    else
      [ "bzip2"]
    end
  end 

  module_commands do
    m = [ "unload PrgEnv-gnu PrgEnv-pgi PrgEnv-cray PrgEnv-intel" ]
    case build_name
    when /gnu/
      m << "load PrgEnv-gnu"
    when /pgi/
      m << "load PrgEnv-pgi"
    when /intel/
      m << "load PrgEnv-intel"
    when /cray/
      m << "load PrgEnv-cray"
    when /python27/
      m << "load python/2.7.9"
    when /python343/
      m << "load python/3.4.3"
    end
    m
  end

  def install
    module_list

    case build_name
    when /gnu/
      toolset="gcc"

      File.open("tools/build/site-config.jam", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          import os ;
          local CRAY_MPICH2_DIR = [ os.environ CRAY_MPICH2_DIR ] ;
          using gcc
            : 4.8.1
            : CC
            : <compileflags>-I#{bzip2.prefix}/include
              <compileflags>-I$(CRAY_MPICH2_DIR)/include
              <linkflags>-L$(CRAY_MPICH2_DIR)/lib
          ;
          using mpi
            : CC
            : <find-shared-library>mpich
            : aprun -n
          ;
        EOF
      end

    when /pgi/
      toolset="pgi"

      File.open("tools/build/site-config.jam", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          import os ;
          local CRAY_MPICH2_DIR = [ os.environ CRAY_MPICH2_DIR ] ;
          using pgi
            : 13.7.0
            : pgCC
            : <compileflags>-I#{bzip2.prefix}/include
              <compileflags>-I$(CRAY_MPICH2_DIR)/include
              <linkflags>-L$(CRAY_MPICH2_DIR)/lib
              <compileflags>-mp
          ;
          using mpi
            : CC
            : <find-shared-library>mpichcxx_pgi
            : aprun -n
          ;
        EOF
      end

    when /intel/
      toolset="intel-linux"

      File.open("tools/build/site-config.jam", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          import os ;
          local CRAY_MPICH2_DIR = [ os.environ CRAY_MPICH2_DIR ] ;
          using intel-linux
            : 13.1.3.192
            : icpc
            : <compileflags>-I#{bzip2.prefix}/include
              <compileflags>-I$(CRAY_MPICH2_DIR)/include
              <linkflags>-L$(CRAY_MPICH2_DIR)/lib
          ;
          using mpi
            : CC
            : <find-shared-library>mpichcxx_intel
            : aprun -n
          ;
        EOF
      end

    when /cray/
      toolset="gcc"
      File.open("tools/build/site-config.jam", "w+") do |f|
        f.write <<-EOF.strip_heredoc
          import os ;
          local CRAY_MPICH2_DIR = [ os.environ CRAY_MPICH2_DIR ] ;
          using cray
            : 8.3.4
            : CC
            : <compileflags>-I#{bzip2.prefix}/include
              <compileflags>-I$(CRAY_MPICH2_DIR)/include
              <linkflags>-L$(CRAY_MPICH2_DIR)/lib
          ;
          using mpi
            : CC
            : <find-shared-library>mpichcxx_cray
            : aprun -n
          ;
        EOF
      end
    end

    py_ver = nil
    python = nil
    python_prefix = "/sw/#{arch}/python/3.4.3/sles11.3_gnu4.3.4"      #THIS IS BAD
    #lib_path = ENV["LD_LIBRARY_PATH"]
    #inc_path = nil

    

    if build_name.include?("shared")
      if build_name.include?("python27")
        py_ver = "2.7"
        python = "python"
      elsif build_name.include?("python343")
        py_ver = "3.4"
        python = "python3"
      end
      system "./bootstrap.sh --prefix=\"#{prefix}\" --with-python=\"#{python}\"  --with-python-root=\"#{prefix} : #{python_prefix}/include/python#{py_ver}m #{python_prefix}/include/python#{py_ver}\""
      if build_name.include?("intel")
        # remove redundant using intel-linux definition that bootstrap.sh spits
        # out in the project-config.jam
        contents = File.read("project-config.jam").gsub(/if ! intel-linux in \[ feature.values <toolset> \].*{.*using intel-linux ;.*}/m, '')
        File.open("project-config.jam", "w+") do |f|
          f.write contents
        end
      end
      if build_name.include?("cray")
        toolset="cray" 
      end
     system "./b2 -q  --ignore-site-config  variant=release  debug-symbols=off  threading=multi  runtime-link=shared  link=shared,static  toolset=gcc  python=\"#{py_ver}\" include=\"#{python_prefix}/include/python#{py_ver}m\" --layout=system  install"
     #system "./b2 -q  --ignore-site-config  variant=release  debug-symbols=off  threading=multi  runtime-link=shared  link=shared  toolset=gcc  python=\"#{py_ver}\" include=\"#{inc_path}\" linkflags=\"-L#{lib_path}\" --layout=system  install"
    else
      system "./bootstrap.sh --with-toolset=#{toolset} --prefix=#{prefix}"
      if build_name.include?("intel")
        # remove redundant using intel-linux definition that bootstrap.sh spits
        # out in the project-config.jam
        contents = File.read("project-config.jam").gsub(/if ! intel-linux in \[ feature.values <toolset> \].*{.*using intel-linux ;.*}/m, '')
        File.open("project-config.jam", "w+") do |f|
          f.write contents
        end
      end
      if build_name.include?("cray")
        toolset="cray" 
      end
      system "./b2 toolset=#{toolset} link=static --debug-configuration install"
    end
  end

  modulefile <<-MODULEFILE.strip_heredoc
    #%Module
    proc ModulesHelp { } {
      puts stderr "<%= @package.name %> <%= @package.version %>"
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    <% if @builds.size > 1 %>
    <%= module_build_list @package, @builds %>

    set PREFIX <%= @package.version_directory %>/$BUILD
    <% else %>
    set PREFIX <%= @package.prefix %>
    <% end %>

    conflict boost

    setenv BOOST_ROOT $PREFIX
    setenv BOOST_DIR   $PREFIX
    set    BOOST_LIB   "-L$PREFIX/lib"
    set    BOOST_INC   "-I$PREFIX/include"
    set    BOOST_LIBS  "-lboost_date_time -lboost_filesystem -lboost_graph -lboost_graph_parallel -lboost_iostreams -lboost_math_c99 -lboost_math_c99f -lboost_math_c99l -lboost_math_tr1 -lboost_math_tr1f -lboost_math_tr1l -lboost_mpi -lboost_prg_exec_monitor -lboost_program_options -lboost_python -lboost_regex -lboost_serialization -lboost_signals -lboost_system -lboost_test_exec_monitor -lboost_thread -lboost_unit_test_framework -lboost_wave -lboost_wserialization"

    setenv BOOST_LIB   $BOOST_LIB
    setenv BOOST_INC   $BOOST_INC
    setenv BOOST_FLAGS "$BOOST_INC $BOOST_LIB"
    setenv BOOST_CLIB  "$BOOST_INC $BOOST_LIB $BOOST_LIBS"

    prepend-path LD_LIBRARY_PATH $PREFIX/lib
  MODULEFILE
end
