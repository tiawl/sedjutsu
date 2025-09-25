### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `jq`, `json_pp` or `json_xs`    #
#   features. It checks if the input is formatted as a valid JSON, add        #
#   colors, indentation and print. It returns the parsing error location      #
#   in case of failure.                                                       #
#                                                                             #
#     If you do not want to see the trailing new line, use the                #
#   `-n`/`--quiet` option.                                                    #
#                                                                             #
#     For UTF-8 support, set (and export) the LC_CTYPE, LANG or LC_ALL        #
#   variables into your environment. Depending on your system you change      #
#   the value of one of these to "C", "C.UTF-8" or "<lang_COUNTRY>.UTF-8"     #
#   (for example: "en_US.UTF-8").                                             #
#                                                                             #
#     You can configure this script behavior by providing these               #
#   environment variables:                                                    #
#   - SEDJUTSU_INDENT: use the given number of spaces (between 1 and 8)       #
#     for indentation (default: 4)                                            #
#   - SEDJUTSU_NOCOLOR: disable color. The script will consider this          #
#     variable whatever its value (even empty).                               #
#   - SEDJUTSU_COLORS: colon-separated list of partial terminal escape        #
#     sequences like "1;31", in this order:                                   #
#     * color for null                                                        #
#     * color for false                                                       #
#     * color for true                                                        #
#     * color for numbers                                                     #
#     * color for strings                                                     #
#     * color for arrays                                                      #
#     * color for objects                                                     #
#     * color for object keys                                                 #
#     The default value is "0;90:0;39:0;39:0;39:0;32:1;39:1;39:1;34".         #
#   If SEDJUTSU_NOCOLOR and SEDJUTSU_COLORS are both exported in your         #
#   environment, SEDJUTSU_NOCOLOR prevails.                                   #
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
#   LC_CTYPE=C sed -znf scripts/json/pretty-printer.sed /path/to/your/json    #
#                                                                             #
#   printf '{"k":0}' | LC_CTYPE=C sed -znf scripts/json/pretty-printer.sed    #
#                                                                             #
###############################################################################

# Init the holdspace with these variables:
# - an empty workflow stack
# - an empty stack to check object keys
# - env vars
# - the next line to print
# - env vars (yes, again: [1] env vars are readonly, so there is no risk of a potential sync error between the 2 locations in the hold space, [2] having a copy here, allow us to remove part of the complexity into (already too) complex regex patterns later)
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
  # Map the NUL characters to `Z` characters because shell does not support it
  /\x00$/ {
    z
    s/^/printf '%s:%s%sZ' "${SEDJUTSU_INDENT:-4}" "${SEDJUTSU_NOCOLOR+y:}" "${SEDJUTSU_COLORS:-0;90:0;39:0;39:0;39:0;32:1;39:1;39:1;34}"/
  }
  /\n$/ {
    z
    s/^/printf '%s:%s%s\n\n' "${SEDJUTSU_INDENT:-4}" "${SEDJUTSU_NOCOLOR+y:}" "${SEDJUTSU_COLORS:-0;90:0;39:0;39:0;39:0;32:1;39:1;39:1;34}"/
  }
  e
  /Z$/ {
    s/.$/\x00/
  }
  /^[1-8]:/ ! {
    h
    z
    s/^/SEDJUTSU_INDENT must be an integer between 1 and 8/
    b json_pp___ENV_FAILURE
  }
  # When set, SEDJUTSU_NOCOLOR disables color by using default escape sequences everywhere
  s/^\([2-8]\):y:[^\n\x00]*/\1::::::::/
  /^[2-8]\(\(:[0-57-9];\(3[0-79]\|9[0-7]\)\)\{8\}\|::::::::\)/ ! {
    h
    z
    s/^/SEDJUTSU_COLORS must be a colon-delimited list of 8 partial terminal escape sequences matching this pattern "[0-57-9];(3[0-79]|9[0-7])" and in this order: null:false:true:numbers:strings:arrays:objects:keys/
    b json_pp___ENV_FAILURE
  }
  t init_holdspace_reset_conditional_branching
  : init_holdspace_reset_conditional_branching
    s/^1:/ :/
    t init_holdspace_end
    s/^2:/  :/
    t init_holdspace_end
    s/^3:/   :/
    t init_holdspace_end
    s/^4:/    :/
    t init_holdspace_end
    s/^5:/     :/
    t init_holdspace_end
    s/^6:/      :/
    t init_holdspace_end
    s/^7:/       :/
    t init_holdspace_end
    s/^8:/        :/
    : init_holdspace_end
      # We store \r into the object keys stack as a stop character
      s/\(.*\)\([\n\x00]\)$/\2\r\2\1\2\2\1\2x\2x\2/
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
          b json_pp___ENV_FAILURE
        }
      }
      /^$/ {
        s/^/empty input/
        b json_pp___PARSING_FAILURE
      }
      b json_pp___json

