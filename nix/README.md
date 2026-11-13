# Nix launcher and build kit

```sh
nix run github:peigongdsd/NX2navi
nix profile add github:peigongdsd/NX2navi
nx2navi
```

The flake builds the Maxwell-to-SPIR-V translator as a native executable from the checked-in sources and patches using .NET NativeAOT. Its NuGet dependencies are hash-pinned in `translator-deps.json`. The launcher, runtime sources and lifter come from this checkout, and the runtime shaders and optional SPIR-V optimizer are built during the Nix build. No AppImage or prebuilt NX2navi compiler is used.

Nix supplies Python 3.14 and its modules, including the separately packaged GPL ZBIC decompressor, LLVM 23, Vulkan headers, VMA, and the build/runtime libraries. A small FHS environment accommodates the upstream compiler tools' conventional include and library paths. It uses the host's graphics driver. The package contains no game data; the launcher builds the game from the player's own dump in a writable game folder outside the Nix store.

The GUI keeps its existing folder selection and progress display. Updating this package updates the launcher and source kit. Use the launcher's Update action to incrementally rebuild the selected game; saves, settings, extracted assets and caches remain there. To run an already built game in the same dependency environment:

```sh
nx2navi --run ~/NSGames/NX2navi
```

Enable the optional optimizer with `spirv_opt = 1` under `[performance]` in the game's `nx2navi.ini`. The helper is copied beside the game by the build tools. It remains off by default, and its optimized modules have a validated disk cache. GPU pipelines remain specific to the GPU, driver and configuration.

FSR 3.1 and frame generation currently depend on upstream's Windows-only FidelityFX loader. This Linux package does not enable unavailable backends. The existing spatial FSR scaler remains available.

After changing the translator's package references, regenerate its dependency lock:

```sh
nix build .#translator.passthru.fetch-deps -o fetch-translator-deps
./fetch-translator-deps nix/translator-deps.json
nix flake check
```

The runtime's three fixes remain separate commits on `integration/linux-three-fixes-20261113`. Packaging lives on the fork's `main` branch. To refresh the installed package later, use `nix profile upgrade` with its NX2navi profile entry.
