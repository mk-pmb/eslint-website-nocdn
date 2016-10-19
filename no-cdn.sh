#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-
SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"


function nocdn () {
  cd "$SELFPATH" || return $?
  local HTDOCS_SUBDIR='/eslint-website-nocdn/'

  export LANG{,UAGE}=en_US.UTF-8

  local CDN_FILES=()
  local CDN_PREFIX_RGX='/eslint-website-3rd-party/'
  CDN_PREFIX_RGX+=$'\n''//cdnjs.cloudflare.com/'

  readarray -t CDN_FILES < <(git grep -lFe "$CDN_PREFIX_RGX" \
    | grep -xvPe '\S+\.sh')
  [ -n "${CDN_FILES[0]}" ] || return 3$(
    echo 'E: cannot find any files referencing known CDNs.' >&2)

  local MOD_FILES=( "${CDN_FILES[@]}"
    _includes/*.html
    )
  git checkout master -- "${MOD_FILES[@]}" || return $?

  CDN_PREFIX_RGX="$(<<<"${CDN_PREFIX_RGX//$'\n'/\|}" sed -re '
    s~[^A-Za-z0-9/|]~\\&~g')"
  local NOCDN_SED='
    s~[\r\a]+~~g
    s~(\x22|\x27|\s)(https?:|)('"$CDN_PREFIX_RGX"')~\1\a~g
    s~(\a(ajax))/(libs)/~\1-\3/~g
    s~\a~/eslint-website-3rd-party/~
    '
  sed -re "$NOCDN_SED" -i -- "${CDN_FILES[@]}" || return $?

  sed -re '
    s~[\r\a]+~~g
    s~(( href=| src=)(\x22|\x27))/~\1\a/~g
    s~\a/([a-z][a-z0-9_-]*/)~'"$HTDOCS_SUBDIR"'\1~g
    s~\a~~g
    /stylesheet/{p;s~(/)main(\.css)~\1no-cdn\2~}
    ' -i -- _includes/*.html || return $?

  git add -- "${MOD_FILES[@]}" || return $?
  git diff master -- "${MOD_FILES[@]}" || return $?
  return 0
}










nocdn "$@"; exit $?
