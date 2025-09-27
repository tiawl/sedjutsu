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
# - an empty number stack
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
  x
  s/^/00S0/
  x
  b math_calc___RETURN

# precedence0
#     precedence1 ws addsub
: math_calc___precedence0
  x
  s/^/10w0a0/
  x
  b math_calc___RETURN

# addsub
#     '+' ws precedence0
#     '-' ws precedence0
#     ""
: math_calc___addsub
  /^-/ {
    s/.//
    x
    s/^/-w0p0/
    x
    b math_calc___RETURN
  }
  /^+/ {
    s/.//
    x
    s/^/+w0p0/
    x
    b math_calc___RETURN
  }
  b math_calc___RETURN

# precedence1
#     precedence2 ws rem
: math_calc___precedence1
  x
  s/^/20w0r0/
  x
  b math_calc___RETURN

# rem
#     '%' ws precedence1
#     ""
: math_calc___rem
  # TODO
  b math_calc___RETURN

# precedence2
#     precedence3 ws muldiv
: math_calc___precedence2
  x
  s/^/30w0m0/
  x
  b math_calc___RETURN

# muldiv
#     '*' ws precedence2
#     '/' ws precedence2
#     ""
: math_calc___muldiv
  # TODO
  b math_calc___RETURN

# precedence3
#     precedence4 ws powroot
: math_calc___precedence3
  x
  s/^/40w0p0/
  x
  b math_calc___RETURN

# powroot
#     '^' ws precedence3
#     'v' ws precedence3
#     ""
: math_calc___powroot
  # TODO
  b math_calc___RETURN

# precedence4
#     '(' ws precedence0 ws ')'
#     number
: math_calc___precedence4
  /^(/ {
    s/.//
    x
    s/^/w000w041/
    x
    b math_calc___RETURN
    : math_calc___precedence4_1
      /^)/ {
        s/.//
        b math_calc___RETURN
      }
      z
      s/^/`)` expected/
      b math_calc___ERROR
  }
  /^[-0-9]/ {
    x
    s/^/n0/
    x
    b math_calc___RETURN
  }
  z
  s/^/`(` expected/
  b math_calc___ERROR

# number
#     integer fraction exponent
: math_calc___number
  x
  s/^/i0f0e0/
  # \t character to split between numbers
  s/$/\t/
  x
  b math_calc___RETURN

# integer
#     sign digit
#     sign onenine digits
: math_calc___integer
  x
  s/^/s0i1/
  x
  b math_calc___RETURN
  : math_calc___integer_1
    /^[1-9][0-9]/ {
      x
      s/^/o0D0/
      x
      b math_calc___RETURN
    }
    /^[0-9]/ {
      x
      s/^/d0/
      x
      b math_calc___RETURN
    }
    z
    s/^/Invalid integer encountered/
    b math_calc___ERROR

# digits
#     digit
#     digit digits
: math_calc___digits
  /^[0-9][0-9]/ {
    x
    s/^/D0/
    x
  }
  x
  s/^/d0/
  x
  b math_calc___RETURN

# digit
#     '0'
#     onenine
: math_calc___digit
  /^0/ {
    s/.//
    x
    s/$/0/
    x
    b math_calc___RETURN
  }
  /^[1-9]/ {
    x
    s/^/o0/
    x
    b math_calc___RETURN
  }
  z
  s/^/Invalid digit encountered/
  b math_calc___ERROR

# onenine
#     '1' . '9'
: math_calc___onenine
  /^[1-9]/ {
    H
    x
    /^[^\x00\n]*\x00/ {
      s/\x00\([1-9]\)[^\x00]*$/\1/
    }
    /^[^\x00\n]*\n/ {
      s/\n\([1-9]\)[^\n]*$/\1/
    }
    x
    s/.//
    b math_calc___RETURN
  }
  z
  s/^/Invalid onenine encountered/
  b math_calc___ERROR

# fraction
#     '.' onenine
#     '.' digits onenine
#     ""
: math_calc___fraction
  /^\./ {
    s/.//
    x
    s/$/./
    x
    /^[0-9][1-9]/ {
      x
      s/^/D0o0/
      x
      b math_calc___RETURN
    }
    /^[1-9]/ {
      x
      s/^/o0/
      x
      b math_calc___RETURN
    }
    z
    s/^/Invalid fraction encountered/
    b math_calc___ERROR
  }
  b math_calc___RETURN

