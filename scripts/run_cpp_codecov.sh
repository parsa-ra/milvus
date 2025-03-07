#!/usr/bin/env bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
ROOT_DIR="$( cd -P "$( dirname "$SOURCE" )/.." && pwd )"

MILVUS_CORE_DIR="${ROOT_DIR}/internal/core/"
MILVUS_CORE_UNITTEST_DIR="${MILVUS_CORE_DIR}/output/unittest/"

echo "ROOT_DIR = ${ROOT_DIR}"
echo "MILVUS_CORE_DIR = ${MILVUS_CORE_DIR}"
echo "MILVUS_CORE_UNITTEST_DIR = ${MILVUS_CORE_UNITTEST_DIR}"

LCOV_CMD="lcov"
LCOV_GEN_CMD="genhtml"

FILE_INFO_BASE="${ROOT_DIR}/lcov_base.info"
FILE_INFO_UT="${ROOT_DIR}/lcov_ut.info"
FILE_INFO_COMBINE="${ROOT_DIR}/lcov_combine.info"
FILE_INFO_OUTPUT="${ROOT_DIR}/lcov_output.info"
DIR_LCOV_OUTPUT="${ROOT_DIR}/cpp_coverage"
DIR_GCNO="${ROOT_DIR}/cmake_build/"

# delete old code coverage info files
rm -f ${FILE_INFO_BASE}
rm -f ${FILE_INFO_UT}
rm -f ${FILE_INFO_COMBINE}
rm -f ${FILE_INFO_OUTPUT}
rm -rf ${DIR_LCOV_OUTPUT}

# generate baseline
${LCOV_CMD} -c -i -d ${DIR_GCNO} -o ${FILE_INFO_BASE}
if [ $? -ne 0 ]; then
    echo "gen baseline coverage run failed"
    exit -1
fi

# run unittest
for test in `ls ${MILVUS_CORE_UNITTEST_DIR}`; do
    echo "${MILVUS_CORE_UNITTEST_DIR}/$test"
    # run unittest
    ${MILVUS_CORE_UNITTEST_DIR}/${test}
    if [ $? -ne 0 ]; then
        echo ${args}
        echo ${${MILVUS_CORE_UNITTEST_DIR}/}/${test} "run failed"
        exit -1
    fi
done

# generate ut file
${LCOV_CMD} -c -d ${DIR_GCNO} -o ${FILE_INFO_UT}

# merge baseline and ut file
${LCOV_CMD} -a ${FILE_INFO_BASE} -a ${FILE_INFO_UT} -o ${FILE_INFO_COMBINE}

# remove unnecessary info
${LCOV_CMD} -r "${FILE_INFO_COMBINE}" -o "${FILE_INFO_OUTPUT}" \
    "/usr/*" \
    "*/src/pb/*" \
    "*/src/core/bench/*" \
    "*/faiss_ep-prefix/*" \
    "*/boost/*" \
    "*/unittest/*" \
    "*/thirdparty/*"

# generate html report
${LCOV_GEN_CMD} ${FILE_INFO_OUTPUT} --output-directory ${DIR_LCOV_OUTPUT}/


