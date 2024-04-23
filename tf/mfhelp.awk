# Regular expression for grep -E option
# (^[a-zA-Z0-9_-]+:.*?## .*$|^###>( | .+)?$)

BEGIN {
  cmdw=20;

  FS="(:.*?## |#> ?)";
  gr="f";
  gray="\033[30m";
  bgray="\033[1;30m";
  cyan="\033[36m";
  clear="\033[0m";

  gc=gray;
  bgc=bgray;
  cmdc=cyan;

  _c = 0;
  _d = 0;
}
{
  if($1 == "##") {
    _d = 0;

    switch($2) {
      case /^ *$/:
        write[_c++] = sprintf("\n");
        gr="f"; next;
      case /^@/:
        gr="f"; next;
      case /^!/:
        write[_c++] = sprintf(bgc "%s" clear "\n", substr($2, 2));
        gr="t"; next;
      default:
        write[_c++] = sprintf(gc "%s" clear "\n", $2);
        gr="t"; next;
    }
    
  } else {

    if(gr == "t") {
      for(i=1;i<=_d;i++) { sub(/^\x1b\[(.;)?..m /, gc "|", write[_c-i]); }
      write[_c++] = sprintf(gc "\\_ " cmdc "%-" (cmdw-3) "s" clear " %s\n", $1, $2);
    } else {
      write[_c++] = sprintf(cmdc "%-" cmdw "s" clear " %s\n", $1, $2);
    }

    _d = 0;
    for(i=3;i<=NF;i++) if($i != "") {
      write[_c++] = sprintf(gc "%-" (cmdw+3) "s%s" clear "\n", "", $i);
      _d++;
    }
  }
}
END {
  for(i=0;i<_c;i++) {
    printf write[i];
  }
}