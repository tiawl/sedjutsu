#! /usr/bin/env bash

tests () {
  set -e -u -C
  set -o pipefail
  shopt -s lastpipe

  local json ok

  for json in tests/*
  do
    if cat "${json}" | sed -z -f scripts/json/validator.sed > /dev/null 2>&1
    then
      printf '[\033[38;5;1mKO\033[m\n] %s' "$(basename "${json}")"
      ok='true'
    else
      printf '[\033[38;5;2mOK\033[m\n] %s' "$(basename "${json}")"
      ok='false'
    fi
    case "${ok}${json}" in
    ( falsey_* ) printf '%s must be accepted\n'; exit 1 ;;
    ( truen_* ) printf '%s must be refused\n'; exit 1 ;;
    ( * ) ;;
    esac
  done
}

tests "${@}"
