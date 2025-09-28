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
    s/^/w000-0/
    x
    b math_calc___RETURN
  }
  /^+/ {
    s/.//
    x
    s/^/w000+0/
    x
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
#     ws number ws
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
  x
  s/^/w0n0w0/
  x
  b math_calc___RETURN

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
      s/\x00\(.\)[^\x00]*$/\1/
    }
    /^[^\x00\n]*\n/ {
      s/\n\(.\)[^\n]*$/\1/
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
#     '.' digits
#     ""
: math_calc___fraction
  /^\./ {
    s/.//
    x
    s/$/./
    x
    /^[0-9]\+/ {
      x
      s/^/D0/
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
    s/^/s0D0^0*0/
    s/$/\t+10.0\t/
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
  s/^+//
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

# Align decimal parts of 2 last numbers into the numbers stack
: math_calc___task_ALIGN
  x
  # Add trailing decimal part for integers
  s/\([-+][0-9]*\)\(\t\|$\)/\1.0\2/g
  # 1) Put decimal part of the 1st number at the end
  s/\.\([0-9]*\)\t[-+][0-9]*\.[0-9]*$/\0\t\1/
  # 2) Into the decimal part of the 1st number (at the end) replace digits with 'x' characters
  t math_calc___task_ALIGN_replace_digit_with_x_1
  : math_calc___task_ALIGN_replace_digit_with_x_1
    s/[0-9]\(x*\)$/x\1/
    t math_calc___task_ALIGN_replace_digit_with_x_1
  # 3) Put decimal part of the 2nd number at the end
  s/\.\([0-9]*\)\tx*$/\0\t\1/
  # 4) Into the decimal part of the 2nd number (at the end) replace digits with 'x' characters
  t math_calc___task_ALIGN_replace_digit_with_x_2
  : math_calc___task_ALIGN_replace_digit_with_x_2
    s/[0-9]\(x*\)$/x\1/
    t math_calc___task_ALIGN_replace_digit_with_x_2
  # 5) Add zeroes to decimal parts of the 2 numbers using 'x' characters
  : math_calc___task_ALIGN_align_decimal_loop
  t math_calc___task_ALIGN_align_decimal_loop
    /\t\(x*\)\t\1$/ {
      b math_calc___task_ALIGN_align_decimal_break
    }
    s/\(x*\)\t\1$/\0x/
    T math_calc___task_ALIGN_align_decimal_loop_1
    s/\tx*\tx*$/0\0/
    b math_calc___task_ALIGN_align_decimal_loop
    : math_calc___task_ALIGN_align_decimal_loop_1
      s/\tx*$/x\0/
      s/\t[-+][0-9]*\.[0-9]*\tx*\tx*$/0\0/
      b math_calc___task_ALIGN_align_decimal_loop
  : math_calc___task_ALIGN_align_decimal_break
    s/\tx*\tx*$//
    x
    b math_calc___RETURN

# Alternatively replace digits into the two last numbers with repeated 'x' then repeated 'y' (or 'z' for zero)
: math_calc___task_CONVERT
  x
  s/\t\([^\t]*\t[^\t]*\)$/\v\1/
  t math_calc___task_CONVERT_to_x
  : math_calc___task_CONVERT_to_x
    s/\v\([-+][xyz]*\.[xyz]*\t[-+][xyz]*\.[xyz]*\)$/\t\1/
    t math_calc___task_CONVERT_end
    s/\([^\v]*\)0$/z\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)1$/x\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)2$/xx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)3$/xxx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)4$/xxxx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)5$/xxxxx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)6$/xxxxxx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)7$/xxxxxxx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)8$/xxxxxxxx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)9$/xxxxxxxxx\1/
    t math_calc___task_CONVERT_to_y
    s/\([^\v]*\)\([-+.\t]\)$/\2\1/
    t math_calc___task_CONVERT_to_x
    b math_calc___UNREACHABLE
  : math_calc___task_CONVERT_to_y
    s/\v\([-+][xyz]*\.[xyz]*\t[-+][xyz]*\.[xyz]*\)$/\t\1/
    t math_calc___task_CONVERT_end
    s/\([^\v]*\)0$/z\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)1$/y\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)2$/yy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)3$/yyy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)4$/yyyy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)5$/yyyyy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)6$/yyyyyy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)7$/yyyyyyy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)8$/yyyyyyyy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)9$/yyyyyyyyy\1/
    t math_calc___task_CONVERT_to_x
    s/\([^\v]*\)\([-+.\t]\)$/\2\1/
    t math_calc___task_CONVERT_to_x
    b math_calc___UNREACHABLE
  : math_calc___task_CONVERT_end
    x
    b math_calc___RETURN

