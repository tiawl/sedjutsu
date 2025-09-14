### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `yq` or `json_xs` features.     #
#   It converts JSON data to YAML.                                            #
#                                                                             #
#   Be aware that:                                                            #
#   - `yq` is more tolerant with malformatted JSON data and can convert it    #
#     to YAML. This should not be possible with this script. For example      #
#     `yq` can convert this JSON data while this script will return a         #
#     parsing error:                                                          #
#     ```                                                                     #
#     {                                                                       #
#       "Line\nBreak":"\tTab"                                                 #
#     }                                                                       #
#     ```                                                                     #
#   - The YAML identation is a bit different from `yq` output.                #
#                                                                             #
#     If you do not want to see the trailing new line, use the                #
#   `-n`/`--quiet` option.                                                    #
#                                                                             #
#     For UTF-8 support, you need to set (and export) the LC_CTYPE, LANG or   #
#   LC_ALL variables into your environment. Depending of your system you      #
#   need to change the value of one of these with "C", "C.UTF-8" or           #
#   "<lang_COUNTRY>.UTF-8" (for example: "en_US.UTF-8").                      #
#                                                                             #
#     You can configure this script behavior by providing these               #
#   environment variables:                                                    #
#   - SEDJUTSU_INDENT: use the given number of spaces (between 2 and 8)       #
#     for indentation (default: 2)                                            #
#   - SEDJUTSU_MONOCHROME: disable color. The script will consider this       #
#     variable whatever its value (even empty).                               #
#   - SEDJUTSU_COLORS: work like JQ_COLORS does (for more details, see:       #
#     https://jqlang.org/manual/#colors)                                      #
#   If SEDJUTSU_MONOCHROME and SEDJUTSU_COLORS are set when the script run,   #
#   coloring is disabled.                                                     #
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
### HOW TO RUN IT #############################################################
#                                                                             #
#   LC_CTYPE=C sed -znf scripts/json/conv/yaml.sed /path/to/your/file.json    #
#                                                                             #
#   printf '{"k":0}' | LC_CTYPE=C sed -n -f scripts/json/conv/yaml.sed        #
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
  # Depending of the `-z`/`--null-data` option usage, the `D`, `G`, `H`, `N` and `P` sed commands work with new line or NUL characters. This script must know which one of these characters these commands are using
  G
  h
  s/.$//
  x
  # Map the NUL characters to `Z` characters because shell does not support it
  /\x00$/ {
    z
    s/^/printf '%s:%s%sZ' "${SEDJUTSU_INDENT:-2}" "${SEDJUTSU_MONOCHROME+y:}" "${SEDJUTSU_COLORS:-0;90:0;39:0;39:0;39:0;32:1;39:1;39:1;34}"/
  }
  /\n$/ {
    z
    s/^/printf '%s:%s%s\n\n' "${SEDJUTSU_INDENT:-2}" "${SEDJUTSU_MONOCHROME+y:}" "${SEDJUTSU_COLORS:-0;90:0;39:0;39:0;39:0;32:1;39:1;39:1;34}"/
  }
  e
  /Z$/ {
    s/.$/\x00/
  }
  /^[2-8]:/ ! {
    h
    z
    s/^/SEDJUTSU_INDENT must be an integer between 2 and 8/
    b json_2_yaml___ENV_FAILURE
  }
  # When set, SEDJUTSU_MONOCHROME disables color by using default escape sequences everywhere
  s/^\([2-8]\):y:[^\n\x00]*/\1:0;39:0;39:0;39:0;39:0;39:0;39:0;39:0;39/
  /^[2-8]\(:[0-57-9];\(3[0-79]\|9[0-7]\)\)\{8\}/ ! {
    h
    z
    s/^/SEDJUTSU_COLORS must be a colon-delimited list of 8 partial terminal escape sequences matching this pattern "[0-57-9];(3[0-79]|9[0-7])" and in this order: null:false:true:numbers:strings:arrays:objects:keys/
    b json_2_yaml___ENV_FAILURE
  }
  t init_holdspace_reset_conditional_branching
  : init_holdspace_reset_conditional_branching
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
      /^$/ {
        s/^/empty input/
        b json_2_yaml___PARSING_FAILURE
      }
      b json_2_yaml___json

#
# JSON grammar in McKeeman Form
#

