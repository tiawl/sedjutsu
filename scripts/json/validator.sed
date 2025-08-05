### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `jq`, `json_pp` or `json_xs`    #
#   features.                                                                 #
#                                                                             #
#     If you do not want to see the trailing new line, use the                #
#   `-n`/`--quiet` option.                                                    #
#                                                                             #
#     For UTF-8 support, you need to set and export the LC_CTYPE, LANG or     #
#   LC_ALL variables into your environment. You can also set it with the      #
#   `env` utility if exporting one of these variable is not possible          #
#   outside the running environment. Depending of your system you need to     #
#   change the value of one of these with "C", "C.UTF-8" or                   #
#   "<lang_COUNTRY>.UTF-8" (for example: "en_US.UTF-8").                      #
#                                                                             #
### KNOWN LIMITATIONS #########################################################
#                                                                             #
#   1) If your input file is empty, this script will parse it successfully    #
#      because `sed` does not operate on empty files. An empty file should    #
#      result in a parsing error.                                             #
#                                                                             #
#   2) The RFC 8259 specifies that an unescaped character could be any        #
#      character between \x20 and 10FFFF except double-quotes `"` and         #
#      backslash `\` characters. However with `sed` there is no way to        #
#      match unicode characters with code point greater than 255.             #
#      Because of this restriction, `sed` can not make distinction between    #
#      matching a string of 4 UTF-8 characters, a string of 2 UTF-16          #
#      characters or 1 UTF-32 character. To override this difficulty          #
#      without betraying more conventions in the JSON specification, the      #
#      script handles characters as UTF-8 characters whatever their           #
#      encoding. The cost of this decision is a more restrictive validator.   #
#      The script will fail to parse JSON strings with UTF-16 or UTF-32       #
#      characters which contain \x00 to \x1f or \x22 (hexadecimal             #
#      representation of the double-quotes character) or \x5c (hexadecimal    #
#      representation of the backslash character) in their code points.       #
#                                                                             #
###############################################################################

# TODO: Error for JSON objects with duplicated keys

# Init the holdspace with these variables:
# - an empty workflow stack
# - row
# - col
: init_holdspace
  $! {
    N
    b init_holdspace
  }
  # Depending of the `-z`/`--null-data` option usage, the `D`, `G`, `H`, `N` and `P` sed commands work with new line or NUL characters. This script must know which one of these characters these commands are using
  G
  h
  s/.$//
  x
  s/.*\(.\)$/\1x\1x\1/
  /\x00$/ {
    x
    s/\x00/\n/g
    x
  }
  x
  /^$/ {
    s/^/empty input/
    b json_validator___FAILURE
  }
  b json_validator___json

#
# JSON grammar in McKeeman Form
#

### json
###    element
: json_validator___json
  x
  s/^/j1/
  x
  b json_validator___element
  : json_validator___json_1
    /^$/ {
      b json_validator___SUCCESS
    }
    z
    s/^/garbage after main element/
    b json_validator___FAILURE

### value
###    object
###    array
###    string
###    number
###    "true"
###    "false"
###    "null"
: json_validator___value
  /^{/ {
    b json_validator___object
  }
  /^\[/ {
    b json_validator___array
  }
  /^"/ {
    b json_validator___string
  }
  /^[-0-9]/ {
    b json_validator___number
  }
  /^true/ {
    s/....//
    x
    s/[\n\x00]$/xxxx\0/
    x
    b json_validator___RETURN
  }
  /^false/ {
    s/.....//
    x
    s/[\n\x00]$/xxxxx\0/
    x
    b json_validator___RETURN
  }
  /^null/ {
    s/....//
    x
    s/[\n\x00]$/xxxx\0/
    x
    b json_validator___RETURN
  }
  z
  s/^/malformed JSON string, neither array, object, number, string or atom/
  b json_validator___FAILURE

### object
###     '{' ws '}'
###     '{' members '}'
: json_validator___object
  /^{[\x20\x0a\x0d\x09]*}/ {
    s/.//
    x
    s/^/o1/
    s/[\n\x00]$/x\0/
    x
    b json_validator___ws
    : json_validator___object_1
      /^}/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_validator___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_validator___FAILURE
  }
  /^{/ {
    s/.//
    x
    s/^/o2/
    s/[\n\x00]$/x\0/
    x
    b json_validator___members
    : json_validator___object_2
      /^}/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_validator___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_validator___FAILURE
  }
  z
  s/^/`{` expected while parsing JSON object/
  b json_validator___FAILURE

