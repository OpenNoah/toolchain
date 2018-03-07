# http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/

ARCH	?= mipsel-linux
PREFIX	?= $(PWD)/$(ARCH)
SYSROOT	:= $(PREFIX)/$(ARCH)
KERNEL	?= $(PWD)/../linux-new
KERNEL_ARCH	?= mips

GCC_DOWNLOAD	?= https://ftp.gnu.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.xz
GMP_DOWNLOAD	?= https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
MPFR_DOWNLOAD	?= http://www.mpfr.org/mpfr-current/mpfr-4.0.1.tar.xz
MPC_DOWNLOAD	?= https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz
ISL_DOWNLOAD	?= http://isl.gforge.inria.fr/isl-0.19.tar.xz
CLOOG_DOWNLOAD	?= https://www.bastoul.net/cloog/pages/download/cloog-0.18.4.tar.gz
GDB_DOWNLOAD	?= https://ftp.gnu.org/gnu/gdb/gdb-8.1.tar.xz
GLIBC_DOWNLOAD	?= https://ftp.gnu.org/gnu/glibc/glibc-2.27.tar.xz
BINUTILS_DOWNLOAD	?= https://ftp.gnu.org/gnu/binutils/binutils-2.30.tar.xz

GCC_ARCHIVE	:= $(notdir $(GCC_DOWNLOAD))
GMP_ARCHIVE	:= $(notdir $(GMP_DOWNLOAD))
MPFR_ARCHIVE	:= $(notdir $(MPFR_DOWNLOAD))
MPC_ARCHIVE	:= $(notdir $(MPC_DOWNLOAD))
ISL_ARCHIVE	:= $(notdir $(ISL_DOWNLOAD))
CLOOG_ARCHIVE	:= $(notdir $(CLOOG_DOWNLOAD))
GDB_ARCHIVE	:= $(notdir $(GDB_DOWNLOAD))
GLIBC_ARCHIVE	:= $(notdir $(GLIBC_DOWNLOAD))
BINUTILS_ARCHIVE	:= $(notdir $(BINUTILS_DOWNLOAD))

GCC_DIR	?= $(GCC_ARCHIVE:%.tar.xz=%)
GMP_DIR	?= $(GMP_ARCHIVE:%.tar.lz=%)
MPFR_DIR	?= $(MPFR_ARCHIVE:%.tar.xz=%)
MPC_DIR	?= $(MPC_ARCHIVE:%.tar.gz=%)
ISL_DIR	?= $(ISL_ARCHIVE:%.tar.xz=%)
CLOOG_DIR	?= $(CLOOG_ARCHIVE:%.tar.gz=%)
GDB_DIR	?= $(GDB_ARCHIVE:%.tar.xz=%)
GLIBC_DIR	?= $(GLIBC_ARCHIVE:%.tar.xz=%)
BINUTILS_DIR	?= $(BINUTILS_ARCHIVE:%.tar.xz=%)

TARGETS	:= gcc gdb binutils glibc
TARGETS_ALL	:= $(ARCH) $(TARGETS) gcc-first glibc-first gmp mpc mpfr isl cloog

.SECONDARY:
.DELETE_ON_ERROR:

.PHONY: all
all: $(TARGETS:%=install-%)

.PHONY: clean
clean: $(TARGETS_ALL:%=clean-%)

# Directories

$(TARGETS_ALL):
	mkdir -p $@

%/build:
	mkdir -p $@

# Common rules

.PHONY: $(TARGETS:%=build-%)
$(TARGETS:%=build-%): build-%: %/.compile

.PHONY: $(TARGETS:%=install-%)
$(TARGETS:%=install-%): install-%: %/.install

%/.extract:
	tar axf "$<" -C $*
	@touch $@

%/.compile: %/.configure
	cd $*/build; $(MAKE)
	@touch $@

%/.install: %/.compile
	cd $*/build; $(MAKE) install
	@touch $@

clean-%:
	rm -rf $*

# Target specific rules

gcc-first/.configure: gcc/.link binutils/.install | gcc-first/build
	cd $|; ../../gcc/$(GCC_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) \
		--enable-languages=c,c++ --disable-threads --disable-multilib \
		--without-headers
	@touch $@

gcc-first/.compile: %/.compile: %/.configure
	cd $*/build; $(MAKE) all-gcc
	@touch $@

gcc-first/.libgcc: %/.libgcc: glibc-first/.install %/.configure
	cd $*/build; $(MAKE) all-target-libgcc
	@touch $@

gcc-first/.install: %/.install: %/.compile
	cd $*/build; $(MAKE) install-gcc
	@touch $@

gcc-first/.libgcc-install: %/.libgcc-install: %/.libgcc
	cd $*/build; $(MAKE) install-target-libgcc
	@touch $@

