{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  alsa-lib,
  pulseaudio,
}:

stdenv.mkDerivation rec {
  pname = "scream-receiver";
  version = "4.0";

  src = fetchFromGitHub {
    owner = "duncanthrax";
    repo = "scream";
    rev = version;
    hash = "sha256-lP5mdNhZjkEVjgQUEsisPy+KXUqsE6xj6dFWcgD+VGM=";
  };

  sourceRoot = "${src.name}/Receivers/unix";

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [
    alsa-lib
    pulseaudio
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp scream $out/bin/scream-receiver
    runHook postInstall
  '';

  meta = {
    description = "Scream virtual network sound card - Unix receiver";
    homepage = "https://github.com/duncanthrax/scream";
    license = lib.licenses.lgpl21Only;
    platforms = lib.platforms.linux;
  };
}
