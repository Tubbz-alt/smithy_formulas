class MagmaFormula < Formula
  homepage "http://icl.cs.utk.edu/magma/index.html"
  url "http://icl.cs.utk.edu/projectsfiles/magma/downloads/magma-1.6.2.tar.gz"

  module_commands do
    pe = "PE-"
    pe = "PrgEnv-" if cray_system?

    commands = [ "unload #{pe}gnu #{pe}pgi #{pe}cray #{pe}intel" ]

    case build_name
    when /gnu/
      commands << "load #{pe}gnu"
      commands << "swap gcc gcc/#{$1}" if build_name =~ /gnu([\d\.]+)/
    when /intel/
      commands << "load #{pe}intel"
      commands << "swap intel intel/#{$1}" if build_name =~ /intel([\d\.]+)/
    end
    
    commands << "load cudatoolkit"
    commands << "load acml"

    commands

  end


  def install
    module_list
   
    case build_name
    when /intel/

      system "cp make.inc.mkl-icc make.inc"

      patch <<-EOF.strip_heredoc
        --- a/make.inc
        +++ b/make.inc
        @@ -16,10 +16,10 @@
         #
         #GPU_TARGET ?= Fermi Kepler
        
        -CC        = icc
        -CXX       = icpc
        +CC        = nvcc
        +CXX       = nvcc
         NVCC      = nvcc
        -FORT      = ifort
        +FORT      = ftn -fpp
        
         ARCH      = ar
         ARCHFLAGS = cr
      EOF


      # The code compiles a utility and checks for void pointer size. This
      # fails on the service node, so I checked using 'aprun' and hard-coded
      # the value.
      system "cp Makefile.internal Makefile.internal.orig"

      patch <<-EOF.strip_heredoc
        --- a/Makefile.internal
        +++ b/Makefile.internal
        @@ -162,7 +162,8 @@
         PTRFILE = $(MAGMA_DIR)/control/sizeptr.c
         PTROBJ  = $(MAGMA_DIR)/control/sizeptr.$(o_ext)
         PTREXEC = $(MAGMA_DIR)/control/sizeptr
        -PTRSIZE = $(shell $(PTREXEC))
        +#PTRSIZE = $(shell $(PTREXEC))
        +PTRSIZE = 8
         PTROPT  = -Dmagma_devptr_t="integer(kind=$(PTRSIZE))"

         $(PTREXEC): $(PTROBJ)
      EOF

      system "export LD_LIBRARY_PATH=/sw/redhat6/acml/5.3.0/gfortran64/lib/ && export CUDADIR=$CRAY_CUDATOOLKIT_DIR && make -k"
    when /gnu/
      patch <<-EOF.strip_heredoc
        diff --git a/make.inc b/make.inc
        new file mode 100644
        index 0000000..8b8cd6a
        --- /dev/null
        +++ b/make.inc
        @@ -0,0 +1,16 @@
        +GPU_TARGET = Kepler
        +CC        = gcc -DCUBLAS_GFORTRAN -lcublas
        +CXX       = g++ -DCUBLAS_GFORTRAN -lcublas
        +NVCC      = nvcc -Xcompiler -fPIC
        +FORT      = mpifort -DCUBLAS_GFORTRAN
        +ARCH      = ar
        +ARCHFLAGS = cr
        +RANLIB    = ranlib
        +OPTS      = -O3 -DADD_ -fPIC
        +F77OPTS   = -O3 -DADD_ -fno-second-underscore -fPIC
        +FOPTS     = -O3 -DADD_ -fno-second-underscore -fPIC
        +NVOPTS    = -O3 -DADD_ --compiler-options -fno-strict-aliasing -DUNIX
        +LDOPTS    = -fPIC -Xlinker -zmuldefs -L$(CUDATOOLKIT_HOME)/lib64 -L$(CUDATOOLKIT_HOME)/extras/CUPTI/lib64 -Wl,--as-needed -Wl,-lcupti -Wl,-lcudart -Wl,--no-as-needed -L$(CUDATOOLKIT_HOME)/lib64 -lcuda
        +LIB       =  -lpthread -lcublas -lm -lcupti -lcudart
        +CUDADIR   = $(CUDATOOLKIT_HOME)
        +INC       = -I$(CUDATOOLKIT_HOME)/include
      EOF

      patch <<-EOF.strip_heredoc
        diff --git a/Makefile b/Makefile
        index a021ec6..01f3ceb 100644
        --- a/Makefile
        +++ b/Makefile
        @@ -53,24 +53,12 @@ libquark:
                ( cd quark          && $(MAKE) )
                @echo
        
        -lapacktest:
        -       @echo ======================================== lapacktest
        -       ( cd testing/matgen && $(MAKE) )
        -       ( cd testing/lin    && $(MAKE) )
        -       @echo
        -
        -test: lib
        -       @echo ======================================== testing
        -       ( cd testing        && $(MAKE) )
        -       @echo
        
         clean:
                ( cd magmablas      && $(MAKE) clean )
                ( cd src            && $(MAKE) clean )
                ( cd control        && $(MAKE) clean )
                ( cd interface_cuda && $(MAKE) clean )
        -       ( cd testing        && $(MAKE) clean )
        -       ( cd testing/lin    && $(MAKE) clean )
                ( cd sparse-iter    && $(MAKE) clean )
                #(cd quark          && $(MAKE) clean )
                -rm -f $(LIBMAGMA) $(LIBMAGMA_SO)
        @@ -81,8 +69,6 @@ cleanall:
                ( cd src            && $(MAKE) cleanall )
                ( cd control        && $(MAKE) cleanall )
                ( cd interface_cuda && $(MAKE) cleanall )
        -       ( cd testing        && $(MAKE) cleanall )
        -       ( cd testing/lin    && $(MAKE) cleanall )
                ( cd sparse-iter    && $(MAKE) cleanall )
                ( cd lib            && rm -f *.a *.so )
                #(cd quark          && $(MAKE) cleanall )
      EOF

      system "export LD_LIBRARY_PATH=/sw/redhat6/acml/5.3.0/gfortran64/lib/:$LD_LIBRARY_PATH && make"
    end

    system "cd #{prefix} && cp -rv source/include source/lib ./"

  end

  modulefile <<-modulefile.strip_heredoc
    #%Module
    proc moduleshelp { } {
       puts stderr "<%= @package.name %> <%= @package.version %>"
       puts stderr ""
    }
    # One line description
    module-whatis "<%= @package.name %> <%= @package.version %>"

    prereq cudatoolkit

    if [ is-loaded PrgEnv-gnu ] {
      set BUILD sles11.3_gnu4.8.2 
    } elseif [ is-loaded PrgEnv-intel ] {
      set BUILD sles11.3_intel14.0.2.144
    } 
    
    if {![info exists BUILD]} {
      puts stderr "[module-info name] is only available for the following environments:"
      puts stderr "sles11.3_gnu4.8.2"
      puts stderr "sles11.3_intel14.0.2.144"
      break
    }

    set PREFIX <%= @package.version_directory %>/$BUILD

    prepend-path LD_LIBRARY_PATH  $PREFIX/lib
    prepend-path LIBRARY_PATH     $PREFIX/lib
    prepend-path INCLUDE_PATH     $PREFIX/include

    set MAGMALIB "-L$PREFIX/lib -lmagma -lmagmablas -lcublas"
    prepend-path MAGMA_LIB $MAGMALIB
    set MAGMAINC "-I$PREFIX/include"
    prepend-path MAGMA_INC $MAGMAINC

    setenv       MAGMA_POST_COMPILE_OPTS $MAGMAINC
    setenv       MAGMA_POST_LINK_OPTS    $MAGMALIB
    append-path  PE_PRODUCT_LIST         MAGMA
  modulefile
end
