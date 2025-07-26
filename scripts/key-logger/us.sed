# mimic xev, evtest, kbd/showkey features with a US keyboard layout
# Prerequisites:
#   1) Use LC_CTYPE, LANG or LC_ALL variables for UTF-8 support with "C", "C.UTF-8" or 
#      "<lang_COUNTRY>.UTF-8" (for example: "en_US.UTF-8").
#   2) Having an OS with /proc/bus/input/devices file
#   3) Having an OS with /dev/input/event* files
#   4) Run this script as privileged user (to access /dev/input/event* files)
#   5) Having a POSIX compliant shell: bash, ash, dash, ...
#   6) Having dd (widely available and adheres to POSIX standards)
# Known limitations:
#   1) Over simplified keyboard: not every keys, modifiers and keys combos are processed
#   2) Sometimes KEY RELEASED events are skipped (currently unexplained)
# How to run it:
#   echo | LC_CTYPE=C sudo -E sed -n -f ./key-logger/us.sed
: keylogger_us_init
  s/.*/while IFS= read -r line || [ -n "${line}" ]; do printf '%s\\n' "${line}"; done < \/proc\/bus\/input\/devices/
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
  # - count=2 => skip the ENTER release when typing the command into the prompt
  s/.*\nH: Handlers=[^\n]*\(event[1-9][0-9]*\)[^\n]*\n[^\n]*\nB: EV=120013\n.*/dd bs=24 count=2 if=\/dev\/input\/\1 2> \/dev\/null/
  H
  e
  z
  x
  # Capture 3 input_event structs:
  # TODO: (sudo dd bs=24 count=1 if=/dev/input/event4 2> /dev/null | hd; echo =======================; sudo dd bs=24 skip=1 count=1 skip=1 if=/dev/input/event4 2> /dev/null | hd; echo PRESSED; sudo dd bs=24 skip=1 count=1 skip=1 if=/dev/input/event4 2> /dev/null | hd; echo REL)
  s/ count=2 / count=3 /
  # keyboard modifiers state: L_ALT R_ALT L_CTRL R_CTRL L_SHIFT R_SHIFT CAPS_LOCK
  s/^/0000000\n/
  # TODO: process SEDJUTSU_FORMAT env var
  x
  b keylogger_us_loop

: keylogger_us_loop
  g
  s/.*\n//
  e
  b keylogger_us_next

  # Process 1 input_event struct
  : keylogger_us_next
    # Remove time field from the input_event struct
    s/.\{,16\}//
    /^\x01\x00/ ! {
      # EV_KEY = \x01 => if the script is here, the catched event is not a keyboard event so skip it
      s/.\{,8\}//
      /^$/ {
        b keylogger_us_loop
      }
      b keylogger_us_next
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
        b keylogger_us_next
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
        b keylogger_us_next
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
        b keylogger_us_next
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
        b keylogger_us_next
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
        b keylogger_us_next
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
        b keylogger_us_next
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
        b keylogger_us_next
      }
      b keylogger_us_mapping

    : keylogger_us_mapping
      /^\x1e/ {
        x
        # check SHIFT modifiers
        /^....000\n/ ! {
          s/^/A\n/
        }
        /^....000\n/ {
          s/^/a\n/
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
        s/^/release\nRELEASE\nreleased\n/
      }
      /^\x01\x00\x00\x00/ {
        x
        s/^/press\nPRESS\npressed\n/
      }
      /^\x02\x00\x00\x00/ {
        x
        s/^/repeat\nREPEAT\nrepeated\n/
      }
      # TODO: process format here and print it
      # printf 'rel\nREL\nR\n%%\n%s' 'The %(c)(c) key %(c) different than %(%)(c) with event %(e)%(n)%(c)%(c)' | sed -z '
      #   : k
      #     s/^\(\([^\n]*\)\n[^\n]*\n[^\n]*\n[^\n]*\n[^\n]*\)%(e)/\1\2/
      #     t k
      #   : l
      #     s/^\([^\n]*\n[^\n]*\n[^\n]*\n\([^\n]*\)\n[^\n]*\)%(c)\(.*\)/\1\2\n\3/
      #     t l
      #     s/^[^\n]*\n[^\n]*\n[^\n]*\n[^\n]*\n//;
      #     s/\n//g
      #     s/%(n)/\n/g'
      P
      x
      s/....//
      b keylogger_us_next

: keylogger_us___UNKNOWN_MAPPING
  z
  s/^/Unknown character into input_event.code/
  w /dev/stderr
  Q 5
