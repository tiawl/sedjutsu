#! /usr/bin/env --split-string sed --file

# Init the holdspace with these following variables:
# - an emptry workflow stack
# - row,col
: init_holdspace
  x
  s/^/\n1,1/
  x

#
# JSON grammar in McKeeman Form
#

### json
###    element
: json_validator
  b json_validator___element

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
  /^[/ {
    b json_validator___array
  }
  /^"/ {
    b json_validator___string
  }
  /^[-0-9]/ {
    b json_validator___number
  }
  /^true/ {
    s/^....//
    b incr4_col
  }
  /^false/ {
    s/^.....//
    b incr5_col
  }
  /^null/ {
    s/^....//
    b incr4_col
  }
  b json_validator___FAILURE

### object
###     '{' ws '}'
###     '{' members '}'
: json_validator___object
  /^{[\x20\x0a\x0d\x09]*}/ {
    s/^{//
    x
    s/^/o1o2/
    x
    b incr_col
    : json_validator___object_1
      b json_validator___ws
    : json_validator___object_2
      s/^}//
      t incr_col
      b json_validator___FAILURE
  }
  /^{/ {
    s/^{//
    x
    s/^/o3o4/
    x
    b incr_col
    : json_validator___object_3
      b json_validator___members
    : json_validator___object_4
      s/^}//
      t incr_col
      b json_validator___FAILURE
  }
  b json_validator___RETURN

### members
###     member
###     member ',' members
: json_validator___members
  x
  s/^/M1/
  x
  b json_validator___member
  : json_validator___members_1
    s/^,//
    t json_validator___members
    b json_validator___RETURN

### member
###     ws string ws ':' element
: json_validator___member
  x
  s/^/m1m2m3m4/
  x
  b json_validator___ws
  : json_validator___member_1
    b json_validator___string
  : json_validator___member_2
    b json_validator___ws
  : json_validator___member_3
    s/^://
    b incr_col
  : json_validator___member_4
    b json_validator___element

### array
###     '[' ws ']'
###     '[' elements ']'

### elements
###     element
###     element ',' elements

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

### characters
###     ""
###     character characters

### character
###     '0020' . '10FFFF' - '"' - '\'
###     '\' escape

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

### hex
###     digit
###     'A' . 'F'
###     'a' . 'f'

### number
###     integer fraction exponent

### integer
###     digit
###     onenine digits
###     '-' digit
###     '-' onenine digits

### digits
###     digit
###     digit digits

### digit
###     '0'
###     onenine

### onenine
###     '1' . '9'

### fraction
###     ""
###     '.' digits

### exponent
###     ""
###     'E' sign digits
###     'e' sign digits

### sign
###     ""
###     '+'
###     '-'

### ws
###     ""
###     '0020' ws
###     '000A' ws
###     '000D' ws
###     '0009' ws
: json_validator___ws
  /^[\x0a]/ {
    s/^.//
    x
    s/^/w1/
    x
    b incr_row
    : json_validator___ws_1
      b json_validator___ws
  }
  /^[\x20\x0d\x09]/ {
    s/^.//
    x
    s/^/w2/
    x
    b incr_col
    : json_validator___ws_2
      b json_validator___ws
  }
  b json_validator___RETURN

: incr_col
  x
  : incr_col_nines2underscores
    s/9\(_*\)$/_\1/
    t incr_col_nines2underscores
  : incr_col_lastdigit
    s/\(_\+\)$/1\1/
    t incr_col_underscores2zeroes
    s/8\(_*\)$/9\1/
    t incr_col_underscores2zeroes
    s/7\(_*\)$/8\1/
    t incr_col_underscores2zeroes
    s/6\(_*\)$/7\1/
    t incr_col_underscores2zeroes
    s/5\(_*\)$/6\1/
    t incr_col_underscores2zeroes
    s/4\(_*\)$/5\1/
    t incr_col_underscores2zeroes
    s/3\(_*\)$/4\1/
    t incr_col_underscores2zeroes
    s/2\(_*\)$/3\1/
    t incr_col_underscores2zeroes
    s/1\(_*\)$/2\1/
    t incr_col_underscores2zeroes
    s/0\(_*\)$/1\1/
  : incr_col_underscores2zeroes
    s/_\(_*\)$/0\1/
    t incr_col_underscores2zeroes
  x
  b json_validator___RETURN

: incr_row
  x
  s/,[^,]*$//
  s/^/ir/
  x
  b incr_col
  : incr_row_1
    x
    s/$/,1/
    x
  b json_validator___RETURN

: incr4_col
  x
  s/9$/D/
  s/8$/C/
  s/7$/B/
  s/6$/A/
  : incr4_col_nines2As
    s/9\(A*[ABCD]\)$/A\1/
    t incr4_col_nines2As
  : incr4_col_ge10
    s/^\(A*[ABCD]\)$/1\1/
    t incr4_col_lastdigit
    s/8\(A*[ABCD]\)$/9\1/
    t incr4_col_lastdigit
    s/7\(A*[ABCD]\)$/8\1/
    t incr4_col_lastdigit
    s/6\(A*[ABCD]\)$/7\1/
    t incr4_col_lastdigit
    s/5\(A*[ABCD]\)$/6\1/
    t incr4_col_lastdigit
    s/4\(A*[ABCD]\)$/5\1/
    t incr4_col_lastdigit
    s/3\(A*[ABCD]\)$/4\1/
    t incr4_col_lastdigit
    s/2\(A*[ABCD]\)$/3\1/
    t incr4_col_lastdigit
    s/1\(A*[ABCD]\)$/2\1/
    t incr4_col_lastdigit
    s/0\(A*[ABCD]\)$/1\1/
  : incr4_col_lastdigit
    s/5$/9/
    t incr4_col_letters2numbers
    s/4$/8/
    t incr4_col_letters2numbers
    s/3$/7/
    t incr4_col_letters2numbers
    s/2$/6/
    t incr4_col_letters2numbers
    s/1$/5/
    t incr4_col_letters2numbers
    s/0$/4/
  : incr4_col_letters2numbers
    s/A\(A*[BCD]\?\)/0\1/
    t incr4_col_letters2numbers
    s/B$/1/
    s/C$/2/
    s/D$/3/
  x
  b json_validator___RETURN

: incr5_col
  x
  s/9$/E/
  s/8$/D/
  s/7$/C/
  s/6$/B/
  s/5$/A/
  : incr5_col_nines2As
    s/9\(A*[ABCDE]\)$/A\1/
    t incr5_col_nines2As
  : incr5_col_ge10
    s/^\(A*[ABCDE]\)$/1\1/
    t incr5_col_lastdigit
    s/8\(A*[ABCDE]\)$/9\1/
    t incr5_col_lastdigit
    s/7\(A*[ABCDE]\)$/8\1/
    t incr5_col_lastdigit
    s/6\(A*[ABCDE]\)$/7\1/
    t incr5_col_lastdigit
    s/5\(A*[ABCDE]\)$/6\1/
    t incr5_col_lastdigit
    s/4\(A*[ABCDE]\)$/5\1/
    t incr5_col_lastdigit
    s/3\(A*[ABCDE]\)$/4\1/
    t incr5_col_lastdigit
    s/2\(A*[ABCDE]\)$/3\1/
    t incr5_col_lastdigit
    s/1\(A*[ABCDE]\)$/2\1/
    t incr5_col_lastdigit
    s/0\(A*[ABCDE]\)$/1\1/
  : incr5_col_lastdigit
    s/4$/9/
    t incr5_col_letters2numbers
    s/3$/8/
    t incr5_col_letters2numbers
    s/2$/7/
    t incr5_col_letters2numbers
    s/1$/6/
    t incr5_col_letters2numbers
    s/0$/5/
  : incr5_col_letters2numbers
    s/A\(A*[BCDE]\?\)/0\1/
    t incr5_col_letters2numbers
    s/B$/1/
    s/C$/2/
    s/D$/3/
    s/E$/4/
  x
  b json_validator___RETURN

# Redirect the workflow depending of the first element in the workflow stack
: json_validator___RETURN
  x
  /^e1/ {
    s/^e1//
    x
    b json_validator___element_1
  }
  /^e2/ {
    s/^e2//
    x
    b json_validator___element_2
  }
  /^ir/ {
    s/^ir//
    x
    b incr_row_1
  }
  /^M1/ {
    s/^M1//
    x
    b json_validator___members_1
  }
  /^m1/ {
    s/^m1//
    x
    b json_validator___member_1
  }
  /^m2/ {
    s/^m2//
    x
    b json_validator___member_2
  }
  /^m3/ {
    s/^m3//
    x
    b json_validator___member_3
  }
  /^m4/ {
    s/^m4//
    x
    b json_validator___member_4
  }
  /^o1/ {
    s/^o1//
    x
    b json_validator___object_1
  }
  /^o2/ {
    s/^o2//
    x
    b json_validator___object_2
  }
  /^o3/ {
    s/^o3//
    x
    b json_validator___object_3
  }
  /^o4/ {
    s/^o4//
    x
    b json_validator___object_4
  }
  /^w1/ {
    s/^w1//
    x
    b json_validator___ws_1
  }
  /^w2/ {
    s/^w2//
    x
    b json_validator___ws_2
  }
  /^\n/ {
    x
    b json_validator___SUCCESS
  }
  x
  b json_validator___ERROR

: json_validator___ERROR
  s/.*/Error in sed\/json\/validate.sed script: Unknown return code/w /dev/stderr
  Q 5

: json_validator___SUCCESS
  # TODO

: json_validator___FAILURE
  # TODO
