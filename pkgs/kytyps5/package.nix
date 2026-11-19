# KytyPS5 (PS5 emulator), built from the `kytyps5` flake input.
#
# Upstream only ships a dev shell, because its CMake build downloads things at
# configure time. Everything it would download is pinned below and handed to
# CMake up front, so the build works inside the Nix sandbox.
#
# The app is "portable": it writes saves, caches and logs next to its own
# binary. launch.sh therefore runs it from ~/.local/share/kytyps5.
{
  lib,
  clangStdenv,
  llvmPackages,
  fetchFromGitHub,
  fetchurl,
  fetchzip,
  runCommand,
  writeShellScriptBin,
  runtimeShell,
  gitMinimal,
  cmake,
  ninja,
  pkg-config,
  python3,
  glslang,
  wayland-scanner,
  copyDesktopItems,
  makeDesktopItem,
  qt6,
  bash,
  coreutils,
  alsa-lib,
  dbus,
  libdecor,
  libglvnd,
  libpulseaudio,
  libx11,
  libxcursor,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxscrnsaver,
  libxtst,
  udev,
  vulkan-headers,
  vulkan-loader,
  wayland,
  wayland-protocols,

  # The flake input (fetched with submodules); see flake.nix.
  src,
}:

let
  # ---- Pins for what upstream's CMake downloads (3rdparty/CMakeLists.txt) ----
  # When upstream moves one of these, evaluation prints a warning naming it:
  # update the rev and hash here to match.
  fetched = {
    OPUS = fetchFromGitHub {
      owner = "xiph";
      repo = "opus";
      rev = "ddbe48383984d56acd9e1ab6a090c54ca6b735a6";
      hash = "sha256-M1G7ypcfs7nJmXgkyoG96jT/CkgN5BOzy+DGO4LVCvA=";
    };
    OPENXR = fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "OpenXR-SDK";
      rev = "f2448a8797c85814aa892efc1ab8707900fbcc78";
      hash = "sha256-glcHMArDabXbrxO4CY2QeTJFTeUTQH4v1O03LuhML7E=";
    };
    XBYAK = fetchFromGitHub {
      owner = "herumi";
      repo = "xbyak";
      rev = "44a72f369268f7d552650891b296693e91db86bb";
      hash = "sha256-S4arAwbhTGsUhDFfy5fTGyDvCm0/x/LKiiPTAuRM8Yk=";
    };
    ZYDIS = fetchFromGitHub {
      owner = "zyantific";
      repo = "zydis";
      rev = "120e0e705f8e3b507dc49377ac2879979f0d545c";
      fetchSubmodules = true;
      hash = "sha256-bjQCaYRA94CGBsxG+UOuDDyLrH3k2ERJbn0+7ITGLeU=";
    };
    ZSTD = fetchFromGitHub {
      owner = "facebook";
      repo = "zstd";
      rev = "f8745da6ff1ad1e7bab384bd1f9d742439278e99";
      hash = "sha256-tNFWIT9ydfozB8dWcmTMuZLCQmQudTFJIkSr0aG7S44=";
    };
    ZARCHIVE_SOURCE = fetchFromGitHub {
      owner = "Exzap";
      repo = "ZArchive";
      rev = "d2c717730092c7bf8cbb033b12fd4001b7c4d932";
      hash = "sha256-hX637O/mVLTzmG0a9swJu9w+3o26VHo+K/9RhMuf1lI=";
    };
  };

  # CMake skips its own patch step for sources handed to it, so apply
  # upstream's ZArchive patch here, the same way it does.
  zarchivePatched = runCommand "zarchive-kyty-patched" { nativeBuildInputs = [ gitMinimal ]; } ''
    cp -r ${fetched.ZARCHIVE_SOURCE} $out
    chmod -R u+w $out
    cd $out
    git apply --ignore-whitespace ${src}/3rdparty/patches/zarchive-reader.patch
  '';

  fetchContentDirs = fetched // {
    ZARCHIVE_SOURCE = zarchivePatched;
  };

  # Static FFmpeg build published for the 3rdparty/ffmpeg-core submodule commit;
  # the release tag is the first 12 characters of that commit.
  ffmpegCoreRev = "9ac4cfd195f1";
  ffmpegPrebuilt = fetchzip {
    url = "https://github.com/KytyPS5/ext-ffmpeg-core/releases/download/${ffmpegCoreRev}/ffmpeg-linux-x64.zip";
    stripRoot = false;
    hash = "sha256-MX8Rifr6CvFFkm0IAmJPNGzLb8FG5HJJUKO/l0zegko=";
  };

  # Noto Sans fallback fonts. CMake verifies these hashes itself and skips the
  # download when the files are already in place.
  notoCommit = "42af67ccd12bc0e31ed85384bf73e39248265374";
  notoFile =
    path: sha256:
    fetchurl {
      url = "https://raw.githubusercontent.com/notofonts/notofonts.github.io/${notoCommit}/fonts/${path}";
      inherit sha256;
    };
  notoFiles = {
    "LICENSE" = notoFile "LICENSE" "f2095b08bed08b23a6fe26112fcd679a2bee3f002eef077eb05d215ed1051bd8";
    "NotoSans-Regular.ttf" =
      notoFile "NotoSans/hinted/ttf/NotoSans-Regular.ttf"
        "478c558ea716033cd60c03438f628dfa75694dcf6b5f6d505a2f05fd2b4f3823";
    "NotoSans-Bold.ttf" =
      notoFile "NotoSans/hinted/ttf/NotoSans-Bold.ttf"
        "1df075a380fc7cb898acf64c1f7b3b4dd780de3caa860178bf929de35817a913";
    "NotoSans-Italic.ttf" =
      notoFile "NotoSans/hinted/ttf/NotoSans-Italic.ttf"
        "467e3f89eeca4108bb8710a2b9e0cf2281ac56d5b0609211a83776d0505eecb5";
    "NotoSans-BoldItalic.ttf" =
      notoFile "NotoSans/hinted/ttf/NotoSans-BoldItalic.ttf"
        "1b602a9d6353be42c91df097a4857b69fa2696f26703d7a33b54a15d87c2622c";
  };

  # Warn (without failing) when the source no longer pins what we pin.
  thirdPartyCMake = builtins.readFile "${src}/3rdparty/CMakeLists.txt";
  stalePins = lib.filter (pin: !lib.hasInfix pin thirdPartyCMake) (
    lib.mapAttrsToList (_: s: s.rev) fetched ++ [ notoCommit ] ++ lib.mapAttrsToList (_: f: f.outputHash) notoFiles
  );

  shortRev = src.shortRev or "unknown";
  date = src.lastModifiedDate or "19700101";

  # The build asks git for its version; there is no .git in the sandbox.
  gitStub = writeShellScriptBin "git" ''
    case "$*" in
      --version) echo "git version 2.0.0" ;;
      describe*) echo "${shortRev}" ;;
      "rev-parse HEAD") echo "${src.rev or "unknown"}" ;;
      "rev-parse --short=12 HEAD") echo "${ffmpegCoreRev}" ;;
      diff-index*) exit 0 ;;
      *) echo "git stub: unsupported: $*" >&2; exit 1 ;;
    esac
  '';

  # Loaded with dlopen() by the bundled SDL3, so they must be on the rpath.
  runtimeLibs = [
    alsa-lib
    dbus
    libdecor
    libglvnd
    libpulseaudio
    libx11
    libxcursor
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxtst
    udev
    vulkan-loader
    wayland
  ];