# exponent
#     'E' sign digits
#     'e' sign digits
#     ""
: math_calc___exponent
  /^[eE]/ {
    s/.//
    x
    s/^/s0D0^*/
    s/$/\t10\t/
    x
  }
  b math_calc___RETURN

# sign
#     '+'
#     '-'
#     ""
: math_calc___sign
  /^-/ {
    s/.//
    x
    s/$/-/
    x
    b math_calc___RETURN
  }
  s/.//
  x
  s/$/+/
  x
  b math_calc___RETURN

# ws
#     '0020' ws
#     '0009' ws
#     '000A' ws
#     '000B' ws
#     '000C' ws
#     '000D' ws
#     ""
: math_calc___ws
  /^[[:space:]]/ {
    s/.//
    x
    s/^/w0/
    x
  }
  b math_calc___RETURN

: math_calc___ADD
  x
  /-\t[.0-9]*\t+[.0-9]*$/ {
    # switch 2 last numbers
  }
  /+\t[.0-9]*\t-[.0-9]*$/ {
    # SUB
  }
  # Add trailing fractional part for integers
  s/\([-+][0-9]*\)\(\t\|$\)/\1.0\2/g
  # 1. Align fracts
  s/\.\([0-9]*\)\t[-+][0-9]*\.\([0-9]*\)$/\0\t\1\t\2/
  # printf '+12.54\n+5.6' | sed -z 's/\([-+][0-9]*\)\(\n\|$\)/\1.0\2/g; s/\.\([0-9]*\)\n[-+][0-9]*\.[0-9]*$/\0\n\1/; tt; :t; s/[0-9]\(x*\)$/x\1/; tt; s/\.\([0-9]*\)\nx*$/\0\n\1/; ts; :s; s/[0-9]\(x*\)$/x\1/; ts; :l; /\(x*\)\n\1$/ { bk; }; bl; :k; s/$/\n/;'
  # 2. Add fracts
  # 3. Add ints
  # 4. Merge ints and fracts
  x
  b math_calc___RETURN

: math_calc___SUB
  # TODO
  b math_calc___RETURN

# Redirect the workflow depending on the first element in the workflow stack
: math_calc___RETURN
  x
  /^+/ {
    s/..//
    x
    b math_calc___ADD
  }
  /^-/ {
    s/..//
    x
    b math_calc___SUB
  }
  /^00/ {
    s/..//
    x
    b math_calc___precedence0
  }
  /^10/ {
    s/..//
    x
    b math_calc___precedence1
  }
  /^20/ {
    s/..//
    x
    b math_calc___precedence2
  }
  /^30/ {
    s/..//
    x
    b math_calc___precedence3
  }
  /^40/ {
    s/..//
    x
    b math_calc___precedence4
  }
  /^41/ {
    s/..//
    x
    b math_calc___precedence4_1
  }
  /^a0/ {
    s/..//
    x
    b math_calc___addsub
  }
  /^d0/ {
    s/..//
    x
    b math_calc___digit
  }
  /^D0/ {
    s/..//
    x
    b math_calc___digits
  }
  /^e0/ {
    s/..//
    x
    b math_calc___exponent
  }
  /^f0/ {
    s/..//
    x
    b math_calc___fraction
  }
  /^i0/ {
    s/..//
    x
    b math_calc___integer
  }
  /^i1/ {
    s/..//
    x
    b math_calc___integer_1
  }
  /^m0/ {
    s/..//
    x
    b math_calc___muldiv
  }
  /^n0/ {
    s/..//
    x
    b math_calc___number
  }
  /^o0/ {
    s/..//
    x
    b math_calc___onenine
  }
  /^p0/ {
    s/..//
    x
    b math_calc___powroot
  }
  /^r0/ {
    s/..//
    x
    b math_calc___rem
  }
  /^s0/ {
    s/..//
    x
    b math_calc___sign
  }
  /^S0/ {
    s/..//
    x
    b math_calc___SUCCESS
  }
  /^w0/ {
    s/..//
    x
    b math_calc___ws
  }
  z
  s/^/"Unknown return code"/
  b math_calc___UNREACHABLE

: math_calc___UNREACHABLE
  x
  /^[^\x00\n]*\x00/ {
    x
    s/.*/\x1b[0mReached unreachable code in scripts\/math\/calc.sed: \0\n/
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    # If outside the scope it triggers the next conditional statement
    z
  }
  /^[^\x00\n]*\n/ {
    x
    s/^/\x1b[0mReached unreachable code in scripts\/math\/calc.sed: /
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    z
  }
  Q 5

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
