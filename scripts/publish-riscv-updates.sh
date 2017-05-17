#! /bin/bash

# This script runs on Mac OS X and is intended to
# publish the ilg.gnumcueclipse.riscv-repository site
# to Bintray:
#
# https://bintray.com/gnu-mcu-eclipse/updates/p2
# https://bintray.com/gnu-mcu-eclipse/updates-test/p2
# https://bintray.com/gnu-mcu-eclipse/updates-experimental/p2
#
# and SourceForge File Release System (FRS):
#
# https://sourceforge.net/projects/gnuarmeclipse/files/Eclipse/


TEST=""

if [ $# -gt 0 ] && [ "$1" = "test" ]
then
  TEST="-test"
  shift
elif [ $# -gt 0 ] && [ "$1" = "experimental" ]
then
  TEST="-experimental"
  shift
fi

SF_FOLDER="Eclipse/updates"

echo "Updating $SF_FOLDER$TEST"

if [ $# -gt 0 ] && [ "$1" == "dry" ]
then
  DRY="dry"
  shift
  echo "Dry run"
fi

if [ $# -gt 0 ] && [ "$1" == "force" ]
then
  FORCE="force"
  shift
  echo "Force write"
fi

CURL_OPTS=-#

# -----------------------------------------------------------------------------

# POST /packages/:subject/:repo/:package/versions
# {
#   "name": "1.1.5",
#   "released": "ISO8601 (yyyy-MM-dd'T'HH:mm:ss.SSSZ)", (optional)
#   "desc": "This version...",
#   "github_release_notes_file": "RELEASE.txt", (optional)
#   "github_use_tag_release_notes": true, (optional)
#   "vcs_tag": "1.1.5" (optional)
# }

# $1 = repo 
# $2 = package
# $3 = version
do_create_version()
{
  local repo="$1"
  local package="$2"
  local version="$3"

  echo "Create version '${repo}/${package}/${version}'"

  local tmp_path="$(mktemp)"
  # Note: EOF is not quoted to allow local substitutions.
  cat <<__EOF__ >"${tmp_path}"
{ 
  "name": "${version}"
}
__EOF__

  local ret="$(curl ${CURL_OPTS} \
    --request POST \
    --user ${BINTRAY_USER}:${BINTRAY_API_KEY} \
    --header "Content-Type: application/json" \
    --data @"${tmp_path}" \
    "${API}/packages/${BINTRAY_OWNER}/${repo}/${package}/versions")"

  if [ "${ret:0:8}" == '{"name":' ]
  then
    echo "Created."
  else
    echo "${ret}"
    failure="-y"
  fi

  rm "${tmp_path}"

  echo
}

# X-Bintray-Package: :package
# X-Bintray-Version: :version
# [X-Bintray-Publish: 0/1]
# [X-Bintray-Override: 0/1]
# [X-Bintray-Explode: 0/1]
# PUT /content/:subject/:repo/:file_path

# $1 = file absolute path
# $2 = repo 
# $3 = package
# $4 = version
# $5 = file relative path
do_upload_to_pv_header()
{
  local file_absolute_path="$1"
  local repo="$2"
  local package="$3"
  local version="$4"
  local file_relative_path="$5"

  echo "Upload '${file_relative_path}' to '/${repo}/${package}/${version}/'"
  local ret="$(curl ${CURL_OPTS} \
    --request PUT \
    --upload-file "${file_absolute_path}" \
    --user ${BINTRAY_USER}:${BINTRAY_API_KEY} \
    --header "X-Bintray-Package: ${package}" \
    --header "X-Bintray-Version: ${version}" \
    --header "X-Bintray-Publish: 0" \
    --header "X-Bintray-Override: 1" \
    --header "X-Bintray-Explode: 0" \
    "${API}/content/${BINTRAY_OWNER}/${repo}/${file_relative_path}")"

  if [ "${ret}" == '{"message":"success"}' ]
  then
    echo "Uploaded."
  else
    failure="-y"
    echo "${ret}"
  fi
}

# POST /content/:subject/:repo/:package/:version/publish
# $1 = repo 
# $2 = package
# $3 = version
do_publish()
{
  local repo="$1"
  local package="$2"
  local version="$3"

  echo "Publish '${repo}/${package}/${version}'"
  curl ${CURL_OPTS} \
    --request POST \
    --user ${BINTRAY_USER}:${BINTRAY_API_KEY} \
    --header "Content-Type: application/json" \
    -d "{ \"publish_wait_for_secs\": -1, \"discard\": \"false\" }" \
    "${API}/content/${BINTRAY_OWNER}/${repo}/${package}/${version}/publish"

  echo 
}

# $1 = repo name
# $2 = full version 
do_upload_to_bintray()
{
  local repo="$1"
  local package="p2"
  local version="$2"
  failure=""
  do_create_version "${repo}" "${package}" "${version}"

  for f in *.* */*
  do
    if [ -z "${failure}" ]
    then
      do_upload_to_pv_header "$(pwd)/${f}" "${repo}" "${package}" "${version}" "${f}"
    fi
  done

  if [ -z "${failure}" ]
  then
    do_publish "${repo}" "${package}" "${version}"
  fi

  echo
}

# -----------------------------------------------------------------------------

BINTRAY_USER=ilg-ul
BINTRAY_OWNER=gnu-riscv-eclipse

API=https://api.bintray.com

echo
echo "User: ${BINTRAY_USER}"
echo "API key: ${BINTRAY_API_KEY}"
echo "Owner: ${BINTRAY_OWNER}"

# -c skip based on checksum, not mod-time & size

if [ ! -d ../ilg.gnumcueclipse.riscv-repository/target/repository ]
then
  echo "No repository folder found"
  exit 1
fi

cd ../ilg.gnumcueclipse.riscv-repository/target

FULL_VERSION="$(grep "unit id='ilg.gnumcueclipse.core'" targetPlatformRepository/content.xml | sed "s/.*version='\(.*\)'.*/\1/")"
(cd repository; do_upload_to_bintray "updates${TEST}" "${FULL_VERSION}")

if [ "${TEST}" == "-test" ]
then
  echo "Published on the test site."
elif [ "${TEST}" == "-experimental" ]
then
  echo "Published on the experimental site."
else
  echo "Published on the main site."
fi

if [ -f *-SNAPSHOT.zip ]
then
  NUMDATE=$(ls repository/plugins/ilg.gnumcueclipse.core* | sed -e 's/.*_[0-9]*[.][0-9]*[.][0-9]*[.]\([0-9]*\)[.]jar/\1/')
  ARCHIVE_PREFIX=$(ls *-SNAPSHOT.zip | sed -e 's/\(.*\)-SNAPSHOT[.]zip/\1/')

  ARCHIVE_FOLDER="../../../archive"
  if [ "${TEST}" != "" ]
  then
    ARCHIVE_FOLDER="${ARCHIVE_FOLDER}/internal"
  else
    ARCHIVE_FOLDER="${ARCHIVE_FOLDER}/releases/plug-ins"
  fi
  
  mkdir -p "${ARCHIVE_FOLDER}"

  P="${ARCHIVE_FOLDER}/${ARCHIVE_PREFIX}-${NUMDATE}.zip"
  AP="$(cd "$(dirname "${P}")"; pwd)/$(basename "${P}")"

  mv -f "${ARCHIVE_PREFIX}-SNAPSHOT.zip" "${AP}"
  (cd "${ARCHIVE_FOLDER}"; shasum -a 256 -p "${AP}" >"${AP}.sha")

  echo "Archive available from \"${AP}\""
fi

if [ "${TEST}" != "" ]
then
  echo "When final, don't forget to publish the archive too!"
fi

