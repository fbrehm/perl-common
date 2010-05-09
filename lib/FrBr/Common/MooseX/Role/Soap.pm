package FrBr::Common::MooseX::Role::Soap;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::Soap

=head1 DESCRIPTION

Alle allgemin verwendbaren Attribute und Methoden für SOAP-Client-Requests

=cut

#---------------------------------------------------------------------------

#use SOAP::Lite +trace;

use Moose::Role;

use Moose::Util::TypeConstraints;
use Encode qw( decode_utf8 encode_utf8 );
use URI            ();
use SOAP::Lite;

use utf8;

use Carp qw(cluck);

with 'FrBr::Common::MooseX::Role::Types';

use version; our $VERSION = qv("0.0.2");

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

=head2 soap_uri

Die komplette URL des SOAP-Servers.

=cut

has 'soap_uri' => (
    is              => 'rw',
    isa             => 'FrBr::Types::URI',
    coerce          => 1,
    lazy            => 1,
    traits          => [ 'Getopt' ],
    cmd_flag        => 'soap-uri',
    builder         => '_build_soap_uri',
    documentation   => 'komplette URL des SOAP-Servers.',
);

#------

sub _build_soap_uri {
    return 'http://soap.brehm-online.com/soap/rpc.pl';
}

#---------------------------------

=head2 soap_ns_uri

Die komplette URL der Namespace-Beschreibung des SOAP-Servers.

=cut

has 'soap_ns_uri' => (
    is              => 'rw',
    isa             => 'CoNet::Types::URI',
    coerce          => 1,
    lazy            => 1,
    traits          => [ 'Getopt' ],
    cmd_flag        => 'soap-ns-uri',
    builder         => '_build_soap_ns_uri',
    documentation   => 'komplette URL der Namespace-Beschreibung des SOAP-Servers.',
);

#------

sub _build_soap_ns_uri {
    return 'http://soap.brehm-online.com/soap/rpc.pl';
}

#---------------------------------

=head2 soap_additional_ns

Eine Hash-Ref mit zusätzlichen Namespace-URLs als Keys und einem möglichen Präfix als Value

=cut

has 'soap_additional_ns' => (
    is              => 'ro',
    isa             => 'HashRef[Maybe[Str]]',
    lazy            => 1,
    traits          => [ 'NoGetopt' ],
    builder         => '_build_soap_additional_ns',
    documentation   => 'Hash-Ref mit zusätzlichen Namespace-URLs als Keys und einem möglichen Präfix als Value',
);

#------

sub _build_soap_additional_ns {
    return {};
}

#---------------------------------

=head2 soap_envprefix

Präfix für die SOAP-Envelope (default: "soap")

=cut

has 'soap_envprefix' => (
    is              => 'rw',
    isa             => 'Maybe[Str]',
    lazy            => 1,
    traits          => [ 'Getopt' ],
    cmd_flag        => 'soap-envprefix',
    cmd_aliases     => 'envprefix',
    documentation   => 'Präfix für die SOAP-Envelope (default: "soap")',
    builder         => '_build_soap_envprefix',
);

#------

sub _build_soap_envprefix {
    return undef;
}

#---------------------------------

=head2 soap_encprefix

Encoding-Präfix für die SOAP-Envelope (default: "soapenc")

=cut

has 'soap_encprefix' => (
    is              => 'rw',
    isa             => 'Maybe[Str]',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    cmd_flag        => 'soap-encprefix',
    cmd_aliases     => 'encprefix',
    documentation   => 'Encoding-Präfix für die SOAP-Envelope (default: "soapenc")',
    builder         => '_build_soap_encprefix',
);

#------

sub _build_soap_encprefix {
    return undef;
}

#---------------------------------

=head2 soap_faultcode

Enthält nach einem SOAP-Fehler den Fehler-Code.

=cut

