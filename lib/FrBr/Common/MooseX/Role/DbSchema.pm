package FrBr::Common::MooseX::Role::DbSchema;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::DbSchema

=head1 DESCRIPTION

Rolle, um einem Moose-Objekt Zugriff auf ein Datenbank-Schema
(vom Type DBIx::Class::Schema) hinzuzufügen.

=cut

#---------------------------------------------------------------------------

use Moose::Role;

use Moose::Util::TypeConstraints;
use Encode qw( decode_utf8 encode_utf8 );

use utf8;

use Carp ();

with 'FrBr::Common::MooseX::Role::Types';
with 'FrBr::Common::MooseX::Role::CommonOpts';

use version; our $VERSION = qv("0.0.1");

############################################################################

=head1 Attribute

Eigene Attribute

=cut

#-----------------------------------------

=head2 show_sql

Sollen SQL-Statements vor der Ausführung angezeigt werden?

=cut

has 'show_sql' => (
    is              => 'rw',
    isa             => 'Bool',
    traits          => [ 'Getopt' ],
    cmd_flag        => 'show-sql',
    builder         => '_build_show_sql',
    documentation   => 'BOOL: Sollen SQL-Statements vor der Ausführung angezeigt werden? Bei "verbose" >= 3 immer an.',
    cmd_aliases     => 'sql',
);

#------

sub _build_show_sql {
    return 0;
}

#-------------------------

=head2 schema

Objekt-Referenz auf ein DBIx::Class::Schema-Objekt, mit dem auf die Db zugegriffen werden kann

=cut

has 'schema' => (
    is              => 'ro',
    isa             => 'DBIx::Class::Schema',
    traits          => [ 'NoGetopt' ],
    documentation   => 'Objekt-Referenz auf ein DBIx::Class::Schema-Objekt, mit dem auf die Db zugegriffen werden kann',
    writer          => '_set_schema',
    predicate       => 'has_schema',
);

#------

sub _set_schema {
    return $_[0];
}

############################################################################

=head1 Benötigte Funktionen

=cut

requires 'debug';                   # im Moose-Objekt FrBr::Common::MooseX:App
requires 'evaluate_config';         # in der Rolle FrBr::Common::MooseX::Role::Config

############################################################################

=head1 Methoden und Methoden-Modifizerer

Methoden und Methoden-Modifizerer dieser Rolle

=head2 around BUILDARGS

=cut

around BUILDARGS => sub {

    my $orig = shift;
    my $class = shift;

    my %Args = @_;

    $Args{'show_sql'} = 1 if $Args{'verbose'} and $Args{'verbose'} >= 3;

    return $class->$orig(%Args);

};

#---------------------------------

=head2 init_db_schema

Initialisiert das Datenbank-Schema

=cut

sub init_db_schema {

    my $self = shift;

    $self->debug( "Initialisiere Datenbankschema ..." );

    my $config = $self->config->{'Model::Schema'};
    unless ($config) {
        die "Keine gültige Datenbankschema-Konfiguration gefunden.\n";
    }

    $ENV{'DBIC_TRACE'} = 1 if $self->show_sql;

    {
        my $eval_str = "use " . $config->{'schema_class'} . ";";
        eval $eval_str;
        if ( $@ ) {
            die sprintf( "Konnte Schema %s nicht benutzen: %s", $config->{'schema_class'}, $@ );
        }
    }

    $self->debug( sprintf( "Öffne Db-Schema %s ...", $config->{'schema_class'} ) );
    my $schema = $config->{'schema_class'}->connect( $config->{'connect_info'} );
    die sprintf( "Konnte Db-Schema %s nicht öffnen.", $config->{'schema_class'} ) unless $schema;
    $self->_set_schema($schema);

}

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
