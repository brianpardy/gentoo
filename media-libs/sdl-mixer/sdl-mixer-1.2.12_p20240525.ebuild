# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Check SDL-1.2 branch for possible backports/new snapshots

inherit multilib-minimal

SDL_MIXER_COMMIT="ed76d39cda0735d26c14a3e4f4da996e420f6478"

MY_PN=${PN/sdl-/SDL_}
DESCRIPTION="Simple Direct Media Layer Mixer Library"
HOMEPAGE="https://www.libsdl.org/projects/SDL_mixer/"
SRC_URI="https://github.com/libsdl-org/SDL_mixer/archive/${SDL_MIXER_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}"/${MY_PN}-${SDL_MIXER_COMMIT}

LICENSE="ZLIB"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~mips ppc ppc64 sparc x86 ~amd64-linux ~x86-linux ~ppc-macos"
IUSE="flac fluidsynth mad midi mikmod mod modplug mp3 playtools smpeg static-libs timidity vorbis +wav"

REQUIRED_USE="
	midi? ( || ( timidity fluidsynth ) )
	timidity? ( midi )
	fluidsynth? ( midi )
	mp3? ( || ( smpeg mad ) )
	smpeg? ( mp3 )
	mad? ( mp3 )
	mod? ( || ( mikmod modplug ) )
	mikmod? ( mod )
	modplug? ( mod )
"

RDEPEND="
	>=media-libs/libsdl-1.2.15-r4[${MULTILIB_USEDEP}]
	flac? ( >=media-libs/flac-1.2.1-r5:=[${MULTILIB_USEDEP}] )
	midi? (
		fluidsynth? ( >=media-sound/fluidsynth-1.1.6-r1:=[${MULTILIB_USEDEP}] )
		timidity? ( media-sound/timidity++ )
	)
	mod? (
		mikmod? ( >=media-libs/libmikmod-3.3.6-r1[${MULTILIB_USEDEP}] )
		modplug? ( >=media-libs/libmodplug-0.8.8.4-r1[${MULTILIB_USEDEP}] )
	)
	mp3? (
		mad? ( >=media-libs/libmad-0.15.1b-r8[${MULTILIB_USEDEP}] )
		smpeg? ( >=media-libs/smpeg-0.4.4-r10[${MULTILIB_USEDEP}] )
	)
	vorbis? (
		>=media-libs/libogg-1.3.0[${MULTILIB_USEDEP}]
		>=media-libs/libvorbis-1.3.3-r1[${MULTILIB_USEDEP}]
	)
"
DEPEND="${RDEPEND}"

multilib_src_configure() {
	local myeconfargs=(
		--disable-music-flac-shared
		--disable-music-fluidsynth-shared
		--disable-music-mod-shared
		--disable-music-mp3-shared
		--disable-music-ogg-shared

		$(use_enable wav music-wave)
		$(use_enable vorbis music-ogg)
		$(use_enable mikmod music-mod)
		$(use_enable modplug music-mod-modplug)
		$(use_enable flac music-flac)
		$(use_enable static-libs static)
		$(use_enable smpeg music-mp3)
		$(use_enable mad music-mp3-mad-gpl)
		$(use_enable timidity music-timidity-midi)
		$(use_enable fluidsynth music-fluidsynth-midi)

		LIBMIKMOD_CONFIG="${EPREFIX}"/usr/bin/${CHOST}-libmikmod-config
	)

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_install() {
	emake DESTDIR="${D}" install
	if multilib_is_native_abi && use playtools; then
		emake DESTDIR="${D}" install-bin
	fi
}

multilib_src_install_all() {
	dodoc CHANGES README
	find "${ED}" -name '*.la' -delete || die
}

pkg_postinst() {
	# bug 412035
	# https://bugs.gentoo.org/show_bug.cgi?id=412035
	if use midi ; then
		if use fluidsynth; then
			ewarn "FluidSynth support requires you to set the SDL_SOUNDFONTS"
			ewarn "environment variable to the location of a SoundFont file"
			ewarn "unless the game or application happens to do this for you."

			if use timidity; then
				ewarn "Failing to do so will result in Timidity being used instead."
			else
				ewarn "Failing to do so will result in silence."
			fi
		fi
	fi
}
