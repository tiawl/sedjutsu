### README ####################################################################
#                                                                             #
#   This script can be used to emulate some features of `jq`, `json_pp` or    #
#   `json_xs`.                                                                #
#                                                                             #
#   Because it is particulary hard to deal with the `n` and `N` GNU `sed`     #
#   commands (If there is no more input, these commands make `sed` exits      #
#   and `sed` has no way to know internally if there is more input), this     #
#   script expects a oneliner input.                                          #
#                                                                             #
#   If your input contains new line characters without NUL characters, you    #
#   definitly want to use the `-z`/`--null-data` GNU `sed` option.            #
#                                                                             #
#   However, if your input contains NUL characters without new line           #
#   characters, avoid this option.                                            #
#                                                                             #
#   If you do not want to see the trailing new line, use the `-n`/`--quiet`   #
#   option.                                                                   #
#                                                                             #
### KNOWN LIMITATIONS #########################################################
#                                                                             #
#   1) If your input contains NUL characters AND new line characters,         #
#      `sed`can not deal with it.                                             #
#                                                                             #
#   2) If your input file is empty, this script will parse it successfully    #
#      because `sed` does not operate on empty files. An empty file should    #
#      result in a parsing error.                                             #
#                                                                             #
###############################################################################

# Init the holdspace with these following variables:
# - an empty workflow stack
# - col
# - row
: init_holdspace
  x
  s/^/\n1\n1/
  x

#
# JSON grammar in McKeeman Form
#

### json
###    element
: json_pp___json
  x
  s/^/j1/
  x
  b json_pp___element
  : json_pp___json_1
    /^$/ {
      b json_pp___SUCCESS
    }
    s/.*/garbage after main element/
    b json_pp___FAILURE