### members
###     member
###     member ',' members
: json_validator___members
  x
  s/^/M1/
  x
  b json_validator___member
  : json_validator___members_1
    /^,/ {
      s/.//
      x
      s/[\n\x00]$/x\0/
      x
      b json_validator___members
    }
    b json_validator___RETURN

### member
###     ws string ws ':' element
: json_validator___member
  x
  s/^/m1m2m3/
  x
  b json_validator___ws
  : json_validator___member_1
    b json_validator___string
  : json_validator___member_2
    b json_validator___ws
  : json_validator___member_3
    /^:/ {
      s/.//
      x
      s/[\n\x00]$/x\0/
      x
      b json_validator___element
    }
    z
    s/^/`:` expected/
    b json_validator___FAILURE

### array
###     '[' ws ']'
###     '[' elements ']'
: json_validator___array
  /^\[[\x20\x0a\x0d\x09]*]/ {
    s/.//
    x
    s/^/a1/
    s/[\n\x00]$/x\0/
    x
    b json_validator___ws
    : json_validator___array_1
      /^]/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_validator___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_validator___FAILURE
  }
  /^\[/ {
    s/.//
    x
    s/^/a2/
    s/[\n\x00]$/x\0/
    x
    b json_validator___elements
    : json_validator___array_2
      /^]/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_validator___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_validator___FAILURE
  }
  z
  s/^/`[` expected while parsing JSON array/
  b json_validator___FAILURE

### elements
###     element
###     element ',' elements
: json_validator___elements
  x
  s/^/E1/
  x
  b json_validator___element
  : json_validator___elements_1
    /^,/ {
      s/.//
      x
      s/[\n\x00]$/x\0/
      x
      b json_validator___elements
    }
    b json_validator___RETURN

### element
###     ws value ws
: json_validator___element
  x
  s/^/e1e2/
  x
  b json_validator___ws
  : json_validator___element_1
    b json_validator___value
  : json_validator___element_2
    b json_validator___ws

### string
### '"' characters '"'
: json_validator___string
  x
  s/^/s1/
  x
  /^"/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___characters
  }
  z
  s/^/`"` expected while parsing JSON string/
  b json_validator___FAILURE
  : json_validator___string_1
    /^"/ {
      s/.//
      x
      s/[\n\x00]$/x\0/
      x
      b json_validator___RETURN
    }
    z
    s/^/Unexpected end of string while parsing JSON string/
    b json_validator___FAILURE

### characters
###     ""
###     character characters
: json_validator___characters
  /^[^\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"]/ {
    x
    s/^/C1/
    x
    b json_validator___character
    : json_validator___characters_1
      b json_validator___characters
  }
  b json_validator___RETURN

### character
###     '0020' . '10FFFF' - '"' - '\'
###     '\' escape
: json_validator___character
  /^\\/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___escape
  }
  /^[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"]/ {
    z
    s/^/Invalid character encountered/
    b json_validator___FAILURE
  }
  s/.//
  x
  s/[\n\x00]$/x\0/
  x
  b json_validator___RETURN

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
: json_validator___escape
  /^u/ {
    s/.//
    x
    s/^/\\1\\2\\3/
    s/[\n\x00]$/x\0/
    x
    b json_validator___hex
    : json_validator___escape_1
      b json_validator___hex
    : json_validator___escape_2
      b json_validator___hex
    : json_validator___escape_3
      b json_validator___hex
  }
  /^["\\/bfnrt]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___RETURN
  }
  z
  s/^/Invalid escaped character encountered/
  b json_validator___FAILURE

### hex
###     digit
###     'A' . 'F'
###     'a' . 'f'
: json_validator___hex
  /^[A-Fa-f]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___RETURN
  }
  /^[0-9]/ {
    b json_validator___digit
  }
  z
  s/^/Invalid hexadecimal character encountered/
  b json_validator___FAILURE

### number
###     integer fraction exponent
: json_validator___number
  x
  s/^/n1n2/
  x
  b json_validator___integer
  : json_validator___number_1
    b json_validator___fraction
  : json_validator___number_2
    b json_validator___exponent

### integer
###     digit
###     onenine digits
###     '-' digit
###     '-' onenine digits
: json_validator___integer
  /^-/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
  }
  /^[1-9][0-9]/ {
    x
    s/^/i1/
    x
    b json_validator___onenine
    : json_validator___integer_1
      b json_validator___digits
  }
  /^[0-9]/ {
    b json_validator___digit
  }
  z
  s/^/Invalid integer encountered/
  b json_validator___FAILURE

