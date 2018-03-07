ARCH	?= mipsel-linux
PREFIX	?= $(PWD)/$(ARCH)
SYSROOT	:= $(PREFIX)/$(ARCH)
KERNEL	?= $(PWD)/../linux-new
KERNEL_ARCH	?= mips

GCC_DOWNLOAD	?= ftp://ftp.gnu.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.xz
GMP_DOWNLOAD	?= https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
MPFR_DOWNLOAD	?= http://www.mpfr.org/mpfr-current/mpfr-4.0.1.tar.xz
MPC_DOWNLOAD	?= https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz
GDB_DOWNLOAD	?= ftp://ftp.gnu.org/gnu/gdb/gdb-8.1.tar.xz
GLIBC_DOWNLOAD	?= ftp://ftp.gnu.org/gnu/glibc/glibc-2.27.tar.xz
BINUTILS_DOWNLOAD	?= ftp://ftp.gnu.org/gnu/binutils/binutils-2.30.tar.xz

GCC_ARCHIVE	:= $(notdir $(GCC_DOWNLOAD))
GMP_ARCHIVE	:= $(notdir $(GMP_DOWNLOAD))
MPFR_ARCHIVE	:= $(notdir $(MPFR_DOWNLOAD))
MPC_ARCHIVE	:= $(notdir $(MPC_DOWNLOAD))
GDB_ARCHIVE	:= $(notdir $(GDB_DOWNLOAD))
GLIBC_ARCHIVE	:= $(notdir $(GLIBC_DOWNLOAD))
BINUTILS_ARCHIVE	:= $(notdir $(BINUTILS_DOWNLOAD))

GCC_DIR	?= $(GCC_ARCHIVE:%.tar.xz=%)
GMP_DIR	?= $(GMP_ARCHIVE:%.tar.lz=%)
MPFR_DIR	?= $(MPFR_ARCHIVE:%.tar.xz=%)
MPC_DIR	?= $(MPC_ARCHIVE:%.tar.gz=%)
GDB_DIR	?= $(GDB_ARCHIVE:%.tar.xz=%)
GLIBC_DIR	?= $(GLIBC_ARCHIVE:%.tar.xz=%)
BINUTILS_DIR	?= $(BINUTILS_ARCHIVE:%.tar.xz=%)

TARGETS	:= gcc gdb binutils glibc
TARGETS_ALL	:= $(TARGETS) gmp mpc mpfr

.SECONDARY:
.DELETE_ON_ERROR:

.PHONY: all
all: $(TARGETS:%=install-%)

.PHONY: clean
clean: $(TARGETS_ALL:%=clean-%) clean-$(ARCH) clean-include

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

%/.install: %/.compile | root
	cd $*/build; $(MAKE) install
	@touch $@

clean-%:
	rm -rf $*

# Target specific rules

gcc-first/.configure: gcc/.link binutils/.install | gcc-first/build
	cd $|; ../../gcc/$(GCC_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) \
		--enable-languages=c,c++ --enable-threads --disable-multilib
	@touch $@

gcc-first/.compile: %/.compile: %/.configure
	cd $*/build; $(MAKE) all-gcc
	@touch $@

gcc-first/.install: %/.install: %/.compile | root
	cd $*/build; $(MAKE) install-gcc
	@touch $@

gcc/.configure: glibc/.install gcc/.link binutils/.install | gcc/build
	cd $|; ../$(GCC_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) \
		--enable-languages=c,c++ --enable-threads --disable-multilib
	@touch $@

gcc/.link: gcc/.extract gmp/.extract mpfr/.extract mpc/.extract
	ln -sfr gmp/$(GMP_DIR) gcc/$(GCC_DIR)/gmp
	ln -sfr mpfr/$(MPFR_DIR) gcc/$(GCC_DIR)/mpfr
	ln -sfr mpc/$(MPC_DIR) gcc/$(GCC_DIR)/mpc
	@touch $@

gdb/.configure: gdb/.extract gcc/.install | gdb/build
	cd $|; ../$(GDB_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) --with-sysroot=$(SYSROOT) --with-python=yes
	@touch $@

glibc/.configure: glibc/.extract glibc/.headers gcc-first/.install | glibc/build
	cd $|; PATH="$$PATH:$(PREFIX)/bin" ../$(GLIBC_DIR)/configure \
		--host=$(ARCH) \
		--prefix=$(SYSROOT) \
		--with-sysroot=$(SYSROOT) --with-headers=$(PWD)/include \
		--enable-strip
	@touch $@

glibc/.compile: %/.compile: %/.configure
	cd $*/build; PATH="$$PATH:$(PREFIX)/bin" $(MAKE)
	@touch $@

glibc/.headers:
	cd $(KERNEL); ARCH=$(KERNEL_ARCH) $(MAKE) INSTALL_HDR_PATH=$(PWD) headers_install
	@touch $@

binutils/.configure: binutils/.extract | binutils/build
	cd $|; ../$(BINUTILS_DIR)/configure --target=$(ARCH) \
		--prefix=$(PREFIX) --with-sysroot=$(SYSROOT)
	@touch $@

# Archives

gcc/.extract: gcc/$(GCC_ARCHIVE)
%/$(GCC_ARCHIVE): | %
	wget -O "$@" "$(GCC_DOWNLOAD)"

gmp/.extract: gmp/GMP_ARCHIVE)
%/$(GMP_ARCHIVE): | %
	wget -O "$@" "$(GMP_DOWNLOAD)"

mpfr/.extract: mpfr/$(MPFR_ARCHIVE)
%/$(MPFR_ARCHIVE): | %
	wget -O "$@" "$(MPFR_DOWNLOAD)"

mpc/.extract: mpc/$(MPC_ARCHIVE)
%/$(MPC_ARCHIVE): | %
	wget -O "$@" "$(MPC_DOWNLOAD)"

gdb/.extract: gdb/$(GDB_ARCHIVE)
%/$(GDB_ARCHIVE): | %
	wget -O "$@" "$(GDB_DOWNLOAD)"

glibc/.extract: glibc/$(GLIBC_ARCHIVE)
%/$(GLIBC_ARCHIVE): | %
	wget -O "$@" "$(GLIBC_DOWNLOAD)"

binutils/.extract: binutils/$(BINUTILS_ARCHIVE)
%/$(BINUTILS_ARCHIVE): | %
	wget -O "$@" "$(BINUTILS_DOWNLOAD)"
