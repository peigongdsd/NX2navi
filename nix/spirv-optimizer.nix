{ stdenv, spirv-tools, spirv-headers, source }:
stdenv.mkDerivation {
  pname = "nx2navi-spirv-optimizer";
  version = "363-perf-v1";
  dontUnpack = true;
  buildInputs = [ spirv-tools spirv-headers ];
  buildPhase = ''
    $CXX -std=c++17 -O2 -fPIC -shared ${source}/tools/spirv_opt/bridge.cpp \
      -lSPIRV-Tools-opt -lSPIRV-Tools -o libnx2navi_spirv_opt.so
  '';
  installPhase = ''
    install -Dm755 libnx2navi_spirv_opt.so $out/lib/libnx2navi_spirv_opt.so
    install -Dm644 ${source}/runtime/licenses/spirv-tools-Apache-2.0.txt \
      $out/share/licenses/nx2navi-spirv-optimizer/Apache-2.0.txt
  '';
}
