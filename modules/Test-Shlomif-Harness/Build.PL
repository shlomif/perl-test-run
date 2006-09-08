use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => "Test::Run",
    requires => 
    {
        'Class::Accessor' => 0,
        'File::Spec' => 0.6,
        'Test::Harness' => "2.53",
        'Scalar::Util' => 0,
        'TAPx::Parser' => "0.21",
    },
    dist_version_from => "lib/Test/Run/Obj.pm",
);

$build->create_build_script;

# sub MY::postamble {
#     return <<'MAKE_FRAG';
# .PHONY: tags
# 
# tags:
# 	ctags -f tags --recurse --totals \
# 		--exclude=blib/ --exclude=t/lib \
# 		--exclude=.svn --exclude='*~' \
# 		--languages=Perl --langmap=Perl:+.t \
# MAKE_FRAG
# }