### value
###    object
###    array
###    string
###    number
###    "true"
###    "false"
###    "null"
: json_pp___value
  /^{/ {
    b json_pp___object
  }
  /^\[/ {
    b json_pp___array
  }
  /^"/ {
    b json_pp___string
  }
  /^[-0-9]/ {
    b json_pp___number
  }
  /^true/ {
    s/....//
    b incr4_col
  }
  /^false/ {
    s/.....//
    b incr5_col
  }
  /^null/ {
    s/....//
    b incr4_col
  }
  s/.*/malformed JSON string, neither array, object, number, string or atom/
  b json_pp___FAILURE

### object
###     '{' ws '}'
###     '{' members '}'
: json_pp___object
  /^{[\x20\x0a\x0d\x09]*}/ {
    s/^{//
    x
    s/^/o1o2/
    x
    b incr_col
    : json_pp___object_1
      b json_pp___ws
    : json_pp___object_2
      /^}/ {
        s/.//
        b incr_col
      }
      s/.*/`,` or `}` expected while parsing JSON object/
      b json_pp___FAILURE
  }
  /^{/ {
    s/^{//
    x
    s/^/o3o4/
    x
    b incr_col
    : json_pp___object_3
      b json_pp___members
    : json_pp___object_4
      /^}/ {
        s/.//
        b incr_col
      }
      s/.*/`,` or `}` expected while parsing JSON object/
      b json_pp___FAILURE
  }
  b json_pp___RETURN

### members
###     member
###     member ',' members
: json_pp___members
  x
  s/^/M1/
  x
  b json_pp___member
  : json_pp___members_1
    /^,/ {
      s/.//
      x
      s/^/M2/
      x
      b incr_col
    }
    b json_pp___RETURN
  : json_pp___members_2
    b json_pp___members

### member
###     ws string ws ':' element
: json_pp___member
  x
  s/^/m1m2m3m4/
  x
  b json_pp___ws
  : json_pp___member_1
    b json_pp___string
  : json_pp___member_2
    b json_pp___ws
  : json_pp___member_3
    /^:/ {
      s/.//
      b incr_col
    }
    s/.*/`:` expected/
    b json_pp___FAILURE
  : json_pp___member_4
    b json_pp___element

### array
###     '[' ws ']'
###     '[' elements ']'
: json_pp___array
  /^\[[\x20\x0a\x0d\x09]*]/ {
    s/^\[//
    x
    s/^/a1a2/
    x
    b incr_col
    : json_pp___array_1
      b json_pp___ws
    : json_pp___array_2
      /^]/ {
        s/.//
        b incr_col
      }
      s/.*/`,` or `]` expected while parsing JSON array/
      b json_pp___FAILURE
  }
  /^\[/ {
    s/^\[//
    x
    s/^/a3a4/
    x
    b incr_col
    : json_pp___array_3
      b json_pp___elements
    : json_pp___array_4
      /^]/ {
        s/.//
        b incr_col
      }
      s/.*/`,` or `]` expected while parsing JSON array/
      b json_pp___FAILURE
  }
  b json_pp___RETURN

### elements
###     element
###     element ',' elements
: json_pp___elements
  x
  s/^/E1/
  x
  b json_pp___element
  : json_pp___elements_1
    /^,/ {
      s/.//
      x
      s/^/E2/
      x
      b incr_col
    }
    b json_pp___RETURN
  : json_pp___elements_2
    b json_pp___elements

### element
###     ws value ws
: json_pp___element
  x
  s/^/e1e2/
  x
  b json_pp___ws
  : json_pp___element_1
    b json_pp___value
  : json_pp___element_2
    b json_pp___ws

### string
### '"' characters '"'
: json_pp___string
  x
  s/^/s1s2/
  x
  /^"/ {
    s/.//
    b incr_col
  }
  s/.*/`"` expected while parsing JSON string/
  b json_pp___FAILURE
  : json_pp___string_1
    b json_pp___characters
  : json_pp___string_2
    /^"/ {
      s/.//
      b incr_col
    }
    s/.*/Unexpected end of string while parsing JSON string/
    b json_pp___FAILURE

### characters
###     ""
###     character characters
: json_pp___characters
  /^[^\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"]/ {
    x
    s/^/C1/
    x
    b json_pp___character
    : json_pp___characters_1
      b json_pp___characters
  }
  b json_pp___RETURN

### character
###     '0020' . '10FFFF' - '"' - '\'
###     '\' escape
: json_pp___character
  /^\\/ {
    s/.//
    x
    s/^/c1/
    x
    b incr_col
    : json_pp___character_1
      b json_pp___escape
  }
  /^[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"]/ {
    s/.*/Invalid character encountered/
    b json_pp___FAILURE
  }
  s/.//
  b incr_col

### escape
###     '"'
###     '\'
###     '/'
###     'b'
###     'f'
###     'n'
###     'r'
###     't'
###     'u' hex hex hex hex
: json_pp___escape
  /^u/ {
    s/.//
    x
    s/^/\\1\\2\\3\\4/
    x
    b incr_col
    : json_pp___escape_1
      b json_pp___hex
    : json_pp___escape_2
      b json_pp___hex
    : json_pp___escape_3
      b json_pp___hex
    : json_pp___escape_4
      b json_pp___hex
  }
  /^["\\/bfnrt]/ {
    s/.//
    b incr_col
  }
  s/.*/Invalid escaped character encountered/
  b json_pp___FAILURE

### hex
###     digit
###     'A' . 'F'
###     'a' . 'f'
: json_pp___hex
  /^[A-Fa-f]/ {
    s/.//
    b incr_col
  }
  /^[0-9]/ {
    b json_pp___digit
  }
  s/.*/Invalid hexadecimal character encountered/
  b json_pp___FAILURE

### number
###     integer fraction exponent
: json_pp___number
  x
  s/^/n1n2/
  x
  b json_pp___integer
  : json_pp___number_1
    b json_pp___fraction
  : json_pp___number_2
    b json_pp___exponent

### integer
###     digit
###     onenine digits
###     '-' digit
###     '-' onenine digits
: json_pp___integer
  /^-/ {
    s/.//
    x
    s/^/i1/
    x
    b incr_col
  }
  : json_pp___integer_1
  /^[1-9][0-9]/ {
    x
    s/^/i2/
    x
    b json_pp___onenine
    : json_pp___integer_2
      b json_pp___digits
  }
  /^[0-9]/ {
    b json_pp___digit
  }
  s/.*/Invalid integer encountered/
  b json_pp___FAILURE

### digits
###     digit
###     digit digits
: json_pp___digits
  /^[0-9][0-9]/ {
    x
    s/^/D1/
    x
  }
  b json_pp___digit
  : json_pp___digits_1
    b json_pp___digits

### digit
###     '0'
###     onenine
: json_pp___digit
  /^0/ {
    s/.//
    b incr_col
  }
  /^[1-9]/ {
    b json_pp___onenine
  }
  s/.*/Invalid digit encountered/
  b json_pp___FAILURE

### onenine
###     '1' . '9'
: json_pp___onenine
  /^[1-9]/ {
    s/.//
    b incr_col
  }
  s/.*/Invalid onenine encountered/
  b json_pp___FAILURE

### fraction
###     ""
###     '.' digits
: json_pp___fraction
  /^\./ {
    s/.//
    x
    s/^/f1/
    x
    b incr_col
    : json_pp___fraction_1
      b json_pp___digits
  }
  b json_pp___RETURN

### exponent
###     ""
###     'E' sign digits
###     'e' sign digits
: json_pp___exponent
  /^[eE]/ {
    s/.//
    x
    s/^/x1x2/
    x
    b incr_col
    : json_pp___exponent_1
      b json_pp___sign
    : json_pp___exponent_2
      b json_pp___digits
  }
  b json_pp___RETURN

### sign
###     ""
###     '+'
###     '-'
: json_pp___sign
  /^[-+]/ {
    s/.//
    b incr_col
  }
  b json_pp___RETURN

### ws
###     ""
###     '0020' ws
###     '000A' ws
###     '000D' ws
###     '0009' ws
: json_pp___ws
  /^\x0a/ {
    s/.//
    x
    s/^/w1/
    x
    b incr_row
    : json_pp___ws_1
      b json_pp___ws
  }
  /^[\x20\x0d\x09]/ {
    s/.//
    x
    s/^/w2/
    x
    b incr_col
    : json_pp___ws_2
      b json_pp___ws
  }
  b json_pp___RETURN

: incr_col
  x
  : incr_col_nines2underscores
    s/^\([^\n]*\n[0-9]*\)9\(_*\n\)/\1_\2/
    t incr_col_nines2underscores
  : incr_col_lastdigit
    s/^\([^\n]*\n\)\(_*\n\)/\11\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)8\(_*\n\)/\19\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)7\(_*\n\)/\18\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)6\(_*\n\)/\17\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)5\(_*\n\)/\16\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)4\(_*\n\)/\15\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)3\(_*\n\)/\14\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)2\(_*\n\)/\13\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)1\(_*\n\)/\12\2/
    t incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)0\(_*\n\)/\11\2/
  : incr_col_underscores2zeroes
    s/^\([^\n]*\n[0-9]*\)_\(_*\n\)/\10\2/
    t incr_col_underscores2zeroes
  x
  b json_pp___RETURN