in
lib.warnIf (stalePins != [ ])
  "kytyps5: upstream changed third-party pins; update pkgs/kytyps5/package.nix (no longer found: ${lib.concatStringsSep ", " stalePins})"
  clangStdenv.mkDerivation
  {
    pname = "kytyps5";
    version = "0.3.0-unstable-${lib.substring 0 4 date}-${lib.substring 4 2 date}-${lib.substring 6 2 date}";

    inherit src;

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      python3 # SPIRV-Tools code generation
      glslang
      gitStub
      llvmPackages.bintools # wrapped lld; upstream links with -fuse-ld=lld
      wayland-scanner
      copyDesktopItems
      qt6.wrapQtAppsHook
    ];

    buildInputs = runtimeLibs ++ [
      qt6.qtbase
      qt6.qtsvg # the launcher's icons are SVG
      qt6.qtwayland
      vulkan-headers
      wayland-protocols
    ];

    # The emulator runs guest code natively and upstream builds without
    # distro hardening flags; match that rather than risk subtle breakage.
    hardeningDisable = [ "all" ];

    cmakeFlags = [
      (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
      (lib.cmakeFeature "FFMPEG_PREBUILT_DIR" "${ffmpegPrebuilt}")
    ]
    ++ lib.mapAttrsToList (name: dir: lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_${name}" "${dir}") fetchContentDirs;

    preConfigure = ''
      mkdir -p build/_deps/noto-sans
      ${lib.concatStrings (
        lib.mapAttrsToList (name: file: ''
          cp ${file} build/_deps/noto-sans/${name}
        '') notoFiles
      )}
    '';

    ninjaFlags = [ "launcher" ]; # also builds kyty_emulator and kyty_updater
    doCheck = false;

    # Upstream installs everything flat into the prefix.
    postInstall = ''
      mkdir -p $out/opt/kytyps5 $out/bin
      find $out -mindepth 1 -maxdepth 1 ! -name opt ! -name bin -exec mv -t $out/opt/kytyps5 {} +

      substitute ${./launch.sh} $out/bin/kytyps5 \
        --subst-var-by shell ${runtimeShell} \
        --subst-var-by app $out/opt/kytyps5
      chmod +x $out/bin/kytyps5

      install -Dm644 ../src/launcher/icons/kyty.svg $out/share/icons/hicolor/scalable/apps/kytyps5.svg
    '';

    dontWrapQtApps = true;

    postFixup = ''
      patchelf --add-rpath ${lib.makeLibraryPath runtimeLibs} \
        $out/opt/kytyps5/kyty_emulator $out/opt/kytyps5/kyty_launcher

      # The launcher starts games through `bash` in a terminal emulator.
      wrapQtApp $out/bin/kytyps5 --suffix PATH : ${
        lib.makeBinPath [
          bash
          coreutils
        ]
      }
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "kytyps5";
        desktopName = "KytyPS5";
        comment = "PlayStation 5 emulator";
        exec = "kytyps5";
        icon = "kytyps5";
        categories = [
          "Game"
          "Emulator"
        ];
      })
    ];

    meta = {
      description = "PlayStation 5 emulator";
      homepage = "https://github.com/KytyPS5/KytyPS5";
      mainProgram = "kytyps5";
      platforms = [ "x86_64-linux" ];
    };
  }
