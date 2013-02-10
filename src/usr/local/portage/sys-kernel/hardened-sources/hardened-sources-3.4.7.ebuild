# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/hardened-sources/hardened-sources-3.4.5.ebuild,v 1.2 2012/08/09 09:28:05 blueness Exp $

EAPI="4"

ETYPE="sources"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="8"
K_DEBLOB_AVAILABLE="1"

GENPATCHES_URI="http://dev.gentoo.org/~mpagano/genpatches/tarballs/genpatches-3.4-8.base.tar.bz2
                http://dev.gentoo.org/~mpagano/genpatches/tarballs/genpatches-3.4-8.extras.tar.bz2"

inherit kernel-2
detect_version

HGPV="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}-1"
HGPV_URI="http://dev.gentoo.org/~blueness/hardened-sources/hardened-patches/hardened-patches-${HGPV}.extras.tar.bz2"
SRC_URI="${KERNEL_URI} ${HGPV_URI} ${GENPATCHES_URI} ${ARCH_URI}"

UNIPATCH_LIST="${DISTDIR}/hardened-patches-${HGPV}.extras.tar.bz2"
UNIPATCH_EXCLUDE="4200_fbcondecor-0.9.6.patch"

DESCRIPTION="Hardened kernel sources (kernel series ${KV_MAJOR}.${KV_MINOR})"
HOMEPAGE="http://www.gentoo.org/proj/en/hardened/"
IUSE="deblob"

KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sparc x86"

RDEPEND=">=sys-devel/gcc-4.5"

pkg_postinst() {
	kernel-2_pkg_postinst

	local GRADM_COMPAT="sys-apps/gradm-2.9.1*"

	ewarn
	ewarn "Hardened Gentoo provides three different predefined grsecurity level:"
	ewarn "[server], [workstation], and [virtualization].  Those who intend to"
	ewarn "use one of these predefined grsecurity levels should read the help"
	ewarn "associated with the level.  Because some options require >=gcc-4.5,"
	ewarn "users with more, than one version of gcc installed should use gcc-config"
	ewarn "to select a compatible version."
	ewarn
	ewarn "Users of grsecurity's RBAC system must ensure they are using"
	ewarn "${GRADM_COMPAT}, which is compatible with ${PF}."
	ewarn "It is strongly recommended that the following command is issued"
	ewarn "prior to booting a ${PF} kernel for the first time:"
	ewarn
	ewarn "emerge -na =${GRADM_COMPAT}"
	ewarn
}
