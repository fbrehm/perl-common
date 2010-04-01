package FrBr::Common::MooseX::Types;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Types

=head1 DESCRIPTION

Definiert alle speziellen Attributtypen

=cut

#---------------------------------------------------------------------------

use Moose::Role;
use Moose::Util::TypeConstraints;

use Carp ();

#---------------------------------------------------------------------------

subtype 'UnsignedInt'
    => as 'Int'
    => where { $_ >= 0 }
    => message { "Die von Ihnen angegebene Zahl '$_' ist negativ." };

subtype 'DBIx::Class::Schema'
    => as 'Object'
    => where { $_->isa('DBIx::Class::Schema') }
    => message { "Das übergebene Objekt muss vom Typ 'DBIx::Class::Schema' sein" };

subtype 'Number::Format'
    => as 'Object'
    => where { $_->isa('Number::Format') }
    => message { "Das übergebene Objekt muss vom Typ 'Number::Format' sein" };

subtype 'XML::Simple'
    => as 'Object'
    => where { $_->isa('XML::Simple') }
    => message { "Das übergebene Objekt muss vom Typ 'XML::Simple' sein" };

#---------------------------------------------------------------------------

no Moose::Role;
1;

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