### json
###    element
: json_2_yaml___json
  x
  s/^/j1/
  x
  b json_2_yaml___element
  : json_2_yaml___json_1
    /^$/ {
      b json_2_yaml___SUCCESS
    }
    z
    s/^/garbage after main element/
    b json_2_yaml___PARSING_FAILURE

### value
###    object
###    array
###    string
###    number
###    "true"
###    "false"
###    "null"

# If a value is a ge-1-item array or a ge-1-item object => new line
: json_2_yaml___value_in_object
  /^{/ {
    b json_2_yaml___object_in_object
  }
  /^\[/ {
    b json_2_yaml___array_in_object
  }
  b json_2_yaml___value_1
: json_2_yaml___value
  /^{/ {
    b json_2_yaml___object
  }
  /^\[/ {
    b json_2_yaml___array
  }
  : json_2_yaml___value_1
    /^"/ {
      x
      s/^/v2/
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{3\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m\0/
      }
      /^[^\x00\n]*\n/ {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{3\}\(\nx\+\)\{2\}\n$/\x1b[\1m\0/
      }
      x
      b json_2_yaml___string
      : json_2_yaml___value_2
        x
        # Format the output for the next line to print
        /^[^\x00\n]*\x00/ {
          s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\x1b[0m\0/
        }
        /^[^\x00\n]*\n/ {
          s/\n[^\n]*\(\nx\+\)\{2\}\n$/\x1b[0m\0/
        }
        x
        b json_2_yaml___RETURN
    }
    /^[-0-9]/ {
      b json_2_yaml___number
    }
    /^true/ {
      s/....//
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{5\}\(\x00x\+\)\{2\}\x00$/\x1b[\1mtrue\x1b[0m\0/
      }
      /^[^\x00\n]*\n/ {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{5\}\(\nx\+\)\{2\}\n$/\x1b[\1mtrue\x1b[0m\0/
      }
      s/[\n\x00]$/xxxx\0/
      x
      b json_2_yaml___RETURN
    }
    /^false/ {
      s/.....//
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{6\}\(\x00x\+\)\{2\}\x00$/\x1b[\1mfalse\x1b[0m\0/
      }
      /^[^\x00\n]*\n/ {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{6\}\(\nx\+\)\{2\}\n$/\x1b[\1mfalse\x1b[0m\0/
      }
      s/[\n\x00]$/xxxxx\0/
      x
      b json_2_yaml___RETURN
    }
    /^null/ {
      s/....//
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{7\}\(\x00x\+\)\{2\}\x00$/\x1b[\1mnull\x1b[0m\0/
      }
      /^[^\x00\n]*\n/ {
        s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{7\}\(\nx\+\)\{2\}\n$/\x1b[\1mnull\x1b[0m\0/
      }
      s/[\n\x00]$/xxxx\0/
      x
      b json_2_yaml___RETURN
    }
    z
    s/^/malformed JSON string, neither array, object, number, string or atom/
    b json_2_yaml___PARSING_FAILURE

### object
###     '{' ws '}'
###     '{' members '}'
: json_2_yaml___object
  /^{[ \n\r\t]*}/ {
    s/.//
    x
    s/^/o1/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m{}\x1b[0m\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m{}\x1b[0m\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___ws
    : json_2_yaml___object_1
      /^}/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_2_yaml___PARSING_FAILURE
  }
  /^{/ {
    s/.//
    x
    s/^/o2/
    # Increment the indent level
    /^[^\x00\n]*\x00/ {
      /^\([^\x00]*\x00\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / {
        s/^o2/o3/
      }
      /^\([^\x00]*\x00\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / ! {
        s/^\([^\x00]*\x00\)\{2\}\( \+\):[^\x00]*\x00/\0\2/
      }
    }
    /^[^\x00\n]*\n/ {
      /^\([^\n]*\n\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / {
        s/^o2/o3/
      }
      /^\([^\n]*\n\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / ! {
        s/^\([^\n]*\n\)\{2\}\( \+\):[^\n]*\n/\0\2/
      }
    }
    # \t character to split keys between objects
    s/^[^\x00\n]*[\x00\n]\r/\0\t/
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___members
    : json_2_yaml___object_2
      /^}/ {
        s/.//
        x
        # Decrement the indent level
        /^[^\x00\n]*\x00/ {
          s/^\([^\x00]*\x00[^\x00]*\x00\)\( \+\)\(:[^\x00]*\x00\)\2/\1\2\3/
        }
        /^[^\x00\n]*\n/ {
          s/^\([^\n]*\n[^\n]*\n\)\( \+\)\(:[^\n]*\n\)\2/\1\2\3/
        }
        # Remove object keys
        s/^\([^\x00\n]*[\x00\n]\)[^\t]*\t/\1\r/
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_2_yaml___PARSING_FAILURE
    : json_2_yaml___object_3
      /^}/ {
        s/.//
        x
        # Remove object keys
        s/^\([^\x00\n]*[\x00\n]\)[^\t]*\t/\1\r/
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_2_yaml___PARSING_FAILURE
  }
  z
  s/^/`{` expected while parsing JSON object/
  b json_2_yaml___PARSING_FAILURE

# If a value is a ge-1-item object => new line
: json_2_yaml___object_in_object
  /^{[ \n\r\t]*}/ {
    s/.//
    x
    s/^/oo1/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m{}\x1b[0m\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m{}\x1b[0m\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___ws
    : json_2_yaml___object_in_object_1
      /^}/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_2_yaml___PARSING_FAILURE
  }
  /^{/ {
    s/.//
    x
    s/^/oo2oo3/
    # \t character to split keys between objects
    s/^[^\x00\n]*[\x00\n]\r/\0\t/
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___PRINT
    : json_2_yaml___object_in_object_2
      x
      # Increment the indent level
      /^[^\x00\n]*\x00/ {
        # Increment AND decrement (later) the indent level IIF the object is not in an array
        /^\([^\x00]*\x00\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / {
          s/^oo3/oo4/
        }
        /^\([^\x00]*\x00\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / ! {
          s/^\([^\x00]*\x00\)\{2\}\( \+\):[^\x00]*\x00/\0\2/
        }
      }
      /^[^\x00\n]*\n/ {
        # Increment AND decrement (later) the indent level IIF the object is not in an array
        /^\([^\n]*\n\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / {
          s/^oo3/oo4/
        }
        /^\([^\n]*\n\)\{3\} *\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m / ! {
          s/^\([^\n]*\n\)\{2\}\( \+\):[^\n]*\n/\0\2/
        }
      }
      x
      b json_2_yaml___members
    : json_2_yaml___object_in_object_3
      /^}/ {
        s/.//
        x
        # Decrement the indent level
        /^[^\x00\n]*\x00/ {
          s/^\([^\x00]*\x00[^\x00]*\x00\)\( \+\)\(:[^\x00]*\x00\)\2/\1\2\3/
        }
        /^[^\x00\n]*\n/ {
          s/^\([^\n]*\n[^\n]*\n\)\( \+\)\(:[^\n]*\n\)\2/\1\2\3/
        }
        # Remove object keys
        s/^\([^\x00\n]*[\x00\n]\)[^\t]*\t/\1\r/
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_2_yaml___PARSING_FAILURE
    : json_2_yaml___object_in_object_4
      /^}/ {
        s/.//
        x
        # Remove object keys
        s/^\([^\x00\n]*[\x00\n]\)[^\t]*\t/\1\r/
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `}` expected while parsing JSON object/
      b json_2_yaml___PARSING_FAILURE
  }
  z
  s/^/`{` expected while parsing JSON object/
  b json_2_yaml___PARSING_FAILURE

### members
###     member
###     member ',' members
: json_2_yaml___members
  x
  s/^/M1h0M2/
  x
  b json_2_yaml___member
  : json_2_yaml___members_1
    b json_2_yaml___PRINT
  : json_2_yaml___members_2
    /^,/ {
      s/.//
      x
      s/[\n\x00]$/x\0/
      x
      b json_2_yaml___members
    }
    b json_2_yaml___RETURN

### member
###     ws string ws ':' element
: json_2_yaml___member
  x
  s/^/m1m2m3/
  x
  b json_2_yaml___ws
  : json_2_yaml___member_1
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]\+:\([^:]\+\)\(\x00x\+\)\{2\}\x00$/\x1b[\1m\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]\+:\([^:]\+\)\(\nx\+\)\{2\}\n$/\x1b[\1m\0/
    }
    # Replace the carriage return character with a bell character into the hold space to indicate we want to store the string as an object key
    s/^\([^\x00\n]*[\x00\n]\)\r/\1\a/
    x
    b json_2_yaml___string
  : json_2_yaml___member_2
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
        b json_2_yaml___PARSING_FAILURE
      }
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\x1b[0m\0/
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
        b json_2_yaml___PARSING_FAILURE
      }
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/\x1b[0m\0/
    }
    # Add the stop character
    s/^[^\x00\n]*[\x00\n]/\0\r/
    x
    b json_2_yaml___ws
  : json_2_yaml___member_3
    /^:/ {
      s/.//
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        s/\x00[^\x00]\+:\([^:]\+\):[^:]\+\(\x00x\+\)\{2\}\x00$/\x1b[\1m:\x1b[0m \0/
      }
      /^[^\x00\n]*\n/ {
        s/\n[^\n]\+:\([^:]\+\):[^:]\+\(\nx\+\)\{2\}\n$/\x1b[\1m:\x1b[0m \0/
      }
      s/[\n\x00]$/x\0/
      x
      b json_2_yaml___element_in_object
    }
    z
    s/^/`:` expected/
    b json_2_yaml___PARSING_FAILURE

### array
###     '[' ws ']'
###     '[' elements ']'
: json_2_yaml___array
  /^\[[ \n\r\t]*]/ {
    s/.//
    x
    s/^/a1/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m[]\x1b[0m\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\nx\+\)\{2\}\n$/\x1b[\1m[]\x1b[0m\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___ws
    : json_2_yaml___array_1
      /^]/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_2_yaml___PARSING_FAILURE
  }
  /^\[/ {
    s/.//
    x
    s/^/a2/
    # Increment the indent level
    /^[^\x00\n]*\x00/ {
      s/^\([^\x00]*\x00\)\{2\}\( \+\):[^\x00]*\x00/\0\2/
    }
    /^[^\x00\n]*\n/ {
      s/^\([^\n]*\n\)\{2\}\( \+\):[^\n]*\n/\0\2/
    }
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___elements
    : json_2_yaml___array_2
      /^]/ {
        s/.//
        x
        # Decrement the indent level
        /^[^\x00\n]*\x00/ {
          s/^\([^\x00]*\x00[^\x00]*\x00\)\( \+\)\(:[^\x00]*\x00\)\2/\1\2\3/
        }
        /^[^\x00\n]*\n/ {
          s/^\([^\n]*\n[^\n]*\n\)\( \+\)\(:[^\n]*\n\)\2/\1\2\3/
        }
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_2_yaml___PARSING_FAILURE
  }
  z
  s/^/`[` expected while parsing JSON array/
  b json_2_yaml___PARSING_FAILURE

# If a value is a ge-1-item array => new line
: json_2_yaml___array_in_object
  /^\[[ \n\r\t]*]/ {
    s/.//
    x
    s/^/ao1/
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m[]\x1b[0m\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{2\}\(\nx\+\)\{2\}\n$/\x1b[\1m[]\x1b[0m\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___ws
    : json_2_yaml___array_in_object_1
      /^]/ {
        s/.//
        x
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_2_yaml___PARSING_FAILURE
  }
  /^\[/ {
    s/.//
    x
    s/^/ao2ao3/
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___PRINT
    : json_2_yaml___array_in_object_2
      x
      # Increment the indent level
      /^[^\x00\n]*\x00/ {
        s/^\([^\x00]*\x00\)\{2\}\( \+\):[^\x00]*\x00/\0\2/
      }
      /^[^\x00\n]*\n/ {
        s/^\([^\n]*\n\)\{2\}\( \+\):[^\n]*\n/\0\2/
      }
      x
      b json_2_yaml___elements
    : json_2_yaml___array_in_object_3
      /^]/ {
        s/.//
        x
        # Decrement the indent level
        /^[^\x00\n]*\x00/ {
          s/^\([^\x00]*\x00[^\x00]*\x00\)\( \+\)\(:[^\x00]*\x00\)\2/\1\2\3/
        }
        /^[^\x00\n]*\n/ {
          s/^\([^\n]*\n[^\n]*\n\)\( \+\)\(:[^\n]*\n\)\2/\1\2\3/
        }
        s/[\n\x00]$/x\0/
        x
        b json_2_yaml___RETURN
      }
      z
      s/^/`,` or `]` expected while parsing JSON array/
      b json_2_yaml___PARSING_FAILURE
  }
  z
  s/^/`[` expected while parsing JSON array/
  b json_2_yaml___PARSING_FAILURE

### elements
###     element
###     element ',' elements
: json_2_yaml___elements
  x
  s/^/E1h0E2/
    /^[^\x00\n]*\x00/ {
      s/^\(\([^\x00]*\x00\)\{2\}\(\( \+\) \)\(:[^:]\+\)\{5\}:\([^:]\+\)[^\x00]*\x00\3*\)\3/\1\x1b[\6m-\x1b[0m\4/
    }
    /^[^\x00\n]*\n/ {
      s/^\(\([^\n]*\n\)\{2\}\(\( \+\) \)\(:[^:]\+\)\{5\}:\([^:]\+\)[^\n]*\n\3*\)\3/\1\x1b[\6m-\x1b[0m\4/
    }
  x
  b json_2_yaml___element
  : json_2_yaml___elements_1
    b json_2_yaml___PRINT
  : json_2_yaml___elements_2
    /^,/ {
      s/.//
      x
      s/[\n\x00]$/x\0/
      x
      b json_2_yaml___elements
    }
    b json_2_yaml___RETURN

# Reset leading hyphens from array's items
: json_2_yaml___reset_hyphens
  x
  /^[^\x00\n]*\x00/ {
    t json_2_yaml___reset_hyphens_1
    : json_2_yaml___reset_hyphens_1
      s/^\(\([^\x00]*\x00\)\{2\} \+\(:[^:]\+\)\{5\}:\([^:]\+\)[^\x00]*\x00 *\)\x1b\[\4m-\x1b\[0m/\1 /
      t json_2_yaml___reset_hyphens_1
  }
  /^[^\x00\n]*\n/ {
    t json_2_yaml___reset_hyphens_2
    : json_2_yaml___reset_hyphens_2
      s/^\(\([^\n]*\n\)\{2\} \+\(:[^:]\+\)\{5\}:\([^:]\+\)[^\n]*\n *\)\x1b\[\4m-\x1b\[0m/\1 /
      t json_2_yaml___reset_hyphens_2
  }
  x
  b json_2_yaml___RETURN

### element
###     ws value ws
: json_2_yaml___element_in_object
  x
  s/^/e2e3/
  x
  b json_2_yaml___ws
: json_2_yaml___element
  x
  s/^/e1e3/
  x
  b json_2_yaml___ws
  : json_2_yaml___element_1
    b json_2_yaml___value
  : json_2_yaml___element_2
    b json_2_yaml___value_in_object
  : json_2_yaml___element_3
    b json_2_yaml___ws

### string
### '"' characters '"'
: json_2_yaml___string
  x
  s/^/s1/
  x
  /^"/ {
    s/.//
    x
    # Add a vertical tab character to check the string later
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\v\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/\v\0/
    }
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___characters
  }
  z
  s/^/`"` expected while parsing JSON string/
  b json_2_yaml___PARSING_FAILURE
  : json_2_yaml___string_1
    /^"/ {
      s/.//
      x
      # Format the output for the next line to print
      /^[^\x00\n]*\x00/ {
        s/\v\([] !#%&*,>@\[`{|}"][^\x00]*\|[-?]\|---[^\x00]*\|[ :]\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)$/'\1'\2/
        s/\v\('[^\x00]*\|~\|[0-9]\+\|\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)$/"\1"\2/
        s/\v\([^\x00\v]*\)\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\)$/\1\2/
      }
      /^[^\x00\n]*\n/ {
        s/\v\([] !#%&*,>@\[`{|}"][^\n]*\|[-?]\|---[^\n]*\|[ :]\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)$/'\1'\2/
        s/\v\('[^\n]*\|~\|[0-9]\+\|\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)$/"\1"\2/
        s/\v\([^\n\v]*\)\(\n[^\n]*\(\nx\+\)\{2\}\n\)$/\1\2/
      }
      s/[\n\x00]$/x\0/
      x
      b json_2_yaml___RETURN
    }
    z
    s/^/Unexpected end of string while parsing JSON string/
    b json_2_yaml___PARSING_FAILURE

### characters
###     ""
###     character characters
: json_2_yaml___characters
  /^[^\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"]/ {
    x
    s/^/C1/
    x
    b json_2_yaml___character
    : json_2_yaml___characters_1
      b json_2_yaml___characters
  }
  b json_2_yaml___RETURN

### character
###     '0020' . '10FFFF' - '"' - '\'
###     '\' escape
: json_2_yaml___character
  # \ and " characters into JSON strings are not escaped into YAML strings
  /^\\[\\"]/ {
    s/.//
    x
    # Format the output for the next line to print
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
    b json_2_yaml___RETURN
  }
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
    b json_2_yaml___escape
  }
  /^[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f"]/ {
    z
    s/^/Invalid character encountered/
    b json_2_yaml___PARSING_FAILURE
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
  b json_2_yaml___RETURN

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
: json_2_yaml___escape
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
    b json_2_yaml___hex
    : json_2_yaml___escape_1
      b json_2_yaml___hex
    : json_2_yaml___escape_2
      b json_2_yaml___hex
    : json_2_yaml___escape_3
      b json_2_yaml___hex
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
    b json_2_yaml___RETURN
  }
  z
  s/^/Invalid escaped character encountered/
  b json_2_yaml___PARSING_FAILURE

### hex
###     digit
###     'A' . 'F'
###     'a' . 'f'
: json_2_yaml___hex
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
    b json_2_yaml___RETURN
  }
  /^[0-9]/ {
    b json_2_yaml___digit
  }
  z
  s/^/Invalid hexadecimal character encountered/
  b json_2_yaml___PARSING_FAILURE

### number
###     integer fraction exponent
: json_2_yaml___number
  x
  s/^/n1n2n3/
  # Format the output for the next line to print
  /^[^\x00\n]*\x00/ {
    s/\x00[^\x00]\+:\([^:]\+\)\(:[^:]\+\)\{4\}\(\x00x\+\)\{2\}\x00$/\x1b[\1m\0/
  }
  /^[^\x00\n]*\n/ {
    s/\n[^\n]\+:\([^:]\+\)\(:[^:]\+\)\{4\}\(\nx\+\)\{2\}\n$/\x1b[\1m\0/
  }
  x
  b json_2_yaml___integer
  : json_2_yaml___number_1
    b json_2_yaml___fraction
  : json_2_yaml___number_2
    b json_2_yaml___exponent
  : json_2_yaml___number_3
    x
    # Format the output for the next line to print
    /^[^\x00\n]*\x00/ {
      s/\x00[^\x00]*\(\x00x\+\)\{2\}\x00$/\x1b[0m\0/
    }
    /^[^\x00\n]*\n/ {
      s/\n[^\n]*\(\nx\+\)\{2\}\n$/\x1b[0m\0/
    }
    x
    b json_2_yaml___RETURN

### integer
###     digit
###     onenine digits
###     '-' digit
###     '-' onenine digits
: json_2_yaml___integer
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
    b json_2_yaml___onenine
    : json_2_yaml___integer_1
      b json_2_yaml___digits
  }
  /^[0-9]/ {
    b json_2_yaml___digit
  }
  z
  s/^/Invalid integer encountered/
  b json_2_yaml___PARSING_FAILURE

### digits
###     digit
###     digit digits
: json_2_yaml___digits
  /^[0-9][0-9]/ {
    x
    s/^/D1/
    x
  }
  b json_2_yaml___digit
  : json_2_yaml___digits_1
    b json_2_yaml___digits

### digit
###     '0'
###     onenine
: json_2_yaml___digit
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
    b json_2_yaml___RETURN
  }
  /^[1-9]/ {
    b json_2_yaml___onenine
  }
  z
  s/^/Invalid digit encountered/
  b json_2_yaml___PARSING_FAILURE

### onenine
###     '1' . '9'
: json_2_yaml___onenine
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
    b json_2_yaml___RETURN
  }
  z
  s/^/Invalid onenine encountered/
  b json_2_yaml___PARSING_FAILURE

### fraction
###     ""
###     '.' digits
: json_2_yaml___fraction
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
    b json_2_yaml___digits
  }
  b json_2_yaml___RETURN

### exponent
###     ""
###     'E' sign digits
###     'e' sign digits
: json_2_yaml___exponent
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
    b json_2_yaml___sign
    : json_2_yaml___exponent_1
      b json_2_yaml___digits
  }
  b json_2_yaml___RETURN

### sign
###     ""
###     '+'
###     '-'
: json_2_yaml___sign
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
  b json_2_yaml___RETURN

### ws
###     ""
###     '0020' ws
###     '000A' ws
###     '000D' ws
###     '0009' ws
: json_2_yaml___ws
  /^\n/ {
    s/.//
    x
    s/[\n\x00]x\+\([\n\x00]\)$/x\1x\1/
    x
    b json_2_yaml___ws
  }
  /^[ \r\t]/ {
    s/.//
    x
    s/[\n\x00]$/x\0/
    x
    b json_2_yaml___ws
  }
  b json_2_yaml___RETURN

: json_2_yaml___PRINT
  x
  /^[^\x00\n]*\x00/ {
    s/.$//
    x
    # Save the hold and pattern spaces
    H
    g
    # Select the formatted line and print it
    s/^\([^\x00]*\x00\)\{2\}\( \+\)[^\x00]*\x00\2\([^\x00]*\)\x00.*/\3\n/
    # Print the line if not empty
    /^\([[:space:]]\|\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m\)*$/ ! {
      p
    }
    # Restore the pattern space to its state before the print
    g
    s/^\([^\x00]*\x00\)\{7\}//
    # Restore the hold space to its state before the print and reset the line to format
    x
    s/^\(\([^\x00]*\x00\)\{3\}\(\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m\| \)*\)[^\x00]*\(\x00[^\x00]*\(\x00x\+\)\{2\}\x00\).*/\1\5/
  }
  /^[^\x00\n]*\n/ {
    s/.$//
    x
    # Save the hold and pattern spaces
    H
    g
    # Select the formatted line and print it
    s/^\([^\n]*\n\)\{2\}\( \+\)[^\n]*\n\2\([^\n]*\)\n.*/\3/
    # Print the line if not empty
    /^\([[:space:]]\|\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m\)*$/ ! {
      p
    }
    # Restore the pattern space to its state before the print
    g
    s/^\([^\n]*\n\)\{7\}//
    # Restore the hold space to its state before the print and reset the line to format
    x
    s/^\(\([^\n]*\n\)\{3\}\(\x1b\[[0-57-9];\(3[0-79]\|9[0-7]\)m-\x1b\[0m\| \)*\)[^\n]*\(\n[^\n]*\(\nx\+\)\{2\}\n\).*/\1\5/
  }
  x
  b json_2_yaml___RETURN

# Redirect the workflow depending of the first element in the workflow stack
: json_2_yaml___RETURN
  x
  /^a1/ {
    s/..//
    x
    b json_2_yaml___array_1
  }
  /^a2/ {
    s/..//
    x
    b json_2_yaml___array_2
  }
  /^ao1/ {
    s/...//
    x
    b json_2_yaml___array_in_object_1
  }
  /^ao2/ {
    s/...//
    x
    b json_2_yaml___array_in_object_2
  }
  /^ao3/ {
    s/...//
    x
    b json_2_yaml___array_in_object_3
  }
  /^C1/ {
    s/..//
    x
    b json_2_yaml___characters_1
  }
  /^D1/ {
    s/..//
    x
    b json_2_yaml___digits_1
  }
  /^E1/ {
    s/..//
    x
    b json_2_yaml___elements_1
  }
  /^E2/ {
    s/..//
    x
    b json_2_yaml___elements_2
  }
  /^e1/ {
    s/..//
    x
    b json_2_yaml___element_1
  }
  /^e2/ {
    s/..//
    x
    b json_2_yaml___element_2
  }
  /^e3/ {
    s/..//
    x
    b json_2_yaml___element_3
  }
  /^h0/ {
    s/..//
    x
    b json_2_yaml___reset_hyphens
  }
  /^i1/ {
    s/..//
    x
    b json_2_yaml___integer_1
  }
  /^j1/ {
    s/..//
    x
    b json_2_yaml___json_1
  }
  /^M1/ {
    s/..//
    x
    b json_2_yaml___members_1
  }
  /^M2/ {
    s/..//
    x
    b json_2_yaml___members_2
  }
  /^m1/ {
    s/..//
    x
    b json_2_yaml___member_1
  }
  /^m2/ {
    s/..//
    x
    b json_2_yaml___member_2
  }
  /^m3/ {
    s/..//
    x
    b json_2_yaml___member_3
  }
  /^n1/ {
    s/..//
    x
    b json_2_yaml___number_1
  }
  /^n2/ {
    s/..//
    x
    b json_2_yaml___number_2
  }
  /^n3/ {
    s/..//
    x
    b json_2_yaml___number_3
  }
  /^o1/ {
    s/..//
    x
    b json_2_yaml___object_1
  }
  /^o2/ {
    s/..//
    x
    b json_2_yaml___object_2
  }
  /^o3/ {
    s/..//
    x
    b json_2_yaml___object_3
  }
  /^oo1/ {
    s/...//
    x
    b json_2_yaml___object_in_object_1
  }
  /^oo2/ {
    s/...//
    x
    b json_2_yaml___object_in_object_2
  }
  /^oo3/ {
    s/...//
    x
    b json_2_yaml___object_in_object_3
  }
  /^oo4/ {
    s/...//
    x
    b json_2_yaml___object_in_object_4
  }
  /^s1/ {
    s/..//
    x
    b json_2_yaml___string_1
  }
  /^v2/ {
    s/..//
    x
    b json_2_yaml___value_2
  }
  /^x1/ {
    s/..//
    x
    b json_2_yaml___exponent_1
  }
  /^\\1/ {
    s/..//
    x
    b json_2_yaml___escape_1
  }
  /^\\2/ {
    s/..//
    x
    b json_2_yaml___escape_2
  }
  /^\\3/ {
    s/..//
    x
    b json_2_yaml___escape_3
  }
  z
  s/^/"Unknown return code"/
  b json_2_yaml___UNREACHABLE

: json_2_yaml___UNREACHABLE
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

: json_2_yaml___COMPUTE_FAILURE_LOCATION
  : json_2_yaml___COMPUTE_FAILURE_LOCATION_ROW
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
      b json_2_yaml___COMPUTE_FAILURE_LOCATION_ROW_NEXT
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_2_yaml___COMPUTE_FAILURE_LOCATION_ROW_NEXT
    }
    G
    s/[\x00\n]//
    s/[\x00\n][^\x00\n]*$//
    x
    s/^\([xyz]*[\x00\n]\)\{2\}//
    x
    b json_2_yaml___COMPUTE_FAILURE_LOCATION_COL
    : json_2_yaml___COMPUTE_FAILURE_LOCATION_ROW_NEXT
      G
      s/[\x00\n]//
      s/[\x00\n][^\x00\n]*$//
      x
      s/^\([xyz]*[\x00\n]\)\{2\}//
      x
      b json_2_yaml___COMPUTE_FAILURE_LOCATION_ROW
  : json_2_yaml___COMPUTE_FAILURE_LOCATION_COL
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
      b json_2_yaml___COMPUTE_FAILURE_LOCATION_COL_NEXT
    }
    /yyyyyyyyyy/ {
      s/yyyyyyyyyy/x/g
      # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
      s/^x\+$/\0z/
      b json_2_yaml___COMPUTE_FAILURE_LOCATION_COL_NEXT
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
    b json_2_yaml___COMPUTE_FAILURE_LOCATION_END
    : json_2_yaml___COMPUTE_FAILURE_LOCATION_COL_NEXT
      G
      s/[\x00\n][^\x00\n]*[\x00\n]//
      x
      s/[\x00\n].*$//
      G
      h
      s/^[xyz]*[\x00\n][xyz]*//
      x
      s/^\([xyz]*[\x00\n][xyz]*\).*/\1/
      b json_2_yaml___COMPUTE_FAILURE_LOCATION_COL
  : json_2_yaml___COMPUTE_FAILURE_LOCATION_END
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
      b json_2_yaml___PARSING_FAILURE_NUL
    }
    b json_2_yaml___PARSING_FAILURE_NEWLINE

: json_2_yaml___PARSING_FAILURE
  x
  /^[^\x00\n]*\x00/ {
    s/.*\x00\(x\+\x00x\+\)\x00$/\1/
    b json_2_yaml___COMPUTE_FAILURE_LOCATION
    : json_2_yaml___PARSING_FAILURE_NUL
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
    b json_2_yaml___COMPUTE_FAILURE_LOCATION
    : json_2_yaml___PARSING_FAILURE_NEWLINE
      x
      H
      x
      s/^\([0-9]\+\)\n\([0-9]\+\)\n*/\x1b[0mJSON parsing error at ROW \1, COL \2: /
      # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
      w /dev/stderr
      z
  }
  Q 6

: json_2_yaml___ENV_FAILURE
  x
  /^[^\x00\n]*\x00/ {
    x
    s/.*/\x1b[0mError when parsing environment: \0\n/
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    # If outside the scope it triggers the next conditional statement
    z
  }
  /^[^\x00\n]*\n/ {
    x
    s/^/\x1b[0mError when parsing environment: /
    # It is duplicated code needed by the script: a weird output bug occured when this instruction is not in the same scope
    w /dev/stderr
    z
  }
  Q 7

: json_2_yaml___SUCCESS
  z