#
# JSON grammar in McKeeman Form
#

### json
###    element
: json_pp___json
  x
  s/^/j1j2/
  x
  b json_pp___element
  : json_pp___json_1
    /^$/ {
      b json_pp___PRINT
      : json_pp___json_2
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
    x
    s/^/v1/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{3\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{3\}\(\nx\+\)\{2\}\n$/\x1b[\1m\0/
      }
    }
    x
    b json_pp___string
    : json_pp___value_1
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
          s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\x1b[0m\0/
        }
      }
      /^[^\x00\n]*\n/ {
        /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
          s/\n[^\n]*\(\nx\+\)\{2\}\n$/\x1b[0m\0/
        }
      }
      x
      b json_pp___RETURN
  }
  /^[-0-9]/ {
    b json_pp___number
  }
  /^true/ {
    s/....//
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{5\}\(\x00x\+\)\{2\}\x00$/\x1b[\1mtrue\x1b[0m\0/
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
        s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/true\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{5\}\(\nx\+\)\{2\}\n$/\x1b[\1mtrue\x1b[0m\0/
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ {
        s/\n[^\n]\+\(\nx\+\)\{2\}\n$/true\0/
      }
    }
    s/[\n\x00]$/xxxx\0/
    x
    b json_pp___RETURN
  }
  /^false/ {
    s/.....//
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{6\}\(\x00x\+\)\{2\}\x00$/\x1b[\1mfalse\x1b[0m\0/
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
        s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/false\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{6\}\(\nx\+\)\{2\}\n$/\x1b[\1mfalse\x1b[0m\0/
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ {
        s/\n[^\n]\+\(\nx\+\)\{2\}\n$/false\0/
      }
    }
    s/[\n\x00]$/xxxxx\0/
    x
    b json_pp___RETURN
  }
  /^null/ {
    s/....//
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{7\}\(\x00x\+\)\{2\}\x00$/\x1b[\1mnull\x1b[0m\0/
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
        s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/null\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{7\}\(\nx\+\)\{2\}\n$/\x1b[\1mnull\x1b[0m\0/
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ {
        s/\n[^\n]\+\(\nx\+\)\{2\}\n$/null\0/
      }
    }
    s/[\n\x00]$/xxxx\0/
    x
    b json_pp___RETURN
  }
  z
  s/^/malformed JSON string, neither array, object, number, string or atom/
  b json_pp___PARSING_FAILURE

### object
###     '{' ws '}'
###     '{' members '}'
: json_pp___object
  /^{[ \n\r\t]*}/ {
    s/.//
    x
    s/^/o1/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m{}\x1b[0m\0/
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
        s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/{}\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m{}\x1b[0m\0/
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ {
        s/\n[^\n]\+\(\nx\+\)\{2\}\n$/{}\0/
      }
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___ws
    : json_pp___object_1
      /^}/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_pp___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_pp___PARSING_FAILURE
  }
  /^{/ {
    s/.//
    x
    s/^/o2o3o4/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m{\x1b[0m\0/
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
        s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/{\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m{\x1b[0m\0/
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ {
        s/\n[^\n]\+\(\nx\+\)\{2\}\n$/{\0/
      }
    }
    x
    b json_pp___PRINT
    : json_pp___object_2
      x
      # Increment the indent level
      /^[^\x00\n]*\x00/ {
        s/^\([^\x00]*\x00\)\{2\}\( \+\):[^\x00]*\x00/\0\2/
      }
      /^[^\x00\n]*\n/ {
        s/^\([^\n]*\n\)\{2\}\( \+\):[^\n]*\n/\0\2/
      }
      # \t character to split keys between objects
      s/^[^\x00\n]*[\x00\n]\r/\0\t/
      s/[\n\x00]$/x\0/
      x
      b json_pp___members
    : json_pp___object_3
      /^}/ {
        s/.//
        b json_pp___PRINT
        : json_pp___object_4
          x
          /^[^\x00\n]*\x00/ {
            # Decrement the indent level
            s/^\([^\x00]*\x00[^\x00]*\x00\)\( \+\)\(:[^\x00]*\x00\)\2/\1\2\3/
            # Format the output for the next line to print
            /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
              s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m}\x1b[0m\0/
            }
            /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
              s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/}\0/
            }
          }
          /^[^\x00\n]*\n/ {
            # Decrement the indent level
            s/^\([^\n]*\n[^\n]*\n\)\( \+\)\(:[^\n]*\n\)\2/\1\2\3/
            # Format the output for the next line to print
            /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
              s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m}\x1b[0m\0/
            }
            /^\([^\n]*\n\)\{2\} *::::::::\n/ {
              s/\n[^\n]\+\(\nx\+\)\{2\}\n$/}\0/
            }
          }
          # Remove object keys
          s/^\([^\x00\n]*[\x00\n]\)[^\t]*\t/\1\r/
          s/[\n\x00]$/x\0/
          x
          b json_pp___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_pp___PARSING_FAILURE
  }
  z
  s/^/`{` expected while parsing JSON object/
  b json_pp___PARSING_FAILURE

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
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
          s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m,\x1b[0m\0/
        }
        /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
          s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/,\0/
        }
      }
      /^[^\x00\n]*\n/ {
        /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
          s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m,\x1b[0m\0/
        }
        /^\([^\n]*\n\)\{2\} *::::::::\n/ {
          s/\n[^\n]\+\(\nx\+\)\{2\}\n$/,\0/
        }
      }
      s/[\n\x00]$/x\0/
      x
      b json_pp___PRINT
      : json_pp___members_2
        b json_pp___members
    }
    b json_pp___RETURN

### member
###     ws string ws ':' element
: json_pp___member
  x
  s/^/m1m2m3/
  x
  b json_pp___ws
  : json_pp___member_1
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\)\(\x00x\+\)\{2\}\x00$/\x1b[\1m\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\)\(\nx\+\)\{2\}\n$/\x1b[\1m\0/
      }
    }
    # Replace the carriage return character with a bell character into the hold space to indicate we want to store the string as an object key
    s/^\([^\x00\n]*[\x00\n]\)\r/\1\a/
    x
    b json_pp___string
  : json_pp___member_2
    x
    s/^[^\x00\n]*[\x00\n]/\0\a/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^[^\x00]*\x00\(\a[^\a\t]*\a\)\(\a[^\a\t]*\a\)*\1/ {
        x
        g
        s/^[^\x00]*\x00\a\([^\a\t]*\).*/\1/
        s/./x/g
        G
        h
        x
        s/^\(x\+\)\x00\(\([^\x00]*\x00\)\{5\}x\+\x00\)\1x/\2/
        x
        s/^x\+\x00[^\x00]*\x00\a\([^\a\t]*\).*/JSON object with duplicated key "\1"/
        b json_pp___PARSING_FAILURE
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\x1b[0m\0/
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
        s/^\(x\+\)\n\(\([^\n]*\n\)\{5\}x\+\n\)\1x/\2/
        x
        s/^x\+\n[^\n]*\n\a\([^\a\t]*\).*/JSON object with duplicated key "\1"/
        b json_pp___PARSING_FAILURE
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]*\(\nx\+\)\{2\}\n$/\x1b[0m\0/
      }
    }
    # Add the stop character
    s/^[^\x00\n]*[\x00\n]/\0\r/
    x
    b json_pp___ws
  : json_pp___member_3
    /^:/ {
      s/.//
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
          s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m:\x1b[0m \0/
        }
        /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
          s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/: \0/
        }
      }
      /^[^\x00\n]*\n/ {
        /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
          s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m:\x1b[0m \0/
        }
        /^\([^\n]*\n\)\{2\} *::::::::\n/ {
          s/\n[^\n]\+\(\nx\+\)\{2\}\n$/: \0/
        }
      }
      s/[\n\x00]$/x\0/
      x
      b json_pp___element
    }
    z
    s/^/`:` expected/
    b json_pp___PARSING_FAILURE

### array
###     '[' ws ']'
###     '[' elements ']'
: json_pp___array
  /^\[[ \n\r\t]*]/ {
    s/.//
    x
    s/^/a1/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m[]\x1b[0m\0/
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
        s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/[]\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\nx\+\)\{2\}\n$/\x1b[\1m[]\x1b[0m\0/
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ {
        s/\n[^\n]\+\(\nx\+\)\{2\}\n$/[]\0/
      }
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___ws
    : json_pp___array_1
      /^]/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_pp___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_pp___PARSING_FAILURE
  }
  /^\[/ {
    s/.//
    x
    s/^/a2a3a4/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m[\x1b[0m\0/
      }
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
        s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/[\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\nx\+\)\{2\}\n$/\x1b[\1m[\x1b[0m\0/
      }
      /^\([^\n]*\n\)\{2\} *::::::::\n/ {
        s/\n[^\n]\+\(\nx\+\)\{2\}\n$/[\0/
      }
    }
    x
    b json_pp___PRINT
    : json_pp___array_2
      x
      # Increment the indent level
      /^[^\x00\n]*\x00/ {
        s/^\([^\x00]*\x00\)\{2\}\( \+\):[^\x00]*\x00/\0\2/
      }
      /^[^\x00\n]*\n/ {
        s/^\([^\n]*\n\)\{2\}\( \+\):[^\n]*\n/\0\2/
      }
      s/[\n\x00]$/x\0/
      x
      b json_pp___elements
    : json_pp___array_3
      /^]/ {
        s/.//
        b json_pp___PRINT
        : json_pp___array_4
          x
          /^[^\x00\n]*\x00/ {
            # Decrement the indent level
            s/^\([^\x00]*\x00[^\x00]*\x00\)\( \+\)\(:[^\x00]*\x00\)\2/\1\2\3/
            # Format the output for the next line to print
            /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
              s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m]\x1b[0m\0/
            }
            /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
              s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/]\0/
            }
          }
          /^[^\x00\n]*\n/ {
            # Decrement the indent level
            s/^\([^\n]*\n[^\n]*\n\)\( \+\)\(:[^\n]*\n\)\2/\1\2\3/
            # Format the output for the next line to print
            /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
              s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\nx\+\)\{2\}\n$/\x1b[\1m]\x1b[0m\0/
            }
            /^\([^\n]*\n\)\{2\} *::::::::\n/ {
              s/\n[^\n]\+\(\nx\+\)\{2\}\n$/]\0/
            }
          }
          s/[\n\x00]$/x\0/
          x
          b json_pp___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_pp___PARSING_FAILURE
  }
  z
  s/^/`[` expected while parsing JSON array/
  b json_pp___PARSING_FAILURE

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
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
          s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m,\x1b[0m\0/
        }
        /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ {
          s/\x00[^\x00]\+\(\x00x\+\)\{2\}\x00$/,\0/
        }
      }
      /^[^\x00\n]*\n/ {
        /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
          s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\nx\+\)\{2\}\n$/\x1b[\1m,\x1b[0m\0/
        }
        /^\([^\n]*\n\)\{2\} *::::::::\n/ {
          s/\n[^\n]\+\(\nx\+\)\{2\}\n$/,\0/
        }
      }
      s/[\n\x00]$/x\0/
      x
      b json_pp___PRINT
      : json_pp___elements_2
        b json_pp___elements
    }
    b json_pp___RETURN

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
  s/^/s1/
  x
  /^"/ {
    s/.//
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/"\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/"\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___characters
  }
  z
  s/^/`"` expected while parsing JSON string/
  b json_pp___PARSING_FAILURE
  : json_pp___string_1
    /^"/ {
      s/.//
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/"\0/
      }
      /^[^\x00\n]*\n/ {
        s/\n[^\n]*\(\nx\+\)\{2\}\n$/"\0/
      }
      s/[\n\x00]$/x\0/
      x
      b json_pp___RETURN
    }
    z
    s/^/Unexpected end of string while parsing JSON string/
    b json_pp___PARSING_FAILURE