has 'soap_faultcode' => (
    is              => 'ro',
    isa             => 'Str',
    traits          => [ 'NoGetopt' ],
    documentation   => 'Enthält nach einem SOAP-Fehler den Fehler-Code.',
    writer          => '_set_soap_faultcode',
    predicate       => 'has_soap_faultcode',
    clearer         => 'clear_soap_faultcode',
);

#------

sub _set_soap_faultcode {
    return $_[1];
}

#---------------------------------

=head2 soap_faultstring

Enthält nach einem SOAP-Fehler den Fehlertext.

=cut

has 'soap_faultstring' => (
    is              => 'ro',
    isa             => 'Str',
    traits          => [ 'NoGetopt' ],
    documentation   => 'Enthält nach einem SOAP-Fehler den Fehlertext.',
    writer          => '_set_soap_faultstring',
    predicate       => 'has_soap_faultstring',
    clearer         => 'clear_soap_faultstring',
);

#------

sub _set_soap_faultstring {
    return $_[1];
}

#---------------------------------------------------------------------------

# Methoden dieser Rolle

#around BUILDARGS => sub {
#
#    my $orig = shift;
#    my $class = shift;
#
#    my %Args = @_;
#
#    #warn "Bin in '" . __PACKAGE__ . "'\n";
#    $Args{'show_sql'} = 1 if $Args{'verbose'} and $Args{'verbose'} >= 3;
#
#    return $class->$orig(%Args);
#
#};

#---------------------------------

before 'evaluate_config' => sub {

    my $self = shift;

    my $add_ns = $self->soap_additional_ns;
    $add_ns->{"http://xml.apache.org/xml-soap"} = 'ns2';

};

#---------------------------------

after 'evaluate_config' => sub {

    my $self = shift;

    $self->debug( "Werte Konfigurationsdinge aus ..." );
    return unless $self->config and keys %{ $self->config };

    unless ( $self->used_cmd_params->{'soap_uri'} ) {
        $self->soap_uri( $self->config->{'soap-uri'} ) if $self->config->{'soap-uri'};
        $self->soap_uri( $self->config->{'soap_uri'} ) if $self->config->{'soap_uri'};
        $self->soap_uri( $self->config->{'soap'}{'uri'} ) if $self->config->{'soap'} and $self->config->{'soap'}{'uri'};
    }

    unless ( $self->used_cmd_params->{'soap_ns_uri'} ) {
        $self->soap_ns_uri( $self->config->{'soap-ns-uri'} ) if $self->config->{'soap-ns-uri'};
        $self->soap_ns_uri( $self->config->{'soap_ns_uri'} ) if $self->config->{'soap_ns_uri'};
        $self->soap_ns_uri( $self->config->{'soap'}{'ns_uri'} ) if $self->config->{'soap'} and $self->config->{'soap'}{'ns_uri'};
    }

    unless ( $self->used_cmd_params->{'soap_envprefix'} ) {
        $self->soap_envprefix( $self->config->{'soap-envprefix'} ) if exists $self->config->{'soap-envprefix'};
        $self->soap_envprefix( $self->config->{'soap_envprefix'} ) if exists $self->config->{'soap_envprefix'};
        $self->soap_envprefix( $self->config->{'soap'}{'envprefix'} ) if $self->config->{'soap'} and exists $self->config->{'soap'}{'envprefix'};
    }

    unless ( $self->used_cmd_params->{'soap_encprefix'} ) {
        $self->soap_encprefix( $self->config->{'soap-encprefix'} ) if exists $self->config->{'soap-encprefix'};
        $self->soap_encprefix( $self->config->{'soap_encprefix'} ) if exists $self->config->{'soap_encprefix'};
        $self->soap_encprefix( $self->config->{'soap'}{'encprefix'} ) if $self->config->{'soap'} and exists $self->config->{'soap'}{'encprefix'};
    }

    if ( exists $self->config->{'soap'}{'additional_ns'} ) {
        my $cnf_ns = $self->config->{'soap'}{'additional_ns'};
        my $add_ns = $self->soap_additional_ns;
        if ( ref($cnf_ns) ) {
            if ( ref($cnf_ns) eq 'ARRAY' ) {
                for my $url ( @$cnf_ns ) {
                    $add_ns->{$url} = undef;
                }
            }
            elsif ( ref($cnf_ns) eq 'HASH' ) {
                for my $url ( keys %$cnf_ns ) {
                    $add_ns->{$url} = $cnf_ns->{$url};
                }
            }
        }
        else {
            $add_ns->{$cnf_ns} = undef;
        }
    }

};

