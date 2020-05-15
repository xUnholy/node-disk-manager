#!/usr/bin/env bash
#
# This script builds the application from source for multiple platforms.
set -e

# Get the git commit
getGitCommit()
{
    if [ -f "$GOPATH"/src/github.com/openebs/node-disk-manager/GITCOMMIT ];
    then
	GIT_COMMIT="$(cat "$GOPATH"/src/github.com/openebs/node-disk-manager/GITCOMMIT)"
    else
	GIT_COMMIT="$(git rev-parse HEAD)"
    fi
    echo "${GIT_COMMIT}"
}

# Delete the old contents
deleteOldContents(){
    rm -rf bin/*
    mkdir -p bin/

    echo "Successfully deleted old bin contents"
}

# Move all the compiled things to the $GOPATH/bin
moveCompiled(){
    GOPATH=${GOPATH:-$(go env GOPATH)}
    case $(uname) in
        CYGWIN*)
            GOPATH="$(cygpath "$GOPATH")"
            ;;
    esac
    OLDIFS=$IFS
    IFS=: MAIN_GOPATH=("$GOPATH")
    IFS=$OLDIFS

    # Create the gopath bin if not already available
    mkdir -p "${MAIN_GOPATH[*]}"/bin/

    # Copy our OS/Arch to ${MAIN_GOPATH}/bin/ directory
    DEV_PLATFORM="./bin/"
    DEV_PLATFORM_OUTPUT=$(find "${DEV_PLATFORM}" -mindepth 1 -maxdepth 1 -type f)
    for F in ${DEV_PLATFORM_OUTPUT}; do
        cp "${F}" "${MAIN_GOPATH[*]}"/bin/
    done

    echo "Moved all the compiled things successfully to :${MAIN_GOPATH[*]}/bin/"
}

# Build
build(){
    output_name="bin/$CTLNAME"
    echo "Building for: ${GOOS} ${GOARCH}"
    gox -cgo -os="$GOOS" -arch="$GOARCH" -ldflags \
        "-X github.com/openebs/node-disk-manager/pkg/version.GitCommit=${GIT_COMMIT} \
        -X main.CtlName='${CTLNAME}' \
        -X github.com/openebs/node-disk-manager/pkg/version.Version=${VERSION}" \
        -output="$output_name" \
        ./cmd/"$BUILDPATH"
    echo "Successfully built: ${CTLNAME}"
}

# Main script starts here .......
export CGO_ENABLED=1

# Get the parent directory of where this script is.
SOURCE="${BASH_SOURCE[*]}"

while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )/../" && pwd )"

# Change into that directory
cd "$DIR"

# Get the git commit
GIT_COMMIT=$(getGitCommit)

# Get the version details. By default set as ci.
VERSION="ci"

if [ -n "${TRAVIS_TAG}" ] ;
then
  # When github is tagged with a release, then Travis will
  # set the release tag in env TRAVIS_TAG
  VERSION="${TRAVIS_TAG}"
fi;

echo "==> Removing old bin contents..."
deleteOldContents

# Build!
echo "==> Building ${CTLNAME} ..."
build

# Move all the compiled things to the $GOPATH/bin
moveCompiled

ls -hl bin
