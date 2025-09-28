#! /usr/bin/env bash

tests_json () {
  local json sed json_d all basename script verbose res expected
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
    ( --quiet ) verbose='' ;;
    ( --verbose ) verbose='yes' ;;
    ( * ) printf 'Unknown json validator test option: "%s"' "${1}" >&2; exit 1 ;;
    esac
    shift
  done

  readonly all

  for json in "${json_d}"/*.json
  do
    unset code skipped
    local code skipped
    code='0'
    skipped=

    basename="$(basename "${json}")"
    case "${json}" in
    ( "${json_d}/n_structure_100000_opening_arrays.json" ) ;& # This test spends to much time to complete successfully
    ( "${json_d}/n_structure_open_array_object.json" ) # This test spends to much time to complete successfully
      if [[ "${all}" == 'yes' ]]
      then
        null='yes'
      else
        skipped='yes'
      fi ;;
    ( "${json_d}/n_structure_null-byte-outside-string.json" ) ;&
    ( "${json_d}/n_multidigit_number_then_00.json" ) null='' ;;
    ( * ) null='yes' ;;
    esac

    printf 'TEST n°%d\n' "${i}"

    if [[ -n "${skipped:-}" ]]
    then
      printf '  STATUS: \033[38;5;6mSKIPPED\033[m\n  SCRIPT: %s\n  JSON: %s\n\n' "${script}" "${basename}"
      (( i++ ))
      continue
    fi

    coproc CAT {
      cat
    }

    if [[ -s "${json}" ]]
    then
      # LC_CTYPE is necessary for UTF-8 support
      case "${verbose}" in
      ( 'yes' ) LC_CTYPE='C' sed "${null:+--null-data}" --quiet --file "${script}" "${json}" || code="${?}" ;;
      ( * ) LC_CTYPE='C' sed "${null:+--null-data}" --quiet --file "${script}" "${json}" > /dev/null 2>&1 || code="${?}" ;;
      esac
    else
      case "${verbose}" in
      ( 'yes' ) printf '\n' | sed --quiet --file "${script}" || code="${?}" ;;
      ( * ) printf '\n' | sed --quiet --file "${script}" > /dev/null 2>&1 || code="${?}" ;;
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

    printf '  EXPECTED: %b\n  RESULT: %b [%d]\n  SCRIPT: %s\n  JSON: %s\n%b' "${expected}" "${res}" "${code}" "${script}" "${basename}" "${verbose:+  OUTPUT:\n}"

    exec {CAT[1]}>&-
    sed -z ':loop; $! { N; b loop; }; s/^/    >> /' <&${CAT[0]}

    printf '\n'

    case "${code}${basename}" in
    ( [1-9]y_* ) printf '  \033[38;5;1m%s must be accepted\033[m\n' "${basename}"; exit 1 ;;
    ( 0n_* ) printf '  \033[38;5;1m%s must be refused\033[m\n' "${basename}"; exit 1 ;;
    ( * ) ;;
    esac

    (( i++ ))
  done
}

tests_json2yaml () {
  local json basename output diff expected expected_output

  for json in data/json2yaml/json/*.json
  do
    basename="$(basename "${json}" '.json')"

    printf 'TEST n°%d\n' "${i}"

    unset code
    local code
    code='0'

    output="$(SEDJUTSU_NOCOLOR= LC_CTYPE='C' sed --quiet --file scripts/json/conv/yaml.sed "${json}" 2> /dev/null)" || code="${?}"

    diff='\033[38;5;5mUNTESTED\033[m'
    case "${basename}" in
    ( y_* )
      expected_output="$(< "data/json2yaml/yaml/${basename}.yaml")"
      if [[ "${output}" == "${expected_output}" ]]
      then
        diff='\033[38;5;2mOK\033[m'
      else
        diff='\033[38;5;1mKO\033[m'
      fi ;;
    esac

    case "${code}" in
    ( 0 ) res='\033[38;5;2mOK\033[m' ;;
    ( * ) res='\033[38;5;1mKO\033[m' ;;
    esac

    case "${basename}" in
    ( y_* ) expected='\033[38;5;2mOK\033[m' ;;
    ( n_* ) expected='\033[38;5;1mKO\033[m' ;;
    esac

    printf '  EXPECTED: %b\n  RESULT: %b [%d]\n  SCRIPT: scripts/json/conv/yaml.sed\n  JSON: %s.json\n  OUTPUT: %b\n\n' "${expected}" "${res}" "${code}" "${basename}" "${diff}"

    (( i++ ))
  done
}

tests_math_calc () {
  local expr expected res code

  # Success tests
  for expr in \
    '1+3' \
    '2+8' \
    ' 2+8' \
    '2+8 ' \
    ' 2+8   ' \
    ' 2  +     8   ' \
    '2 + 0' \
    '0 + 0' \
    '2 + 8 + 1' \
    '2 + 8 + 1 + 9 + 7 + 4 + 5 + 3 + 6 + 0' \
    '12 + 6' \
    '12 + 8' \
    '12.0 + 8' \
    '12 + 8.0' \
    '12.0 + 8.0' \
    '12.0000 + 8.0000' \
    '12.0000 + 8.00000000' \
    '12.6 + 5.4' \
    '12.654272 + 5.44005' \
    '12.654272 + 5.44005000'
  do
    expected="$(calc -p -- "${expr}")"
    res="$(printf '%s' "${expr}" | sed -n -f wip/math/calc.sed)"
    printf '[math/calc.sed n°%s] EXPR: "%s", EXPECTED: %s, RESULT: %s ' "${i}" "${expr}" "${expected}" "${res}"
    case "${res}" in
    ( "${expected}" ) printf '\033[38;5;2mOK\033[m\n' ;;
    ( * ) printf '\033[38;5;1mKO\033[m\n' ;;
    esac
    (( i++ ))
  done

  # Failure tests
  for expr in \
    '2+' \
    '2 + ' \
    '2+6.' \
    '2.+6' \
    '2 ++ ' \
    '2 ++ 6' \
    '2 1 + 4' \
    '2 + 1 4' \
    '2 1 + 4 2'
  do
    printf '%s' "${expr}" | sed -n -f wip/math/calc.sed 2> /dev/null >&2 || code="${?}"
    printf '[math/calc.sed n°%s] EXPR: "%s", EXPECTED: \033[38;5;1mKO\033[m, CODE: ' "${i}" "${expr}"
    case "${code}" in
    ( 0 ) printf '\033[38;5;2mOK\033[m\n'; exit 1 ;;
    ( * ) printf '\033[38;5;1mKO\033[m\n' ;;
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
  opts[json2yaml]='--fast --quiet'

  while [[ "${#}" -gt 0 ]]
  do
    case "${1}" in
    # Handle '--file=file1' the same as '--file file1' for long-form 1-arg options
    ( --json-validator=*|--json-pp=*|--json2yaml* ) set -- "${1%%=*}" "${1#*=}" "${@:2}"; continue ;;

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
    ( --json2yaml )
      shift
      if [[ -z "${1:-}" ]]
      then
        printf 'The "--json2yaml" option takes 1 argument\n' >&2
        exit 1
      fi
      opts[json2yaml]="${opts[json2yaml]} --${1//,/ --}" ;;
    ( * ) printf 'Unknown option: "%s"' "${1}" >&2; exit 1 ;;
    esac
    shift
  done

  i='1'
  tests_json 'scripts/json/validator.sed' "${opts[json_validator]}"
  tests_json 'scripts/json/pretty-printer.sed' "${opts[json_pp]}"
  tests_json 'scripts/json/conv/yaml.sed' "${opts[json2yaml]}"
  tests_json2yaml
  tests_math_calc
}

tests "${@}"
