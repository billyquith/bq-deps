#! /usr/bin/env bash
# Build and install various libraries.
# >> ilib LIB
# >> ilib all   # install all

WHAT=$1

# libraries that are dependencies (and independent of each other)
LDEPS="eastl cppformat"

ALL="$LDEPS"

if [ -z $WHAT ]; then
    echo "what? ($ALL)"
    exit 1
fi

THISDIR="$(cd $(dirname $0) ; pwd -P)"
INST=$THISDIR/inst
IDEPS=$INST/deps
BUILDN=build_ninja

function run_test {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "error with $1" >&2
        exit 1
    fi
    return $status
}

function ensure_dir {
    echo "Ensuring $1"
    if [ ! -d $1 ]; then
        mkdir -p $1
    fi
}

function check_inst
{
    local root=$1
    ensure_dir $root/include
    ensure_dir $root/lib
    ensure_dir $root/share
    ensure_dir $root/doc
}

function check_roots
{
    check_inst $IDEPS
    check_inst $IOWN
}

#####################################################################
# install

function install_eastl
{
    pushd ext/eastl
    ensure_dir $BUILDN
    cd $BUILDN
    cmake -DCMAKE_INSTALL_PREFIX=$IDEPS -DEASTL_BUILD_TESTS=ON -G "Ninja" ..
    cmake --build . --config RelWithDebInfo
    pushd test
    run_test ctest -C RelWithDebInfo
    popd
    ninja install
    ninja clean
    popd
}

function install_cppformat
{
    pushd ext/cppformat
    ensure_dir $BUILDN
    pushd $BUILDN
    # -DFMT_DOC=ON
    cmake -DCMAKE_INSTALL_PREFIX=$IDEPS \
        -DFMT_INSTALL=ON -DFMT_TEST=ON \
        -G "Ninja" ..
    cmake --build . --config RelWithDebInfo
    pushd test
    run_test ctest -C RelWithDebInfo
    popd
    # ninja doc
    ninja install
    ninja clean
    popd
    rm -r $BUILDN
    popd
}

function install_all
{
    echo "Removing all exisiting installed libraries..."
    rm -r $INST
    check_roots
    for lib in $ALL
    do
        install_$lib
    done
    du -h $INST
}

check_roots
install_$WHAT

