### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `bc` or `dc` features.          #
#                                                                             #
#     If you do not want to see the trailing new line, use the                #
#   `-n`/`--quiet` option.                                                    #
#                                                                             #
#     You can configure this script behavior by providing these               #
#   environment variables:                                                    #
#   - SEDJUTSU_PREFIX: add a prefix to the final output. If you want to       #
#     remove the prefix, leave it empty: SEDJUTSU_PREFIX=                     #
#     (default: `0x`).                                                        #
#   - SEDJUTSU_UPPERCASE: print A-F instead of a-f hexadecimal digits into    #
#     the final output. The script will consider this variable whatever its   #
#     value (even empty).                                                     #
#                                                                             #
###############################################################################

: init_holdspace
  # Remove trailing newline if the `-z`/`--null-data` is used
  s/\n$//
  # Depending of the `-z`/`--null-data` option usage, the `D`, `G`, `H`, `N` and `P` sed commands work with new line or NUL characters. This script must know which one of these characters these commands are using
  G
  h
  s/.$//
  x
  # Map the NUL characters to `Z` characters because shell does not support it
  /\x00$/ {
    z
    s/^/printf '%sZ%s' "${SEDJUTSU_PREFIX:-0x}" "${SEDJUTSU_UPPERCASE+y}"/
  }
  /\n$/ {
    z
    s/^/printf '%s\n%s\n' "${SEDJUTSU_PREFIX:-0x}" "${SEDJUTSU_UPPERCASE+y}"/
  }
  e
  s/Z\(y\?\)$/\x00\1/
  x
  /[^0-9]/ {
    z
    s/^/Input must a positive integer/
    w /dev/stderr
    Q 6
  }
  # Directly go to the end if the input is zero
  /^0\+$/ {
    z
    H
    s/^/z/
    b math_conv_dec2hex_xy_to_base16
  }
  # Remove leading zeroes
  s/^0*//
  b math_conv_dec2hex_base10_to_x

# The 2 next loops are working together. Alternatively they replace digits
# from the decimal representation with 'x' and 'y' characters

# Replace trailing digit with 'x'
: math_conv_dec2hex_base10_to_x
  t math_conv_dec2hex_base10_to_x

  # If the pattern space is empty, go to the next step
  /^[xy]\+$/ {
    b math_conv_dec2hex_xy_to_x
  }

  s/\(.*\)0$/x\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)1$/xx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)2$/xxx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)3$/xxxx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)4$/xxxxx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)5$/xxxxxx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)6$/xxxxxxx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)7$/xxxxxxxx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)8$/xxxxxxxxx\1/
  t math_conv_dec2hex_base10_to_y
  s/\(.*\)9$/xxxxxxxxxx\1/
  t math_conv_dec2hex_base10_to_y
  b math_conv_dec2hex___UNREACHABLE

# Replace trailing digit with 'y'
: math_conv_dec2hex_base10_to_y
  t math_conv_dec2hex_base10_to_y

  # If the pattern space is empty, go to the next step
  /^[xy]\+$/ {
    b math_conv_dec2hex_xy_to_x
  }

  s/\(.*\)0$/y\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)1$/yy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)2$/yyy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)3$/yyyy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)4$/yyyyy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)5$/yyyyyy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)6$/yyyyyyy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)7$/yyyyyyyy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)8$/yyyyyyyyy\1/
  t math_conv_dec2hex_base10_to_x
  s/\(.*\)9$/yyyyyyyyyy\1/
  t math_conv_dec2hex_base10_to_x
  b math_conv_dec2hex___UNREACHABLE

# Alternatively replace leading 'x' character with 10 'y' then leading 'y' with 10 'x'
: math_conv_dec2hex_xy_to_x
  t math_conv_dec2hex_xy_to_x
  # If the pattern space is a string full of 'x' characters, go to the next step
  /^x\+$/ {
    s/x//
    b math_conv_dec2hex_x_to_xy
  }
  s/^\(x*\)x\|^\(y*\)y/\U\1\1\1\1\1\1\1\1\1\1\2\2\2\2\2\2\2\2\2\2\E/
  y/XY/yx/
  t math_conv_dec2hex_xy_to_x
  b math_conv_dec2hex___UNREACHABLE

: math_conv_dec2hex_x_to_xy
  H
  # Keep leading 'x' or 'y' repeated characters into the pattern space
  s/^\(x\+\).*\|^\(y\+\).*/\1\2/
  x
  # Keep trailing 'x' and 'y' characters into the hold space for the next iteration
  s/^\(\([^\x00\n]*[\x00\n]\)\{2\}\)x*\|^\(\([^\x00\n]*[\x00\n]\)\{2\}\)y*/\1\3/
  #s/[\x00\n]$//
  x
  # Replace 16 'x' with 'y'
  /xxxxxxxxxxxxxxxx/ {
    s/xxxxxxxxxxxxxxxx/y/g
    # If the pattern space if full of 'y' we add a trailing 'z' to replace it later with a '0'
    s/^y\+$/\0z/
    b math_conv_dec2hex_x_to_xy_next
  }
  # Replace 16 'y' with 'x'
  /yyyyyyyyyyyyyyyy/ {
    s/yyyyyyyyyyyyyyyy/x/g
    # If the pattern space if full of 'x' we add a trailing 'z' to replace it later with a '0'
    s/^x\+$/\0z/
    b math_conv_dec2hex_x_to_xy_next
  }
  # If there are no 'x' or 'y' character into the pattern space, go to the final step
  b math_conv_dec2hex_xy_to_base16
  : math_conv_dec2hex_x_to_xy_next
    H
    g
    s/^\([^\x00\n]*[\x00\n]\)\{2\}\([xyz]*\)[\n\x00]\([xyz]*\)/\3\2/
    x
    s/[\x00\n][xyz]*[\x00\n][xyz]*$//
    x
    b math_conv_dec2hex_x_to_xy

# Replace repeated characters with base16 digits
: math_conv_dec2hex_xy_to_base16
  H
  g
  s/^\([^\x00\n]*[\x00\n]\)\{2\}\([xyz]*\)[\n\x00]\([xyz]*\)/\3\2/
  x
  s/[\x00\n][xyz]*[\x00\n][xyz]*$//
  x
  s/xxxxxxxxxxxxxxx\|yyyyyyyyyyyyyyy/f/g
  s/xxxxxxxxxxxxxx\|yyyyyyyyyyyyyy/e/g
  s/xxxxxxxxxxxxx\|yyyyyyyyyyyyy/d/g
  s/xxxxxxxxxxxx\|yyyyyyyyyyyy/c/g
  s/xxxxxxxxxxx\|yyyyyyyyyyy/b/g
  s/xxxxxxxxxx\|yyyyyyyyyy/a/g
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
  G
  # Uppercase output
  /[\x00\n]y$/ {
    s/^\([0-9a-f]\+\)[\x00\n]\([^\x00\n]*\)[\x00\n]y/\2\U\1\E/
    b math_conv_dec2hex___SUCCESS
  }
  # Lowercase output
  s/^\([0-9a-f]\+\)[\x00\n]\([^\x00\n]*\)[\x00\n]/\2\1/
  b math_conv_dec2hex___SUCCESS

: math_conv_dec2hex___UNREACHABLE
  z
  s/^/Reached unreachable code in scripts\/math\/conv\/dec2hex.sed/
  w /dev/stderr
  Q 5

: math_conv_dec2hex___SUCCESS
  p
  z
