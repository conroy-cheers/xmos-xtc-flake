{
  stdenv,
  lib,
  requireFile,
  autoPatchelfHook,
  makeWrapper,
  udev,
  zlib,
  ncurses,
  libusb1,
  libxcrypt-legacy,
}:

let
  xmosPackageVersions = import ../../data/packages.nix;
  inherit (xmosPackageVersions) version systems;

  hash = systems.${stdenv.hostPlatform.system}.hash;
  url = systems.${stdenv.hostPlatform.system}.url;
  archiveFilename = systems.${stdenv.hostPlatform.system}.filename;
in

stdenv.mkDerivation rec {
  pname = "xtc-tools";
  inherit version;

  src = requireFile {
    name = archiveFilename;
    url = "https://www.xmos.com/software-tools#xtc-tools";
    sha256 = hash;
  };

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  preferLocalBuild = true;

  outputs = [
    "out"
    "lib"
    "doc"
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    udev
    stdenv.cc.cc.lib
    zlib
    ncurses
    libusb1
    libxcrypt-legacy
  ];

  runtimeDependencies = [ udev ];

  postPatch = ''
    substituteInPlace XTC/$version/scripts/99-xmos.rules \
      --replace-fail "usb|usb_device" "usb" \
      --replace-fail 'ATTRS{idVendor}==' 'ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}==' \
      --replace-fail "SYMLINK=" "SYMLINK+="
  '';

  installPhase = ''
    runHook preInstall

    cd XTC/$version/

    mkdir -p $out/bin/unwrapped $lib $doc

    mv bin/* $out/bin/unwrapped
    mv lib $lib/

    install --directory $out/lib/udev/rules.d
    mv scripts/99-xmos.rules $out/lib/udev/rules.d/

    for f in $out/bin/unwrapped/*; do
      name=$(basename $f)
      if [[ -f $f && -x $f ]]; then
        makeWrapper $f $out/bin/$name \
          --set PATH "$out/bin:$PATH"
      fi
    done

    mv doc/ $doc/XTC

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://www.xmos.com/software-tools#xtc-tools";
    description = "XMOS XTC Tools";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = with maintainers; [ conroy-cheers ];
    mainProgram = "xflash";
  };
}