: math_calc___task_REVERT
  x
  t math_calc___task_REVERT_loop
  : math_calc___task_REVERT_loop
    s/\(xxxxxxxxx\|yyyyyyyyy\)\([.0-9]*\)$/9\2/
    t math_calc___task_REVERT_loop
    s/\(xxxxxxxx\|yyyyyyyy\)\([.0-9]*\)$/8\2/
    t math_calc___task_REVERT_loop
    s/\(xxxxxxx\|yyyyyyy\)\([.0-9]*\)$/7\2/
    t math_calc___task_REVERT_loop
    s/\(xxxxxx\|yyyyyy\)\([.0-9]*\)$/6\2/
    t math_calc___task_REVERT_loop
    s/\(xxxxx\|yyyyy\)\([.0-9]*\)$/5\2/
    t math_calc___task_REVERT_loop
    s/\(xxxx\|yyyy\)\([.0-9]*\)$/4\2/
    t math_calc___task_REVERT_loop
    s/\(xxx\|yyy\)\([.0-9]*\)$/3\2/
    t math_calc___task_REVERT_loop
    s/\(xx\|yy\)\([.0-9]*\)$/2\2/
    t math_calc___task_REVERT_loop
    s/\(x\|y\)\([.0-9]*\)$/1\2/
    t math_calc___task_REVERT_loop
    s/z\([.0-9]*\)$/0\1/
    t math_calc___task_REVERT_loop
  x
  b math_calc___RETURN