: incr_row
  x
  s/^\([^\n]*\n\)[0-9]*\n/\1/
  s/^/ir/
  x
  b incr_col
  : incr_row_1
    x
    s/^\([^\n]*\n\)/\11\n/
    x
  b json_pp___RETURN

: incr4_col
  x
  s/^\([^\n]*\n[0-9]*\)9\n/\1D\n/
  s/^\([^\n]*\n[0-9]*\)8\n/\1C\n/
  s/^\([^\n]*\n[0-9]*\)7\n/\1B\n/
  s/^\([^\n]*\n[0-9]*\)6\n/\1A\n/
  : incr4_col_nines2As
    s/^\([^\n]*\n[0-9]*\)9\(A*[ABCD]\n\)/\1A\2/
    t incr4_col_nines2As
  : incr4_col_ge10
    s/^\([^\n]*\n\)\(A*[ABCD]\n\)/\11\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)8\(A*[ABCD]\n\)/\19\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)7\(A*[ABCD]\n\)/\18\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)6\(A*[ABCD]\n\)/\17\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)5\(A*[ABCD]\n\)/\16\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)4\(A*[ABCD]\n\)/\15\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)3\(A*[ABCD]\n\)/\14\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)2\(A*[ABCD]\n\)/\13\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)1\(A*[ABCD]\n\)/\12\2/
    t incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)0\(A*[ABCD]\n\)/\11\2/
  : incr4_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)5\n/\19\n/
    t incr4_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)4\n/\18\n/
    t incr4_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)3\n/\17\n/
    t incr4_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)2\n/\16\n/
    t incr4_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)1\n/\15\n/
    t incr4_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)0\n/\14\n/
  : incr4_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)A\(A*[BCD]\?\)/\10\2/
    t incr4_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)B\n/\11\n/
    s/^\([^\n]*\n[0-9]*\)C\n/\12\n/
    s/^\([^\n]*\n[0-9]*\)D\n/\13\n/
  x
  b json_pp___RETURN

: incr5_col
  x
  s/^\([^\n]*\n[0-9]*\)9\n/\1E\n/
  s/^\([^\n]*\n[0-9]*\)8\n/\1D\n/
  s/^\([^\n]*\n[0-9]*\)7\n/\1C\n/
  s/^\([^\n]*\n[0-9]*\)6\n/\1B\n/
  s/^\([^\n]*\n[0-9]*\)5\n/\1A\n/
  : incr5_col_nines2As
    s/^\([^\n]*\n[0-9]*\)9\(A*[ABCDE]\n\)/\1A\2/
    t incr5_col_nines2As
  : incr5_col_ge10
    s/^\([^\n]*\n\)\(A*[ABCDE]\n\)/\11\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)8\(A*[ABCDE]\n\)/\19\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)7\(A*[ABCDE]\n\)/\18\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)6\(A*[ABCDE]\n\)/\17\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)5\(A*[ABCDE]\n\)/\16\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)4\(A*[ABCDE]\n\)/\15\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)3\(A*[ABCDE]\n\)/\14\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)2\(A*[ABCDE]\n\)/\13\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)1\(A*[ABCDE]\n\)/\12\2/
    t incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)0\(A*[ABCDE]\n\)/\11\2/
  : incr5_col_lastdigit
    s/^\([^\n]*\n[0-9]*\)4\n/\19\n/
    t incr5_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)3\n/\18\n/
    t incr5_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)2\n/\17\n/
    t incr5_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)1\n/\16\n/
    t incr5_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)0\n/\15\n/
  : incr5_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)A\(A*[BCDE]\?\)/\10\2/
    t incr5_col_letters2numbers
    s/^\([^\n]*\n[0-9]*\)B\n/\11\n/
    s/^\([^\n]*\n[0-9]*\)C\n/\12\n/
    s/^\([^\n]*\n[0-9]*\)D\n/\13\n/
    s/^\([^\n]*\n[0-9]*\)E\n/\14\n/
  x
  b json_pp___RETURN

