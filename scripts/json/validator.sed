### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `jq`, `json_pp` or `json_xs`    #
#   features. It checks if the input is formatted as a valid JSON. It         #
#   returns a success message if it is. Otherwise it returns the parsing      #
#   error location.                                                           #
#                                                                             #
#     If you do not want to see the trailing new line, use the                #
#   `-n`/`--quiet` option.                                                    #
#                                                                             #
#     For UTF-8 support, set (and export) the LC_CTYPE, LANG or LC_ALL        #
#   variables into your environment. Depending on your system you change      #
#   the value of one of these to   "C", "C.UTF-8" or "<lang_COUNTRY>.UTF-8"   #
#   (for example: "en_US.UTF-8").                                             #
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
#      representation of the backslash character) in their UTF-8 encoding.    #
#                                                                             #
### HOW TO RUN IT #############################################################
#                                                                             #
#   LC_CTYPE=C sed -znf scripts/json/validator.sed /path/to/your/file.json    #
#                                                                             #
#   printf '{"key": 0}\n' | LC_CTYPE=C sed -znf scripts/json/validator.sed    #
#                                                                             #
###############################################################################

v 4.0

# Init the holdspace with these variables:
# - an empty workflow stack
# - an empty stack to check object keys
# - row
# - col
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
  # We store \r into the object keys stack as a stop character
  s/.*\(.\)$/\1\r\1x\1x\1/
  /\x00$/ {
    x
    s/\x00/\n/g
    x
  }
  x
  /\x80\|\x81\|\x82\|\x83\|\x84\|\x85\|\x86\|\x87\|\x88\|\x89\|\x8a\|\x8b\|\x8c\|\x8d\|\x8e\|\x8f\|\x90\|\x91\|\x92\|\x93\|\x94\|\x95\|\x96\|\x97\|\x98\|\x99\|\x9a\|\x9b\|\x9c\|\x9d\|\x9e\|\x9f\|\xa0\|\xa1\|\xa2\|\xa3\|\xa4\|\xa5\|\xa6\|\xa7\|\xa8\|\xa9\|\xaa\|\xab\|\xac\|\xad\|\xae\|\xaf\|\xb0\|\xb1\|\xb2\|\xb3\|\xb4\|\xb5\|\xb6\|\xb7\|\xb8\|\xb9\|\xba\|\xbb\|\xbc\|\xbd\|\xbe\|\xbf\|\xc0\|\xc1\|\xc2\|\xc3\|\xc4\|\xc5\|\xc6\|\xc7\|\xc8\|\xc9\|\xca\|\xcb\|\xcc\|\xcd\|\xce\|\xcf\|\xd0\|\xd1\|\xd2\|\xd3\|\xd4\|\xd5\|\xd6\|\xd7\|\xd8\|\xd9\|\xda\|\xdb\|\xdc\|\xdd\|\xde\|\xdf\|\xe0\|\xe1\|\xe2\|\xe3\|\xe4\|\xe5\|\xe6\|\xe7\|\xe8\|\xe9\|\xea\|\xeb\|\xec\|\xed\|\xee\|\xef\|\xf0\|\xf1\|\xf2\|\xf3\|\xf4\|\xf5\|\xf6\|\xf7\|\xf8\|\xf9\|\xfa\|\xfb\|\xfc\|\xfd\|\xfe\|\xff/ {
    /^.*$/ ! {
      z
      s/^/UTF-8 encoding detected in your input. Export LC_CTYPE, LANG or LC_ALL in your environment to allow UTF-8 support with sed/
      b json_validator___ENV_FAILURE
    }
  }
  /^$/ {
    s/^/empty input/
    b json_validator___PARSING_FAILURE
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
    b json_validator___PARSING_FAILURE

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
  b json_validator___PARSING_FAILURE

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
      b json_validator___PARSING_FAILURE
  }
  /^{/ {
    s/.//
    x
    s/^/o2/
    # \t character to split keys between objects
    s/^[^\x00\n]*[\x00\n]\r/\0\t/
    s/[\n\x00]$/x\0/
    x
    b json_validator___members
    : json_validator___object_2
      /^}/ {
        s/.//
        x
        # Remove object keys
        s/^\([^\x00\n]*[\x00\n]\)[^\t]*\t/\1\r/
        s/[\n\x00]$/x\0/
        x
        b json_validator___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_validator___PARSING_FAILURE
  }
  z
  s/^/`{` expected while parsing JSON object/
  b json_validator___PARSING_FAILURE

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
    # Replace the carriage return character with a bell character into the hold space to indicate we want to store the string as an object key
    x
    s/^\([^\x00\n]*[\x00\n]\)\r/\1\a/
    x
    b json_validator___string
  : json_validator___member_2
    # Check the stored key
    x
    s/^[^\x00\n]*[\x00\n]/\0\a/
    /^[^\x00\n]*\x00/ {
      /^[^\x00]*\x00\(\a[^\a\t]*\a\)\(\a[^\a\t]*\a\)*\1/ {
        x
        g
        s/^[^\x00]*\x00\a\([^\a\t]*\).*/\1/
        s/./x/g
        G
        h
        x
        s/^\(x\+\)\x00\(\([^\x00]*\x00\)\{2\}x\+\x00\)\1x/\2/
        x
        s/^x\+\x00[^\x00]*\x00\a\([^\a\t]*\).*/JSON object with duplicated key "\1"/
        b json_validator___PARSING_FAILURE
      }
    }
    /^[^\x00\n]*\n/ {
      /^[^\n]*\n\(\a[^\a\t]*\a\)\(\a[^\a\t]*\a\)*\1/ {
        x
        g
        s/^[^\n]*\n\a\([^\a\t]*\).*/\1/
        s/./x/g
        G
        h
        x
        s/^\(x\+\)\n\(\([^\n]*\n\)\{2\}x\+\n\)\1x/\2/
        x
        s/^x\+\n[^\n]*\n\a\([^\a\t]*\).*/JSON object with duplicated key "\1"/
        b json_validator___PARSING_FAILURE
      }
    }
    # Add the stop character
    s/^[^\x00\n]*[\x00\n]/\0\r/
    x
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
    b json_validator___PARSING_FAILURE

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
      b json_validator___PARSING_FAILURE
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
      b json_validator___PARSING_FAILURE
  }
  z
  s/^/`[` expected while parsing JSON array/
  b json_validator___PARSING_FAILURE

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
  b json_validator___PARSING_FAILURE
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
    b json_validator___PARSING_FAILURE

