class ParmetisFormula < Formula
  homepage "http://glaros.dtc.umn.edu/"
  url "http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/OLD/parmetis-4.0.2.tar.gz"

  depends_on [ "cmake" ]

  module_commands do
    commands = [ "purge" ]
    commands << "load cmake"
    pe = "PrgEnv-" if cray_system?
    pe = "PE-" if !cray_system?
    case build_name
    when /gnu/
      commands << "load #{pe}gnu"
    when /pgi/
      commands << "load #{pe}pgi"
    when /cray/
      commands << "load #{pe}cray"
    when /intel/
      commands << "load #{pe}intel"
    end
    commands
  end

  def install
    module_list
    module_commands
    ENV["CRAY_CPU_TARGET"] = "interlagos"
    ENV["XTPE_LINK_TYPE"] = "dynamic"
    patch <<-EOF.strip_heredoc
    --- a/metis/include/metis.h
    +++ b/metis/include/metis_new.h
    @@ -30,7 +30,7 @@
      GCC does provides these definitions in stdint.h, but it may require some
      modifications on other architectures.
     --------------------------------------------------------------------------*/
    -#define IDXTYPEWIDTH 32
    +#define IDXTYPEWIDTH 64
    
    
     /*--------------------------------------------------------------------------
    @@ -40,7 +40,7 @@
        32 : single precission floating point (float)
        64 : double precission floating point (double)
     --------------------------------------------------------------------------*/
    -#define REALTYPEWIDTH 32
    +#define REALTYPEWIDTH 64
    EOF
    patch <<-EOF.strip_heredoc
      --- a/CMakeLists.txt
      +++ b/CMakeLists_new.txt
      @@ -1,4 +1,5 @@
       cmake_minimum_required(VERSION 2.8)
      +SET(CMAKE_SYSTEM_NAME Catamount)
       project(ParMETIS)
      
       set(GKLIB_PATH METIS/GKlib CACHE PATH "path to GKlib")
    EOF
    system "make config cc=cc cxx=CC prefix=#{prefix}"
    system "make"
    system "make install"
  end

  modulefile do
    <<-MODULEFILE
      #%Module
      proc ModulesHelp { } {
         puts stderr "Sets up environment to use Parmetis with any compiler."
         puts stderr "Usage:   ftn test.f90 \${PARMETIS_LIB} "
         puts stderr "    or   cc test.c \${PARMETIS_LIB}"
         puts stderr "The parmetis module must be reloaded if you change the PrgEnv"
         puts stderr "   or you must issue a 'module update' command."
      }
      module-whatis "Sets up environment to use parmetis with any compiler."
      
      if [ is-loaded PrgEnv-gnu ] {
        set BUILD cle4.0_gnu4.6.2
      } elseif [ is-loaded PrgEnv-pgi ] {
        set BUILD cle4.0_pgi12.1.0
      } elseif [ is-loaded PrgEnv-intel ] {
        set BUILD cle4.0_intel12.1.1.256
      } elseif [ is-loaded PrgEnv-cray ] {
        set BUILD cle4.0_cray8.0.1
      } elseif [ is-loaded PrgEnv-pathscale ] {
        puts stderr "Not implemented for the pathscale compiler"
      }
      if {![info exists BUILD]} {
        puts stderr "[module-info name] is only available for the following environments:"
        puts stderr "cle5.2up04_cray"
        puts stderr "cle5.2up04_gnu"
        puts stderr "cle5.2up04_intel"
        puts stderr "cle5.2up04_pgi"
        break
      }
      
      set PREFIX /sw/xk6/parmetis/4.0.2/$BUILD
      
      set PARMETIS_INCLUDE_PATH "-I$PREFIX"
      set PARMETIS_LD_OPTS "-L$PREFIX/lib -lparmetis -lmetis"
      setenv PARMETIS_LIB "$PARMETIS_INCLUDE_PATH $PARMETIS_LD_OPTS"
      setenv PARMETIS_DIR "$PREFIX"
      
      
      if { [lsearch -nocase {load display switch switch1 switch2 switch3} [module-info mode]] != -1 } {
      #  system /ccs/sw/sources/module-retire/bin/retiring-msg -p parmetis -v 4.0.2
      } 
      MODULEFILE
  end
end
