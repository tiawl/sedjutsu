### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `bc`, `dc` or shell features    #
#   It is an arithmetic float calculator:                                     #
#   Supported features:                                                       #
#   - positive and negative float arithmetic                                  #
#   - operators: + (addition), - (substraction), * (multiplication),          #
#       / (division), ** (exponentiation), V (root) and % (remainder)         #
#   - grouping with parentheses: (, )                                         #
#                                                                             #
###############################################################################

# Init the holdspace with these variables:
# - an empty workflow stack
: init_holdspace
  $! {
    N
    b init_holdspace
  }
  # Depending on the `-z`/`--null-data` option usage, the `D`, `G`, `H`, `N` and `P` sed commands work with new line or NUL characters. This script must know which one of these characters these commands are using
  G
  h
  s/.$//
  x
  s/.*\(.\)$/\1/g
  x
  /^$/ {
    s/^/empty input/
    b math_calc___ERROR
  }
  b math_calc___calc

#
# Grammar in McKeeman Form
#

# calc
#     precedence0
: math_calc___calc
  # TODO

# precedence0
#     precedence1 ws addsub
: math_calc___precedence0
  # TODO

# addsub
#     '+' ws precedence0
#     '-' ws precedence0
#     ""
: math_calc___addsub
  # TODO

# precedence1
#     precedence2 ws rem
: math_calc___precedence1
  # TODO

# rem
#     '%' ws precedence1
#     ""
: math_calc___rem
  # TODO

# precedence2
#     precedence3 ws muldiv
: math_calc___precedence2
  # TODO

# muldiv
#     '*' ws precedence2
#     '/' ws precedence2
#     ""
: math_calc___muldiv
  # TODO

# precedence3
#     precedence4 ws powroot
: math_calc___precedence3
  # TODO

# powroot
#     '^' ws precedence3
#     'v' ws precedence3
#     ""
: math_calc___powroot
  # TODO

# precedence4
#     '(' ws precedence0 ws ')'
#     number
: math_calc___precedence4
  # TODO

: math_calc___bool
: math_calc___and
: math_calc___or
: math_calc___xor
: math_calc___not
: math_calc___gt
: math_calc___lt
: math_calc___ge
: math_calc___le
: math_calc___eq
: math_calc___ne

# number
#     integer fraction
: math_calc___number
  # TODO

# integer
#     digit
#     onenine digits
#     '-' digit
#     '-' onenine digits
: math_calc___integer
  # TODO

# digits
#     digit
#     digit digits
: math_calc___digits
  # TODO

# digit
#     '0'
#     onenine
: math_calc___digit
  # TODO

# onenine
#     '1' . '9'
: math_calc___onenine
  # TODO

# fraction
#     '.' onenine
#     '.' digits onenine
#     ""
: math_calc___fraction
  # TODO

# ws
#     '0020' ws
#     '000A' ws
#     '000D' ws
#     '0009' ws
#     ""
: math_calc___ws
  # TODO

: math_calc___RETURN
  # TODO

: math_calc___ERROR
  x
  /^[^\x00\n]*\x00/ {
    x
    s/.*/Parsing error: \0\n/
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    z
  }
  /^[^\x00\n]*\n/ {
    x
    s/^/Parsing error: /
    w /dev/stderr
    # If outside the scope it triggers the next conditional statement
    z
  }
  Q 6

: math_calc___SUCCESS
  # TODO
