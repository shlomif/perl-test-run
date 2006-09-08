use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => "Test::Run::Module::Build",
    code => <<'EOF',
use Test::Run::CmdLine::Iface;

sub ACTION_runtest
{
    my ($self) = @_;

    $self->depends_on('code');

    local @INC = @INC;

    $self->do_test_run_tests;
}

sub ACTION_distruntest {
  my ($self) = @_;

  $self->depends_on('distdir');

  my $start_dir = $self->cwd;
  my $dist_dir = $self->dist_dir;
  chdir $dist_dir or die "Cannot chdir to $dist_dir: $!";
  # XXX could be different names for scripts

  $self->run_perl_script('Build.PL') # XXX Should this be run w/ --nouse-rcfile
      or die "Error executing 'Build.PL' in dist directory: $!";
  $self->run_perl_script('Build')
      or die "Error executing 'Build' in dist directory: $!";
  $self->run_perl_script('Build', [], ['runtest'])
      or die "Error executing 'Build test' in dist directory";
  chdir $start_dir;
}

sub do_test_run_tests
{
    my $self = shift;

    my $test_run =
        Test::Run::CmdLine::Iface->new(
            'test_files' => [glob("t/*.t")],
            # 'backend_params' => $self->_get_backend_params(),
        );

    return $test_run->run();
}
EOF
);

my $build = $class->new(
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

