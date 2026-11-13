{
  description = "NX2navi Linux launcher and NativeAOT shader translator built from source";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/da2a10dcfe71559def1d5486203d9f8570676df2";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
  in {
    packages.${system} = rec {
      default = nx2navi;
      nx2navi = pkgs.callPackage ./nix/package.nix { source = self; inherit spirv-optimizer translator; };
      translator = pkgs.callPackage ./nix/translator.nix { source = self; };
      spirv-optimizer = pkgs.callPackage ./nix/spirv-optimizer.nix { source = self; };
    };
    apps.${system}.default = {
      type = "app";
      program = "${self.packages.${system}.nx2navi}/bin/nx2navi";
    };
    checks.${system} = {
      hdr-enumeration = pkgs.runCommand "nx2navi-hdr-enumeration-check" {
        nativeBuildInputs = [ pkgs.python3 pkgs.clang ];
      } ''
        mkdir -p source/tests source/runtime
        cp ${self}/tests/surface_formats_check.{c,py} source/tests/
        cp ${self}/runtime/gfx_present.c source/runtime/
        python source/tests/surface_formats_check.py --sanitize
        touch $out
      '';
      spirv-optimizer = pkgs.runCommand "nx2navi-optimizer-check" {
        nativeBuildInputs = [ pkgs.python3 ];
      } ''
        python ${./nix/check-optimizer.py} ${self.packages.${system}.spirv-optimizer}/lib/libnx2navi_spirv_opt.so
        touch $out
      '';
      runtime-compilation = pkgs.runCommand "nx2navi-runtime-preflight-check" {
        nativeBuildInputs = [ self.packages.${system}.nx2navi.python pkgs.llvmPackages_latest.clang pkgs.llvmPackages_latest.lld ];
        buildInputs = with pkgs; [
          sdl3 vulkan-headers vulkan-loader vulkan-memory-allocator libopus libvpx dav1d zstd
        ];
      } ''
        kit=${self.packages.${system}.nx2navi.kit}/usr/kit
        export VMA_INCLUDE="${pkgs.vulkan-memory-allocator}/include"
        python - "$kit" <<'PY'
import pathlib
import sys
kit = pathlib.Path(sys.argv[1])
sys.path.insert(0, str(kit / 'tools'))
import make_game
make_game.preflight(pathlib.Path('/unused'), 4)
PY
        touch $out
      '';
    };
  };
}
