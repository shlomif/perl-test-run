#!/usr/bin/perl

use strict;
use warnings;

package MyTaggerApp;

use Moose;

use SVN::Ra;
use SVN::Client;
use SVN::Core;

has '_repos_path' => (isa => "Str", is => "ro", required => 1,
    init_arg => "repos_path");
has '_svn_ra' => (isa => "SVN::Ra", is => "ro", lazy => 1, 
    builder  => "_create_svn_ra"
);

sub _create_svn_ra
{ 
    my $self = shift;

    my ($baton) = SVN::Core::auth_open_helper([SVN::Client::get_ssl_server_trust_file_provider()]);
    return SVN::Ra->new(
        url => $self->_repos_path(),
        auth => $baton,
    ) ; 
}

sub _get_correct_node_kind
{
    my $self = shift;
    return $self->should_be_dir() ? $SVN::Node::dir : $SVN::Node::file;
}

sub _should_be_dir
{
    my ($self, $path) = @_;

    return (($path eq "") || ($path =~ m{/\z}));
}

sub _check_node_kind
{
    my $self = shift;
    my $path = shift;
    my $node_kind = shift;

    if (($node_kind eq $SVN::Node::none) || ($node_kind eq $SVN::Node::unknown))
    {
        return "unknown";
    }
    elsif ($node_kind ne $self->_get_correct_node_kind($path))
    {
        return "mismatch";
    }
    else
    {
        return $SVN::Node::dir ? "dir" : "file";
    }
}

sub check_path
{
    my ($self, $path) = @_;

    my $node_kind = $self->_svn_ra->check_path(
        $path,
        $self->_svn_ra()->get_latest_revnum(),
    );

    return $self->_check_node_kind($path, $node_kind);
}

package main;

my $app = MyTaggerApp->new(
    {
        repos_path => "https://svn.berlios.de/svnroot/repos/web-cpan/",
    }
);

# Must not start with a slash.
my $node_kind = $app->check_path( "Test-Harness-NG/tags/releases/0.0122");

print $node_kind, "\n";

