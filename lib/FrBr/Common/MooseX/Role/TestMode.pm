package FrBr::Common::MooseX::Role::TestMode;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::TestMode

=head1 DESCRIPTION

Fügt die Eigenschaft 'testmode' dem Objekt hinzu

=cut

#---------------------------------------------------------------------------

use Moose::Role;

use Moose::Util::TypeConstraints;
use Encode qw( decode_utf8 encode_utf8 );

use utf8;

use Carp qw(cluck);

with 'FrBr::Common::MooseX::Role::Types';

use version; our $VERSION = qv("0.0.1");

############################################################################

=head1 Benötigte Funktionen

=cut

requires 'debug';                   # im Moose-Objekt FrBr::Common::MooseX:App
requires 'evaluate_config';         # in der Rolle FrBr::Common::MooseX::Role::Config

############################################################################

=head1 Attribute

Eigene Attribute

=cut

#-----------------------------------------

=head2 testmode

Es sollten keine verändernden Aktionen durchgeführt werden

=cut

has 'testmode' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    traits          => [ 'Getopt' ],
    cmd_flag        => 'testmode',
    builder         => '_build_testmode',
    documentation   => 'Testmodus - es werden keine verändernden Aktionen durchgeführt.',
    cmd_aliases     => [ 'T', 'test', ],
);

#------

sub _build_testmode {
    return 0;
}

#---------------------------------------------------------------------------

# Methoden dieser Rolle

#---------------------------------

after 'evaluate_config' => sub {

    my $self = shift;

    $self->debug( "Werte Konfigurationsdinge aus ..." );
    return unless $self->config and keys %{ $self->config };

    if ( $self->verbose >= 2 ) {
        my $tmp = $self->testmode;
    }

    unless ( $self->used_cmd_params->{'testmode'} ) {
        for my $key ( keys %{ $self->config } ) {
            my $val = $self->config->{$key};
            $self->testmode($val) if $key =~ /^test[_-]?mode$/i;
        }
    }

};

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
