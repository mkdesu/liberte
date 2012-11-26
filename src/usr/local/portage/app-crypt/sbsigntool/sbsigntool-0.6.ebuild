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
KEYWORDS="x86 amd64"
IUSE="test"

RDEPEND="dev-libs/openssl"
DEPEND="${RDEPEND}
	sys-boot/gnu-efi"

src_prepare() {
	sed -i 's@^\(EFI_ARCH=\$(uname -m\))$@\1 | sed s/i686/ia32/)@' "${S}"/configure.ac
	eautoreconf
	default
}
