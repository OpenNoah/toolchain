PREFIX	:= /opt/toolchain/mipsel-linux
SYSROOT	:= $(PREFIX)/mipsel-linux

GCC_DOWNLOAD	:= ftp://ftp.gnu.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.xz
GMP_DOWNLOAD	:= https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
MPFR_DOWNLOAD	:= http://www.mpfr.org/mpfr-current/mpfr-4.0.1.tar.xz
MPC_DOWNLOAD	:= https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz

GCC_ARCHIVE	:= $(notdir $(GCC_DOWNLOAD))
GMP_ARCHIVE	:= $(notdir $(GMP_DOWNLOAD))
MPFR_ARCHIVE	:= $(notdir $(MPFR_DOWNLOAD))
MPC_ARCHIVE	:= $(notdir $(MPC_DOWNLOAD))

GCC_DIR	:= $(GCC_ARCHIVE:%.tar.xz=%)
GMP_DIR	:= $(GMP_ARCHIVE:%.tar.lz=%)
MPFR_DIR	:= $(MPFR_ARCHIVE:%.tar.xz=%)
MPC_DIR	:= $(MPC_ARCHIVE:%.tar.gz=%)

.SECONDARY:
.DELETE_ON_ERROR:

.PHONY: all
all: build-gcc

# Directories
gcc gcc/build gmp mpc mpfr: %:
	mkdir -p $*

.PHONY: build-gcc
build-gcc: gcc/.compile

gcc/.compile: gcc/.make

gcc/.make: gcc/.compile
	cd gcc/build; $(MAKE)
	@touch $@

gcc/.configure: gcc/.link | gcc/build
	cd $|; ../$(GCC_DIR)/configure --target=mipsel-linux --prefix=$(PREFIX) --enable-threads --disable-multilib --enable-languages=c,c++
	@touch $@

gcc/.link: gcc/.extract gmp/.extract mpfr/.extract mpc/.extract
	ln -sfr gmp/$(GMP_DIR) gcc/$(GCC_DIR)/gmp
	ln -sfr mpfr/$(MPFR_DIR) gcc/$(GCC_DIR)/mpfr
	ln -sfr mpc/$(MPC_DIR) gcc/$(GCC_DIR)/mpc
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
