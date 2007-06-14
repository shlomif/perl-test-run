package Test::Run::Base::Plugger;

use strict;
use warnings;

use NEXT;

use base 'Test::Run::Base';

use Carp;

require UNIVERSAL::require;

__PACKAGE__->mk_accessors(
    qw(
        _base
        _into
        _plugins
    )
);

sub _initialize
{
    my ($self, $args) = @_;

    $self->NEXT::_initialize($args);

    $self->_base($args->{base})
        or confess "Wrong base $args->{base}";
    $self->_into($args->{into})
        or confess "Wrong 'into' $args->{into}";

    $self->_plugins([]);

    $self->_update_ISA();
    
    return 0;
}

sub _update_ISA
{
    my $self = shift;
    
    my $base_class = $self->_base();
    my $into_class = $self->_into();

    my $isa_ref = do { no strict 'refs'; \@{"${into_class}::ISA"} };

    @$isa_ref = ();

    foreach my $plugin (@{$self->_plugins()})
    {
        $plugin->require();
        if ($@)
        {
            die $@;
        }
        push @$isa_ref, $plugin;
    }    

    $base_class->require();
    if ($@)
    {
        die $@
    }

    push @$isa_ref, $base_class;

    return;
}

sub add_plugins
{
    my $self = shift;
    my $more_plugins = shift;

    push @{$self->_plugins()}, @{$more_plugins};

    $self->_update_ISA();
}

sub create_new
{
    my $self = shift;

    return $self->_into()->new(@_);
}

1;

