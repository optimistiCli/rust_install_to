#!/bin/bash

DEST="$1"

if [ -z "$DEST" ] ; then
    echo "Error: No destination path" >&2
    exit 1
fi

if [ -e "$DEST" ] ; then
    echo "Error: Destination path already exists >>>$DEST<<<" >&2
    exit 1
fi

if ! mkdir -p "$DEST" ; then
    echo "Error: Can not create destination dir >>>$DEST<<<" >&2
    exit 1
fi

REAL_DEST="$(cd "$(echo "$DEST" | sed "s ^~/ ${HOME}/ ")" ; pwd -P)"

if which realpath >/dev/null 2>/dev/null ; then
    REAL_DEST="$(realpath "$DEST")"
else
    REAL_DEST="$(cd "$DEST" ; pwd -P)"
fi

RUSTUP_INIT="${REAL_DEST}/rustup-init"

export RUSTUP_INIT_SKIP_PATH_CHECK=yes
export RUSTUP_HOME="${REAL_DEST}/rustup"
export CARGO_HOME="${REAL_DEST}/cargo"

curl \
	--proto '=https' \
	--tlsv1.2 \
	-o "$RUSTUP_INIT" \
	-sSf https://sh.rustup.rs

if ! ls -1 "$RUSTUP_INIT" >/dev/null 2>/dev/null ; then
    echo "Error: rustup-init download failed >>>$RUSTUP_INIT<<<" >&2
    exit 1
fi

chmod a+x "$RUSTUP_INIT"

${RUSTUP_INIT} -y --no-modify-path

cat >"${REAL_DEST}/activate" <<EOF
HIST="\$(history 1)"
SCRIPT="\$(echo "\$HIST" | sed 's/^[[:blank:]]\{1,\}[[:digit:]]\{1,\}[[:blank:]]\{1,\}\.[[:blank:]]\{1,\}//')"

if [ "\$HIST" = "\$SCRIPT" ] ; then
    echo "This script must be sourced, not run" >&2
else
    RUST="\$(cd "\$(dirname "\$SCRIPT" | sed "s ^~/ \${HOME}/ ")" ; pwd -P)"
    RUSTUP_HOME="\${RUST}/rustup"
    CARGO_HOME="\${RUST}/cargo"
    
    if [ -d "\$RUSTUP_HOME" -a -d "\$CARGO_HOME" ] ; then
        export RUSTUP_HOME CARGO_HOME
        BIN="\${CARGO_HOME}/bin:"
        if ! echo "\$PATH" | grep -q "\$BIN" ; then
            export PATH="\${BIN}\${PATH}"
        fi
    else
        echo "Cargo dirs not found" >&2
    fi
fi
EOF