### digits
###     digit
###     digit digits
: json_validator___digits
  /^[0-9][0-9]/ {
    x
    s/^/D1/
    x
  }
  b json_validator___digit
  : json_validator___digits_1
    b json_validator___digits

### digit
###     '0'
###     onenine
: json_validator___digit
  /^0/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___RETURN
  }
  /^[1-9]/ {
    b json_validator___onenine
  }
  z
  s/^/Invalid digit encountered/
  b json_validator___FAILURE

### onenine
###     '1' . '9'
: json_validator___onenine
  /^[1-9]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___RETURN
  }
  z
  s/^/Invalid onenine encountered/
  b json_validator___FAILURE

### fraction
###     ""
###     '.' digits
: json_validator___fraction
  /^\./ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___digits
  }
  b json_validator___RETURN

### exponent
###     ""
###     'E' sign digits
###     'e' sign digits
: json_validator___exponent
  /^[eE]/ {
    s/.//
    x
    s/^/x1/
    s/[\n\x00]$/x\0/
    x
    b json_validator___sign
    : json_validator___exponent_1
      b json_validator___digits
  }
  b json_validator___RETURN

### sign
###     ""
###     '+'
###     '-'
: json_validator___sign
  /^[-+]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
  }
  b json_validator___RETURN

### ws
###     ""
###     '0020' ws
###     '000A' ws
###     '000D' ws
###     '0009' ws
: json_validator___ws
  /^\x0a/ {
    s/.//
    x
    s/[\n\x00]x\+\([\n\x00]\)$/x\1x\1/
    x
    b json_validator___ws
  }
  /^[\x20\x0d\x09]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_validator___ws
  }
  b json_validator___RETURN

# Redirect the workflow depending of the first element in the workflow stack
: json_validator___RETURN
  x
  /^a1/ {
    s/..//
    x
    b json_validator___array_1
  }
  /^a2/ {
    s/..//
    x
    b json_validator___array_2
  }
  /^C1/ {
    s/..//
    x
    b json_validator___characters_1
  }
  /^D1/ {
    s/..//
    x
    b json_validator___digits_1
  }
  /^E1/ {
    s/..//
    x
    b json_validator___elements_1
  }
  /^e1/ {
    s/..//
    x
    b json_validator___element_1
  }
  /^e2/ {
    s/..//
    x
    b json_validator___element_2
  }
  /^i1/ {
    s/..//
    x
    b json_validator___integer_1
  }
  /^j1/ {
    s/..//
    x
    b json_validator___json_1
  }
  /^M1/ {
    s/..//
    x
    b json_validator___members_1
  }
  /^m1/ {
    s/..//
    x
    b json_validator___member_1
  }
  /^m2/ {
    s/..//
    x
    b json_validator___member_2
  }
  /^m3/ {
    s/..//
    x
    b json_validator___member_3
  }
  /^n1/ {
    s/..//
    x
    b json_validator___number_1
  }
  /^n2/ {
    s/..//
    x
    b json_validator___number_2
  }
  /^o1/ {
    s/..//
    x
    b json_validator___object_1
  }
  /^o2/ {
    s/..//
    x
    b json_validator___object_2
  }
  /^s1/ {
    s/..//
    x
    b json_validator___string_1
  }
  /^x1/ {
    s/..//
    x
    b json_validator___exponent_1
  }
  /^\\1/ {
    s/..//
    x
    b json_validator___escape_1
  }
  /^\\2/ {
    s/..//
    x
    b json_validator___escape_2
  }
  /^\\3/ {
    s/..//
    x
    b json_validator___escape_3
  }
  z
  s/^/"Unknown return code"/
  b json_validator___UNREACHABLE

