#!/usr/bin/env sh
# This wrapper script is invoked by xdg-desktop-portal-termfilechooser.
#
# For more information about input/output arguments read `xdg-desktop-portal-termfilechooser(5)`

multiple="$1"
directory="$2"
save="$3"
path="$4"
out="$5"
debug="$6"

set -e

if [ "$debug" = 1 ]; then
    set -x
fi

# Remember the help file so a renamed or moved stub is still allowed.
help_head=""
help_id=""
if [ "$save" = "1" ] && [ -f "$path" ]; then
    help_head=$(head -c 96 -- "$path" 2>/dev/null || true)
    help_id=$(stat -Lc '%d:%i' -- "$path" 2>/dev/null || true)
fi

cmd="yazi"
termcmd="${TERMCMD:-ghostty --gtk-single-instance=false --title=termfilechooser -e}"

if [ "$save" = "1" ]; then
    # save a file
    set -- --chooser-file="$out" "$path"
elif [ "$directory" = "1" ]; then
    # upload files from a directory
    set -- --chooser-file="$out" --cwd-file="$out"".1" "$path"
elif [ "$multiple" = "1" ]; then
    # upload multiple files
    set -- --chooser-file="$out" "$path"
else
    # upload only 1 file
    set -- --chooser-file="$out" "$path"
fi

command="$termcmd $cmd"
for arg in "$@"; do
    # escape double quotes
    escaped=$(printf "%s" "$arg" | sed 's/"/\\"/g')
    # escape special
    command="$command \"$escaped\""
done

sh -c "$command"

# Save safeguard: keep existing files; collisions become "name (N).ext".
if [ "$save" = "1" ] && [ -s "$out" ] && [ -n "$help_head" ]; then
    selected=$(head -n 1 -- "$out" 2>/dev/null || true)

    if [ -n "$selected" ] && [ -f "$selected" ] && [ -s "$selected" ]; then
        selected_head=$(head -c 96 -- "$selected" 2>/dev/null || true)
        selected_id=$(stat -Lc '%d:%i' -- "$selected" 2>/dev/null || true)

        if [ "$selected" != "$path" ] &&
            [ "$selected_head" != "$help_head" ] &&
            { [ -z "$help_id" ] || [ "$selected_id" != "$help_id" ]; }; then
            dir=$(dirname -- "$selected")
            base=$(basename -- "$selected")
            stem=$base
            ext=""

            case "$base" in
                .*)
                    rest=${base#.}
                    case "$rest" in
                        *.*)
                            ext=".${rest##*.}"
                            stem=".${rest%.*}"
                            ;;
                    esac
                    ;;
                *.*)
                    ext=".${base##*.}"
                    stem="${base%.*}"
                    ;;
            esac

            n=1
            while [ -e "$dir/$stem ($n)$ext" ] || [ -L "$dir/$stem ($n)$ext" ]; do
                n=$((n + 1))
            done

            new_path="$dir/$stem ($n)$ext"
            if touch -- "$new_path" 2>/dev/null; then
                printf '%s\n' "$new_path" > "$out"
            else
                # Cancel rather than overwrite.
                rm -f -- "$out"
            fi
        fi
    fi
fi

if [ "$directory" = "1" ]; then
    if [ ! -s "$out" ] && [ -s "$out"".1" ]; then
        cat "$out"".1" > "$out"
        rm "$out"".1"
    else
        rm "$out"".1"
    fi
fi
