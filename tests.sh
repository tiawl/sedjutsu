#! /usr/bin/env bash

tests_json () {
  local json sed json_d all basename script quiet
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
    ( --fast ) all='no' ;;
    ( --skip ) return 0 ;;
    ( --quiet ) quiet='yes' ;;
    ( --verbose ) quiet='no' ;;
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
    ( "${json_d}"'/n_structure_100000_opening_arrays.json' ) ;&
    ( "${json_d}"'/n_structure_open_array_object.json' )
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
    ( "${json_d}"'/n_structure_single_eacute.json' ) ;&
    ( "${json_d}"'/n_structure_incomplete_UTF8_BOM.json' ) ;&
    ( "${json_d}"'/n_structure_lone-invalid-utf-8.json' ) ;&
    ( "${json_d}"'/n_string_invalid_utf8_after_escape.json' ) ;&
    ( "${json_d}"'/n_string_invalid-utf-8-in-escape.json' ) ;&
    ( "${json_d}"'/n_object_lone_continuation_byte_in_key_and_trailing_comma.json' ) ;&
    ( "${json_d}"'/n_number_real_with_invalid_utf8_after_e.json' ) ;&
    ( "${json_d}"'/n_number_invalid-utf-8-in-bigger-int.json' ) ;&
    ( "${json_d}"'/n_number_invalid-utf-8-in-exponent.json' ) ;&
    ( "${json_d}"'/n_number_invalid-utf-8-in-int.json' ) ;&
    ( "${json_d}"'/n_array_invalid_utf8.json' ) ;&
    ( "${json_d}"'/n_array_a_invalid_utf8.json' ) ;&
    ( "${json_d}"'/i_string_invalid_utf-8.json' ) ;&
    ( "${json_d}"'/i_string_iso_latin_1.json' ) ;&
    ( "${json_d}"'/i_string_lone_utf8_continuation_byte.json' ) ;&
    ( "${json_d}"'/i_string_overlong_sequence_2_bytes.json' ) ;&
    ( "${json_d}"'/i_string_overlong_sequence_6_bytes.json' ) ;&
    ( "${json_d}"'/i_string_overlong_sequence_6_bytes_null.json' ) ;&
    ( "${json_d}"'/i_string_truncated-utf-8.json' ) ;&
    ( "${json_d}"'/i_string_UTF-16LE_with_BOM.json' ) ;&
    ( "${json_d}"'/i_string_UTF-8_invalid_sequence.json' )
      printf '[\033[38;5;6mSKIPPED\033[m] %s > %s\n          \033[38;5;5m=> SED does not handle characters in this file\033[m\n' "${script}" "${basename}"
      continue ;;
    ( * ) sed='sed --null-data' ;;
    esac

    unset code
    local code
    code='0'

    case "${quiet}" in
    ( 'yes' ) ${sed} --quiet --file "${script}" "${json}" > /dev/null 2>&1 || code="${?}" ;;
    ( 'no' ) ${sed} --quiet --file "${script}" "${json}" || code="${?}" ;;
    ( * ) printf 'Reached unreachable code\n' >&2; exit 1 ;;
    esac

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