#---------------------------------

=head2 soap_request( $method, @Params )

Der eigentliche SOAP-Request.

Es muss ein Methodenname übergeben werden.

Die Parameter, die mit dieser $method übergeben werden, sollten mit generate_soap_param()
erzeugt werden.

=cut

sub soap_request {

    my $self = shift;

    $self->clear_soap_faultcode();
    $self->clear_soap_faultstring();

    my $method = shift;
    unless ( $method ) {
        $self->error( "Kein Methodenname übergeben." );
        return undef;
    }

    my @Params;
    if ( $_[0] and ref($_[0]) ) {
        if ( ref($_[0]) eq 'HASH' ) {
            @Params = %{ $_[0] };
        }
        elsif ( ref($_[0]) eq 'ARRAY' ) {
            @Params = @{ $_[0] };
        }
        else {
            @Params = @_;
        }
    }
    else {
        @Params = @_;
    }
    $self->debug( "SOAP-Methode: ", $method );
    $self->debug( "SOAP-Parameter: ", \@Params ) if $self->verbose >= 2;

    my $proxy = $self->soap_uri->canonical->as_string;
    $self->debug( sprintf( "Verwende SOAP-Proxy: '%s'.", $proxy ) );

    my $soap = SOAP::Lite->new()->on_action( sub { join'/', @_ } )->proxy($proxy);
#    if ( $self->verbose >= 3 ) {
#        $soap->on_debug( sub { $self->debug(@_) } );
#    }

    $soap->serializer->envprefix( $self->soap_envprefix ) if $self->soap_envprefix;
    $soap->serializer->encprefix( $self->soap_encprefix ) if $self->soap_encprefix;

    my $add_ns = $self->soap_additional_ns;
    for my $uri ( keys %$add_ns ) {
        if ( $add_ns->{$uri} ) {
            $soap->serializer->register_ns( $uri, $add_ns->{$uri} );
        }
        else {
            $soap->serializer->register_ns( $uri );
        }
    }

    my $ns_uri = $self->soap_ns_uri->canonical->as_string or $self->soap_uri->canonical->as_string;
    $self->debug( sprintf( "Verwende Namespace-URI: '%s'.", $ns_uri ) );
    my $method_object = SOAP::Data->name($method)->attr({ xmlns => $ns_uri });
    $self->debug( "Methoden-Objekt: ", $method_object ) if $self->verbose >= 3;

    my $som;

    $som = $soap->call( $method_object, @Params );

    if ( $som->fault() ) {
        $self->_set_soap_faultcode( $som->faultcode );
        $self->_set_soap_faultstring( $som->faultstring );
        $self->warn( "SOAP-Fehlercode: " . $som->faultcode );
        $self->warn( "SOAP-Fehlertext: " . $som->faultstring );
        return undef;
    }

    $self->debug( "SOAP::Lite-Ergebnis: ", $som->result );

    return $som->result;

}

#---------------------------------------------------------------------------

=head2 generate_soap_param( 'subject', 'Bli Bla Blub', 'string' )

Generiert aus übergebenen Parameter-Namen, -Wert und -Typ
einen gültigen SOAP-Parameter.

Der Parameter-Name muss übergeben werden.

Es sind alle grundlegenden und abgeleiteten Datentypen als Parameter-Typ
laut L<http://www.w3.org/TR/xmlschema-2/> erlaubt.

