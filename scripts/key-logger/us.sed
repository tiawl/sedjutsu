### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `xev`, `evtest` or              #
#   `kdb/showkey`features                                                     #
#                                                                             #
#     You can configure this script behavior by providing these               #
#   environment variables:                                                    #
#   - SEDJUTSU_FORMAT: literal string to make this script display             #
#     information on stdout. The format is a string that may contain          #
#     plain text mixed with any number of variables. The variables present    #
#     in the output format will be substituted by the value or text this      #
#     script thinks fit, as described  below. All variables are specified     #
#     as %{variable_name}. You can output a normal % by using %{percent}      #
#     and a newline by using %{new_line}. The variables available are:        #
#     * code_ascii: ASCII value from the keyboard event according to the US   #
#                   keyboard layout                                           #
#     * code_key: key code from the keyboard event                            #
#     * code_scan: scan code from the keyboard event                          #
#     * value_low: `release`, `press` or `repeat`                             #
#     * value_up: `RELEASE`, `PRESS` or `REPEAT`                              #
#     * value_verb: `released`, `pressed` or `repeated`                       #
#     * value_id: 0 for release, 1 for press, and 2 for repeat                #
#     Its default value is `%{code_ascii} %{value_verb}`
#                                                                             #
### PREREQUESITES #############################################################
#                                                                             #
#   1) UTF-8 support is needed here to process binary output from             #
#      /dev/input/eventX files. Use LC_CTYPE, LANG or LC_ALL variables        #
#      with "C", "C.UTF-8" or "<lang_COUNTRY>.UTF-8" (for example:            #
#      "en_US.UTF-8") to allow it.                                            #
#   2) Having an OS with /proc/bus/input/devices file                         #
#   3) Having an OS with /dev/input/event* files                              #
#   4) Run this script as privileged user (to access /dev/input/event*        #
#      files)                                                                 #
#   5) Having a POSIX compliant shell: bash, ash, dash, ...                   #
#   6) Having dd (widely available and adheres to POSIX standards)            #
#                                                                             #
### HOW TO RUN IT #############################################################
#                                                                             #
#   echo | LC_CTYPE=C sudo -E sed -n -f /path/to/key-logger/us.sed            #
#                                                                             #
### KNOWN LIMITATIONS #########################################################
#                                                                             #
#   1) Over simplified keyboard: not every keys, modifiers and keys combos    #
#      are processed                                                          #
#   2) Sometimes KEY RELEASED events are skipped (currently unexplained)      #
#                                                                             #
###############################################################################

: keylogger_us_init
  z
  s/^/printf '%s' "${SEDJUTSU_FORMAT:-"%{code_ascii} %{value_verb}"}"/
  e
  s/\n/%{new_line}/g
  x
  z
  s/^/while IFS= read -r line || [ -n "${line}" ]; do printf '%s\\n' "${line}"; done < \/proc\/bus\/input\/devices/
  e
  # - bs=24:
  #     >> struct input_event {       # 24 bytes (64-bit system) / 16 bytes (32-bit system)
  #     >>     struct timeval time;   #   16 bytes (64-bit system) / 8 bytes (32-bit system)
  #     >>     __u16 type;            #    2 bytes
  #     >>     __u16 code;            #    2 bytes
  #     >>     __s32 value;           #    4 bytes
  #     >> };
  #     >> struct timeval {           # 16 bytes (64-bit system) / 8 bytes (32-bit system)
  #     >>     time_t tv_sec;         #    8 bytes (64-bit system) / 4 bytes (32-bit system)
  #     >>     suseconds_t tv_usec;   #    8 bytes (64-bit system) / 4 bytes (32-bit system)
  #     >> };
  # - count=1 => skip the ENTER release when typing the command into the prompt
  s/.*\nH: Handlers=[^\n]*\(event[1-9][0-9]*\)[^\n]*\n[^\n]*\nB: EV=120013\n.*/dd bs=24 count=1 if=\/dev\/input\/\1 2> \/dev\/null/
  H
  e
  z
  x
  # Skip 1 block before and 1 block after the block to catch
  s/ count=1 \([^\n]*\)$/ skip=1 count=1 skip=1 \1/
  # keyboard modifiers state: L_ALT R_ALT L_CTRL R_CTRL L_SHIFT R_SHIFT CAPS_LOCK
  s/^/0000000\n/
  x
  b keylogger_us_loop