### characters
###     character characters
###     ""
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
    b json_validator___PARSING_FAILURE
  }
  x
  s/[\n\x00]$/x\0/
  # Add the character if it is part of an object key
  /^[^\x00\n]*[\x00\n][^\r]/ {
    x
    H
    x
    /^[^\x00\n]*\x00/ {
      s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2/
    }
    /^[^\x00\n]*\n/ {
      s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2/
    }
  }
  x
  s/.//
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
    # Add the character if it is part of an object key
    /^[^\x00\n]*[\x00\n][^\r]/ {
      s/^[^\x00\n]*[\x00\n]/\0u/
    }
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
    x
    s/[\n\x00]$/x\0/
    # Add the character if it is part of an object key
    /^[^\x00\n]*[\x00\n][^\r]/ {
      x
      H
      x
      /^[^\x00\n]*\x00/ {
        s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2/
      }
      /^[^\x00\n]*\n/ {
        s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2/
      }
    }
    x
    s/.//
    b json_validator___RETURN
  }
  z
  s/^/Invalid escaped character encountered/
  b json_validator___PARSING_FAILURE

### hex
###     digit
###     'A' . 'F'
###     'a' . 'f'
: json_validator___hex
  /^[A-Fa-f]/ {
    x
    s/[\n\x00]$/x\0/
    # Add the character if it is part of an object key
    /^[^\x00\n]*[\x00\n][^\r]/ {
      x
      H
      x
      /^[^\x00\n]*\x00/ {
        s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2/
      }
      /^[^\x00\n]*\n/ {
        s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2/
      }
    }
    x
    s/.//
    b json_validator___RETURN
  }
  /^[0-9]/ {
    b json_validator___digit
  }
  z
  s/^/Invalid hexadecimal character encountered/
  b json_validator___PARSING_FAILURE

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
  b json_validator___PARSING_FAILURE

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
    # Add the character if it is part of an object key
    /^[^\x00\n]*[\x00\n][^\r]/ {
      s/^[^\x00\n]*[\x00\n]/\00/
    }
    x
    b json_validator___RETURN
  }
  /^[1-9]/ {
    b json_validator___onenine
  }
  z
  s/^/Invalid digit encountered/
  b json_validator___PARSING_FAILURE

