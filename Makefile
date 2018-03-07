PREFIX	:= $(PWD)/root
SYSROOT	:= $(PREFIX)/mipsel-linux

GCC_DOWNLOAD	:= ftp://ftp.gnu.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.xz
GMP_DOWNLOAD	:= https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
MPFR_DOWNLOAD	:= http://www.mpfr.org/mpfr-current/mpfr-4.0.1.tar.xz
MPC_DOWNLOAD	:= https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz
BINUTILS_DOWNLOAD	:= ftp://ftp.gnu.org/gnu/binutils/binutils-2.30.tar.xz

GCC_ARCHIVE	:= $(notdir $(GCC_DOWNLOAD))
GMP_ARCHIVE	:= $(notdir $(GMP_DOWNLOAD))
MPFR_ARCHIVE	:= $(notdir $(MPFR_DOWNLOAD))
MPC_ARCHIVE	:= $(notdir $(MPC_DOWNLOAD))
BINUTILS_ARCHIVE	:= $(notdir $(BINUTILS_DOWNLOAD))

GCC_DIR	:= $(GCC_ARCHIVE:%.tar.xz=%)
GMP_DIR	:= $(GMP_ARCHIVE:%.tar.lz=%)
MPFR_DIR	:= $(MPFR_ARCHIVE:%.tar.xz=%)
MPC_DIR	:= $(MPC_ARCHIVE:%.tar.gz=%)
BINUTILS_DIR	:= $(BINUTILS_ARCHIVE:%.tar.xz=%)

.SECONDARY:
.DELETE_ON_ERROR:

.PHONY: all
all: build-gcc

.PHONY: clean
clean: clean-gcc clean-gmp clean-mpc clean-mpfr clean-binutils clean-root

# Directories
gcc gmp mpc mpfr binutils:
	mkdir -p $@

%/build %/root:
	mkdir -p $@

# Common rules

%/.compile: %/.configure
	cd $*/build; $(MAKE)
	@touch $@

%/.install: %/.compile | %/root
	cd $*/build; $(MAKE) install
	@touch $@

clean-%:
	rm -rf $*

# Target specific rules

.PHONY: build-gcc build-binutils
build-gcc build-binutils: build-%: %/.compile

gcc/.configure: gcc/.link binutils/.install | gcc/build
	cd $|; ../$(GCC_DIR)/configure --target=mipsel-linux --prefix=$(PREFIX) --with-sysroot=$(SYSROOT) --enable-threads --disable-multilib --enable-languages=c,c++
	@touch $@

gcc/.link: gcc/.extract gmp/.extract mpfr/.extract mpc/.extract
	ln -sfr gmp/$(GMP_DIR) gcc/$(GCC_DIR)/gmp
	ln -sfr mpfr/$(MPFR_DIR) gcc/$(GCC_DIR)/mpfr
	ln -sfr mpc/$(MPC_DIR) gcc/$(GCC_DIR)/mpc
	@touch $@

binutils/.configure: binutils/.extract | binutils/build
	cd $|; ../$(BINUTILS_DIR)/configure --target=mipsel-linux --prefix=$(PREFIX) --with-sysroot=$(SYSROOT)
	@touch $@

# Download archives

gcc/$(GCC_ARCHIVE): | gcc
	wget -O "$@" "$(GCC_DOWNLOAD)"

gmp/$(GMP_ARCHIVE): | gmp
	wget -O "$@" "$(GMP_DOWNLOAD)"

mpfr/$(MPFR_ARCHIVE): | mpfr
	wget -O "$@" "$(MPFR_DOWNLOAD)"

mpc/$(MPC_ARCHIVE): | mpc
	wget -O "$@" "$(MPC_DOWNLOAD)"

binutils/$(BINUTILS_ARCHIVE): | binutils
	wget -O "$@" "$(BINUTILS_DOWNLOAD)"

# Extract archives

gcc/.extract: gcc/$(GCC_ARCHIVE)
	tar axf "$<" -C gcc
	@touch $@

gmp/.extract: gmp/$(GMP_ARCHIVE)
	tar axf "$<" -C gmp
	@touch $@

mpfr/.extract: mpfr/$(MPFR_ARCHIVE)
	tar axf "$<" -C mpfr
	@touch $@

mpc/.extract: mpc/$(MPC_ARCHIVE)
	tar axf "$<" -C mpc
	@touch $@

binutils/.extract: binutils/$(BINUTILS_ARCHIVE)
	tar axf "$<" -C binutils
	@touch $@
