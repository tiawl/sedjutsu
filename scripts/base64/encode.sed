: init_holdspace
  # TODO: add \x00 and \n to encode them in final output
  $! {
    N
    b init_holdspace
  }
  x
  s/^/printf '%s' "${SEDJUTSU_CHARTABLE:-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+\/}"/
  e
  x

: base64_encode_binary
  s/./\x00\0/g
  # Deal with 1 then 0 characters
  s/\x001/\x00110001/g
  s/\x000/\x0000110000/g
  s/\x001/\x00001/g
  # Deal with unescaped basic regex special characters
  s/\x00\$/\x0000100100/g
  s/\x00\&/\x0000100110/g
  s/\x00\*/\x0000101010/g
  s/\x00\./\x0000101110/g
  s/\x00\[/\x0001011011/g
  s/\x00\\/\x0001011100/g
  s/\x00\^/\x0001011110/g
  # Deal with all other characters
  s/\x00\x00/\x0000000000/g
  s/\x00\x01/\x0000000001/g
  s/\x00\x02/\x0000000010/g
  s/\x00\x03/\x0000000011/g
  s/\x00\x04/\x0000000100/g
  s/\x00\x05/\x0000000101/g
  s/\x00\x06/\x0000000110/g
  s/\x00\x07/\x0000000111/g
  s/\x00\x08/\x0000001000/g
  s/\x00\x09/\x0000001001/g
  s/\x00\x0a/\x0000001010/g
  s/\x00\x0b/\x0000001011/g
  s/\x00\x0c/\x0000001100/g
  s/\x00\x0d/\x0000001101/g
  s/\x00\x0e/\x0000001110/g
  s/\x00\x0f/\x0000001111/g
  s/\x00\x10/\x0000010000/g
  s/\x00\x11/\x0000010001/g
  s/\x00\x12/\x0000010010/g
  s/\x00\x13/\x0000010011/g
  s/\x00\x14/\x0000010100/g
  s/\x00\x15/\x0000010101/g
  s/\x00\x16/\x0000010110/g
  s/\x00\x17/\x0000010111/g
  s/\x00\x18/\x0000011000/g
  s/\x00\x19/\x0000011001/g
  s/\x00\x1a/\x0000011010/g
  s/\x00\x1b/\x0000011011/g
  s/\x00\x1c/\x0000011100/g
  s/\x00\x1d/\x0000011101/g
  s/\x00\x1e/\x0000011110/g
  s/\x00\x1f/\x0000011111/g
  s/\x00\x20/\x0000100000/g
  s/\x00\x21/\x0000100001/g
  s/\x00\x22/\x0000100010/g
  s/\x00\x23/\x0000100011/g
  s/\x00\x25/\x0000100101/g
  s/\x00\x27/\x0000100111/g
  s/\x00\x28/\x0000101000/g
  s/\x00\x29/\x0000101001/g
  s/\x00\x2b/\x0000101011/g
  s/\x00\x2c/\x0000101100/g
  s/\x00\x2d/\x0000101101/g
  s/\x00\x2f/\x0000101111/g
  s/\x00\x32/\x0000110010/g
  s/\x00\x33/\x0000110011/g
  s/\x00\x34/\x0000110100/g
  s/\x00\x35/\x0000110101/g
  s/\x00\x36/\x0000110110/g
  s/\x00\x37/\x0000110111/g
  s/\x00\x38/\x0000111000/g
  s/\x00\x39/\x0000111001/g
  s/\x00\x3a/\x0000111010/g
  s/\x00\x3b/\x0000111011/g
  s/\x00\x3c/\x0000111100/g
  s/\x00\x3d/\x0000111101/g
  s/\x00\x3e/\x0000111110/g
  s/\x00\x3f/\x0000111111/g
  s/\x00\x40/\x0001000000/g
  s/\x00\x41/\x0001000001/g
  s/\x00\x42/\x0001000010/g
  s/\x00\x43/\x0001000011/g
  s/\x00\x44/\x0001000100/g
  s/\x00\x45/\x0001000101/g
  s/\x00\x46/\x0001000110/g
  s/\x00\x47/\x0001000111/g
  s/\x00\x48/\x0001001000/g
  s/\x00\x49/\x0001001001/g
  s/\x00\x4a/\x0001001010/g
  s/\x00\x4b/\x0001001011/g
  s/\x00\x4c/\x0001001100/g
  s/\x00\x4d/\x0001001101/g
  s/\x00\x4e/\x0001001110/g
  s/\x00\x4f/\x0001001111/g
  s/\x00\x50/\x0001010000/g
  s/\x00\x51/\x0001010001/g
  s/\x00\x52/\x0001010010/g
  s/\x00\x53/\x0001010011/g
  s/\x00\x54/\x0001010100/g
  s/\x00\x55/\x0001010101/g
  s/\x00\x56/\x0001010110/g
  s/\x00\x57/\x0001010111/g
  s/\x00\x58/\x0001011000/g
  s/\x00\x59/\x0001011001/g
  s/\x00\x5a/\x0001011010/g
  s/\x00\x5d/\x0001011101/g
  s/\x00\x5f/\x0001011111/g
  s/\x00\x60/\x0001100000/g
  s/\x00\x61/\x0001100001/g
  s/\x00\x62/\x0001100010/g
  s/\x00\x63/\x0001100011/g
  s/\x00\x64/\x0001100100/g
  s/\x00\x65/\x0001100101/g
  s/\x00\x66/\x0001100110/g
  s/\x00\x67/\x0001100111/g
  s/\x00\x68/\x0001101000/g
  s/\x00\x69/\x0001101001/g
  s/\x00\x6a/\x0001101010/g
  s/\x00\x6b/\x0001101011/g
  s/\x00\x6c/\x0001101100/g
  s/\x00\x6d/\x0001101101/g
  s/\x00\x6e/\x0001101110/g
  s/\x00\x6f/\x0001101111/g
  s/\x00\x70/\x0001110000/g
  s/\x00\x71/\x0001110001/g
  s/\x00\x72/\x0001110010/g
  s/\x00\x73/\x0001110011/g
  s/\x00\x74/\x0001110100/g
  s/\x00\x75/\x0001110101/g
  s/\x00\x76/\x0001110110/g
  s/\x00\x77/\x0001110111/g
  s/\x00\x78/\x0001111000/g
  s/\x00\x79/\x0001111001/g
  s/\x00\x7a/\x0001111010/g
  s/\x00\x7b/\x0001111011/g
  s/\x00\x7c/\x0001111100/g
  s/\x00\x7d/\x0001111101/g
  s/\x00\x7e/\x0001111110/g
  s/\x00\x7f/\x0001111111/g
  s/\x00\x80/\x0010000000/g
  s/\x00\x81/\x0010000001/g
  s/\x00\x82/\x0010000010/g
  s/\x00\x83/\x0010000011/g
  s/\x00\x84/\x0010000100/g
  s/\x00\x85/\x0010000101/g
  s/\x00\x86/\x0010000110/g
  s/\x00\x87/\x0010000111/g
  s/\x00\x88/\x0010001000/g
  s/\x00\x89/\x0010001001/g
  s/\x00\x8a/\x0010001010/g
  s/\x00\x8b/\x0010001011/g
  s/\x00\x8c/\x0010001100/g
  s/\x00\x8d/\x0010001101/g
  s/\x00\x8e/\x0010001110/g
  s/\x00\x8f/\x0010001111/g
  s/\x00\x90/\x0010010000/g
  s/\x00\x91/\x0010010001/g
  s/\x00\x92/\x0010010010/g
  s/\x00\x93/\x0010010011/g
  s/\x00\x94/\x0010010100/g
  s/\x00\x95/\x0010010101/g
  s/\x00\x96/\x0010010110/g
  s/\x00\x97/\x0010010111/g
  s/\x00\x98/\x0010011000/g
  s/\x00\x99/\x0010011001/g
  s/\x00\x9a/\x0010011010/g
  s/\x00\x9b/\x0010011011/g
  s/\x00\x9c/\x0010011100/g
  s/\x00\x9d/\x0010011101/g
  s/\x00\x9e/\x0010011110/g
  s/\x00\x9f/\x0010011111/g
  s/\x00\xa0/\x0010100000/g
  s/\x00\xa1/\x0010100001/g
  s/\x00\xa2/\x0010100010/g
  s/\x00\xa3/\x0010100011/g
  s/\x00\xa4/\x0010100100/g
  s/\x00\xa5/\x0010100101/g
  s/\x00\xa6/\x0010100110/g
  s/\x00\xa7/\x0010100111/g
  s/\x00\xa8/\x0010101000/g
  s/\x00\xa9/\x0010101001/g
  s/\x00\xaa/\x0010101010/g
  s/\x00\xab/\x0010101011/g
  s/\x00\xac/\x0010101100/g
  s/\x00\xad/\x0010101101/g
  s/\x00\xae/\x0010101110/g
  s/\x00\xaf/\x0010101111/g
  s/\x00\xb0/\x0010110000/g
  s/\x00\xb1/\x0010110001/g
  s/\x00\xb2/\x0010110010/g
  s/\x00\xb3/\x0010110011/g
  s/\x00\xb4/\x0010110100/g
  s/\x00\xb5/\x0010110101/g
  s/\x00\xb6/\x0010110110/g
  s/\x00\xb7/\x0010110111/g
  s/\x00\xb8/\x0010111000/g
  s/\x00\xb9/\x0010111001/g
  s/\x00\xba/\x0010111010/g
  s/\x00\xbb/\x0010111011/g
  s/\x00\xbc/\x0010111100/g
  s/\x00\xbd/\x0010111101/g
  s/\x00\xbe/\x0010111110/g
  s/\x00\xbf/\x0010111111/g
  s/\x00\xc0/\x0011000000/g
  s/\x00\xc1/\x0011000001/g
  s/\x00\xc2/\x0011000010/g
  s/\x00\xc3/\x0011000011/g
  s/\x00\xc4/\x0011000100/g
  s/\x00\xc5/\x0011000101/g
  s/\x00\xc6/\x0011000110/g
  s/\x00\xc7/\x0011000111/g
  s/\x00\xc8/\x0011001000/g
  s/\x00\xc9/\x0011001001/g
  s/\x00\xca/\x0011001010/g
  s/\x00\xcb/\x0011001011/g
  s/\x00\xcc/\x0011001100/g
  s/\x00\xcd/\x0011001101/g
  s/\x00\xce/\x0011001110/g
  s/\x00\xcf/\x0011001111/g
  s/\x00\xd0/\x0011010000/g
  s/\x00\xd1/\x0011010001/g
  s/\x00\xd2/\x0011010010/g
  s/\x00\xd3/\x0011010011/g
  s/\x00\xd4/\x0011010100/g
  s/\x00\xd5/\x0011010101/g
  s/\x00\xd6/\x0011010110/g
  s/\x00\xd7/\x0011010111/g
  s/\x00\xd8/\x0011011000/g
  s/\x00\xd9/\x0011011001/g
  s/\x00\xda/\x0011011010/g
  s/\x00\xdb/\x0011011011/g
  s/\x00\xdc/\x0011011100/g
  s/\x00\xdd/\x0011011101/g
  s/\x00\xde/\x0011011110/g
  s/\x00\xdf/\x0011011111/g
  s/\x00\xe0/\x0011100000/g
  s/\x00\xe1/\x0011100001/g
  s/\x00\xe2/\x0011100010/g
  s/\x00\xe3/\x0011100011/g
  s/\x00\xe4/\x0011100100/g
  s/\x00\xe5/\x0011100101/g
  s/\x00\xe6/\x0011100110/g
  s/\x00\xe7/\x0011100111/g
  s/\x00\xe8/\x0011101000/g
  s/\x00\xe9/\x0011101001/g
  s/\x00\xea/\x0011101010/g
  s/\x00\xeb/\x0011101011/g
  s/\x00\xec/\x0011101100/g
  s/\x00\xed/\x0011101101/g
  s/\x00\xee/\x0011101110/g
  s/\x00\xef/\x0011101111/g
  s/\x00\xf0/\x0011110000/g
  s/\x00\xf1/\x0011110001/g
  s/\x00\xf2/\x0011110010/g
  s/\x00\xf3/\x0011110011/g
  s/\x00\xf4/\x0011110100/g
  s/\x00\xf5/\x0011110101/g
  s/\x00\xf6/\x0011110110/g
  s/\x00\xf7/\x0011110111/g
  s/\x00\xf8/\x0011111000/g
  s/\x00\xf9/\x0011111001/g
  s/\x00\xfa/\x0011111010/g
  s/\x00\xfb/\x0011111011/g
  s/\x00\xfc/\x0011111100/g
  s/\x00\xfd/\x0011111101/g
  s/\x00\xfe/\x0011111110/g
  s/\x00\xff/\x0011111111/g
  s/\x00//g
  s/.\{,6\}/\x00\0/g
  x
  G
  t base64_encode_padding

: base64_encode_padding
  s/\x00\(..\)$/\x00\10000==/
  t base64_encode_tobase64_0
  s/\x00\(....\)$/\x00\100=/
  t base64_encode_tobase64_0
: base64_encode_tobase64_0
  s/^\(.\)\(.\{63\}.*\)\x00000000/\1\2\1/
  t base64_encode_tobase64_0
  s/.//
: base64_encode_tobase64_1
  s/^\(.\)\(.\{62\}.*\)\x00000001/\1\2\1/
  t base64_encode_tobase64_1
  s/.//
: base64_encode_tobase64_2
  s/^\(.\)\(.\{61\}.*\)\x00000010/\1\2\1/
  t base64_encode_tobase64_2
  s/.//
: base64_encode_tobase64_3
  s/^\(.\)\(.\{60\}.*\)\x00000011/\1\2\1/
  t base64_encode_tobase64_3
  s/.//
: base64_encode_tobase64_4
  s/^\(.\)\(.\{59\}.*\)\x00000100/\1\2\1/
  t base64_encode_tobase64_4
  s/.//
: base64_encode_tobase64_5
  s/^\(.\)\(.\{58\}.*\)\x00000101/\1\2\1/
  t base64_encode_tobase64_5
  s/.//
: base64_encode_tobase64_6
  s/^\(.\)\(.\{57\}.*\)\x00000110/\1\2\1/
  t base64_encode_tobase64_6
  s/.//
: base64_encode_tobase64_7
  s/^\(.\)\(.\{56\}.*\)\x00000111/\1\2\1/
  t base64_encode_tobase64_7
  s/.//
: base64_encode_tobase64_8
  s/^\(.\)\(.\{55\}.*\)\x00001000/\1\2\1/
  t base64_encode_tobase64_8
  s/.//
: base64_encode_tobase64_9
  s/^\(.\)\(.\{54\}.*\)\x00001001/\1\2\1/
  t base64_encode_tobase64_9
  s/.//
: base64_encode_tobase64_10
  s/^\(.\)\(.\{53\}.*\)\x00001010/\1\2\1/
  t base64_encode_tobase64_10
  s/.//
: base64_encode_tobase64_11
  s/^\(.\)\(.\{52\}.*\)\x00001011/\1\2\1/
  t base64_encode_tobase64_11
  s/.//
: base64_encode_tobase64_12
  s/^\(.\)\(.\{51\}.*\)\x00001100/\1\2\1/
  t base64_encode_tobase64_12
  s/.//
: base64_encode_tobase64_13
  s/^\(.\)\(.\{50\}.*\)\x00001101/\1\2\1/
  t base64_encode_tobase64_13
  s/.//
: base64_encode_tobase64_14
  s/^\(.\)\(.\{49\}.*\)\x00001110/\1\2\1/
  t base64_encode_tobase64_14
  s/.//
: base64_encode_tobase64_15
  s/^\(.\)\(.\{48\}.*\)\x00001111/\1\2\1/
  t base64_encode_tobase64_15
  s/.//
: base64_encode_tobase64_16
  s/^\(.\)\(.\{47\}.*\)\x00010000/\1\2\1/
  t base64_encode_tobase64_16
  s/.//
: base64_encode_tobase64_17
  s/^\(.\)\(.\{46\}.*\)\x00010001/\1\2\1/
  t base64_encode_tobase64_17
  s/.//
: base64_encode_tobase64_18
  s/^\(.\)\(.\{45\}.*\)\x00010010/\1\2\1/
  t base64_encode_tobase64_18
  s/.//
: base64_encode_tobase64_19
  s/^\(.\)\(.\{44\}.*\)\x00010011/\1\2\1/
  t base64_encode_tobase64_19
  s/.//
: base64_encode_tobase64_20
  s/^\(.\)\(.\{43\}.*\)\x00010100/\1\2\1/
  t base64_encode_tobase64_20
  s/.//
: base64_encode_tobase64_21
  s/^\(.\)\(.\{42\}.*\)\x00010101/\1\2\1/
  t base64_encode_tobase64_21
  s/.//
: base64_encode_tobase64_22
  s/^\(.\)\(.\{41\}.*\)\x00010110/\1\2\1/
  t base64_encode_tobase64_22
  s/.//
: base64_encode_tobase64_23
  s/^\(.\)\(.\{40\}.*\)\x00010111/\1\2\1/
  t base64_encode_tobase64_23
  s/.//
: base64_encode_tobase64_24
  s/^\(.\)\(.\{39\}.*\)\x00011000/\1\2\1/
  t base64_encode_tobase64_24
  s/.//
: base64_encode_tobase64_25
  s/^\(.\)\(.\{38\}.*\)\x00011001/\1\2\1/
  t base64_encode_tobase64_25
  s/.//
: base64_encode_tobase64_26
  s/^\(.\)\(.\{37\}.*\)\x00011010/\1\2\1/
  t base64_encode_tobase64_26
  s/.//
: base64_encode_tobase64_27
  s/^\(.\)\(.\{36\}.*\)\x00011011/\1\2\1/
  t base64_encode_tobase64_27
  s/.//
: base64_encode_tobase64_28
  s/^\(.\)\(.\{35\}.*\)\x00011100/\1\2\1/
  t base64_encode_tobase64_28
  s/.//
: base64_encode_tobase64_29
  s/^\(.\)\(.\{34\}.*\)\x00011101/\1\2\1/
  t base64_encode_tobase64_29
  s/.//
: base64_encode_tobase64_30
  s/^\(.\)\(.\{33\}.*\)\x00011110/\1\2\1/
  t base64_encode_tobase64_30
  s/.//
: base64_encode_tobase64_31
  s/^\(.\)\(.\{32\}.*\)\x00011111/\1\2\1/
  t base64_encode_tobase64_31
  s/.//
: base64_encode_tobase64_32
  s/^\(.\)\(.\{31\}.*\)\x00100000/\1\2\1/
  t base64_encode_tobase64_32
  s/.//
: base64_encode_tobase64_33
  s/^\(.\)\(.\{30\}.*\)\x00100001/\1\2\1/
  t base64_encode_tobase64_33
  s/.//
: base64_encode_tobase64_34
  s/^\(.\)\(.\{29\}.*\)\x00100010/\1\2\1/
  t base64_encode_tobase64_34
  s/.//
: base64_encode_tobase64_35
  s/^\(.\)\(.\{28\}.*\)\x00100011/\1\2\1/
  t base64_encode_tobase64_35
  s/.//
: base64_encode_tobase64_36
  s/^\(.\)\(.\{27\}.*\)\x00100100/\1\2\1/
  t base64_encode_tobase64_36
  s/.//
: base64_encode_tobase64_37
  s/^\(.\)\(.\{26\}.*\)\x00100101/\1\2\1/
  t base64_encode_tobase64_37
  s/.//
: base64_encode_tobase64_38
  s/^\(.\)\(.\{25\}.*\)\x00100110/\1\2\1/
  t base64_encode_tobase64_38
  s/.//
: base64_encode_tobase64_39
  s/^\(.\)\(.\{24\}.*\)\x00100111/\1\2\1/
  t base64_encode_tobase64_39
  s/.//
: base64_encode_tobase64_40
  s/^\(.\)\(.\{23\}G.*\)\x00101000/\1\2\1/
  t base64_encode_tobase64_40
  s/.//
: base64_encode_tobase64_41
  s/^\(.\)\(.\{22\}.*\)\x00101001/\1\2\1/
  t base64_encode_tobase64_41
  s/.//
: base64_encode_tobase64_42
  s/^\(.\)\(.\{21\}.*\)\x00101010/\1\2\1/
  t base64_encode_tobase64_42
  s/.//
: base64_encode_tobase64_43
  s/^\(.\)\(.\{20\}.*\)\x00101011/\1\2\1/
  t base64_encode_tobase64_43
  s/.//
: base64_encode_tobase64_44
  s/^\(.\)\(.\{19\}.*\)\x00101100/\1\2\1/
  t base64_encode_tobase64_44
  s/.//
: base64_encode_tobase64_45
  s/^\(.\)\(.\{18\}.*\)\x00101101/\1\2\1/
  t base64_encode_tobase64_45
  s/.//
: base64_encode_tobase64_46
  s/^\(.\)\(.\{17\}.*\)\x00101110/\1\2\1/
  t base64_encode_tobase64_46
  s/.//
: base64_encode_tobase64_47
  s/^\(.\)\(.\{16\}.*\)\x00101111/\1\2\1/
  t base64_encode_tobase64_47
  s/.//
: base64_encode_tobase64_48
  s/^\(.\)\(.\{15\}.*\)\x00110000/\1\2\1/
  t base64_encode_tobase64_48
  s/.//
: base64_encode_tobase64_49
  s/^\(.\)\(.\{14\}.*\)\x00110001/\1\2\1/
  t base64_encode_tobase64_49
  s/.//
: base64_encode_tobase64_50
  s/^\(.\)\(.\{13\}.*\)\x00110010/\1\2\1/
  t base64_encode_tobase64_50
  s/.//
: base64_encode_tobase64_51
  s/^\(.\)\(.\{12\}.*\)\x00110011/\1\2\1/
  t base64_encode_tobase64_51
  s/.//
: base64_encode_tobase64_52
  s/^\(.\)\(.\{11\}.*\)\x00110100/\1\2\1/
  t base64_encode_tobase64_52
  s/.//
: base64_encode_tobase64_53
  s/^\(.\)\(.\{10\}.*\)\x00110101/\1\2\1/
  t base64_encode_tobase64_53
  s/.//
: base64_encode_tobase64_54
  s/^\(.\)\(.\{9\}.*\)\x00110110/\1\2\1/
  t base64_encode_tobase64_54
  s/.//
: base64_encode_tobase64_55
  s/^\(.\)\(.\{8\}.*\)\x00110111/\1\2\1/
  t base64_encode_tobase64_55
  s/.//
: base64_encode_tobase64_56
  s/^\(.\)\(.\{7\}.*\)\x00111000/\1\2\1/
  t base64_encode_tobase64_56
  s/.//
: base64_encode_tobase64_57
  s/^\(.\)\(.\{6\}.*\)\x00111001/\1\2\1/
  t base64_encode_tobase64_57
  s/.//
: base64_encode_tobase64_58
  s/^\(.\)\(.\{5\}.*\)\x00111010/\1\2\1/
  t base64_encode_tobase64_58
  s/.//
: base64_encode_tobase64_59
  s/^\(.\)\(.\{4\}.*\)\x00111011/\1\2\1/
  t base64_encode_tobase64_59
  s/.//
: base64_encode_tobase64_60
  s/^\(.\)\(.\{3\}.*\)\x00111100/\1\2\1/
  t base64_encode_tobase64_60
  s/.//
: base64_encode_tobase64_61
  s/^\(.\)\(.\{2\}.*\)\x00111101/\1\2\1/
  t base64_encode_tobase64_61
  s/.//
: base64_encode_tobase64_62
  s/^\(.\)\(.\+\)\x00111110/\1\2\1/
  t base64_encode_tobase64_62
  s/.//
: base64_encode_tobase64_63
  s/^\(.\)\(.*\)\x00111111/\1\2\1/
  t base64_encode_tobase64_63
  s/..//
