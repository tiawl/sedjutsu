### README ####################################################################
#                                                                             #
#   This script can be used to emulate some `jq`, `json_pp` or `json_xs`      #
#   features.                                                                 #
#                                                                             #
#   You can configure this script with these environment variables:           #
#   - SEDJUTSU_INDENT: use the given number of spaces (between 1 and 8)       #
#     for indentation (default: 4)                                            #
#   - SEDJUTSU_MONOCHROME: disable color whatever its value                   #
#   - SEDJUTSU_COLORS: work like JQ_COLORS does (for more details, see:       #
#     https://jqlang.org/manual/#colors)                                      #
#   If SEDJUTSU_MONOCHROME and SEDJUTSU_COLORS are set when the script run,   #
#   coloring is disabled.                                                     #
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

# Init the holdspace with these variables:
# - an empty workflow stack
# - the indentation level
# - env vars
# - row
# - col
: init_holdspace
  x
  s/^/printf '%s:%s%s' "${SEDJUTSU_INDENT:-4}" "${SEDJUTSU_MONOCHROME+y:}" "${SEDJUTSU_COLORS:-0;90:0;39:0;39:0;39:0;32:1;39:1;39:1;34}"/
  e
  /^[1-8]:/ ! {
    z
    s/^/SEDJUTSU_INDENT must be an integer between 1 and 8/
    b json_pp___ENV_FAILURE
  }
  # When set, SEDJUTSU_MONOCHROME disables color by using default escape sequences everywhere
  s/^\([1-8]\):y:.*/\1:0;39:0;39:0;39:0;39:0;39:0;39:0;39:0;39/
  /^[1-8]\(:[01];\(3[0-79]\|9[0-7]\)\)\{8\}/ ! {
    z
    s/^/SEDJUTSU_COLORS must be a colon-delimited list of 8 partial terminal escape sequences matching this pattern "[01];(3[0-79]|9[0-7])" and in this order: null:false:true:numbers:strings:arrays:objects:keys/
    b json_pp___ENV_FAILURE
  }
  t init_holdspace_check_env_and_reset_conditional_branching
  : init_holdspace_check_env_and_reset_conditional_branching
    s/^1:/\n\n :/
    t init_holdspace_end
    s/^2:/\n\n  :/
    t init_holdspace_end
    s/^3:/\n\n   :/
    t init_holdspace_end
    s/^4:/\n\n    :/
    t init_holdspace_end
    s/^5:/\n\n     :/
    t init_holdspace_end
    s/^6:/\n\n      :/
    t init_holdspace_end
    s/^7:/\n\n       :/
    t init_holdspace_end
    s/^8:/\n\n        :/
    : init_holdspace_end
      s/$/\n1\n1/
      x
      b json_pp__json

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
    z
    s/^/garbage after main element/
    b json_pp___PARSING_FAILURE

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
  z
  s/^/malformed JSON string, neither array, object, number, string or atom/
  b json_pp___PARSING_FAILURE

