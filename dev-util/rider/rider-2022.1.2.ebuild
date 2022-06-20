# Copyright 2022 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit desktop wrapper

DESCRIPTION="Fast & powerful cross-platform .NET IDE"
HOMEPAGE="https://www.jetbrains.com/rider"
# FIXME check licenses
LICENSE="
	|| ( jetbrains_business-4.0 jetbrains_individual-4.2 jetbrains_educational-4.0 jetbrains_classroom-4.2 jetbrains_opensource-4.2 )
	Apache-1.1 Apache-2.0 BSD BSD-2 CC0-1.0 CC-BY-2.5 CDDL CDDL-1.1 codehaus CPL-1.0 GPL-2 GPL-2-with-classpath-exception GPL-3 ISC LGPL-2.1 LGPL-3 MIT MPL-1.1 MPL-2.0 OFL trilead-ssh yFiles yourkit W3C ZLIB
"
SLOT="0"
VER="$(ver_cut 1-2)"
KEYWORDS="~amd64"
RESTRICT="bindist mirror splitdebug"
IUSE="jbrsdk jbr-fd +jbrsdk-jcef jbr-vanilla"
REQUIRED_USE="^^ ( jbrsdk jbr-fd jbrsdk-jcef jbr-vanilla )"
QA_PREBUILT="opt/${P}/*"
RDEPEND="
	>=app-accessibility/at-spi2-atk-2.15.1
	dev-libs/libdbusmenu
	dev-util/lldb
	dev-util/lttng-ust
	media-libs/mesa[X(+)]
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	>=x11-libs/libXi-1.3
	>=x11-libs/libXrandr-1.5
"

SIMPLE_NAME="Rider"
MY_PN="rider"
SRC_URI_PATH="rider"
SRC_URI_PN="JetBrains.Rider"
JBR_PV="17.0.3"
JBR_PB="463.3"
SRC_URI="https://download.jetbrains.com/${SRC_URI_PATH}/${SRC_URI_PN}-${PV}.tar.gz -> ${P}.tar.gz
	jbr-fd?		( https://cache-redirector.jetbrains.com/intellij-jbr/jbr_fd-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbr-vanilla?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbr-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbrsdk?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
	jbrsdk-jcef?	( https://cache-redirector.jetbrains.com/intellij-jbr/jbrsdk_jcef-${JBR_PV}-linux-x64-b${JBR_PB}.tar.gz )
"

S="${WORKDIR}/JetBrains Rider-${PV}"

src_prepare() {
	default

	local pty4j_path="lib/pty4j-native/linux"
	local ReSharperHost_path="lib/ReSharperHost/"
	local remove_me=( "${pty4j_path}"/ppc64le "${pty4j_path}"/aarch64 "${pty4j_path}"/mips64el "${pty4j_path}"/arm )
	remove_me+=( "${ReSharperHost_path}"/linux-arm "${ReSharperHost_path}"/linux-arm64 "${ReSharperHost_path}"/linux-x86 "${ReSharperHost_path}"/macos-arm64 "${ReSharperHost_path}"/macos-x64 "${ReSharperHost_path}"/windows-x64 "${ReSharperHost_path}"/windows-x86 )

	if ! use jbrsdk-jcef ; then
		remove_me+=( )
	fi

	rm -rv "${remove_me[@]}" || die
}

src_install() {
	local dir="/opt/${P}"

	insinto "${dir}"
	doins -r *
	fperms 755 "${dir}"/bin/"${MY_PN}".sh

	if ! use jbrsdk-jcef ; then
		doins -r ../jbr
	fi
	fperms 755 "${dir}"/jbr/bin/{jaotc,java,javac,jdb,jfr,jhsdb,jjs,jrunscript,keytool,pack200,rmid,rmiregistry,serialver,unpack200}
	fperms 755 "${dir}"/plugins/cidr-debugger-plugin/bin/lldb/linux/bin/*

	if use jbrsdk-jcef; then
		fperms 755 "${dir}"/jbr/lib/jcef_helper
	fi

	fperms 755 "${dir}"/bin/fsnotifier
	fperms 755 "${dir}"/lib/ReSharperHost/linux-x64/dotnet/dotnet

	make_wrapper "${PN}" "${dir}"/bin/"${MY_PN}".sh
	newicon bin/"${MY_PN}".svg "${PN}".svg
	make_desktop_entry "${PN}" "${SIMPLE_NAME} ${VER}" "${PN}" "Development;IDE;"

	# recommended by: https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit
	dodir /usr/lib/sysctl.d/
	echo "fs.inotify.max_user_watches = 524288" > "${D}/usr/lib/sysctl.d/30-${PN}-inotify-watches.conf" || die
}
