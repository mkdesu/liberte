# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit autotools eutils

DESCRIPTION="Utilities for signing and verifying files for UEFI Secure Boot"
HOMEPAGE="http://packages.ubuntu.com/quantal/sbsigntool"
SRC_URI="https://launchpad.net/ubuntu/+archive/primary/+files/${PN}_${PV}.orig.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""
RESTRICT="x86? ( test )"

RDEPEND="dev-libs/openssl"
DEPEND="${RDEPEND}
	sys-boot/gnu-efi"

src_prepare() {
	# need correct /usr/include/efi/${efi_arch} on include path
	efi_arch=${ARCH}
	use x86   && efi_arch=ia32
	use amd64 && efi_arch=x86_64
	sed -i "s/^\(EFI_ARCH\)=.*/\1=${efi_arch}/" "${S}"/configure.ac

	eautoreconf
	default
}
