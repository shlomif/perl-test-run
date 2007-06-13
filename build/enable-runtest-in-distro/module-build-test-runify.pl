#!/usr/bin/perl 

use strict;
use warnings;

use IO::All;

my $build_pl_text = io()->file("Build.PL")->slurp();

my $prelude = <<'EOF';
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;
EOF

$build_pl_text =~ s{use Module::Build;}{$prelude};

$build_pl_text =~ s{Module::Build(->new)}{Test::Run::Builder$1};

io()->file("Build.PL")->print($build_pl_text);

my $dir = "inc/Test/Run";
my $builder_file = "$dir/Builder.pm";
io()->dir($dir)->mkpath();
io()->file($builder_file)->print(<<'END_OF_T_R_BUILD');
package Test::Run::Builder;

use strict;
use warnings;

use Module::Build;

use vars qw(@ISA);

@ISA = (qw(Module::Build));

sub ACTION_runtest
{
    my ($self) = @_;
    my $p = $self->{properties};

    $self->depends_on('code');

    local @INC = @INC;

    # Make sure we test the module in blib/
    unshift @INC, (File::Spec->catdir($p->{base_dir}, $self->blib, 'lib'),
		 File::Spec->catdir($p->{base_dir}, $self->blib, 'arch'));

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

    require Test::Run::CmdLine::Iface;

    my $test_run =
        Test::Run::CmdLine::Iface->new(
            {
                'test_files' => [glob("t/*.t")],
            }   
            # 'backend_params' => $self->_get_backend_params(),
        );

    return $test_run->run();
}

1;
END_OF_T_R_BUILD

{
    my @manifest = io->file("MANIFEST")->chomp()->getlines();
    push @manifest, $builder_file;
    io->file("MANIFEST")->print(map { "$_\n" } sort { lc($a) cmp lc($b) } @manifest);
}

