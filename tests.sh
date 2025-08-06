#! /usr/bin/env bash

tests_json () {
  local json sed json_d all basename script quiet i res expected
  i='1'
  json_d='data/json'
  script="${1}"
  readonly json_d script

  set -f
  set -- ${@:2}
  set +f

  while [[ "${#}" -gt 0 ]]
  do
    case "${1}" in
    ( --all ) all='yes' ;;
    ( --fast ) all='' ;;
    ( --skip ) return 0 ;;
    ( --quiet ) quiet='yes' ;;
    ( --verbose ) quiet='' ;;
    ( * ) printf 'Unknown json validator test option: "%s"' "${1}" >&2; exit 1 ;;
    esac
    shift
  done

  readonly all

  for json in "${json_d}"/*.json
  do
    basename="$(basename "${json}")"
    case "${json}" in
    ( "${json_d}/n_structure_100000_opening_arrays.json" ) ;& # This test spends 21m to complete successfully
    ( "${json_d}/n_structure_open_array_object.json" ) # This test spends 85m to complete successfully
      if [[ "${all}" == 'yes' ]]
      then
        null='yes'
      else
        printf '[\033[38;5;6mSKIPPED\033[m] %s > %s\n' "${script}" "${basename}"
        continue
      fi ;;
    ( "${json_d}/n_structure_null-byte-outside-string.json" ) ;&
    ( "${json_d}/n_multidigit_number_then_00.json" ) null='' ;;
    ( * ) null='yes' ;;
    esac

    coproc CAT {
      cat
    }

    printf 'TEST n°%d\n' "${i}"

    unset code
    local code
    code='0'

    if [[ -s "${json}" ]]
    then
      # LC_CTYPE is necessary for UTF-8 support
      case "${quiet}" in
      ( 'yes' ) LC_CTYPE='C' sed "${null:+--null-data}" --quiet --file "${script}" "${json}" > /dev/null 2>&1 || code="${?}" ;;
      ( * ) LC_CTYPE='C' sed "${null:+--null-data}" --quiet --file "${script}" "${json}" || code="${?}" ;;
      esac
    else
      case "${quiet}" in
      ( 'yes' ) printf '\n' | sed --quiet --file "${script}" > /dev/null 2>&1 || code="${?}" ;;
      ( * ) printf '\n' | sed --quiet --file "${script}" || code="${?}" ;;
      esac
    fi >&${CAT[1]} 2>&1

    case "${code}" in
    ( 0 ) res='\033[38;5;2mOK\033[m' ;;
    ( * ) res='\033[38;5;1mKO\033[m' ;;
    esac

    case "${basename}" in
    ( y_* ) expected='\033[38;5;2mOK\033[m' ;;
    ( n_* ) expected='\033[38;5;1mKO\033[m' ;;
    ( * ) expected='\033[38;5;5mFREE\033[m' ;;
    esac

    printf '  EXPECTED: %b\n  RESULT: %b\n  SCRIPT: %s\n  JSON: %s\n  OUTPUT:\n' "${expected}" "${res}" "${script}" "${basename}"

    exec {CAT[1]}>&-
    sed -z 's/^/    >> /g' <&${CAT[0]}

    printf '\n'

    case "${code}${basename}" in
    ( [1-9]y_* ) printf '  \033[38;5;1m%s must be accepted\033[m\n' "${basename}"; exit 1 ;;
    ( 0n_* ) printf '  \033[38;5;1m%s must be refused\033[m\n' "${basename}"; exit 1 ;;
    ( * ) ;;
    esac

    (( i++ ))
  done
}

tests () {
  set -e -u -C
  set -o pipefail
  shopt -s lastpipe

  local -A opts
  opts[json_validator]='--fast --quiet'
  opts[json_pp]='--fast --quiet'

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
      opts[json_validator]="${opts[json_validator]} --${1//,/ --}" ;;
    ( --json-pp )
      shift
      if [[ -z "${1:-}" ]]
      then
        printf 'The "--json-pp" option takes 1 argument\n' >&2
        exit 1
      fi
      opts[json_pp]="${opts[json_pp]} --${1//,/ --}" ;;
    ( * ) printf 'Unknown option: "%s"' "${1}" >&2; exit 1 ;;
    esac
    shift
  done

  tests_json 'scripts/json/validator.sed' "${opts[json_validator]}"
  tests_json 'scripts/json/pretty-printer.sed' "${opts[json_pp]}"
}

tests "${@}"
