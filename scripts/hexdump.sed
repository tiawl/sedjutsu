### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `hd`, `od` or `xxd`             #
#   features. It diplays input in hexadecimal.                                #
#                                                                             #
#     If you do not want to see the trailing new line, use the                #
#   `-n`/`--quiet` option.                                                    #
#                                                                             #
#     For UTF-8 support, set (and export) the LC_CTYPE, LANG or LC_ALL        #
#   variables into your environment. Depending on your system you change      #
#   the value of one of these to "C", "C.UTF-8" or "<lang_COUNTRY>.UTF-8"     #
#   (for example: "en_US.UTF-8").                                             #
#                                                                             #
### HOW TO RUN IT #############################################################
#                                                                             #
#   LC_CTYPE=C sed -z -n -f scripts/hexdump.sed /path/to/the/file             #
#                                                                             #
#   printf 'dump me\n' | LC_CTYPE=C sed -z -n -f scripts/hexdump.sed          #
#                                                                             #
###############################################################################

v 4.0

: init_holdspace
  $! {
    N
    b init_holdspace
  }
  x

: hexdump_loop
  g
  s/\(.\{,16\}\).*/\1/g
  s/./\x00\0/g
  # Deal with unescaped basic regex special characters
  s/\x00\$/ 24/g
  s/\x00\&/ 26/g
  s/\x00\*/ 2a/g
  s/\x00\./ 2e/g
  s/\x00\[/ 5b/g
  s/\x00\\/ 5c/g
  s/\x00\^/ 5e/g
  # Deal with all other characters
  s/\x00\x00/ 00/g
  s/\x00\x01/ 01/g
  s/\x00\x02/ 02/g
  s/\x00\x03/ 03/g
  s/\x00\x04/ 04/g
  s/\x00\x05/ 05/g
  s/\x00\x06/ 06/g
  s/\x00\x07/ 07/g
  s/\x00\x08/ 08/g
  s/\x00\x09/ 09/g
  s/\x00\x0a/ 0a/g
  s/\x00\x0b/ 0b/g
  s/\x00\x0c/ 0c/g
  s/\x00\x0d/ 0d/g
  s/\x00\x0e/ 0e/g
  s/\x00\x0f/ 0f/g
  s/\x00\x10/ 10/g
  s/\x00\x11/ 11/g
  s/\x00\x12/ 12/g
  s/\x00\x13/ 13/g
  s/\x00\x14/ 14/g
  s/\x00\x15/ 15/g
  s/\x00\x16/ 16/g
  s/\x00\x17/ 17/g
  s/\x00\x18/ 18/g
  s/\x00\x19/ 19/g
  s/\x00\x1a/ 1a/g
  s/\x00\x1b/ 1b/g
  s/\x00\x1c/ 1c/g
  s/\x00\x1d/ 1d/g
  s/\x00\x1e/ 1e/g
  s/\x00\x1f/ 1f/g
  s/\x00\x20/ 20/g
  s/\x00\x21/ 21/g
  s/\x00\x22/ 22/g
  s/\x00\x23/ 23/g
  s/\x00\x25/ 25/g
  s/\x00\x27/ 27/g
  s/\x00\x28/ 28/g
  s/\x00\x29/ 29/g
  s/\x00\x2b/ 2b/g
  s/\x00\x2c/ 2c/g
  s/\x00\x2d/ 2d/g
  s/\x00\x2f/ 2f/g
  s/\x00\x30/ 30/g
  s/\x00\x31/ 31/g
  s/\x00\x32/ 32/g
  s/\x00\x33/ 33/g
  s/\x00\x34/ 34/g
  s/\x00\x35/ 35/g
  s/\x00\x36/ 36/g
  s/\x00\x37/ 37/g
  s/\x00\x38/ 38/g
  s/\x00\x39/ 39/g
  s/\x00\x3a/ 3a/g
  s/\x00\x3b/ 3b/g
  s/\x00\x3c/ 3c/g
  s/\x00\x3d/ 3d/g
  s/\x00\x3e/ 3e/g
  s/\x00\x3f/ 3f/g
  s/\x00\x40/ 40/g
  s/\x00\x41/ 41/g
  s/\x00\x42/ 42/g
  s/\x00\x43/ 43/g
  s/\x00\x44/ 44/g
  s/\x00\x45/ 45/g
  s/\x00\x46/ 46/g
  s/\x00\x47/ 47/g
  s/\x00\x48/ 48/g
  s/\x00\x49/ 49/g
  s/\x00\x4a/ 4a/g
  s/\x00\x4b/ 4b/g
  s/\x00\x4c/ 4c/g
  s/\x00\x4d/ 4d/g
  s/\x00\x4e/ 4e/g
  s/\x00\x4f/ 4f/g
  s/\x00\x50/ 50/g
  s/\x00\x51/ 51/g
  s/\x00\x52/ 52/g
  s/\x00\x53/ 53/g
  s/\x00\x54/ 54/g
  s/\x00\x55/ 55/g
  s/\x00\x56/ 56/g
  s/\x00\x57/ 57/g
  s/\x00\x58/ 58/g
  s/\x00\x59/ 59/g
  s/\x00\x5a/ 5a/g
  s/\x00\x5d/ 5d/g
  s/\x00\x5f/ 5f/g
  s/\x00\x60/ 60/g
  s/\x00\x61/ 61/g
  s/\x00\x62/ 62/g
  s/\x00\x63/ 63/g
  s/\x00\x64/ 64/g
  s/\x00\x65/ 65/g
  s/\x00\x66/ 66/g
  s/\x00\x67/ 67/g
  s/\x00\x68/ 68/g
  s/\x00\x69/ 69/g
  s/\x00\x6a/ 6a/g
  s/\x00\x6b/ 6b/g
  s/\x00\x6c/ 6c/g
  s/\x00\x6d/ 6d/g
  s/\x00\x6e/ 6e/g
  s/\x00\x6f/ 6f/g
  s/\x00\x70/ 70/g
  s/\x00\x71/ 71/g
  s/\x00\x72/ 72/g
  s/\x00\x73/ 73/g
  s/\x00\x74/ 74/g
  s/\x00\x75/ 75/g
  s/\x00\x76/ 76/g
  s/\x00\x77/ 77/g
  s/\x00\x78/ 78/g
  s/\x00\x79/ 79/g
  s/\x00\x7a/ 7a/g
  s/\x00\x7b/ 7b/g
  s/\x00\x7c/ 7c/g
  s/\x00\x7d/ 7d/g
  s/\x00\x7e/ 7e/g
  s/\x00\x7f/ 7f/g
  s/\x00\x80/ 80/g
  s/\x00\x81/ 81/g
  s/\x00\x82/ 82/g
  s/\x00\x83/ 83/g
  s/\x00\x84/ 84/g
  s/\x00\x85/ 85/g
  s/\x00\x86/ 86/g
  s/\x00\x87/ 87/g
  s/\x00\x88/ 88/g
  s/\x00\x89/ 89/g
  s/\x00\x8a/ 8a/g
  s/\x00\x8b/ 8b/g
  s/\x00\x8c/ 8c/g
  s/\x00\x8d/ 8d/g
  s/\x00\x8e/ 8e/g
  s/\x00\x8f/ 8f/g
  s/\x00\x90/ 90/g
  s/\x00\x91/ 91/g
  s/\x00\x92/ 92/g
  s/\x00\x93/ 93/g
  s/\x00\x94/ 94/g
  s/\x00\x95/ 95/g
  s/\x00\x96/ 96/g
  s/\x00\x97/ 97/g
  s/\x00\x98/ 98/g
  s/\x00\x99/ 99/g
  s/\x00\x9a/ 9a/g
  s/\x00\x9b/ 9b/g
  s/\x00\x9c/ 9c/g
  s/\x00\x9d/ 9d/g
  s/\x00\x9e/ 9e/g
  s/\x00\x9f/ 9f/g
  s/\x00\xa0/ a0/g
  s/\x00\xa1/ a1/g
  s/\x00\xa2/ a2/g
  s/\x00\xa3/ a3/g
  s/\x00\xa4/ a4/g
  s/\x00\xa5/ a5/g
  s/\x00\xa6/ a6/g
  s/\x00\xa7/ a7/g
  s/\x00\xa8/ a8/g
  s/\x00\xa9/ a9/g
  s/\x00\xaa/ aa/g
  s/\x00\xab/ ab/g
  s/\x00\xac/ ac/g
  s/\x00\xad/ ad/g
  s/\x00\xae/ ae/g
  s/\x00\xaf/ af/g
  s/\x00\xb0/ b0/g
  s/\x00\xb1/ b1/g
  s/\x00\xb2/ b2/g
  s/\x00\xb3/ b3/g
  s/\x00\xb4/ b4/g
  s/\x00\xb5/ b5/g
  s/\x00\xb6/ b6/g
  s/\x00\xb7/ b7/g
  s/\x00\xb8/ b8/g
  s/\x00\xb9/ b9/g
  s/\x00\xba/ ba/g
  s/\x00\xbb/ bb/g
  s/\x00\xbc/ bc/g
  s/\x00\xbd/ bd/g
  s/\x00\xbe/ be/g
  s/\x00\xbf/ bf/g
  s/\x00\xc0/ c0/g
  s/\x00\xc1/ c1/g
  s/\x00\xc2/ c2/g
  s/\x00\xc3/ c3/g
  s/\x00\xc4/ c4/g
  s/\x00\xc5/ c5/g
  s/\x00\xc6/ c6/g
  s/\x00\xc7/ c7/g
  s/\x00\xc8/ c8/g
  s/\x00\xc9/ c9/g
  s/\x00\xca/ ca/g
  s/\x00\xcb/ cb/g
  s/\x00\xcc/ cc/g
  s/\x00\xcd/ cd/g
  s/\x00\xce/ ce/g
  s/\x00\xcf/ cf/g
  s/\x00\xd0/ d0/g
  s/\x00\xd1/ d1/g
  s/\x00\xd2/ d2/g
  s/\x00\xd3/ d3/g
  s/\x00\xd4/ d4/g
  s/\x00\xd5/ d5/g
  s/\x00\xd6/ d6/g
  s/\x00\xd7/ d7/g
  s/\x00\xd8/ d8/g
  s/\x00\xd9/ d9/g
  s/\x00\xda/ da/g
  s/\x00\xdb/ db/g
  s/\x00\xdc/ dc/g
  s/\x00\xdd/ dd/g
  s/\x00\xde/ de/g
  s/\x00\xdf/ df/g
  s/\x00\xe0/ e0/g
  s/\x00\xe1/ e1/g
  s/\x00\xe2/ e2/g
  s/\x00\xe3/ e3/g
  s/\x00\xe4/ e4/g
  s/\x00\xe5/ e5/g
  s/\x00\xe6/ e6/g
  s/\x00\xe7/ e7/g
  s/\x00\xe8/ e8/g
  s/\x00\xe9/ e9/g
  s/\x00\xea/ ea/g
  s/\x00\xeb/ eb/g
  s/\x00\xec/ ec/g
  s/\x00\xed/ ed/g
  s/\x00\xee/ ee/g
  s/\x00\xef/ ef/g
  s/\x00\xf0/ f0/g
  s/\x00\xf1/ f1/g
  s/\x00\xf2/ f2/g
  s/\x00\xf3/ f3/g
  s/\x00\xf4/ f4/g
  s/\x00\xf5/ f5/g
  s/\x00\xf6/ f6/g
  s/\x00\xf7/ f7/g
  s/\x00\xf8/ f8/g
  s/\x00\xf9/ f9/g
  s/\x00\xfa/ fa/g
  s/\x00\xfb/ fb/g
  s/\x00\xfc/ fc/g
  s/\x00\xfd/ fd/g
  s/\x00\xfe/ fe/g
  s/\x00\xff/ ff/g
  b hexdump_fill_last_line

: hexdump_fill_last_line
  /\( [ 0-9a-f][ 0-9a-f]\)\{16\}/ ! {
    s/$/   /
    b hexdump_fill_last_line
  }
  b hexdump_pretty

: hexdump_pretty
  s/\( [ 0-9a-f][ 0-9a-f]\)\{8\}/\0 /
  s/$/   /
  s/^/  /
  G
  /^  \( [ 0-9a-f][ 0-9a-f]\)\{8\} \( [ 0-9a-f][ 0-9a-f]\)\{8\}   \x00/ {
    s/\x00\(.\{,16\}\).*/|\1|/
    s/[^[:print:]]/\x1b[1;35m.\x1b[0m/g
    s/$/\n/
    b hexdump_pretty_hex
  }
  /^  \( [ 0-9a-f][ 0-9a-f]\)\{8\} \( [ 0-9a-f][ 0-9a-f]\)\{8\}   \n/ {
    s/\n\(.\{,16\}\).*/|\1|/
    s/[^[:print:]]/\x1b[1;35m.\x1b[0m/g
    b hexdump_pretty_hex
  }
  b hexdump_next

: hexdump_pretty_hex
  t hexdump_pretty_hex_in
  : hexdump_pretty_hex_in
    s/^\([^|]*\) \([0189a-f][0-9a-f]\) /\1 \x1b[1;35m\2\x1b[0m /
    t hexdump_pretty_hex_in
  p
  b hexdump_next

: hexdump_next
  x
  s/.\{,16\}//
  /^$/ {
    b hexdump_break
  }
  x
  b hexdump_loop

: hexdump_break
