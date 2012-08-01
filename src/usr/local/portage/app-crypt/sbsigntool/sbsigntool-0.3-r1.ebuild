# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit autotools eutils

DESCRIPTION="Utilities for signing and verifying files for UEFI Secure Boot"
HOMEPAGE="http://packages.ubuntu.com/quantal/sbsigntool"
SRC_URI="http://archive.ubuntu.com/ubuntu/pool/universe/s/sbsigntool/${PN}_${PV}.orig.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

RDEPEND="dev-libs/openssl"
DEPEND="${RDEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/sbsigntool-0.3-support-i386.patch
	default
}
