{
  lib,
  stdenv,
  fetchFromGitHub,
  autoconf,
  autoconf-archive,
  gcc,
  glib,
  dbus-glib,
  libxml2,
  pkg-config,
  automake,
  gtk-doc,
  systemd,
  upower,
  libnl,
  man-db,
}:

stdenv.mkDerivation (final: {
  pname = "intel-lpmd";
  version = "0.1.0";
  nativeBuildInputs = [
    autoconf
    autoconf-archive
    gcc
    man-db
    glib
    dbus-glib
    libxml2
    pkg-config
    gtk-doc
    systemd
    automake
    upower
    libnl
  ];
  src = fetchFromGitHub {
    owner = "intel";
    repo = "intel-lpmd";
    rev = "v${final.version}";
    sha256 = "sha256-eZBgWpR2tdSDeqYV4Y2h2j5UeJebQg2tXlXcUywwZEA=";
  };
  # https://github.com/intel/intel-lpmd?tab=readme-ov-file#build-and-install
  configurePhase = ''
    ./autogen.sh --localstatedir=/var --sysconfdir=$out/etc
    		'';
  buildPhase = ''
            make
    				mkdir -p "$out/bin"
    				cp ./intel_lpmd $out/bin/intel_lpmd
  '';
  # Needed for config files, which the program will not run without.
  installPhase = ''
        	mkdir -p "$out/etc/intel_lpmd/"
    			cp $src/data/* $out/etc/intel_lpmd/ -r 
            	'';
})
