/^$/ {
  s/^/y/
}

: loop
p
b loop
