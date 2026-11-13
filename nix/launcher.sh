#!/bin/bash
set -euo pipefail
PY='@python@'
KIT='@kit@'
unset PYTHONPATH PYTHONHOME

if [ $# -eq 0 ]; then
    if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
        exec "$PY" "$KIT/tools/appimage_gui.py" --apprun "$0" --icon "$KIT/docs/images/navi.png"
    fi
    set -- --help
fi
case "$1" in
    -V|--version|version)
        printf 'NX2navi %s (Nix source build)\n' "$(cat "$KIT/VERSION")"
        exit 0 ;;
    -h|--help)
        printf 'NX2navi %s (Nix source build)\n\n' "$(cat "$KIT/VERSION")"
        printf '%s\n' 'nx2navi                                  Open the launcher' \
            'nx2navi DUMP.nup [GAME_FOLDER]             Build the game' \
            'nx2navi --run GAME_FOLDER [options]        Run an existing build' \
            'nx2navi --make-game [options]              Use the build tools directly' \
            'nx2navi --check DUMP.nup                   Check the dump version' \
            'nx2navi --version                         Print the launcher version'
        exit 0 ;;
    --run)
        shift
        [ $# -gt 0 ] || { echo 'Usage: nx2navi --run GAME_FOLDER [options]' >&2; exit 2; }
        game=$(realpath "$1"); shift
        [ -x "$game/ocarina" ] || { echo "No built game at $game/ocarina" >&2; exit 1; }
        cp -f "$KIT/bin/libnx2navi_spirv_opt.so" "$game/libnx2navi_spirv_opt.so"
        cd "$game"
        exec ./ocarina "$@" ;;
    --make-game) shift; exec "$PY" "$KIT/tools/make_game.py" "$@" ;;
    --check)
        [ $# -eq 2 ] || { echo 'Usage: nx2navi --check DUMP.nup' >&2; exit 2; }
        exec "$PY" "$KIT/tools/make_game.py" --nup "$2" --check ;;
esac
events=()
if [ "$1" = --events ]; then events=(--events); shift; fi
[ $# -gt 0 ] || { echo 'Choose a game dump to build.' >&2; exit 2; }
if [ ${#events[@]} -gt 0 ]; then
    printf '%s\n' '@@{"ev":"step","step":"deps","state":"done"}' \
        '@@{"ev":"step","step":"dlss","state":"skip"}'
fi
dump="$1"
case "$dump" in
    -*) printf 'Unknown option: %s\nUse nx2navi --help for usage.\n' "$dump" >&2; exit 2 ;;
esac
[ -f "$dump" ] || { printf 'Game dump not found: %s\n' "$dump" >&2; exit 2; }
game="${2:-$HOME/Games/Ocarina}"
mem_gb=$(awk '/MemTotal/ {print int($2 / 1048576)}' /proc/meminfo)
jobs=$((mem_gb / 4)); [ "$jobs" -ge 2 ] || jobs=2
[ "$jobs" -le "$(nproc)" ] || jobs=$(nproc)
"$PY" "$KIT/tools/make_game.py" --nup "$dump" --out "$game" --jobs "$jobs" "${events[@]}"
# Re-enter the dependency environment when a desktop shortcut starts the game.
printf '#!/bin/bash\nexec %q --run %q "$@"\n' nx2navi "$(realpath "$game")" > "$game/play.sh"
chmod +x "$game/play.sh"