### characters
###     character characters
###     ""
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
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\\\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/\\\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___escape
  }
  /^[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"]/ {
    z
    s/^/Invalid character encountered/
    b json_pp___PARSING_FAILURE
  }
  x
  /^[^\x00\n]*\x00/ {
    s/.$//
    x
    H
    s/.//
    x
    # Add the character if it is part of an object key
    /^[^\x00]*\x00[^\r]/ {
      s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2\x00\3/
    }
    # Format the output for the next line to print
    s/^\(\([^\x00]*\x00\)\{3\}[^\x00]*\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)\(.\).*/\1\5\3/
  }
  /^[^\x00\n]*\n/ {
    s/.$//
    x
    H
    s/.//
    x
    # Add the character if it is part of an object key
    /^[^\n]*\n[^\r]/ {
      s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2\n\3/
    }
    # Format the output for the next line to print
    s/^\(\([^\n]*\n\)\{3\}[^\n]*\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)\(.\).*/\1\5\3/
  }
  s/[\n\x00]$/x\0/
  x
  b json_pp___RETURN

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
    s/^/\\1\\2\\3/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/u\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/u\0/
    }
    s/[\n\x00]$/x\0/
    # Add the character if it is part of an object key
    /^[^\x00\n]*[\x00\n][^\r]/ {
      s/^[^\x00\n]*[\x00\n]/\0u/
    }
    x
    b json_pp___hex
    : json_pp___escape_1
      b json_pp___hex
    : json_pp___escape_2
      b json_pp___hex
    : json_pp___escape_3
      b json_pp___hex
  }
  /^["\\/bfnrt]/ {
    x
    /^[^\x00\n]*\x00/ {
      s/.$//
      x
      H
      s/.//
      x
      # Add the character if it is part of an object key
      /^[^\x00]*\x00[^\r]/ {
        s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2\x00\3/
      }
      # Format the output for the next line to print
      s/^\(\([^\x00]*\x00\)\{3\}[^\x00]*\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)\(.\).*/\1\5\3/
    }
    /^[^\x00\n]*\n/ {
      s/.$//
      x
      H
      s/.//
      x
      # Add the character if it is part of an object key
      /^[^\n]*\n[^\r]/ {
        s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2\n\3/
      }
      # Format the output for the next line to print
      s/^\(\([^\n]*\n\)\{3\}[^\n]*\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)\(.\).*/\1\5\3/
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___RETURN
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
    x
    /^[^\x00\n]*\x00/ {
      s/.$//
      x
      H
      s/.//
      x
      # Add the character if it is part of an object key
      /^[^\x00]*\x00[^\r]/ {
        s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2\x00\3/
      }
      # Format the output for the next line to print
      s/^\(\([^\x00]*\x00\)\{3\}[^\x00]*\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)\(.\).*/\1\5\3/
    }
    /^[^\x00\n]*\n/ {
      s/.$//
      x
      H
      s/.//
      x
      # Add the character if it is part of an object key
      /^[^\n]*\n[^\r]/ {
        s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2\n\3/
      }
      # Format the output for the next line to print
      s/^\(\([^\n]*\n\)\{3\}[^\n]*\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)\(.\).*/\1\5\3/
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___RETURN
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
  s/^/n1n2n3/
  # Format the output for the next line to print
  /^[^\x00\n]*\x00/ {
    /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
      s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{4\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m\0/
    }
  }
  /^[^\x00\n]*\n/ {
    /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
      s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{4\}\(\nx\+\)\{2\}\n$/\x1b[\1m\0/
    }
  }
  x
  b json_pp___integer
  : json_pp___number_1
    b json_pp___fraction
  : json_pp___number_2
    b json_pp___exponent
  : json_pp___number_3
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{2\} *::::::::\x00/ ! {
        s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\x1b[0m\0/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{2\} *::::::::\n/ ! {
        s/\n[^\n]*\(\nx\+\)\{2\}\n$/\x1b[0m\0/
      }
    }
    x
    b json_pp___RETURN

### integer
###     digit
###     onenine digits
###     '-' digit
###     '-' onenine digits
: json_pp___integer
  /^-/ {
    s/.//
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/-\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/-\0/
    }
    s/[\n\x00]$/x\0/
    x
  }
  /^[1-9][0-9]/ {
    x
    s/^/i1/
    x
    b json_pp___onenine
    : json_pp___integer_1
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
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/0\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/0\0/
    }
    s/[\n\x00]$/x\0/
    # Add the character if it is part of an object key
    /^[^\x00\n]*[\x00\n][^\r]/ {
      s/^[^\x00\n]*[\x00\n]/\00/
    }
    x
    b json_pp___RETURN
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
    x
    /^[^\x00\n]*\x00/ {
      s/.$//
      x
      H
      s/.//
      x
      # Add the character if it is part of an object key
      /^[^\x00]*\x00[^\r]/ {
        s/^\([^\x00]*\x00\)\(.*\)\x00\([^\x00]\)[^\x00]*$/\1\3\2\x00\3/
      }
      # Format the output for the next line to print
      s/^\(\([^\x00]*\x00\)\{3\}[^\x00]*\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)\(.\).*/\1\5\3/
    }
    /^[^\x00\n]*\n/ {
      s/.$//
      x
      H
      s/.//
      x
      # Add the character if it is part of an object key
      /^[^\n]*\n[^\r]/ {
        s/^\([^\n]*\n\)\(.*\)\n\([^\n]\)[^\n]*$/\1\3\2\n\3/
      }
      # Format the output for the next line to print
      s/^\(\([^\n]*\n\)\{3\}[^\n]*\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)\(.\).*/\1\5\3/
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___RETURN
  }
  z
  s/^/Invalid onenine encountered/
  b json_pp___PARSING_FAILURE

### fraction
###     '.' digits
###     ""
: json_pp___fraction
  /^\./ {
    s/.//
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/.\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/.\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___digits
  }
  b json_pp___RETURN

### exponent
###     'E' sign digits
###     'e' sign digits
###     ""
: json_pp___exponent
  /^[eE]/ {
    x
    s/^/x1/
    /^[^\x00\n]*\x00/ {
      s/.$//
      x
      H
      s/.//
      x
      # Format the output for the next line to print
      s/^\(\([^\x00]*\x00\)\{3\}[^\x00]*\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)\(.\).*/\1\5\3/
    }
    /^[^\x00\n]*\n/ {
      s/.$//
      x
      H
      s/.//
      x
      # Format the output for the next line to print
      s/^\(\([^\n]*\n\)\{3\}[^\n]*\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)\(.\).*/\1\5\3/
    }
    s/[\n\x00]$/x\0/
    x
    b json_pp___sign
    : json_pp___exponent_1
      b json_pp___digits
  }
  b json_pp___RETURN

### sign
###     '+'
###     '-'
###     ""
: json_pp___sign
  /^[-+]/ {
    x
    /^[^\x00\n]*\x00/ {
      s/.$//
      x
      H
      s/.//
      x
      # Format the output for the next line to print
      s/^\(\([^\x00]*\x00\)\{3\}[^\x00]*\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)\(.\).*/\1\5\3/
    }
    /^[^\x00\n]*\n/ {
      s/.$//
      x
      H
      s/.//
      x
      # Format the output for the next line to print
      s/^\(\([^\n]*\n\)\{3\}[^\n]*\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)\(.\).*/\1\5\3/
    }
    s/[\n\x00]$/x\0/
    x
  }
  b json_pp___RETURN

### ws
###     '0020' ws
###     '000A' ws
###     '000D' ws
###     '0009' ws
###     ""
: json_pp___ws
  /^\n/ {
    s/.//
    x
    s/[\n\x00]x\+\([\n\x00]\)$/x\1x\1/
    x
    b json_pp___ws
  }
  /^[ \r\t]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_pp___ws
  }
  b json_pp___RETURN

: json_pp___PRINT
  x
  /^[^\x00\n]*\x00/ {
    s/.$//
    x
    # Save the hold and pattern spaces
    H
    g
    # Select the formatted line and print it
    s/^\([^\x00]*\x00\)\{3\}\([^\x00]*\)\x00.*/\2\n/
    p
    # Restore the pattern space to its state before the print
    g
    s/^\([^\x00]*\x00\)\{7\}//
    # Restore the hold space to its state before the print and reset the line to format
    x
    s/^\(\([^\x00]*\x00\)\{3\} *\)[^\x00]*\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\).*/\1\3/
  }
  /^[^\x00\n]*\n/ {
    s/.$//
    x
    # Save the hold and pattern spaces
    H
    g
    # Select the formatted line and print it
    s/^\([^\n]*\n\)\{3\}\([^\n]*\)\n.*/\2/
    p
    # Restore the pattern space to its state before the print
    g
    s/^\([^\n]*\n\)\{7\}//
    # Restore the hold space to its state before the print and reset the line to format
    x
    s/^\(\([^\n]*\n\)\{3\} *\)[^\n]*\(\n[^\n]*\(\nx\+\)\{2\}\n\).*/\1\3/
  }
  x
  b json_pp___RETURN

# Redirect the workflow depending on the first element in the workflow stack
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
  /^i1/ {
    s/..//
    x
    b json_pp___integer_1
  }
  /^j1/ {
    s/..//
    x
    b json_pp___json_1
  }
  /^j2/ {
    s/..//
    x
    b json_pp___json_2
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
  /^n3/ {
    s/..//
    x
    b json_pp___number_3
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
  /^v1/ {
    s/..//
    x
    b json_pp___value_1
  }
  /^x1/ {
    s/..//
    x
    b json_pp___exponent_1
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
  z
  s/^/"Unknown return code"/
  b json_pp___UNREACHABLE

: json_pp___UNREACHABLE
  x
  /^[^\x00\n]*\x00/ {
    x
    s/.*/\x1b[0mReached unreachable code in scripts\/json\/pretty-printer.sed: \0\n/
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    # If outside the scope it triggers the next conditional statement
    z
  }
  /^[^\x00\n]*\n/ {
    x
    s/^/\x1b[0mReached unreachable code in scripts\/json\/pretty-printer.sed: /
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    z
  }
  Q 5

: json_pp___COMPUTE_FAILURE_LOCATION
  : json_pp___COMPUTE_FAILURE_LOCATION_ROW
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
      b json_pp___COMPUTE_FAILURE_LOCATION_ROW_NEXT
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_pp___COMPUTE_FAILURE_LOCATION_ROW_NEXT
    }
    G
    s/[\x00\n]//
    s/[\x00\n][^\x00\n]*$//
    x
    s/^\([xyz]*[\x00\n]\)\{2\}//
    x
    b json_pp___COMPUTE_FAILURE_LOCATION_COL
    : json_pp___COMPUTE_FAILURE_LOCATION_ROW_NEXT
      G
      s/[\x00\n]//
      s/[\x00\n][^\x00\n]*$//
      x
      s/^\([xyz]*[\x00\n]\)\{2\}//
      x
      b json_pp___COMPUTE_FAILURE_LOCATION_ROW
  : json_pp___COMPUTE_FAILURE_LOCATION_COL
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
      b json_pp___COMPUTE_FAILURE_LOCATION_COL_NEXT
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_pp___COMPUTE_FAILURE_LOCATION_COL_NEXT
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
    b json_pp___COMPUTE_FAILURE_LOCATION_END
    : json_pp___COMPUTE_FAILURE_LOCATION_COL_NEXT
      G
      s/[\x00\n][^\x00\n]*[\x00\n]//
      x
      s/[\x00\n].*$//
      G
      h
      s/^[xyz]*[\x00\n][xyz]*//
      x
      s/^\([xyz]*[\x00\n][xyz]*\).*/\1/
      b json_pp___COMPUTE_FAILURE_LOCATION_COL
  : json_pp___COMPUTE_FAILURE_LOCATION_END
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
      b json_pp___PARSING_FAILURE_NUL
    }
    b json_pp___PARSING_FAILURE_NEWLINE

: json_pp___PARSING_FAILURE
  x
  /^[^\x00\n]*\x00/ {
    s/.*\x00\(x\+\x00x\+\)\x00$/\1/
    b json_pp___COMPUTE_FAILURE_LOCATION
    : json_pp___PARSING_FAILURE_NUL
      x
      H
      x
      s/^\([0-9]\+\)\x00\([0-9]\+\)\x00\(.*\)/\x1b[0mJSON parsing error at ROW \1, COL \2: \3\n/
      # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
      w /dev/stderr
      # If outside the scope it triggers the next conditional statement
      z
  }
  /^[^\x00\n]*\n/ {
    s/.*\n\(x\+\nx\+\)\n$/\1/
    b json_pp___COMPUTE_FAILURE_LOCATION
    : json_pp___PARSING_FAILURE_NEWLINE
      x
      H
      x
      s/^\([0-9]\+\)\n\([0-9]\+\)\n*/\x1b[0mJSON parsing error at ROW \1, COL \2: /
      # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
      w /dev/stderr
      z
  }
  Q 6

: json_pp___ENV_FAILURE
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

: json_pp___SUCCESS
  z