Als Parameter-Typ sind ausserdem folgende Werte erlaubt:

  - map (zur Konvertierung eines Hashs in eine Struktur, die PHP als assoziatives Array versteht)
  - array (als 

=cut

sub generate_soap_param {

    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my $type  = shift;

    my $w3c_type = {
        'string'             => 'primitive',
        'boolean'            => 'primitive',
        'decimal'            => 'primitive',
        'float'              => 'primitive',
        'double'             => 'primitive',
        'duration'           => 'primitive',
        'dateTime'           => 'primitive',
        'time'               => 'primitive',
        'date'               => 'primitive',
        'gYearMonth'         => 'primitive',
        'gYear'              => 'primitive',
        'gMonthDay'          => 'primitive',
        'gDay'               => 'primitive',
        'gMonth'             => 'primitive',
        'hexBinary'          => 'primitive',
        'base64Binary'       => 'primitive',
        'anyURI'             => 'primitive',
        'QName'              => 'primitive',
        'NOTATION'           => 'primitive',
        'normalizedString'   => 'derived',
        'token'              => 'derived',
        'language'           => 'derived',
        'NMTOKEN'            => 'derived',
        'NMTOKENS'           => 'derived',
        'Name'               => 'derived',
        'NCName'             => 'derived',
        'ID'                 => 'derived',
        'IDREF'              => 'derived',
        'IDREFS'             => 'derived',
        'ENTITY'             => 'derived',
        'ENTITIES'           => 'derived',
        'integer'            => 'derived',
        'nonPositiveInteger' => 'derived',
        'negativeInteger'    => 'derived',
        'long'               => 'derived',
        'int'                => 'derived',
        'short'              => 'derived',
        'byte'               => 'derived',
        'nonNegativeInteger' => 'derived',
        'unsignedLong'       => 'derived',
        'unsignedInt'        => 'derived',
        'unsignedShort'      => 'derived',
        'unsignedByte'       => 'derived',
        'positiveInteger'    => 'derived',
    };

    if ( $type ) {
        $type =~ s/^\s+//;
        $type =~ s/\s+$//;
        if ( $type eq '' ) {
            $type = undef;
        }
        else {
            unless ( $w3c_type->{$type} or
                     $type eq 'map' or
                     $type eq 'array' or
                     $type =~ /^array\[.+\]$/ ) {
                $self->fatal( "Ungültige Typ-Angabe '" . $type . "' beim Aufruf." );
                cluck( "Ungültige Typ-Angabe '" . $type . "' beim Aufruf." );
                exit 55;
            }
        }
    }

    unless ( defined $value ) {
        return SOAP::Data->new( name => $name, value => undef );
    }

    if ( $type and $w3c_type->{$type} ) {
        return SOAP::Data->new( name => $name, value => $value )->type($type);
    }

    if ( $type and $type eq 'map' and ref($value) and ref($value) eq 'HASH' ) {
        my @Params = ();
        for my $key ( keys %$value ) {
            my $elem = SOAP::Data->name( "item" => \SOAP::Data->value(
                SOAP::Data->name( 'key' => $key ),
                SOAP::Data->name( 'value' => $value->{$key} ),
            ) );
            push @Params, $elem;
        }
        return SOAP::Data->name( $name => \SOAP::Data->value( @Params ) )->type( "ns2:Map" );
    }

    if ( ref($value) and ref($value) eq 'ARRAY' ) {
        my @Params = ();
        my $i = 0;
        my $param;
        for my $elem ( @$value ) {
            my $ename = sprintf( "elem%02d", $i );
            if ( $type and $type =~ /^array\[(.+)\]$/ ) {
                my $etype = $1;
                $param = $self->generate_soap_param( $ename, $elem, $etype )
            }
            else {
                $param = SOAP::Data->name( $ename => $elem );
            }
            push @Params, $param;
            $i++;
        }

        return [ @Params ];

    }

    return $value;

}

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
