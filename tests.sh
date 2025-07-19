#! /usr/bin/env bash

tests_json () {
  local json sed json_d all basename script
  json_d='data/json'
  script="${1}"
  all='no'
  readonly json_d script

  shift

  while [[ "${#}" -gt 0 ]]
  do
    case "${1}" in
    ( --all ) all='yes' ;;
    ( --fast ) all='no' ;;
    ( --skip ) return 0 ;;
    ( * ) printf 'Unknown json validator test option: "%s"' "${1}" >&2; exit 1 ;;
    esac
    shift
  done

  readonly all

  for json in "${json_d}"/*.json
  do
    basename="$(basename "${json}")"
    case "${json}" in
    # These tests spend 21m and 85m respectively to complete successfully
    ( "${json_d}"'/n_structure_100000_opening_arrays.json'|"${json_d}"'/n_structure_open_array_object.json' )
      if [[ "${all}" == 'yes' ]]
      then
        sed='sed --null-data'
      else
        printf '[\033[38;5;6mSKIPPED\033[m] %s > %s\n' "${script}" "${basename}"
        continue
      fi ;;
    ( "${json_d}"'/n_multidigit_number_then_00.json' ) sed='sed' ;;
    ( "${json_d}"'/n_structure_no_data.json' )
      printf '[\033[38;5;2mOK\033[m] %s > n_structure_no_data.json\n     \033[38;5;5m=> SED does not operate on empty files\033[m\n' "${script}"
      continue ;;
    ( * ) sed='sed --null-data' ;;
    esac

    unset code
    local code
    code='0'

    ${sed} --quiet --file "${script}" "${json}" > /dev/null 2>&1 || code="${?}"

    if [[ "${code}" -eq 0 ]]
    then
      printf '[\033[38;5;2mOK\033[m] %s > %s\n' "${script}" "${basename}"
    else
      printf '[\033[38;5;1mKO\033[m] %s > %s\n' "${script}" "${basename}"
    fi

    case "${code}${basename}" in
    ( [1-9]y_* ) printf '\033[38;5;1m%s must be accepted\033[m\n' "${basename}"; exit 1 ;;
    ( 0n_* ) printf '\033[38;5;1m%s must be refused\033[m\n' "${basename}"; exit 1 ;;
    ( * ) ;;
    esac
  done
}

tests () {
  set -e -u -C
  set -o pipefail
  shopt -s lastpipe

  local -A opts
  opts[json_validator]='--fast'
  opts[json_pp]='--fast'

  while [[ "${#}" -gt 0 ]]
  do
    case "${1}" in
    # Handle '--file=file1' the same as '--file file1' for long-form 1-arg options
    ( --json-validator=*|--json-pp=* ) set -- "${1%%=*}" "${1#*=}" "${@:2}"; continue ;;

    ( --json-validator )
      shift
      if [[ -z "${1:-}" ]]
      then
        printf 'The "--json-validator" option takes 1 argument\n' >&2
        exit 1
      fi
      opts[json_validator]="--${1}" ;;
    ( --json-pp )
      shift
      if [[ -z "${1:-}" ]]
      then
        printf 'The "--json-pp" option takes 1 argument\n' >&2
        exit 1
      fi
      opts[json_pp]="--${1}" ;;
    ( * ) printf 'Unknown option: "%s"' "${1}" >&2; exit 1 ;;
    esac
    shift
  done

  tests_json 'scripts/json/validator.sed' "${opts[json_validator]}"
  tests_json 'scripts/json/pretty-printer.sed' "${opts[json_pp]}"
}

tests "${@}"