: json_validator___COMPUTE_FAILURE_LOCATION
  : json_validator___COMPUTE_FAILURE_LOCATION_ROW
    G
    h
    s/^\([xyz]*\)[\x00\n].*/\1/
    x
    s/^x*\|^y*//
    x
    s/^\(x\+\).*\|^\(y\+\).*/\1\2/
    /xxxxxxxxxx/ {
      s/xxxxxxxxxx/y/g
      # If the pattern space if full of 'y' we add a trailing 'z' to replace it later with a '0'
      s/^y\+$/\0z/
      b json_validator___COMPUTE_FAILURE_LOCATION_ROW_next
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_validator___COMPUTE_FAILURE_LOCATION_ROW_next
    }
    G
    s/[\x00\n]//
    s/[\x00\n][^\x00\n]*$//
    x
    s/^\([xyz]*[\x00\n]\)\{2\}//
    x
    b json_validator___COMPUTE_FAILURE_LOCATION_COL
    : json_validator___COMPUTE_FAILURE_LOCATION_ROW_next
      G
      s/[\x00\n]//
      s/[\x00\n][^\x00\n]*$//
      x
      s/^\([xyz]*[\x00\n]\)\{2\}//
      x
      b json_validator___COMPUTE_FAILURE_LOCATION_ROW
  : json_validator___COMPUTE_FAILURE_LOCATION_COL
    G
    h
    s/^[xyz]*[\x00\n]\([xyz]*\)[\x00\n].*/\1/
    x
    s/\([\x00\n]\)x*\|\([\x00\n]\)y*/\1\2/
    x
    s/^\(x\+\).*\|^\(y\+\).*/\1\2/
    /xxxxxxxxxx/ {
      s/xxxxxxxxxx/y/g
      # If the pattern space if full of 'y' we add a trailing 'z' to replace it later with a '0'
      s/^y\+$/\0z/
      b json_validator___COMPUTE_FAILURE_LOCATION_COL_next
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_validator___COMPUTE_FAILURE_LOCATION_COL_next
    }
    G
    s/[\x00\n][^\x00\n]*[\x00\n]//
    x
    s/[\x00\n].*$//
    G
    h
    s/^[xyz]*[\x00\n][xyz]*//
    x
    s/^\([xyz]*[\x00\n][xyz]*\).*/\1/
    b json_validator___COMPUTE_FAILURE_LOCATION_END
    : json_validator___COMPUTE_FAILURE_LOCATION_COL_next
      G
      s/[\x00\n][^\x00\n]*[\x00\n]//
      x
      s/[\x00\n].*$//
      G
      h
      s/^[xyz]*[\x00\n][xyz]*//
      x
      s/^\([xyz]*[\x00\n][xyz]*\).*/\1/
      b json_validator___COMPUTE_FAILURE_LOCATION_COL
  : json_validator___COMPUTE_FAILURE_LOCATION_END
    s/xxxxxxxxx\|yyyyyyyyy/9/g
    s/xxxxxxxx\|yyyyyyyy/8/g
    s/xxxxxxx\|yyyyyyy/7/g
    s/xxxxxx\|yyyyyy/6/g
    s/xxxxx\|yyyyy/5/g
    s/xxxx\|yyyy/4/g
    s/xxx\|yyy/3/g
    s/xx\|yy/2/g
    s/x\|y/1/g
    s/z/0/g
    /\x00/ {
      b json_validator___FAILURE_NUL
    }
    b json_validator___FAILURE_NEWLINE

: json_validator___UNREACHABLE
  x
  /\x00$/ {
    x
    s/.*/\x1b[0mReached unreachable code in scripts\/json\/validator.sed: \0\n/
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    # If outside the scope it triggers the next conditional statement
    z
  }
  /\n$/ {
    x
    s/^/\x1b[0mReached unreachable code in scripts\/json\/validator.sed: /
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    z
  }
  Q 5

: json_validator___FAILURE
  x
  /[^\n\x00]$/ {
    z
    s/^/"Hold space must end with a new line or NUL character"/
    b json_validator___UNREACHABLE
  }
  /\x00$/ {
    s/.*\x00\(x\+\x00x\+\)\x00$/\1/
    b json_validator___COMPUTE_FAILURE_LOCATION
    : json_validator___FAILURE_NUL
      x
      H
      x
      s/^\([0-9]\+\)\x00\([0-9]\+\)\x00\(.*\)/JSON parsing error at ROW \1, COL \2: \3\n/
      # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
      w /dev/stderr
      z
  }
  /\n$/ {
    s/.*\n\(x\+\nx\+\)\n$/\1/
    b json_validator___COMPUTE_FAILURE_LOCATION
    : json_validator___FAILURE_NEWLINE
      x
      H
      x
      s/^\([0-9]\+\)\n\([0-9]\+\)\n/JSON parsing error at ROW \1, COL \2: /
      # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
      w /dev/stderr
      # If outside the scope it triggers the next conditional statement
      z
  }
  Q 6

: json_validator___SUCCESS
  x
  /[^\n\x00]$/ {
    z
    s/^/"Hold space must end with a new line or NUL character"/
    b json_validator___UNREACHABLE
  }
  /\x00$/ {
    x
    z
    s/^/JSON parsing succeed\n/
    # If the next commands are outside this scope it triggers the next conditional statement
    p
    z
  }
  /\n$/ {
    x
    z
    s/^/JSON parsing succeed/
    p
    z
  }
