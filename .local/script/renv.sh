#!/usr/bin/env bash

RENV_ROOT="${RENV_ROOT:-$HOME/.renv}"
RENV_VERSIONS="$RENV_ROOT/versions"
RENV_GLOBAL="$RENV_ROOT/global"
RENV_ARCHIVE="$RENV_ROOT/archive"
RENV_BIN="$RENV_ROOT/bin"
RENV_VERSON="0.1.0"

print_usage() {
    cat <<EOF
Usage: renv <command> [<args>]

Some useful renv commands are:
   install      Install an R version
   uninstall    Uninstall R version
   versions     List all installed R versions
   global       Set or show the global R version
   local        Set or show the local R version
   version      Show the current R version and its origin
   which        Display the full path to the R executable
   root         Display the renv root directory
   help         Show this help message
   --version    Show renv script version

Becareful: renv is a simple R version manager, not a full-fledged package manager.And it is only support version 4

See \`renv help <command>\` for information on a specific command.
EOF
}

mkdir -p "$RENV_VERSIONS"
mkdir -p "$RENV_ARCHIVE"
mkdir -p "$RENV_BIN"

case "$1" in
    install)
        shift
        VERSION="$1"
        if [ -z "$VERSION" ]; then
            echo "Usage: renv install <version>"
            exit 1
        fi
        # 检查是否已安装该版本
        if [ -d "$RENV_VERSIONS/$VERSION" ]; then
            echo "R version $VERSION is already installed."
            exit 0
        fi
        # wget 静默下载
        if [ ! -d "$RENV_ARCHIVE/R-$VERSION" ];then
            echo "Downloading R version $VERSION..."
            wget "https://cran.r-project.org/src/base/R-4/R-$VERSION.tar.gz"  -O "$RENV_ARCHIVE/R-$VERSION.tar.gz" || {
                echo "Failed to download R version $VERSION"
                exit 1
            }
        else
            echo "Using archived package."
        fi
        echo "Extracting R version $VERSION..."
        tar --use-compress-program=pigz -xvpf "$RENV_ARCHIVE/R-$VERSION.tar.gz" -C "$RENV_ARCHIVE/" || {
            echo "Failed to extract R version $VERSION"
            exit 1
        }
        cd "$RENV_ARCHIVE/R-$VERSION/"
        echo "Configuring R version $VERSION..."
        "$RENV_ARCHIVE/R-$VERSION/configure" --enable-R-shlib --prefix="$RENV_VERSIONS/$VERSION" || {
            echo "Failed to configure R version $VERSION"
            exit 1
        }
        make clean
        echo "Compiling R version $VERSION..."
        make -j$(nproc) || {
            echo "Failed to compile R version $VERSION"
            exit 1
        }
        echo "Installing R version $VERSION..."
        make install || {
            echo "Failed to install R version $VERSION"
            exit 1
        }
        echo "R version $VERSION installed successfully."
        exit 0
        ;;
    uninstall)
        shift
        VERSION="$1"
        if [ -z "$VERSION" ]; then
            echo "Usage: renv uninstall <version>"
            exit 1
        fi
        if [ ! -d "$RENV_VERSIONS/$VERSION" ]; then
            echo "R version $VERSION is not installed."
            exit 1
        fi
        cd "$RENV_ARCHIVE/R-$VERSION"
        make uninstall
        rm -rf "$RENV_VERSIONS/$VERSION"
        echo "R version $VERSION uninstalled successfully."
        exit 0
        ;;
    versions)
        for dir in "$RENV_VERSIONS"/*; do
            if [ -d "$dir" ]; then
                version=$(basename "$dir")
                if [[ $version == $(cat $RENV_GLOBAL) ]];then
                    version="* $version"
                else
                    version="  $version"
                fi
                echo "$version"
            fi
        done
        exit 0
        ;;
    global)
        shift
        if [ -z "$1" ]; then
            echo "Usage: renv global <version>"
            exit 1
        fi
        if [ ! -d "$RENV_VERSIONS/$1" ]; then
            echo "R version $1 is not installed."
            exit 1
        fi
        if [ -d "$RENV_BIN/R" ]; then
            rm -rf "$RENV_BIN/R"
        fi
        ln -s "$RENV_VERSIONS/$1/R" "$RENV_BIN" 2>/dev/null || {
            echo "Failed to set global R version to $1. Make sure it is installed."
            exit 1
        }
        echo $1 > "$RENV_GLOBAL"
        exit 0
        ;;
    local)
        shift
        if [ -z "$1" ]; then
            echo "Usage: renv local <version>"
            exit 1
        fi
        if [ -d "$RENV_VERSIONS/$1" ]; then
            echo "Please manual execute : export PATH=$RENV_VERSIONS/$1:\$PATH"
        fi
        ;;
    version)
        cat $RENV_GLOBAL 2>/dev/null || {
            echo "No global R version set. Use 'renv global <version>' to set one."
            exit 1
        }
        ;;
    which)
        if [ -L "$RENV_BIN/R" ]; then
            echo "$RENV_VERSIONS/$(cat $RENV_GLOBAL)/bin/R"
        else
            echo "No R version set. Use 'renv global <version>' to set one."
            exit 1
        fi
        ;;
    root)
        echo "$RENV_ROOT"
        ;;
    --version)
        echo "renv version $RENV_VERSON"
        ;;
    help|"")
        print_usage
        ;;
    *)
        echo "Unknown command: $1"
        print_usage
        exit 1
        ;;
esac