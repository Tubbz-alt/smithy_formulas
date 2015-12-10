class LammpsFormula < Formula
  homepage "http://lammps.sandia.gov/"
  url "none"

  # Recent Changes Page: http://lammps.sandia.gov/bug.html
  # See https://github.com/lammps/lammps/commits/master for svn version numbers
  concern for_version("15May2015_reaxc") do
    included do
      params svn_url: "svn://svn.icms.temple.edu/lammps-ro/trunk@13475"
    end
  end

  concern for_version("15May2015") do
    included do
      params svn_url: "svn://svn.icms.temple.edu/lammps-ro/trunk@13475"
    end
  end

  concern for_version("30Apr2015") do
    included do
      params svn_url: "svn://svn.icms.temple.edu/lammps-ro/trunk@13450"
    end
  end

  concern for_version("06Mar2015") do
    #Release date: 6 Mar 2015
    included do
      params svn_url: "svn://svn.icms.temple.edu/lammps-ro/trunk@13216"
    end
  end

  concern for_version("20Jan2015") do
    #Release date: 20 Jan 2015
    included do
       params svn_url: "svn://svn.icms.temple.edu/lammps-ro/trunk@12958"

    end
  end

  concern for_version("10Feb15") do
    # 10 Feb 2015 = stable version, SVN rev = 13095
    included do
      params svn_url: "svn://svn.lammps.org/lammps-ro/trunk@13095"
    end
  end

  concern for_version("15May15") do
    # Patched version
    # See ticket https://rt.ccs.ornl.gov/Ticket/Display.html?id=254892
    included do
      params svn_url "svn://svn.lammps.org/lammps-ro/trunk@13475"
    end
  end

  module_commands do
    pe = "PE-"
    pe = "PrgEnv-" if module_is_available?("PrgEnv-gnu")

    commands = [ "unload #{pe}gnu #{pe}pgi #{pe}cray #{pe}intel" ]
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
    when /cray/
      commands << "load #{pe}cray"
      commands << "swap cce cce/#{$1}" if build_name =~ /cray([\d\.]+)/
    end

    commands << "load subversion"
    commands << "load fftw"
    commands << "load cudatoolkit" if module_is_available?("cudatoolkit")
    commands
  end

  def install
    module_list
    system "svn co #{svn_url} source" unless Dir.exists?("source")
    Dir.chdir prefix+"/source"

    # Special case for reaxc build/RT268132
    if version =~ /15May2015_reaxc/
      system "svn revert lib/reax/reax_defs.h"
      patch <<-EOF.strip_heredoc
        --- a/lib/reax/reax_defs.h
        +++ b/lib/reax/reax_defs.h
        @@ -44,7 +44,7 @@
         #define NATDEF 40000
         #define NATTOTDEF 39744
         #define NSORTDEF 20
        -#define MBONDDEF 20
        +#define MBONDDEF 40
         #define NAVIBDEF 50
         #define NBOTYMDEF 200
         #define NVATYMDEF 200
      EOF
    end

    # The executable should be named lmp_${target_arch} on each machine.
    target_arch="exe"
    case arch
    when /xk7/, /xk6/
      target_arch="titan"
    when /xc30/
      target_arch="eos"
    end

    system "svn revert src/MAKE/MACHINES/Makefile.jaguar"
    system "cp src/MAKE/MACHINES/Makefile.jaguar src/MAKE/MACHINES/Makefile.#{target_arch}"
    system "sed 's/\\(CCFLAGS.*\\=.*\\)/\\1 -craype-verbose -O2 -march=bdver1 -ftree-vectorize/' src/MAKE/MACHINES/Makefile.jaguar > src/MAKE/MACHINES/Makefile.#{target_arch}"
    system "sed -i 's/\\(LINKFLAGS.*\\=.*\\)/\\1 -O2 -march=bdver1 -ftree-vectorize/' src/MAKE/MACHINES/Makefile.#{target_arch}"

    # No GPUS on xc30: This segment does not make sense for eos, though compiler
    # wrappers appear to handle build correctly anyway.
    Dir.chdir prefix + "/source/lib/gpu"
    system "make -j8 -f Makefile.xk7 clean"
    system "make -j8 -f Makefile.xk7"
    
    Dir.chdir prefix + "/source/lib/reax"
    system "sed 's/ gfortran/ftn/g' Makefile.gfortran > Makefile.cray"
    system "make -f Makefile.cray clean"
    system "make -f Makefile.cray"

    Dir.chdir prefix + "/source/lib/meam"
    system "sed 's/ gfortran/ftn/g' Makefile.gfortran > Makefile.cray"
    system "make -f Makefile.cray clean"
    system "make -f Makefile.cray"

    Dir.chdir prefix + "/source/src"
    system "make no-all clean-all"
    system "make yes-std no-kim yes-meam no-poems yes-reax no-kokkos no-voronoi yes-gpu yes-kspace yes-molecule yes-rigid yes-colloid yes-manybody yes-misc yes-user-reaxc"
    system "make -j8 #{target_arch}"

    system "mkdir -p #{prefix}/bin"
    system "cp #{prefix}/source/src/lmp_* #{prefix}/bin/"
  end

  modulefile <<-EOF.strip_heredoc
    #%Module
    proc ModulesHelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    module-whatis "<%= @package.name %> <%= @package.version %>"

    prereq PrgEnv-gnu
    prereq fftw

    set PREFIX <%= @package.prefix %>

    prepend-path PATH            $PREFIX/bin
  EOF
end