### object
###     '{' ws '}'
###     '{' members '}'
: json_pp___object
  /^{[\x20\x0a\x0d\x09]*}/ {
    s/.//
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
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_pp___PARSING_FAILURE
  }
  /^{/ {
    s/.//
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
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_pp___PARSING_FAILURE
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
    z
    s/^/`:` expected/
    b json_pp___PARSING_FAILURE
  : json_pp___member_4
    b json_pp___element

### array
###     '[' ws ']'
###     '[' elements ']'
: json_pp___array
  /^\[[\x20\x0a\x0d\x09]*]/ {
    s/.//
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
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_pp___PARSING_FAILURE
  }
  /^\[/ {
    s/.//
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
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_pp___PARSING_FAILURE
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
  z
  s/^/`"` expected while parsing JSON string/
  b json_pp___PARSING_FAILURE
  : json_pp___string_1
    b json_pp___characters
  : json_pp___string_2
    /^"/ {
      s/.//
      b incr_col
    }
    z
    s/^/Unexpected end of string while parsing JSON string/
    b json_pp___PARSING_FAILURE

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
    z
    s/^/Invalid character encountered/
    b json_pp___PARSING_FAILURE
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
  z
  s/^/Invalid escaped character encountered/
  b json_pp___PARSING_FAILURE

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
  z
  s/^/Invalid hexadecimal character encountered/
  b json_pp___PARSING_FAILURE

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
  z
  s/^/Invalid integer encountered/
  b json_pp___PARSING_FAILURE

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
  z
  s/^/Invalid digit encountered/
  b json_pp___PARSING_FAILURE

### onenine
###     '1' . '9'
: json_pp___onenine
  /^[1-9]/ {
    s/.//
    b incr_col
  }
  z
  s/^/Invalid onenine encountered/
  b json_pp___PARSING_FAILURE

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
    s/9\(_*\)$/_\1/
    t incr_col_nines2underscores
  : incr_col_lastdigit
    s/\n\(_*\)$/\n1\1/
    t incr_col_underscores2zeroes
    s/8\(_*\)$/9\1/
    t incr_col_underscores2zeroes
    s/7\(_*\)$/8\1/
    t incr_col_underscores2zeroes
    s/6\(_*\)$/7\1/
    t incr_col_underscores2zeroes
    s/5\(_*\)$/6\1/
    t incr_col_underscores2zeroes
    s/4\(_*\)$/5\1/
    t incr_col_underscores2zeroes
    s/3\(_*\)$/4\1/
    t incr_col_underscores2zeroes
    s/2\(_*\)$/3\1/
    t incr_col_underscores2zeroes
    s/1\(_*\)$/2\1/
    t incr_col_underscores2zeroes
    s/0\(_*\)$/1\1/
  : incr_col_underscores2zeroes
    s/_\(_*\)$/0\1/
    t incr_col_underscores2zeroes
  x
  b json_pp___RETURN

: incr_row
  x
  s/\n[^\n]\+$//
  s/^/ir/
  x
  b incr_col
  : incr_row_1
    x
    s/$/\n1/
    x
  b json_pp___RETURN

: incr4_col
  x
  s/9$/D/
  s/8$/C/
  s/7$/B/
  s/6$/A/
  : incr4_col_nines2As
    s/9\(A*[ABCD]\)$/A\1/
    t incr4_col_nines2As
  : incr4_col_ge10
    s/\n\(A*[ABCD]\)$/\n1\1/
    t incr4_col_lastdigit
    s/8\(A*[ABCD]\)$/9\1/
    t incr4_col_lastdigit
    s/7\(A*[ABCD]\)$/8\1/
    t incr4_col_lastdigit
    s/6\(A*[ABCD]\)$/7\1/
    t incr4_col_lastdigit
    s/5\(A*[ABCD]\)$/6\1/
    t incr4_col_lastdigit
    s/4\(A*[ABCD]\)$/5\1/
    t incr4_col_lastdigit
    s/3\(A*[ABCD]\)$/4\1/
    t incr4_col_lastdigit
    s/2\(A*[ABCD]\)$/3\1/
    t incr4_col_lastdigit
    s/1\(A*[ABCD]\)$/2\1/
    t incr4_col_lastdigit
    s/0\(A*[ABCD]\)$/1\1/
  : incr4_col_lastdigit
    s/5$/9/
    t incr4_col_letters2numbers
    s/4$/8/
    t incr4_col_letters2numbers
    s/3$/7/
    t incr4_col_letters2numbers
    s/2$/6/
    t incr4_col_letters2numbers
    s/1$/5/
    t incr4_col_letters2numbers
    s/0$/4/
  : incr4_col_letters2numbers
    s/A\(A*[BCD]\?\)/0\1/
    t incr4_col_letters2numbers
    s/B$/1/
    s/C$/2/
    s/D$/3/
  x
  b json_pp___RETURN

: incr5_col
  x
  s/9$/E/
  s/8$/D/
  s/7$/C/
  s/6$/B/
  s/5$/A/
  : incr5_col_nines2As
    s/9\(A*[ABCDE]\)$/A\1/
    t incr5_col_nines2As
  : incr5_col_ge10
    s/\n\(A*[ABCDE]\)$/\n1\1/
    t incr5_col_lastdigit
    s/8\(A*[ABCDE]\)$/9\1/
    t incr5_col_lastdigit
    s/7\(A*[ABCDE]\)$/8\1/
    t incr5_col_lastdigit
    s/6\(A*[ABCDE]\)$/7\1/
    t incr5_col_lastdigit
    s/5\(A*[ABCDE]\)$/6\1/
    t incr5_col_lastdigit
    s/4\(A*[ABCDE]\)$/5\1/
    t incr5_col_lastdigit
    s/3\(A*[ABCDE]\)$/4\1/
    t incr5_col_lastdigit
    s/2\(A*[ABCDE]\)$/3\1/
    t incr5_col_lastdigit
    s/1\(A*[ABCDE]\)$/2\1/
    t incr5_col_lastdigit
    s/0\(A*[ABCDE]\)$/1\1/
  : incr5_col_lastdigit
    s/4$/9/
    t incr5_col_letters2numbers
    s/3$/8/
    t incr5_col_letters2numbers
    s/2$/7/
    t incr5_col_letters2numbers
    s/1$/6/
    t incr5_col_letters2numbers
    s/0$/5/
  : incr5_col_letters2numbers
    s/A\(A*[BCDE]\?\)/0\1/
    t incr5_col_letters2numbers
    s/B$/1/
    s/C$/2/
    s/D$/3/
    s/E$/4/
  x
  b json_pp___RETURN

# Redirect the workflow depending of the first element in the workflow stack
: json_pp___RETURN
  x
  /^a1/ {
    s/..//
    x
    b json_pp___array_1
  }
  /^a2/ {
    s/..//
    x
    b json_pp___array_2
  }
  /^a3/ {
    s/..//
    x
    b json_pp___array_3
  }
  /^a4/ {
    s/..//
    x
    b json_pp___array_4
  }
  /^C1/ {
    s/..//
    x
    b json_pp___characters_1
  }
  /^c1/ {
    s/..//
    x
    b json_pp___character_1
  }
  /^D1/ {
    s/..//
    x
    b json_pp___digits_1
  }
  /^E1/ {
    s/..//
    x
    b json_pp___elements_1
  }
  /^E2/ {
    s/..//
    x
    b json_pp___elements_2
  }
  /^e1/ {
    s/..//
    x
    b json_pp___element_1
  }
  /^e2/ {
    s/..//
    x
    b json_pp___element_2
  }
  /^f1/ {
    s/..//
    x
    b json_pp___fraction_1
  }
  /^i1/ {
    s/..//
    x
    b json_pp___integer_1
  }
  /^i2/ {
    s/..//
    x
    b json_pp___integer_2
  }
  /^ir/ {
    s/..//
    x
    b incr_row_1
  }
  /^j1/ {
    s/..//
    x
    b json_pp___json_1
  }
  /^M1/ {
    s/..//
    x
    b json_pp___members_1
  }
  /^M2/ {
    s/..//
    x
    b json_pp___members_2
  }
  /^m1/ {
    s/..//
    x
    b json_pp___member_1
  }
  /^m2/ {
    s/..//
    x
    b json_pp___member_2
  }
  /^m3/ {
    s/..//
    x
    b json_pp___member_3
  }
  /^m4/ {
    s/..//
    x
    b json_pp___member_4
  }
  /^n1/ {
    s/..//
    x
    b json_pp___number_1
  }
  /^n2/ {
    s/..//
    x
    b json_pp___number_2
  }
  /^o1/ {
    s/..//
    x
    b json_pp___object_1
  }
  /^o2/ {
    s/..//
    x
    b json_pp___object_2
  }
  /^o3/ {
    s/..//
    x
    b json_pp___object_3
  }
  /^o4/ {
    s/..//
    x
    b json_pp___object_4
  }
  /^s1/ {
    s/..//
    x
    b json_pp___string_1
  }
  /^s2/ {
    s/..//
    x
    b json_pp___string_2
  }
  /^x1/ {
    s/..//
    x
    b json_pp___exponent_1
  }
  /^x2/ {
    s/..//
    x
    b json_pp___exponent_2
  }
  /^w1/ {
    s/..//
    x
    b json_pp___ws_1
  }
  /^w2/ {
    s/..//
    x
    b json_pp___ws_2
  }
  /^\\1/ {
    s/..//
    x
    b json_pp___escape_1
  }
  /^\\2/ {
    s/..//
    x
    b json_pp___escape_2
  }
  /^\\3/ {
    s/..//
    x
    b json_pp___escape_3
  }
  /^\\4/ {
    s/..//
    x
    b json_pp___escape_4
  }
  z
  s/^/"Unknown return code"/
  b json_pp___UNREACHABLE

: json_pp___UNREACHABLE
  s/^/Reached unreachable code in scripts\/json\/pretty-printer.sed: /
  s/$/\n/
  w /dev/stderr
  z
  Q 5

: json_pp___PARSING_FAILURE
  H
  x
  s/^[^\n]*\n\([0-9]\+\)\n\([0-9]\+\)/JSON parsing error at ROW \1, COL \2: /
  s/$/\n/
  w /dev/stderr
  z
  Q 6

: json_pp___ENV_FAILURE
  s/^/Error when parsing environment: /
  s/$/\n/
  w /dev/stderr
  z
  Q 7

: json_pp___SUCCESS
  z
  s/^/JSON parsing succeed\n/
  p
  z
