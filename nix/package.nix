{ lib, buildFHSEnv, runCommand, python314, shaderc, spirv-tools, fetchurl,
  makeDesktopItem, source, spirv-optimizer, translator }:
let
  version = lib.trim (builtins.readFile (source + /VERSION));
  zbic = python314.pkgs.buildPythonPackage {
    pname = "zbic";
    version = "1.0.1.post1";
    pyproject = true;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/51/34/a108004438db175641f13b9d9de8b6b57c96911c582e8f39fc57b277f9d8/zbic-1.0.1.post1.tar.gz";
      hash = "sha256-p5jCSupY+BoLS7Aibw84O35/B6mgFQcyy0XcZaxUH/M=";
    };
    build-system = [ python314.pkgs.setuptools ];
    pythonImportsCheck = [ "zbic" ];
    meta.license = lib.licenses.gpl2Only;
  };
  python = python314.withPackages (p: [ p.tkinter p.numpy p.lz4 p.zstandard p.fonttools p.pillow zbic ]);
  headers = fetchurl {
    url = "https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.4.363.tar.gz";
    hash = "sha256-y69ofTxZuWZv4IDn+Dlra09NNEp2juazN8WYUvRSa2g=";
  };
  kit = runCommand "nx2navi-${version}-source-kit" {
    nativeBuildInputs = [ python shaderc spirv-tools ];
  } ''
    mkdir -p $out/usr/kit/bin
    for name in runtime recomp tools docs tests; do
      cp -r ${source}/$name $out/usr/kit/
    done
    chmod -R u+w $out
    rm -rf $out/usr/kit/tools/vendor $out/usr/kit/tools/xlate
    cp ${source}/{VERSION,LICENSE,LICENSE-ADDITIONS,THIRD_PARTY_NOTICES.md,nx2navi.ini.example} $out/usr/kit/
    python $out/usr/kit/tools/vulkan_pin.py --archive ${headers} --dest $out/usr/kit/toolchain/vulkan-headers
    python $out/usr/kit/tools/build_shaders.py
    install -m755 ${translator}/bin/nx2navi_xlate $out/usr/kit/bin/
    install -m644 ${translator}/share/nx2navi/nx2navi_xlate.id $out/usr/kit/bin/
    install -m755 ${spirv-optimizer}/lib/libnx2navi_spirv_opt.so $out/usr/kit/bin/
    install -m644 ${source}/runtime/licenses/spirv-tools-Apache-2.0.txt $out/usr/kit/bin/spirv-tools-LICENSE.txt
  '';
  launcher = runCommand "nx2navi-${version}-launcher" { } ''
    mkdir -p $out/bin
    substitute ${./launcher.sh} $out/bin/nx2navi-launch \
      --replace-fail '@python@' '${python}/bin/python3' \
      --replace-fail '@kit@' '${kit}/usr/kit'
    chmod +x $out/bin/nx2navi-launch
  '';
  desktop = makeDesktopItem {
    name = "nx2navi";
    desktopName = "NX2navi";
    comment = "Build and play NX2navi from your own game dump";
    exec = "nx2navi";
    icon = "nx2navi";
    categories = [ "Game" ];
  };
in buildFHSEnv {
  pname = "nx2navi";
  inherit version;
  runScript = "${launcher}/bin/nx2navi-launch";
  targetPkgs = p: with p; [
    llvmPackages_latest.clang llvmPackages_latest.lld llvmPackages_latest.compiler-rt
    gcc pkg-config gnumake ninja git curl cacert coreutils gawk
    sdl3 libopus libvpx dav1d zstd vulkan-headers vulkan-loader
    libunwind vulkan-memory-allocator shaderc spirv-tools
    openssl icu libffi zlib fontconfig xdg-utils
  ];
  extraOutputsToInstall = [ "dev" "static" ];
  profile = ''export VMA_INCLUDE=/usr/include'';
  extraInstallCommands = ''
    mkdir -p $out/share/applications $out/share/icons/hicolor/256x256/apps
    cp ${desktop}/share/applications/nx2navi.desktop $out/share/applications/
    cp ${source}/docs/images/navi.png $out/share/icons/hicolor/256x256/apps/nx2navi.png
  '';
  passthru = { inherit kit translator python; };
  meta = {
    description = "NX2navi launcher and compiler kit built from source";
    homepage = "https://github.com/peigongdsd/NX2navi";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "nx2navi";
  };
}
