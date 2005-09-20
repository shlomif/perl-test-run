BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}


print "1..1\n";

unless (eval 'require Test::Shlomif::Harness::Obj') {
  print "not ok 1\n";
} else {
  print "ok 1\n";
}
