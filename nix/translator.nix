{ lib, buildDotnetModule, dotnet-sdk_10, python3, git, clang, zlib, source }:
buildDotnetModule {
  pname = "nx2navi-translator";
  version = lib.trim (builtins.readFile ../VERSION);
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../VERSION
      ../tools/build_xlate.py
      ../tools/xlate
      ../tools/vendor/ryujinx
    ];
  };
  projectFile = "build/xlate/xlate/nx2navi_xlate.csproj";
  nugetDeps = ./translator-deps.json;
  dotnet-sdk = dotnet-sdk_10;
  dotnet-runtime = null;
  selfContainedBuild = true;
  runtimeId = "linux-x64";
  executables = [ "nx2navi_xlate" ];
  nativeBuildInputs = [ python3 git clang ];
  buildInputs = [ zlib ];
  preBuild = ''export DOTNET_PROCESSOR_COUNT="$NIX_BUILD_CORES"'';
  preConfigure = ''python ${./prepare-translator.py}'';
  dotnetFlags = [ "-p:PublishAot=true" "-p:InvariantGlobalization=true" ];
  postInstall = ''
    python ${./prepare-translator.py} --identity
    install -Dm644 build/xlate/nx2navi_xlate.id $out/share/nx2navi/nx2navi_xlate.id
  '';
  meta = {
    description = "NativeAOT Maxwell to SPIR-V translator for NX2navi";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
