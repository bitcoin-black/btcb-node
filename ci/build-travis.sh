#!/bin/bash

qt_dir=${1}
src_dir=${2}

set -o errexit
set -o nounset
set -o xtrace
OS=`uname`

# This is to prevent out of scope access in async_write from asio which is not picked up by static analysers
if [[ $(grep -rl --exclude="*asio.hpp" "asio::async_write" ./nano) ]]; then
    echo "using boost::asio::async_write directly is not permitted (except in nano/lib/asio.hpp). Use nano::async_write instead"
    exit 1
fi

# prevent unsolicited use of std::lock_guard & std::unique_lock outside of allowed areas
if [[ $(grep -rl --exclude={"*random_pool.cpp","*random_pool.hpp","*locks.hpp","*locks.cpp"} "std::unique_lock\|std::lock_guard\|std::condition_variable" ./nano) ]]; then
    echo "using std::unique_lock, std::lock_guard or std::condition_variable is not permitted (except in nano/lib/locks.hpp and non-nano dependent libraries). Use the nano::* versions instead"
    exit 1
fi

mkdir build
pushd build

if [[ ${RELEASE-0} -eq 1 ]]; then
    BUILD_TYPE="RelWithDebInfo"
else
    BUILD_TYPE="Debug"
fi

if [[ ${ASAN_INT-0} -eq 1 ]]; then
    SANITIZERS="-DBTCB_ASAN_INT=ON"
elif [[ ${ASAN-0} -eq 1 ]]; then
    SANITIZERS="-DBTCB_ASAN=ON"
elif [[ ${TSAN-0} -eq 1 ]]; then
    SANITIZERS="-DBTCB_TSAN=ON"
else
    SANITIZERS=""
fi

ulimit -S -n 8192

if [[ "$OS" == 'Linux' ]]; then
    ROCKSDB="-DROCKSDB_LIBRARIES=/tmp/rocksdb/lib/librocksdb.a \
    -DROCKSDB_INCLUDE_DIRS=/tmp/rocksdb/include"
else
    ROCKSDB=""
fi


cmake \
    -G'Unix Makefiles' \
    -DACTIVE_NETWORK=btcb_test_network \
    -DBTCB_TEST=ON \
    -DBTCB_GUI=ON \
    -DBTCB_ROCKSDB=ON \
    ${ROCKSDB} \
    -DBTCB_WARN_TO_ERR=ON \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DBOOST_ROOT=/tmp/boost/ \
    -DQt5_DIR=${qt_dir} \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    ${SANITIZERS} \
    ..

if [[ "$OS" == 'Linux' ]]; then
    cmake --build ${PWD} -- -j2
else
    sudo cmake --build ${PWD} -- -j2
fi

popd

./ci/test.sh ./build
