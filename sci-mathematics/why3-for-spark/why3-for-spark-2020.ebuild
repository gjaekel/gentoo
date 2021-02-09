# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools

MYP=why3-${PV}-20200429-199EF-src

DESCRIPTION="Platform for deductive program verification"
HOMEPAGE="http://why3.lri.fr/"
SRC_URI="https://community.download.adacore.com/v1/8bb5801e17b8b23453262da69c981c091959eec7?filename=${MYP}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="coq doc emacs gtk html +ocamlopt zarith zip"
RESTRICT="strip"

DEPEND=">=dev-lang/ocaml-4.09.0:=[ocamlopt=]
	>=dev-ml/ocamlbuild-0.14.0
	dev-ml/menhir:=
	dev-ml/num:=
	dev-ml/yojson:=
	coq? (
		>=sci-mathematics/coq-8.9.1
		<sci-mathematics/coq-8.12
	)
	doc? (
		dev-tex/rubber
		dev-python/sphinx
		media-gfx/graphviz
		dev-python/sphinxcontrib-bibtex
	)
	gtk? ( >=dev-ml/lablgtk-2.18.8:=[sourceview] )
	emacs? ( >=app-editors/emacs-23.1:* )
	html? ( dev-tex/hevea:= )
	zarith? ( dev-ml/zarith:= )
	zip? ( >=dev-ml/camlzip-1.07:= )"
RDEPEND="${DEPEND}"

S="${WORKDIR}"/${MYP}

PATCHES=(
	"${FILESDIR}"/${P}-gentoo.patch
	"${FILESDIR}"/${P}-flags.patch
	"${FILESDIR}"/${P}-bibtex.patch
)

QA_FLAGS_IGNORED=(
	/usr/lib64/why3/commands/why3shell
	/usr/lib64/why3/commands/why3extract
	/usr/lib64/why3/commands/why3execute
	/usr/lib64/why3/commands/why3prove
	/usr/lib64/why3/commands/why3wc
	/usr/lib64/why3/commands/why3doc
	/usr/lib64/why3/commands/why3replay
	/usr/lib64/why3/commands/why3webserver
	/usr/lib64/why3/plugins/'.*'.cmxs
	/usr/lib64/ocaml/why3/why3.cmxs
	/usr/lib64/ocaml/why3/why3extract.cmxs
	/usr/bin/why3
	/usr/bin/why3config
	/usr/bin/why3session
	/usr/bin/gnat_server
	/usr/bin/gnatwhy3
	/usr/bin/why3realize
)

REQUIRED_USE="html? ( doc )"

src_prepare() {
	find examples -name \*gz | xargs gunzip
	default
	eautoreconf
}

src_configure() {
	econf \
		--disable-pvs-libs \
		--disable-isabelle-libs \
		--enable-verbose-make \
		$(use_enable coq coq-libs) \
		$(use_enable doc) \
		$(use_enable emacs emacs-compilation) \
		$(use_enable gtk ide) \
		$(use_enable html html-pdf) \
		$(use_enable ocamlopt native-code) \
		$(use_enable zarith) \
		$(use_enable zip)
}

src_compile() {
	emake -j1
	if use ocamlopt; then
		emake byte
	fi
	use doc && emake doc
}

src_install() {
	emake DESTDIR="${D}" -j1 install
	emake DESTDIR="${D}" -j1 install-lib
	emake DESTDIR="${D}" install_spark2014_dev
	local cmdPath=/usr/$(get_libdir)/why3/commands
	dosym ../why3server ${cmdPath}/why3server
	# Remove duplicated files
	for filename in config ide realize server session; do
		if [[ -e "${D}"${cmdPath}/why3${filename} ]]; then
			rm "${D}"${cmdPath}/why3${filename}
			dosym ../../../bin/why3${filename} ${cmdPath}/why3${filename}
		fi
	done
	rm "${D}"/usr/$(get_libdir)/why3/why3cpulimit
	dosym ../../bin/why3cpulimit /usr/$(get_libdir)/why3/why3cpulimit

	einstalldocs
	docompress -x /usr/share/doc/${PF}/examples
	dodoc -r examples
	if use doc; then
		use html && dodoc -r doc/html
	fi
}
