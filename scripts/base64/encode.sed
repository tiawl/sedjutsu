### README ####################################################################
#                                                                             #
#     This script can be used to emulate some `base64` features. It encodes   #
#   data into base64 data.                                                    #
#                                                                             #
#     If you do not want to see the trailing new line, use the                #
#   `-n`/`--quiet` option.                                                    #
#                                                                             #
#     For UTF-8 support, set (and export) the LC_CTYPE, LANG or LC_ALL        #
#   variables into your environment. Depending of your system you change      #
#   the value of one of these with "C", "C.UTF-8" or "<lang_COUNTRY>.UTF-8"   #
#   (for example: "en_US.UTF-8").                                             #
#                                                                             #
#     You can configure this script behavior by providing these               #
#   environment variables:                                                    #
#   - SEDJUTSU_CHARTABLE: use the given characters table to encode the data   #
#     (default:                                                               #
#       "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"    #
#     )                                                                       #
#                                                                             #
### HOW TO RUN IT #############################################################
#                                                                             #
#   LC_CTYPE=C sed -z -n -f scripts/base64/encode.sed /path/to/the/file       #
#                                                                             #
#   printf 'encode me\n' | LC_CTYPE=C sed -n -f scripts/base64/encode.sed     #
#                                                                             #
###############################################################################