# Redirect the workflow depending of the first element in the workflow stack
: json_pp___RETURN
  x
  /^a1/ {
    s/^a1//
    x
    b json_pp___array_1
  }
  /^a2/ {
    s/^a2//
    x
    b json_pp___array_2
  }
  /^a3/ {
    s/^a3//
    x
    b json_pp___array_3
  }
  /^a4/ {
    s/^a4//
    x
    b json_pp___array_4
  }
  /^C1/ {
    s/^C1//
    x
    b json_pp___characters_1
  }
  /^c1/ {
    s/^c1//
    x
    b json_pp___character_1
  }
  /^D1/ {
    s/^D1//
    x
    b json_pp___digits_1
  }
  /^E1/ {
    s/^E1//
    x
    b json_pp___elements_1
  }
  /^E2/ {
    s/^E2//
    x
    b json_pp___elements_2
  }
  /^e1/ {
    s/^e1//
    x
    b json_pp___element_1
  }
  /^e2/ {
    s/^e2//
    x
    b json_pp___element_2
  }
  /^f1/ {
    s/^f1//
    x
    b json_pp___fraction_1
  }
  /^i1/ {
    s/^i1//
    x
    b json_pp___integer_1
  }
  /^i2/ {
    s/^i2//
    x
    b json_pp___integer_2
  }
  /^ir/ {
    s/^ir//
    x
    b incr_row_1
  }
  /^j1/ {
    s/^j1//
    x
    b json_pp___json_1
  }
  /^M1/ {
    s/^M1//
    x
    b json_pp___members_1
  }
  /^M2/ {
    s/^M2//
    x
    b json_pp___members_2
  }
  /^m1/ {
    s/^m1//
    x
    b json_pp___member_1
  }
  /^m2/ {
    s/^m2//
    x
    b json_pp___member_2
  }
  /^m3/ {
    s/^m3//
    x
    b json_pp___member_3
  }
  /^m4/ {
    s/^m4//
    x
    b json_pp___member_4
  }
  /^n1/ {
    s/^n1//
    x
    b json_pp___number_1
  }
  /^n2/ {
    s/^n2//
    x
    b json_pp___number_2
  }
  /^o1/ {
    s/^o1//
    x
    b json_pp___object_1
  }
  /^o2/ {
    s/^o2//
    x
    b json_pp___object_2
  }
  /^o3/ {
    s/^o3//
    x
    b json_pp___object_3
  }
  /^o4/ {
    s/^o4//
    x
    b json_pp___object_4
  }
  /^s1/ {
    s/^s1//
    x
    b json_pp___string_1
  }
  /^s2/ {
    s/^s2//
    x
    b json_pp___string_2
  }
  /^x1/ {
    s/^x1//
    x
    b json_pp___exponent_1
  }
  /^x2/ {
    s/^x2//
    x
    b json_pp___exponent_2
  }
  /^w1/ {
    s/^w1//
    x
    b json_pp___ws_1
  }
  /^w2/ {
    s/^w2//
    x
    b json_pp___ws_2
  }
  /^\\1/ {
    s/^\\1//
    x
    b json_pp___escape_1
  }
  /^\\2/ {
    s/^\\2//
    x
    b json_pp___escape_2
  }
  /^\\3/ {
    s/^\\3//
    x
    b json_pp___escape_3
  }
  /^\\4/ {
    s/^\\4//
    x
    b json_pp___escape_4
  }
  x
  s/.*/"Unknown return code"/
  b json_pp___UNREACHABLE

: json_pp___UNREACHABLE
  s/^/Reached unreachable code in scripts\/json\/pretty-printer.sed: /
  s/$/\n/
  w /dev/stderr
  Q 5

: json_pp___FAILURE
  H
  x
  s/^[^\n]*\n\([0-9]\+\)\n\([0-9]\+\)/JSON parsing error at ROW \1, COL \2: /
  s/$/\n/
  w /dev/stderr
  Q 6

: json_pp___SUCCESS
  s/.*/JSON parsing succeed\n/
  p
  z
