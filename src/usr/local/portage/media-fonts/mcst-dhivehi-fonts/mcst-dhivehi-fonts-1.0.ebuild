# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit font

DESCRIPTION="Maldives MCST Dhivehi fonts"
HOMEPAGE="http://www.mcst.gov.mv/News_and_Events/xpfonts.htm"

# MCST site is down for quite a long time
base_uri="http://sites.google.com/site/iheckersite/uploads/dhivehi-fonts"
SRC_URI="${base_uri}/MvElaafLite.otf.ttf      -> ${P}-MvElaafLite.ttf
         ${base_uri}/MvElaafNormal.otf.ttf    -> ${P}-MvElaafNormal.ttf
         ${base_uri}/MvGroupXAvas.otf.ttf     -> ${P}-MvGroupXAvas.ttf
         ${base_uri}/MvIyyuNala.otf.ttf       -> ${P}-MvIyyuNala.ttf
         ${base_uri}/MvIyyuNormal.otf.ttf     -> ${P}-MvIyyuNormal.ttf
         ${base_uri}/MvLadyLuck.otf.ttf       -> ${P}-MvLadyLuck.ttf
         ${base_uri}/MvMAGRoundHollow.otf.ttf -> ${P}-MvMAGRoundHollow.ttf
         ${base_uri}/MvMAGRoundXBold.otf.ttf  -> ${P}-MvMAGRoundXBold.ttf
         ${base_uri}/MvSehgaFB.otf.ttf        -> ${P}-MvSehgaFB.ttf
         ${base_uri}/MvSehgaOld.otf.ttf       -> ${P}-MvSehgaOld.ttf
         ${base_uri}/MvGalan.ttf              -> ${P}-MvGalan.ttf"

# http://github.com/jinahadam/iDhivehiSites-/blob/e599261f656dffa113eede9945656e35d829b84f/Mv%20MAG%20Round.otf.ttf
# Should be 27088 in size, SHA-256 ac5407d4a4611cc277f9c82a3f8dbd63ee1705c594682b32d26719fe185bea38

LICENSE="freedist"
SLOT="0"
KEYWORDS="amd64 x86"

# Space delimited list of font suffixes to install
FONT_SUFFIX="ttf"

# Dir containing the fonts
FONT_S="${S}"

# Unpacking unnecessary
src_unpack() {
    mkdir -p "${S}"
    cd "${S}"

    cp "${DISTDIR}"/* .

    for f in ${P}-*.ttf; do
        mv ${f} ${f#${P}-}
    done
}
