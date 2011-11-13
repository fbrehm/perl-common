package FrBr::Common::MooseX::Pid;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Pid;

=head1 DESCRIPTION

Basismodul fuer PID-Management

Beruht auf MooseX::Daemonize::Pid

=cut

#---------------------------------------------------------------------------

use Moose;

use utf8;

use strict;    # because Kwalitee is pedantic

use Moose::Util::TypeConstraints;

#-----------------------------------------

# Versionitis

use version; our $VERSION = qv("0.1.0");

#-----------------------------------------

coerce 'FrBr::Common::MooseX::Pid'
    => from 'Int'
        => via { FrBr::Common::MooseX::Pid->new( pid => $_ ) };

############################################################################

=head1 ATTRIBUTES

Alle für dieses allgemeine Anwendungsobjekt definierten Attribute/Eigenschaften,
die nicht durch dazugehörige Rollen definiert werden.

=cut

#---------------------------------------------------------------------------

=head2 pid

Die PID, die dieses Objekt beinhaltet.

=cut

has 'pid' => (
    is        => 'rw',
    isa       => 'Int',
    lazy      => 1,
    clearer   => 'clear_pid',
    predicate => 'has_pid',
    default   => sub { $$ }
);

#############################################################################################

=head1 METHODS

Methoden und Methoden-Modifizierer

=head2 is_running( )

Gibt an, ob der Prozess mit der beinhalteten PID noch läuft.

=cut

sub is_running { kill(0, (shift)->pid) ? 1 : 0 }

#---------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