: keylogger_us_loop
  g
  s/.*\n//
  e
  # Remove time field from the input_event struct
  s/.\{,16\}//
  /^\x01\x00/ ! {
    # EV_KEY = \x01 => if the script is here, the catched event is not a keyboard event so skip it
    s/.\{,8\}//
    b keylogger_us_loop
  }
  # Remove type field from the input_event struct
  s/..//
  b keylogger_us_modifiers

  : keylogger_us_modifiers
    /^\x38/ {
      s/..//
      /^\x00/ {
        x
        s/./0/
      }
      /^[\x01\x02]/ {
        x
        s/./1/
      }
      x
      s/....//
      b keylogger_us_loop
    }
    /^\x64/ {
      s/..//
      /^\x00/ {
        x
        s/^\(.\)./\10/
      }
      /^[\x01\x02]/ {
        x
        s/^\(.\)./\11/
      }
      x
      s/....//
      b keylogger_us_loop
    }
    /^\x1d/ {
      s/..//
      /^\x00/ {
        x
        s/^\(..\)./\10/
      }
      /^[\x01\x02]/ {
        x
        s/^\(..\)./\11/
      }
      x
      s/....//
      b keylogger_us_loop
    }
    /^\x61/ {
      s/..//
      /^\x00/ {
        x
        s/^\(...\)./\10/
      }
      /^[\x01\x02]/ {
        x
        s/^\(...\)./\11/
      }
      x
      s/....//
      b keylogger_us_loop
    }
    /^\x2a/ {
      s/..//
      /^\x00/ {
        x
        s/^\(....\)./\10/
      }
      /^[\x01\x02]/ {
        x
        s/^\(....\)./\11/
      }
      x
      s/....//
      b keylogger_us_loop
    }
    /^\x36/ {
      s/..//
      /^\x00/ {
        x
        s/^\(.....\)./\10/
      }
      /^[\x01\x02]/ {
        x
        s/^\(.....\)./\11/
      }
      x
      s/....//
      b keylogger_us_loop
    }
    /^\x3a/ {
      s/..//
      /^\x01/ {
        x
        s/^\(......\)0/\12/
        s/^\(......\)1/\10/
        s/^\(......\)2/\11/
        x
      }
      s/....//
      b keylogger_us_loop
    }
    b keylogger_us_mapping

  : keylogger_us_mapping
    /^\x1e/ {
      x
      # check SHIFT modifiers
      /^....000\n/ ! {
        s/^[01]\+\n\([^\n]*\n\)/30\n0x1e\nA\n\1\0/
      }
      /^....000\n/ {
        s/^[01]\+\n\([^\n]*\n\)/30\n0x1e\na\n\1\0/
      }
      x
      s/..//
      b keylogger_us___PRINT
    }
    # TODO: complete the mapping
    b keylogger_us___UNKNOWN_MAPPING

  : keylogger_us___PRINT
    # Remove value field from the input_event struct
    /^\x00\x00\x00\x00/ {
      x
      s/^/release\nRELEASE\nreleased\n0\n/
    }
    /^\x01\x00\x00\x00/ {
      x
      s/^/press\nPRESS\npressed\n1\n/
    }
    /^\x02\x00\x00\x00/ {
      x
      s/^/repeat\nREPEAT\nrepeated\n2\n/
    }
    # TODO: timestamp ??
    : keylogger_us___PRINT_format_value_low
      s/^\(\([^\n]*\)\n\([^\n]*\n\)\{6\}[^\n]*\)%{value_low}/\1\2/
      t keylogger_us___PRINT_format_value_low
    : keylogger_us___PRINT_format_value_up
      s/^\([^\n]*\n\([^\n]*\)\n\([^\n]*\n\)\{5\}[^\n]*\)%{value_up}/\1\2/
      t keylogger_us___PRINT_format_value_up
    : keylogger_us___PRINT_format_value_verb
      s/^\(\([^\n]*\n\)\{2\}\([^\n]*\)\n\([^\n]*\n\)\{4\}[^\n]*\)%{value_verb}/\1\3/
      t keylogger_us___PRINT_format_value_verb
    : keylogger_us___PRINT_format_value_id
      s/^\(\([^\n]*\n\)\{3\}\([^\n]*\)\n\([^\n]*\n\)\{3\}[^\n]*\)%{value_id}/\1\3/
      t keylogger_us___PRINT_format_value_id
    : keylogger_us___PRINT_format_code_key
      s/^\(\([^\n]*\n\)\{4\}\([^\n]*\)\n\([^\n]*\n\)\{2\}[^\n]*\)%{code_key}/\1\3/
      t keylogger_us___PRINT_format_code_key
    : keylogger_us___PRINT_format_code_scan
      s/^\(\([^\n]*\n\)\{5\}\([^\n]*\)\n[^\n]*\n[^\n]*\)%{code_scan}/\1\3/
      t keylogger_us___PRINT_format_code_scan
    : keylogger_us___PRINT_format_code_ascii
      s/^\(\([^\n]*\n\)\{6\}\([^\n]*\)\n[^\n]*\)%{code_ascii}/\1\3/
      t keylogger_us___PRINT_format_code_ascii
    : keylogger_us___PRINT_format_special_chars
      s/^\([^\n]*\n\)\{7\}//
    : keylogger_us___PRINT_remove_inserted_new_line
      s/\([^\n]*\)\n\([^\n]*\n[01]\+\n[^\n]*\n[^\n]*\)$/\1\2/
      t keylogger_us___PRINT_remove_inserted_new_line
      s/%{new_line}/\n/g
      s/%{percent}/%/g
    P
    # Remove formatted printed line
    s/^[^\n]*\n//
    x
    s/....//
    b keylogger_us_loop

: keylogger_us___UNKNOWN_MAPPING
  z
  s/^/Unknown character into input_event.code/
  w /dev/stderr
  Q 5
