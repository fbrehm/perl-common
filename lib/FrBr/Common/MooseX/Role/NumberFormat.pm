package FrBr::Common::MooseX::Role::NumberFormat;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::NumberFormat

=head1 DESCRIPTION

Rolle, um eine Formatierung von Zahlen über ein Number::Format-Objekt
zu ermöglichen.

=cut

#---------------------------------------------------------------------------

use Moose::Role;

use Moose::Util::TypeConstraints;
use Number::Format;

use utf8;

use Carp ();

with 'MooseX::Getopt';

with 'FrBr::Common::MooseX::Role::Types';

use version; our $VERSION = qv("0.0.1");

#---------------------------------------------------------------------------

# Eigene Attribute

#-------------------------

has 'number_format' => (
    is              => 'ro',
    isa             => 'Number::Format',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    documentation   => 'Objekt zur Konvertierung von Zahlen in hübsch gestaltete Strings',
    builder         => '_build_number_format',
    writer          => '_set_number_format',
);

#------

sub _set_number_format {
    return $_[0];
}

#-

sub _build_number_format {
    return new Number::Format(
        '-thousands_sep'    => '.',
        '-decimal_point'    => ',',
        '-int_curr_symbol'  => '€',
    );
}

#---------------------------------------------------------------------------

# Ändern der Eigenschaften einiger geerbter Attribute

#---------------------------------------------------------------------------

# Methoden dieser Rolle

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
