### README ####################################################################
#                                                                             #
# ########################################################################### #
#                                                                             #
#                              LINUX-ONLY SCRIPT                              #
#                                                                             #
# ########################################################################### #
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
#     Its default value is `%{code_ascii} %{value_verb}`                      #
#                                                                             #
### PREREQUESITES #############################################################
#                                                                             #
#   1) UTF-8 support is needed here to process binary output from             #
#      /dev/input/eventX files. Use LC_CTYPE, LANG or LC_ALL variables        #
#      with "C", "C.UTF-8" or "<lang_COUNTRY>.UTF-8" (for example:            #
#      "en_US.UTF-8") to allow it.                                            #
#   2) Having an OS with /proc/bus/input/devices file (So a Linux OS)         #
#   3) Having an OS with /dev/input/event* files (So a Linux OS)              #
#   4) Run this script as privileged user (to access /dev/input/event*        #
#      files)                                                                 #
#   5) Having a POSIX compliant shell: bash, ash, dash, ...                   #
#   6) Having dd (widely available and adheres to POSIX standards)            #
#                                                                             #
### HOW TO RUN IT #############################################################
#                                                                             #
#   echo | LC_CTYPE=C sudo -E sed -n -f /path/to/scripts/kblogger/us.sed    #
#                                                                             #
### KNOWN LIMITATIONS #########################################################
#                                                                             #
#   1) Over simplified keyboard: not every keys, modifiers and keys combos    #
#      are processed. See comment section into the kblogger_us_mapping       #
#      branch for more details.                                               #
#   2) Sometimes KEY RELEASED events are skipped just after KEY REPEATED      #
#      events. Probably because sed becomes too slow when processing          #
#      multiple events in a row and the KEY RELEASED event is caught by an    #
#      other process.                                                         #
#                                                                             #
###############################################################################

: kblogger_us_init
  z
  s/^/printf '%s' "${SEDJUTSU_FORMAT:-"%{code_ascii} %{value_verb}"}"/
  e
  s/\n/%{new_line}/g
  x
  z
  s/^/cat \/proc\/bus\/input\/devices/
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
  b kblogger_us_loop