: math_calc___op_ADD
  x
  /-[.0-9]*\t+[.0-9]*$/ {
    # TODO: switch 2 last numbers
  }
  /+[.0-9]*\t-[.0-9]*$/ {
    # TODO: SUB
  }
  /-[.0-9]*\t-[.0-9]*$/ {
    # TODO: + +
    #       MUL by -1.0
  }
  s/^/tAtC+1tR/
  x
  b math_calc___RETURN
  # Sum sequences of 'x' and 'y' characters into 2 last numbers
  : math_calc___op_ADD_1
    x
    s/\t[^\t]*\t[^\t]*$/\t+\0/
    : math_calc___op_ADD_sum_x
      # Upper trailing 'x' into 'X' characters for 2 last numbers
      s/x*x$/\U\0\E/
      s/\(x*x\)\(\t[^\t]*\)$/\U\1\E\2/
      t math_calc___op_ADD_sum_x
      s/\t+\t+$//
      t math_calc___op_ADD_2
      # trailing 'XX*' and 'XX*' case
      s/\([.xyz]*\t[^X\t]*\)\(XX*\)\(\t[^X\t]*\)\(XX*\)$/\L\2\4\E\1\3/
      t math_calc___op_ADD_sum_x_end
      # trailing 'z' and 'XX*' case
      s/\([.xyz]*\t[^\t]*\)z\(\t[^X\t]*\)\(XX*\)$/\L\3\E\1\2/
      t math_calc___op_ADD_sum_x_end
      # trailing 'XX*' and 'z' case
      s/\([.xyz]*\t[^X\t]*\)\(XX*\)\(\t[^\t]*\)z$/\L\2\E\1\3/
      t math_calc___op_ADD_sum_x_end
      # trailing 'z' and 'z' case
      s/\([.xyz]*\t[^\t]*\)z\(\t[^\t]*\)z$/z\1\2/
      t math_calc___op_ADD_sum_x_end
      # trailing '+' and 'XX*' case
      s/\([.xyz]*\t+\t[^X\t]*\)\(XX*\)$/\L\2\E\1/
      t math_calc___op_ADD_sum_x_end
      # trailing '+' and 'z' case
      s/\([.xyz]*\t+\t[^\t]*\)z$/z\1/
      t math_calc___op_ADD_sum_x_end
      # trailing 'XX*' and '+' case
      s/\([.xyz]*\t[^X\t]*\)\(XX*\)\t+$/\L\2\E\1\t+/
      t math_calc___op_ADD_sum_x_end
      # trailing 'z' and '+' case
      s/\([.xyz]*\t[^\t]*\)z\t+$/z\1\t+/
      t math_calc___op_ADD_sum_x_end
      b math_calc___UNREACHABLE
    : math_calc___op_ADD_sum_x_end
      # trailing '.' and '.' case
      s/\([xyz]*\t[^\t]*\)\.\(\t[^\t]*\)\.$/.\1\2/
      t math_calc___op_ADD_sum_x_end_1
      s/xxxxxxxxxx\(x[^\t]*\t[^\t]*\t[^\t]*\)$/y\1/
      t math_calc___op_ADD_sum_y
      s/xxxxxxxxxx\([^\t]*\t[^\t]*\t[^\t]*\)$/yz\1/
      b math_calc___op_ADD_sum_y
      : math_calc___op_ADD_sum_x_end_1
        s/\.xxxxxxxxxx\(x[^\t]*\t[^\t]*\t[^\t]*\)$/x.\1/
        t math_calc___op_ADD_sum_x
        s/\.xxxxxxxxxx\([^\t]*\t[^\t]*\t[^\t]*\)$/x.z\1/
        b math_calc___op_ADD_sum_x
    : math_calc___op_ADD_sum_y
      s/y*y$/\U\0\E/
      s/\(y*y\)\(\t[^\t]*\)$/\U\1\E\2/
      t math_calc___op_ADD_sum_y
      s/\t+\t+$//
      t math_calc___op_ADD_2
      s/\([.xyz]*\t[^Y\t]*\)\(YY*\)\(\t[^Y\t]*\)\(YY*\)$/\L\2\4\E\1\3/
      t math_calc___op_ADD_sum_y_end
      s/\([.xyz]*\t[^\t]*\)z\(\t[^Y\t]*\)\(YY*\)$/\L\3\E\1\2/
      t math_calc___op_ADD_sum_y_end
      s/\([.xyz]*\t[^Y\t]*\)\(YY*\)\(\t[^\t]*\)z$/\L\2\E\1\3/
      t math_calc___op_ADD_sum_y_end
      s/\([.xyz]*\t[^\t]*\)z\(\t[^\t]*\)z$/z\1\2/
      t math_calc___op_ADD_sum_y_end
      s/\([.xyz]*\t+\t[^Y\t]*\)\(YY*\)$/\L\2\E\1/
      t math_calc___op_ADD_sum_y_end
      s/\([.xyz]*\t+\t[^\t]*\)z$/z\1/
      t math_calc___op_ADD_sum_y_end
      s/\([.xyz]*\t[^Y\t]*\)\(YY*\)\t+$/\L\2\E\1\t+/
      t math_calc___op_ADD_sum_y_end
      s/\([.xyz]*\t[^\t]*\)z\t+$/z\1\t+/
      t math_calc___op_ADD_sum_y_end
      b math_calc___UNREACHABLE
    : math_calc___op_ADD_sum_y_end
      s/\([xyz]*\t[^\t]*\)\.\(\t[^\t]*\)\.$/.\1\2/
      t math_calc___op_ADD_sum_y_end
      s/\(\.\?\)yyyyyyyyyy\(y[^\t]*\t[^\t]*\t[^\t]*\)$/x\1\2/
      t math_calc___op_ADD_sum_x
      s/\(\.\?\)yyyyyyyyyy\([^\t]*\t[^\t]*\t[^\t]*\)$/x\1z\2/
      b math_calc___op_ADD_sum_x
  : math_calc___op_ADD_2
    x
    b math_calc___RETURN

: math_calc___op_SUB
  # TODO
  b math_calc___RETURN

# Redirect the workflow depending on the first element in the workflow stack
: math_calc___RETURN
  x
  /^+0/ {
    s/..//
    x
    b math_calc___op_ADD
  }
  /^+1/ {
    s/..//
    x
    b math_calc___op_ADD_1
  }
  /^-0/ {
    s/..//
    x
    b math_calc___op_SUB
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
  /^tA/ {
    s/..//
    x
    b math_calc___task_ALIGN
  }
  /^tC/ {
    s/..//
    x
    b math_calc___task_CONVERT
  }
  /^tR/ {
    s/..//
    x
    b math_calc___task_REVERT
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
  x
  /^[^\x00\n]*\x00/ {
    s/.*\t[-+]\([.0-9]*\)$/\1\n/
    s/0*\n/\n/
    s/\.\n/\n/
    p
    z
  }
  /^[^\x00\n]*\n/ {
    s/.*\t[-+]\([.0-9]*\)$/\1/
    s/0*$//
    s/\.$//
    p
    z
  }