: init_holdspace
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
  # Deal with 3 then 0, 1 and 2 characters
  s/\x003/\x00303/g
  s/\x000/\x000300/g
  s/\x001/\x000301/g
  s/\x002/\x000302/g
  s/\x003/\x0003/g
  # Deal with unescaped basic regex special characters
  s/\x00\$/\x000210/g
  s/\x00\&/\x000212/g
  s/\x00\*/\x000222/g
  s/\x00\./\x000232/g
  s/\x00\[/\x001123/g
  s/\x00\\/\x001130/g
  s/\x00\^/\x001132/g
  # Deal with all other characters
  s/\x00\x00/\x000000/g
  s/\x00\x01/\x000001/g
  s/\x00\x02/\x000002/g
  s/\x00\x03/\x000003/g
  s/\x00\x04/\x000010/g
  s/\x00\x05/\x000011/g
  s/\x00\x06/\x000012/g
  s/\x00\x07/\x000013/g
  s/\x00\x08/\x000020/g
  s/\x00\x09/\x000021/g
  s/\x00\x0a/\x000022/g
  s/\x00\x0b/\x000023/g
  s/\x00\x0c/\x000030/g
  s/\x00\x0d/\x000031/g
  s/\x00\x0e/\x000032/g
  s/\x00\x0f/\x000033/g
  s/\x00\x10/\x000100/g
  s/\x00\x11/\x000101/g
  s/\x00\x12/\x000102/g
  s/\x00\x13/\x000103/g
  s/\x00\x14/\x000110/g
  s/\x00\x15/\x000111/g
  s/\x00\x16/\x000112/g
  s/\x00\x17/\x000113/g
  s/\x00\x18/\x000120/g
  s/\x00\x19/\x000121/g
  s/\x00\x1a/\x000122/g
  s/\x00\x1b/\x000123/g
  s/\x00\x1c/\x000130/g
  s/\x00\x1d/\x000131/g
  s/\x00\x1e/\x000132/g
  s/\x00\x1f/\x000133/g
  s/\x00\x20/\x000200/g
  s/\x00\x21/\x000201/g
  s/\x00\x22/\x000202/g
  s/\x00\x23/\x000203/g
  s/\x00\x25/\x000211/g
  s/\x00\x27/\x000213/g
  s/\x00\x28/\x000220/g
  s/\x00\x29/\x000221/g
  s/\x00\x2b/\x000223/g
  s/\x00\x2c/\x000230/g
  s/\x00\x2d/\x000231/g
  s/\x00\x2f/\x000233/g
  s/\x00\x34/\x000310/g
  s/\x00\x35/\x000311/g
  s/\x00\x36/\x000312/g
  s/\x00\x37/\x000313/g
  s/\x00\x38/\x000320/g
  s/\x00\x39/\x000321/g
  s/\x00\x3a/\x000322/g
  s/\x00\x3b/\x000323/g
  s/\x00\x3c/\x000330/g
  s/\x00\x3d/\x000331/g
  s/\x00\x3e/\x000332/g
  s/\x00\x3f/\x000333/g
  s/\x00\x40/\x001000/g
  s/\x00\x41/\x001001/g
  s/\x00\x42/\x001002/g
  s/\x00\x43/\x001003/g
  s/\x00\x44/\x001010/g
  s/\x00\x45/\x001011/g
  s/\x00\x46/\x001012/g
  s/\x00\x47/\x001013/g
  s/\x00\x48/\x001020/g
  s/\x00\x49/\x001021/g
  s/\x00\x4a/\x001022/g
  s/\x00\x4b/\x001023/g
  s/\x00\x4c/\x001030/g
  s/\x00\x4d/\x001031/g
  s/\x00\x4e/\x001032/g
  s/\x00\x4f/\x001033/g
  s/\x00\x50/\x001100/g
  s/\x00\x51/\x001101/g
  s/\x00\x52/\x001102/g
  s/\x00\x53/\x001103/g
  s/\x00\x54/\x001110/g
  s/\x00\x55/\x001111/g
  s/\x00\x56/\x001112/g
  s/\x00\x57/\x001113/g
  s/\x00\x58/\x001120/g
  s/\x00\x59/\x001121/g
  s/\x00\x5a/\x001122/g
  s/\x00\x5d/\x001131/g
  s/\x00\x5f/\x001133/g
  s/\x00\x60/\x001200/g
  s/\x00\x61/\x001201/g
  s/\x00\x62/\x001202/g
  s/\x00\x63/\x001203/g
  s/\x00\x64/\x001210/g
  s/\x00\x65/\x001211/g
  s/\x00\x66/\x001212/g
  s/\x00\x67/\x001213/g
  s/\x00\x68/\x001220/g
  s/\x00\x69/\x001221/g
  s/\x00\x6a/\x001222/g
  s/\x00\x6b/\x001223/g
  s/\x00\x6c/\x001230/g
  s/\x00\x6d/\x001231/g
  s/\x00\x6e/\x001232/g
  s/\x00\x6f/\x001233/g
  s/\x00\x70/\x001300/g
  s/\x00\x71/\x001301/g
  s/\x00\x72/\x001302/g
  s/\x00\x73/\x001303/g
  s/\x00\x74/\x001310/g
  s/\x00\x75/\x001311/g
  s/\x00\x76/\x001312/g
  s/\x00\x77/\x001313/g
  s/\x00\x78/\x001320/g
  s/\x00\x79/\x001321/g
  s/\x00\x7a/\x001322/g
  s/\x00\x7b/\x001323/g
  s/\x00\x7c/\x001330/g
  s/\x00\x7d/\x001331/g
  s/\x00\x7e/\x001332/g
  s/\x00\x7f/\x001333/g
  s/\x00\x80/\x002000/g
  s/\x00\x81/\x002001/g
  s/\x00\x82/\x002002/g
  s/\x00\x83/\x002003/g
  s/\x00\x84/\x002010/g
  s/\x00\x85/\x002011/g
  s/\x00\x86/\x002012/g
  s/\x00\x87/\x002013/g
  s/\x00\x88/\x002020/g
  s/\x00\x89/\x002021/g
  s/\x00\x8a/\x002022/g
  s/\x00\x8b/\x002023/g
  s/\x00\x8c/\x002030/g
  s/\x00\x8d/\x002031/g
  s/\x00\x8e/\x002032/g
  s/\x00\x8f/\x002033/g
  s/\x00\x90/\x002100/g
  s/\x00\x91/\x002101/g
  s/\x00\x92/\x002102/g
  s/\x00\x93/\x002103/g
  s/\x00\x94/\x002110/g
  s/\x00\x95/\x002111/g
  s/\x00\x96/\x002112/g
  s/\x00\x97/\x002113/g
  s/\x00\x98/\x002120/g
  s/\x00\x99/\x002121/g
  s/\x00\x9a/\x002122/g
  s/\x00\x9b/\x002123/g
  s/\x00\x9c/\x002130/g
  s/\x00\x9d/\x002131/g
  s/\x00\x9e/\x002132/g
  s/\x00\x9f/\x002133/g
  s/\x00\xa0/\x002200/g
  s/\x00\xa1/\x002201/g
  s/\x00\xa2/\x002202/g
  s/\x00\xa3/\x002203/g
  s/\x00\xa4/\x002210/g
  s/\x00\xa5/\x002211/g
  s/\x00\xa6/\x002212/g
  s/\x00\xa7/\x002213/g
  s/\x00\xa8/\x002220/g
  s/\x00\xa9/\x002221/g
  s/\x00\xaa/\x002222/g
  s/\x00\xab/\x002223/g
  s/\x00\xac/\x002230/g
  s/\x00\xad/\x002231/g
  s/\x00\xae/\x002232/g
  s/\x00\xaf/\x002233/g
  s/\x00\xb0/\x002300/g
  s/\x00\xb1/\x002301/g
  s/\x00\xb2/\x002302/g
  s/\x00\xb3/\x002303/g
  s/\x00\xb4/\x002310/g
  s/\x00\xb5/\x002311/g
  s/\x00\xb6/\x002312/g
  s/\x00\xb7/\x002313/g
  s/\x00\xb8/\x002320/g
  s/\x00\xb9/\x002321/g
  s/\x00\xba/\x002322/g
  s/\x00\xbb/\x002323/g
  s/\x00\xbc/\x002330/g
  s/\x00\xbd/\x002331/g
  s/\x00\xbe/\x002332/g
  s/\x00\xbf/\x002333/g
  s/\x00\xc0/\x003000/g
  s/\x00\xc1/\x003001/g
  s/\x00\xc2/\x003002/g
  s/\x00\xc3/\x003003/g
  s/\x00\xc4/\x003010/g
  s/\x00\xc5/\x003011/g
  s/\x00\xc6/\x003012/g
  s/\x00\xc7/\x003013/g
  s/\x00\xc8/\x003020/g
  s/\x00\xc9/\x003021/g
  s/\x00\xca/\x003022/g
  s/\x00\xcb/\x003023/g
  s/\x00\xcc/\x003030/g
  s/\x00\xcd/\x003031/g
  s/\x00\xce/\x003032/g
  s/\x00\xcf/\x003033/g
  s/\x00\xd0/\x003100/g
  s/\x00\xd1/\x003101/g
  s/\x00\xd2/\x003102/g
  s/\x00\xd3/\x003103/g
  s/\x00\xd4/\x003110/g
  s/\x00\xd5/\x003111/g
  s/\x00\xd6/\x003112/g
  s/\x00\xd7/\x003113/g
  s/\x00\xd8/\x003120/g
  s/\x00\xd9/\x003121/g
  s/\x00\xda/\x003122/g
  s/\x00\xdb/\x003123/g
  s/\x00\xdc/\x003130/g
  s/\x00\xdd/\x003131/g
  s/\x00\xde/\x003132/g
  s/\x00\xdf/\x003133/g
  s/\x00\xe0/\x003200/g
  s/\x00\xe1/\x003201/g
  s/\x00\xe2/\x003202/g
  s/\x00\xe3/\x003203/g
  s/\x00\xe4/\x003210/g
  s/\x00\xe5/\x003211/g
  s/\x00\xe6/\x003212/g
  s/\x00\xe7/\x003213/g
  s/\x00\xe8/\x003220/g
  s/\x00\xe9/\x003221/g
  s/\x00\xea/\x003222/g
  s/\x00\xeb/\x003223/g
  s/\x00\xec/\x003230/g
  s/\x00\xed/\x003231/g
  s/\x00\xee/\x003232/g
  s/\x00\xef/\x003233/g
  s/\x00\xf0/\x003300/g
  s/\x00\xf1/\x003301/g
  s/\x00\xf2/\x003302/g
  s/\x00\xf3/\x003303/g
  s/\x00\xf4/\x003310/g
  s/\x00\xf5/\x003311/g
  s/\x00\xf6/\x003312/g
  s/\x00\xf7/\x003313/g
  s/\x00\xf8/\x003320/g
  s/\x00\xf9/\x003321/g
  s/\x00\xfa/\x003322/g
  s/\x00\xfb/\x003323/g
  s/\x00\xfc/\x003330/g
  s/\x00\xfd/\x003331/g
  s/\x00\xfe/\x003332/g
  s/\x00\xff/\x003333/g
  s/\x00//g
  s/.\{,3\}/\x00\0/g
  x
  G
  t base64_encode_padding

: base64_encode_padding
  s/\x00\(.\)$/\x00\100==/
  t base64_encode_tobase64_0
  s/\x00\(..\)$/\x00\10=/
  t base64_encode_tobase64_0
: base64_encode_tobase64_0
  s/^\(.\)\(.\{63\}.*\)\x00000/\1\2\1/
  t base64_encode_tobase64_0
  s/.//
: base64_encode_tobase64_1
  s/^\(.\)\(.\{62\}.*\)\x00001/\1\2\1/
  t base64_encode_tobase64_1
  s/.//
: base64_encode_tobase64_2
  s/^\(.\)\(.\{61\}.*\)\x00002/\1\2\1/
  t base64_encode_tobase64_2
  s/.//
: base64_encode_tobase64_3
  s/^\(.\)\(.\{60\}.*\)\x00003/\1\2\1/
  t base64_encode_tobase64_3
  s/.//
: base64_encode_tobase64_4
  s/^\(.\)\(.\{59\}.*\)\x00010/\1\2\1/
  t base64_encode_tobase64_4
  s/.//
: base64_encode_tobase64_5
  s/^\(.\)\(.\{58\}.*\)\x00011/\1\2\1/
  t base64_encode_tobase64_5
  s/.//
: base64_encode_tobase64_6
  s/^\(.\)\(.\{57\}.*\)\x00012/\1\2\1/
  t base64_encode_tobase64_6
  s/.//
: base64_encode_tobase64_7
  s/^\(.\)\(.\{56\}.*\)\x00013/\1\2\1/
  t base64_encode_tobase64_7
  s/.//
: base64_encode_tobase64_8
  s/^\(.\)\(.\{55\}.*\)\x00020/\1\2\1/
  t base64_encode_tobase64_8
  s/.//
: base64_encode_tobase64_9
  s/^\(.\)\(.\{54\}.*\)\x00021/\1\2\1/
  t base64_encode_tobase64_9
  s/.//
: base64_encode_tobase64_10
  s/^\(.\)\(.\{53\}.*\)\x00022/\1\2\1/
  t base64_encode_tobase64_10
  s/.//
: base64_encode_tobase64_11
  s/^\(.\)\(.\{52\}.*\)\x00023/\1\2\1/
  t base64_encode_tobase64_11
  s/.//
: base64_encode_tobase64_12
  s/^\(.\)\(.\{51\}.*\)\x00030/\1\2\1/
  t base64_encode_tobase64_12
  s/.//
: base64_encode_tobase64_13
  s/^\(.\)\(.\{50\}.*\)\x00031/\1\2\1/
  t base64_encode_tobase64_13
  s/.//
: base64_encode_tobase64_14
  s/^\(.\)\(.\{49\}.*\)\x00032/\1\2\1/
  t base64_encode_tobase64_14
  s/.//
: base64_encode_tobase64_15
  s/^\(.\)\(.\{48\}.*\)\x00033/\1\2\1/
  t base64_encode_tobase64_15
  s/.//
: base64_encode_tobase64_16
  s/^\(.\)\(.\{47\}.*\)\x00100/\1\2\1/
  t base64_encode_tobase64_16
  s/.//
: base64_encode_tobase64_17
  s/^\(.\)\(.\{46\}.*\)\x00101/\1\2\1/
  t base64_encode_tobase64_17
  s/.//
: base64_encode_tobase64_18
  s/^\(.\)\(.\{45\}.*\)\x00102/\1\2\1/
  t base64_encode_tobase64_18
  s/.//
: base64_encode_tobase64_19
  s/^\(.\)\(.\{44\}.*\)\x00103/\1\2\1/
  t base64_encode_tobase64_19
  s/.//
: base64_encode_tobase64_20
  s/^\(.\)\(.\{43\}.*\)\x00110/\1\2\1/
  t base64_encode_tobase64_20
  s/.//
: base64_encode_tobase64_21
  s/^\(.\)\(.\{42\}.*\)\x00111/\1\2\1/
  t base64_encode_tobase64_21
  s/.//
: base64_encode_tobase64_22
  s/^\(.\)\(.\{41\}.*\)\x00112/\1\2\1/
  t base64_encode_tobase64_22
  s/.//
: base64_encode_tobase64_23
  s/^\(.\)\(.\{40\}.*\)\x00113/\1\2\1/
  t base64_encode_tobase64_23
  s/.//
: base64_encode_tobase64_24
  s/^\(.\)\(.\{39\}.*\)\x00120/\1\2\1/
  t base64_encode_tobase64_24
  s/.//
: base64_encode_tobase64_25
  s/^\(.\)\(.\{38\}.*\)\x00121/\1\2\1/
  t base64_encode_tobase64_25
  s/.//
: base64_encode_tobase64_26
  s/^\(.\)\(.\{37\}.*\)\x00122/\1\2\1/
  t base64_encode_tobase64_26
  s/.//
: base64_encode_tobase64_27
  s/^\(.\)\(.\{36\}.*\)\x00123/\1\2\1/
  t base64_encode_tobase64_27
  s/.//
: base64_encode_tobase64_28
  s/^\(.\)\(.\{35\}.*\)\x00130/\1\2\1/
  t base64_encode_tobase64_28
  s/.//
: base64_encode_tobase64_29
  s/^\(.\)\(.\{34\}.*\)\x00131/\1\2\1/
  t base64_encode_tobase64_29
  s/.//
: base64_encode_tobase64_30
  s/^\(.\)\(.\{33\}.*\)\x00132/\1\2\1/
  t base64_encode_tobase64_30
  s/.//
: base64_encode_tobase64_31
  s/^\(.\)\(.\{32\}.*\)\x00133/\1\2\1/
  t base64_encode_tobase64_31
  s/.//
: base64_encode_tobase64_32
  s/^\(.\)\(.\{31\}.*\)\x00200/\1\2\1/
  t base64_encode_tobase64_32
  s/.//
: base64_encode_tobase64_33
  s/^\(.\)\(.\{30\}.*\)\x00201/\1\2\1/
  t base64_encode_tobase64_33
  s/.//
: base64_encode_tobase64_34
  s/^\(.\)\(.\{29\}.*\)\x00202/\1\2\1/
  t base64_encode_tobase64_34
  s/.//
: base64_encode_tobase64_35
  s/^\(.\)\(.\{28\}.*\)\x00203/\1\2\1/
  t base64_encode_tobase64_35
  s/.//
: base64_encode_tobase64_36
  s/^\(.\)\(.\{27\}.*\)\x00210/\1\2\1/
  t base64_encode_tobase64_36
  s/.//
: base64_encode_tobase64_37
  s/^\(.\)\(.\{26\}.*\)\x00211/\1\2\1/
  t base64_encode_tobase64_37
  s/.//
: base64_encode_tobase64_38
  s/^\(.\)\(.\{25\}.*\)\x00212/\1\2\1/
  t base64_encode_tobase64_38
  s/.//
: base64_encode_tobase64_39
  s/^\(.\)\(.\{24\}.*\)\x00213/\1\2\1/
  t base64_encode_tobase64_39
  s/.//
: base64_encode_tobase64_40
  s/^\(.\)\(.\{23\}.*\)\x00220/\1\2\1/
  t base64_encode_tobase64_40
  s/.//
: base64_encode_tobase64_41
  s/^\(.\)\(.\{22\}.*\)\x00221/\1\2\1/
  t base64_encode_tobase64_41
  s/.//
: base64_encode_tobase64_42
  s/^\(.\)\(.\{21\}.*\)\x00222/\1\2\1/
  t base64_encode_tobase64_42
  s/.//
: base64_encode_tobase64_43
  s/^\(.\)\(.\{20\}.*\)\x00223/\1\2\1/
  t base64_encode_tobase64_43
  s/.//
: base64_encode_tobase64_44
  s/^\(.\)\(.\{19\}.*\)\x00230/\1\2\1/
  t base64_encode_tobase64_44
  s/.//
: base64_encode_tobase64_45
  s/^\(.\)\(.\{18\}.*\)\x00231/\1\2\1/
  t base64_encode_tobase64_45
  s/.//
: base64_encode_tobase64_46
  s/^\(.\)\(.\{17\}.*\)\x00232/\1\2\1/
  t base64_encode_tobase64_46
  s/.//
: base64_encode_tobase64_47
  s/^\(.\)\(.\{16\}.*\)\x00233/\1\2\1/
  t base64_encode_tobase64_47
  s/.//
: base64_encode_tobase64_48
  s/^\(.\)\(.\{15\}.*\)\x00300/\1\2\1/
  t base64_encode_tobase64_48
  s/.//
: base64_encode_tobase64_49
  s/^\(.\)\(.\{14\}.*\)\x00301/\1\2\1/
  t base64_encode_tobase64_49
  s/.//
: base64_encode_tobase64_50
  s/^\(.\)\(.\{13\}.*\)\x00302/\1\2\1/
  t base64_encode_tobase64_50
  s/.//
: base64_encode_tobase64_51
  s/^\(.\)\(.\{12\}.*\)\x00303/\1\2\1/
  t base64_encode_tobase64_51
  s/.//
: base64_encode_tobase64_52
  s/^\(.\)\(.\{11\}.*\)\x00310/\1\2\1/
  t base64_encode_tobase64_52
  s/.//
: base64_encode_tobase64_53
  s/^\(.\)\(.\{10\}.*\)\x00311/\1\2\1/
  t base64_encode_tobase64_53
  s/.//
: base64_encode_tobase64_54
  s/^\(.\)\(.\{9\}.*\)\x00312/\1\2\1/
  t base64_encode_tobase64_54
  s/.//
: base64_encode_tobase64_55
  s/^\(.\)\(.\{8\}.*\)\x00313/\1\2\1/
  t base64_encode_tobase64_55
  s/.//
: base64_encode_tobase64_56
  s/^\(.\)\(.\{7\}.*\)\x00320/\1\2\1/
  t base64_encode_tobase64_56
  s/.//
: base64_encode_tobase64_57
  s/^\(.\)\(.\{6\}.*\)\x00321/\1\2\1/
  t base64_encode_tobase64_57
  s/.//
: base64_encode_tobase64_58
  s/^\(.\)\(.\{5\}.*\)\x00322/\1\2\1/
  t base64_encode_tobase64_58
  s/.//
: base64_encode_tobase64_59
  s/^\(.\)\(.\{4\}.*\)\x00323/\1\2\1/
  t base64_encode_tobase64_59
  s/.//
: base64_encode_tobase64_60
  s/^\(.\)\(.\{3\}.*\)\x00330/\1\2\1/
  t base64_encode_tobase64_60
  s/.//
: base64_encode_tobase64_61
  s/^\(.\)\(.\{2\}.*\)\x00331/\1\2\1/
  t base64_encode_tobase64_61
  s/.//
: base64_encode_tobase64_62
  s/^\(.\)\(.\+\)\x00332/\1\2\1/
  t base64_encode_tobase64_62
  s/.//
: base64_encode_tobase64_63
  s/^\(.\)\(.*\)\x00333/\1\2\1/
  t base64_encode_tobase64_63
  s/..//
  p