gcc/.configure: glibc/.install gcc/.link binutils/.install | gcc/build
	cd $|; ../$(GCC_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) \
		--enable-languages=c,c++ --enable-threads --disable-multilib
	@touch $@

gcc/.link: gcc/.extract gmp/.extract mpfr/.extract mpc/.extract isl/.extract cloog/.extract
	ln -sfr gmp/$(GMP_DIR) gcc/$(GCC_DIR)/gmp
	ln -sfr mpfr/$(MPFR_DIR) gcc/$(GCC_DIR)/mpfr
	ln -sfr mpc/$(MPC_DIR) gcc/$(GCC_DIR)/mpc
	ln -sfr isl/$(ISL_DIR) gcc/$(GCC_DIR)/isl
	ln -sfr cloog/$(CLOOG_DIR) gcc/$(GCC_DIR)/cloog
	@touch $@

gdb/.configure: gdb/.extract gcc/.install | gdb/build
	cd $|; ../$(GDB_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) --with-sysroot=$(SYSROOT) --with-python=yes
	@touch $@

glibc-first/.configure: glibc/.extract glibc/.headers gcc-first/.install | glibc-first/build
	cd $|; PATH="$$PATH:$(PREFIX)/bin" ../../glibc/$(GLIBC_DIR)/configure \
		--host=$(ARCH) \
		--prefix=/ \
		--with-headers=$(SYSROOT)/include \
		--enable-strip --disable-multilib
	@touch $@

glibc-first/.compile: %/.compile: %/.configure
	cd $*/build; PATH="$$PATH:$(PREFIX)/bin" $(MAKE) csu/subdir_lib
	@touch $@

glibc-first/.install: %/.install: %/.compile
	cd $*/build; $(MAKE) install-bootstrap-headers=yes install-headers DESTDIR=$(SYSROOT)
	cd $*/build; install csu/crt1.o csu/crti.o csu/crtn.o $(SYSROOT)/lib
	$(PREFIX)/bin/mipsel-linux-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $(SYSROOT)/lib/libc.so
	@touch $@

glibc/.configure: glibc/.extract glibc/.headers gcc-first/.libgcc-install | glibc/build
	cd $|; PATH="$$PATH:$(PREFIX)/bin" ../../glibc/$(GLIBC_DIR)/configure \
		--host=$(ARCH) \
		--prefix=/ \
		--with-headers=$(SYSROOT)/include \
		--enable-strip --disable-multilib
	@touch $@


glibc/.compile: %/.compile: %/.configure
	cd $*/build; PATH="$$PATH:$(PREFIX)/bin" $(MAKE)
	@touch $@

glibc/.install: %/.install: %/.compile
	cd $*/build; $(MAKE) install DESTDIR=$(SYSROOT)
	@touch $@

glibc/.headers:
	cd $(KERNEL); ARCH=$(KERNEL_ARCH) $(MAKE) INSTALL_HDR_PATH=$(SYSROOT) headers_install
	@touch $@

binutils/.configure: binutils/.extract | binutils/build
	cd $|; ../$(BINUTILS_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) --with-sysroot=$(SYSROOT)
	@touch $@

# Archives

gcc/.extract: gcc/$(GCC_ARCHIVE)
%/$(GCC_ARCHIVE): | %
	wget -O "$@" "$(GCC_DOWNLOAD)"

gmp/.extract: gmp/$(GMP_ARCHIVE)
%/$(GMP_ARCHIVE): | %
	wget -O "$@" "$(GMP_DOWNLOAD)"

mpfr/.extract: mpfr/$(MPFR_ARCHIVE)
%/$(MPFR_ARCHIVE): | %
	wget -O "$@" "$(MPFR_DOWNLOAD)"

mpc/.extract: mpc/$(MPC_ARCHIVE)
%/$(MPC_ARCHIVE): | %
	wget -O "$@" "$(MPC_DOWNLOAD)"

isl/.extract: isl/$(ISL_ARCHIVE)
%/$(ISL_ARCHIVE): | %
	wget -O "$@" "$(ISL_DOWNLOAD)"

cloog/.extract: cloog/$(CLOOG_ARCHIVE)
%/$(CLOOG_ARCHIVE): | %
	wget -O "$@" "$(CLOOG_DOWNLOAD)"

gdb/.extract: gdb/$(GDB_ARCHIVE)
%/$(GDB_ARCHIVE): | %
	wget -O "$@" "$(GDB_DOWNLOAD)"

glibc/.extract: glibc/$(GLIBC_ARCHIVE)
%/$(GLIBC_ARCHIVE): | %
	wget -O "$@" "$(GLIBC_DOWNLOAD)"

binutils/.extract: binutils/$(BINUTILS_ARCHIVE)
%/$(BINUTILS_ARCHIVE): | %
	wget -O "$@" "$(BINUTILS_DOWNLOAD)"