: kblogger_us_loop
  g
  s/.*\n//
  e
  # Remove time field from the input_event struct
  s/.\{,16\}//
  /^\x01\x00/ ! {
    # EV_KEY = \x01 => if the script is here, the catched event is not a keyboard event so skip it
    s/.\{,8\}//
    b kblogger_us_loop
  }
  # Remove type field from the input_event struct
  s/..//
  b kblogger_us_modifiers

  : kblogger_us_modifiers
    # L_ALT
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
      b kblogger_us_loop
    }
    # R_ALT
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
      b kblogger_us_loop
    }
    # L_CTRL
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
      b kblogger_us_loop
    }
    # R_CTRL
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
      b kblogger_us_loop
    }
    # L_SHIFT
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
      b kblogger_us_loop
    }
    # R_SHIFT
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
      b kblogger_us_loop
    }
    # CAPS_LOCK
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
      b kblogger_us_loop
    }
    b kblogger_us_mapping

  # List of covered keys. If not covered this symbol ✖░ is used. For each not bold-font square:
  # - the bottom-left side is the ascii representation of the key without modifier
  # - the top-left side is the ascii representation of the key with SHIFT modifier
  # - the top-right side is the ascii representation of the key with ALT and SHIFT modifiers
  # - the bottom-right side is the ascii representation of the key with ALT modifier
  # ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┲━━━━━━━━━┓
  # │ ✖ ✖ │ ✖ ̨✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃Backspace┃
  # │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃  ✖  ⌫   ┃
  # ┢━━━━━┷━┱───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┴─┬───┺━┳━━━━━━━┫
  # ┃  ✖ ⇥  ┃ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃ Enter ┃
  # ┃  ✖ ⇤  ┃ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃   ✖   ┃
  # ┣━━━━━━━┻┱────┴┬────┴┬────┴┬────┴┬────┴┬────┴┬────┴┬────┴┬────┴┬────┴┬────┴┬────┺┓  ⏎   ┃
  # ┃Caps    ┃ A ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃      ┃
  # ┃Lock ⇬  ┃ a ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃      ┃
  # ┣━━━━━━━┳┹────┬┴────┬┴────┬┴────┬┴────┬┴────┬┴────┬┴────┬┴────┬┴────┬┴────┲┷━━━━━┻━━━━━━┫
  # ┃Shift  ┃ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃    Shift    ┃
  # ┃     ⇧ ┃ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ │ ✖ ✖ ┃      ⇧      ┃
  # ┣━━━━━━━╋━━━━━┷━┳━━━┷━━━┳━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━━━┷━━━┳━┷━━━━━╈━━━━━┻━┳━━━┳━━━┳━━━┫
  # ┃Ctrl   ┃Meta ✖ ┃Alt    ┃ ␣ ✖ Space       ✖ Escaped space ⍽ ┃ AltGr ┃Ctrl   ┃ ⇞ ┃ ↑ ┃ ⇟ ┃
  # ┃       ┃       ┃       ┃ ␣                               ⍽ ┃   ⇮   ┃       ┣━━━╋━━━╋━━━┫
  # ┗━━━━━━━┻━━━━━━━┻━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━┻━━━━━━━┫ ← ┃ ↓ ┃→  ┃
  #                                                                             ┗━━━┻━━━┻━━━┛
  : kblogger_us_mapping
    # Key: a A
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
      b kblogger_us___PRINT
    }
    # Key: →
    /^\x6a/ {
      x
      s/^[01]\+\n\([^\n]*\n\)/106\n0x6a\n\x1b\x5b\x43\n\1\0/
      x
      s/..//
      b kblogger_us___PRINT
    }
    # Key: ←
    /^\x69/ {
      x
      s/^[01]\+\n\([^\n]*\n\)/105\n0x69\n\x1b\x5b\x44\n\1\0/
      x
      s/..//
      b kblogger_us___PRINT
    }
    # Key: ↑
    /^\x67/ {
      x
      s/^[01]\+\n\([^\n]*\n\)/103\n0x67\n\x1b\x5b\x41\n\1\0/
      x
      s/..//
      b kblogger_us___PRINT
    }
    # Key: ↓
    /^\x6c/ {
      x
      s/^[01]\+\n\([^\n]*\n\)/108\n0x6c\n\x1b\x5b\x42\n\1\0/
      x
      s/..//
      b kblogger_us___PRINT
    }
    # Key: ⇞
    /^\x68/ {
      x
      s/^[01]\+\n\([^\n]*\n\)/104\n0x68\n\x1b\x5b\x35\x7e\n\1\0/
      x
      s/..//
      b kblogger_us___PRINT
    }
    # Key: ⇟
    /^\x6d/ {
      x
      s/^[01]\+\n\([^\n]*\n\)/109\n0x6d\n\x1b\x5b\x35\x7e\n\1\0/
      x
      s/..//
      b kblogger_us___PRINT
    }
    # TODO: complete the mapping
    b kblogger_us___UNKNOWN_MAPPING

  : kblogger_us___PRINT
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
    : kblogger_us___PRINT_format_value_low
      s/^\(\([^\n]*\)\n\([^\n]*\n\)\{6\}[^\n]*\)%{value_low}/\1\2/
      t kblogger_us___PRINT_format_value_low
    : kblogger_us___PRINT_format_value_up
      s/^\([^\n]*\n\([^\n]*\)\n\([^\n]*\n\)\{5\}[^\n]*\)%{value_up}/\1\2/
      t kblogger_us___PRINT_format_value_up
    : kblogger_us___PRINT_format_value_verb
      s/^\(\([^\n]*\n\)\{2\}\([^\n]*\)\n\([^\n]*\n\)\{4\}[^\n]*\)%{value_verb}/\1\3/
      t kblogger_us___PRINT_format_value_verb
    : kblogger_us___PRINT_format_value_id
      s/^\(\([^\n]*\n\)\{3\}\([^\n]*\)\n\([^\n]*\n\)\{3\}[^\n]*\)%{value_id}/\1\3/
      t kblogger_us___PRINT_format_value_id
    : kblogger_us___PRINT_format_code_key
      s/^\(\([^\n]*\n\)\{4\}\([^\n]*\)\n\([^\n]*\n\)\{2\}[^\n]*\)%{code_key}/\1\3/
      t kblogger_us___PRINT_format_code_key
    : kblogger_us___PRINT_format_code_scan
      s/^\(\([^\n]*\n\)\{5\}\([^\n]*\)\n[^\n]*\n[^\n]*\)%{code_scan}/\1\3/
      t kblogger_us___PRINT_format_code_scan
    : kblogger_us___PRINT_format_code_ascii
      s/^\(\([^\n]*\n\)\{6\}\([^\n]*\)\n[^\n]*\)%{code_ascii}/\1\3/
      t kblogger_us___PRINT_format_code_ascii
    : kblogger_us___PRINT_format_special_chars
      s/^\([^\n]*\n\)\{7\}//
    : kblogger_us___PRINT_remove_inserted_new_line
      s/\([^\n]*\)\n\([^\n]*\n[01]\+\n[^\n]*\n[^\n]*\)$/\1\2/
      t kblogger_us___PRINT_remove_inserted_new_line
      s/%{new_line}/\n/g
      s/%{percent}/%/g
    P
    # Remove formatted printed line
    s/^[^\n]*\n//
    x
    s/....//
    b kblogger_us_loop

: kblogger_us___UNKNOWN_MAPPING
  z
  s/^/Unknown character into input_event.code/
  w /dev/stderr
  Q 5