### onenine
###     '1' . '9'
: json_validator___onenine
  /^[1-9]/ {
    x
    s/[\n\x00]$/x\0/
    # Add the character if it is part of an object key
    /^[^\x00\n]*[\x00\n][^\r]/ {
      x
      H
      x
      /^[^\x00\n]*\x00/ {
        s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2/
      }
      /^[^\x00\n]*\n/ {
        s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2/
      }
    }
    x
    s/.//
    b json_validator___RETURN
  }
  z
  s/^/Invalid onenine encountered/
  b json_validator___PARSING_FAILURE

### fraction
###     '.' digits
###     ""
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
###     'E' sign digits
###     'e' sign digits
###     ""
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
###     '+'
###     '-'
###     ""
: json_validator___sign
  /^[-+]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
  }
  b json_validator___RETURN

### ws
###     '0020' ws
###     '000A' ws
###     '000D' ws
###     '0009' ws
###     ""
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

# Redirect the workflow depending on the first element in the workflow stack
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

: json_validator___COMPUTE_PARSING_FAILURE_LOCATION
  : json_validator___COMPUTE_PARSING_FAILURE_LOCATION_ROW
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
      b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_ROW_NEXT
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_ROW_NEXT
    }
    G
    s/[\x00\n]//
    s/[\x00\n][^\x00\n]*$//
    x
    s/^\([xyz]*[\x00\n]\)\{2\}//
    x
    b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_COL
    : json_validator___COMPUTE_PARSING_FAILURE_LOCATION_ROW_NEXT
      G
      s/[\x00\n]//
      s/[\x00\n][^\x00\n]*$//
      x
      s/^\([xyz]*[\x00\n]\)\{2\}//
      x
      b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_ROW
  : json_validator___COMPUTE_PARSING_FAILURE_LOCATION_COL
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
      b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_COL_NEXT
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_COL_NEXT
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
    b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_END
    : json_validator___COMPUTE_PARSING_FAILURE_LOCATION_COL_NEXT
      G
      s/[\x00\n][^\x00\n]*[\x00\n]//
      x
      s/[\x00\n].*$//
      G
      h
      s/^[xyz]*[\x00\n][xyz]*//
      x
      s/^\([xyz]*[\x00\n][xyz]*\).*/\1/
      b json_validator___COMPUTE_PARSING_FAILURE_LOCATION_COL
  : json_validator___COMPUTE_PARSING_FAILURE_LOCATION_END
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
      b json_validator___PARSING_FAILURE_NUL
    }
    b json_validator___PARSING_FAILURE_NEWLINE

: json_validator___UNREACHABLE
  x
  /^[^\x00\n]*\x00/ {
    x
    s/.*/\x1b[0mReached unreachable code in scripts\/json\/validator.sed: \0\n/
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    # If outside the scope it triggers the next conditional statement
    z
  }
  /^[^\x00\n]*\n/ {
    x
    s/^/\x1b[0mReached unreachable code in scripts\/json\/validator.sed: /
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    z
  }
  Q 5

: json_validator___PARSING_FAILURE
  x
  /^[^\x00\n]*\x00/ {
    s/.*\x00\(x\+\x00x\+\)\x00$/\1/
    b json_validator___COMPUTE_PARSING_FAILURE_LOCATION
    : json_validator___PARSING_FAILURE_NUL
      x
      H
      x
      s/^\([0-9]\+\)\x00\([0-9]\+\)\x00\(.*\)/JSON parsing error at ROW \1, COL \2: \3\n/
      # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
      w /dev/stderr
      z
  }
  /^[^\x00\n]*\n/ {
    s/.*\n\(x\+\nx\+\)\n$/\1/
    b json_validator___COMPUTE_PARSING_FAILURE_LOCATION
    : json_validator___PARSING_FAILURE_NEWLINE
      x
      H
      x
      s/^\([0-9]\+\)\n\([0-9]\+\)\n*/JSON parsing error at ROW \1, COL \2: /
      # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
      w /dev/stderr
      # If outside the scope it triggers the next conditional statement
      z
  }
  Q 6

: json_validator___ENV_FAILURE
  x
  /^[^\x00\n]*\x00/ {
    x
    s/.*/\x1b[0mError in your environment: \0\n/
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    # If outside the scope it triggers the next conditional statement
    z
  }
  /^[^\x00\n]*\n/ {
    x
    s/^/\x1b[0mError in your environment: /
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    z
  }
  Q 7

: json_validator___SUCCESS
  x
  /^[^\x00\n]*\x00/ {
    x
    z
    s/^/JSON parsing succeed\n/
    # If the next commands are outside this scope it triggers the next conditional statement
    p
    z
  }
  /^[^\x00\n]*\n/ {
    x
    z
    s/^/JSON parsing succeed/
    p
    z
  }
