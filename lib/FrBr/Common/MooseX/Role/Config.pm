package FrBr::Common::MooseX::Role::Config;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::Config

=head1 DESCRIPTION

Rolle, um eine wie auch immer geartete Konfiguration zu integrieren

=cut

#---------------------------------------------------------------------------

use Moose::Role;

use MooseX::Getopt::Meta::Attribute::Trait;
use MooseX::Getopt::Meta::Attribute::Trait::NoGetopt;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;
use File::Basename;
use FindBin;
use Path::Class;
use Clone qw(clone);
use Config::Any;

use utf8;

use Carp ();

with 'FrBr::Common::MooseX::Role::Types';

use version; our $VERSION = qv("0.0.1");

############################################################################

=head1 Benötigte Funktionen

=cut

requires 'debug';                   # im Moose-Objekt FrBr::Common::MooseX:App
requires 'init_app';                # im Moose-Objekt FrBr::Common::MooseX:App

############################################################################

=head1 Attribute

Eigene Attribute

=cut

#-------------------------

=head2 cfg_stem

Basisname der Konfigurationsdatei (ohne Endung) im Konfigurationsverzeichnis

=cut

has 'cfg_stem' => (
    is              => 'ro',
    isa             => 'Str',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    builder         => '_build_cfg_stem',
    documentation   => 'Basisname der Konfigurationsdatei (ohne Endung) im Konfigurationsverzeichnis',
    cmd_flag        => 'config',
    cmd_aliases     => 'cfg-stem',
);

#------

sub _build_cfg_stem {
    return "config";
}

#-------------------------

=head2 cfg_dir

Verzeichnis der Konfigurationsdateien

=cut

has 'cfg_dir' => (
    is              => 'rw',
    isa             => 'Path::Class::Dir',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    builder         => '_build_cfg_dir',
    documentation   => 'Verzeichnis der Konfigurationsdateien',
    writer          => '_set_cfg_dir',
    coerce          => 1,
    metaclass       => 'MooseX::Getopt::Meta::Attribute',
    cmd_flag        => 'cfg-dir',
    cmd_aliases     => 'cfgdir',
);

#------

sub _build_cfg_dir {
    return dir->new( dir->new( $FindBin::Bin )->parent->absolute, 'etc' );
}

#-

sub _set_cfg_dir {
    return dir->new( $_[0] )->absolute;
}

#---------------------------------

=head2 config

Konfiguration als Hash-Ref nach dem Lesen

=cut

has 'config' => (
    is              => 'rw',
    isa             => 'HashRef',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    builder         => '_build_config',
    documentation   => 'Konfiguration als Hash-Ref',
);

#------

sub _build_config {
    return {};
}

#---------------------------------

=head2 default_config

Vorgabe-Konfiguration als Hash-Ref

=cut

has 'default_config' => (
    is              => 'ro',
    isa             => 'HashRef',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    builder         => '_build_default_config',
    documentation   => 'Vorgabe-Konfiguration als Hash-Ref',
);

#------

sub _build_default_config {
    return {};
}

#---------------------------------

=head2 used_cmd_params

Die tatsächlich mit der Kommandozeile übergebenen Parameter
(besser: ihr dazugehöriger Attributname) als Key, Value immer 1

=cut

has 'used_cmd_params' => (
    is              => 'rw',
    isa             => 'HashRef',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    builder         => '_build_used_cmd_params',
    documentation   => 'Die tatsächlich mit der Kommandozeile übergebenen Parameter (besser: ihr dazugehöriger Attributname) als Key, Value immer 1',
);

#------

sub _build_used_cmd_params {
    return {};
}

#-------------------------

=head2 configuration_evaluated

Wurde die Konfiguration bereits ausgewertet?

=cut

has 'configuration_evaluated' => (
    is              => 'ro',
    isa             => 'Bool',
    traits          => [ 'NoGetopt' ],
    builder         => '_build_configuration_evaluated',
    writer          => '_set_configuration_evaluated',
    documentation   => 'Wurde die Konfiguration bereits ausgewertet',
);

#------

sub _build_configuration_evaluated {
    return 0;
}

sub _set_configuration_evaluated {
    return $_[1];
}

#-------------------------

=head2 configuration_read

Wurde die Konfiguration bereits gelesen?

=cut

has 'configuration_read' => (
    is              => 'ro',
    isa             => 'Bool',
    traits          => [ 'NoGetopt' ],
    builder         => '_build_configuration_read',
    writer          => '_set_configuration_read',
    documentation   => 'Wurde die Konfiguration bereits gelesen',
);

#------

sub _build_configuration_read {
    return 0;
}

sub _set_configuration_read {
    return $_[1];
}

############################################################################

=head1 Benötigte Funktionen

=cut

#requires 'debug';

#---------------------------------------------------------------------------

# Ändern der Eigenschaften einiger geerbter Attribute

############################################################################

=head1 Methoden und Methoden-Modifizerer

Methoden und Methoden-Modifizerer dieser Rolle

=cut

#---------------------------------------------------------------------------

=head 2 after BUILD

wird nach dem BUILD-Prozess des Anwendungsprozesses aufgerufen

=cut

#after 'BUILD' => sub {
#    my $self = shift;
#    $self->read_config_file();
#    $self->evaluate_config();
#};

sub BUILD {
    my $self = shift;
    $self->read_config_file();
    $self->evaluate_config();
}

#---------------------------------------------------------------------------

after 'init_app' => sub {

    my $self = shift;

    $self->read_config_file();
    $self->evaluate_config();

    if ( $self->verbose >= 2 ) {

        my $tmp;
        for my $f ( 'configuration_evaluated', 'configuration_read', 'cfg_stem', 'cfg_dir', 'config', 'default_config', 'used_cmd_params', ) {
            $tmp = $self->$f();
        }

    }

};

#---------------------------------------------------------------------------

=head2 read_config_file( [$force] )

Liest die Konfiguration aus den Konfigurations-Dateien ein.

Der boolsche Parameter $force besagt, wenn mit einem wahren Wert übergeben,
dass die Konfiguration eingelesen werden soll, auch wenn sie bereits
gelesen wurde.

=cut

sub read_config_file {

    my $self  = shift;
    my $force = shift;

    unless ( $force ) {
        return if $self->configuration_read;
    }

    $self->debug( "Lese Konfiguration ..." );

    my $config = clone($self->default_config());

    my $stems = [ file( $self->cfg_dir, $self->cfg_stem )->stringify ];

    $self->debug( "Versuche Config-STEMS zu lesen: ", $stems ) if $self->verbose > 3;
    my $cfg = Config::Any->load_stems( { stems => $stems, flatten_to_hash => 0, use_ext => 1 } );
    $self->debug( "Gelesene Konfiguration: ", $cfg )  if $self->verbose > 3;

    for my $file ( keys %$cfg ) {
        if ( keys %{ $cfg->{$file} } ) {
            $config = merge_hashes( $config, $cfg->{$file} );
        }
    }

    $stems = [ file( $self->cfg_dir, ( $self->cfg_stem . "_local" ) )->stringify ];
    $self->debug( "Versuche lokale Config-STEMS zu lesen: ", $stems ) if $self->verbose > 3;
    $cfg = Config::Any->load_stems( { stems => $stems, flatten_to_hash => 0, use_ext => 1 } );
    $self->debug( "Gelesene lokale Konfiguration: ", $cfg )  if $self->verbose > 3;

    for my $file ( keys %$cfg ) {
        if ( keys %{ $cfg->{$file} } ) {
            $config = merge_hashes( $config, $cfg->{$file} );
        }
    }

    $self->debug( "Zusammengemixte Konfiguration: ", $config ) if $self->verbose > 2;

    $self->config($config);

    $self->_set_configuration_read(1);
    $self->_set_configuration_evaluated(0);

}

#---------------------------------

=head2 evaluate_config( )

Wertet die gelesene Konfiguration aus.

=cut

sub evaluate_config {

    my $self = shift;

    return if $self->configuration_evaluated;

    if ( $self->config and keys %{ $self->config } ) {

        $self->config->{'log'} = {} unless $self->config->{'log'};

        for my $key ( keys %{ $self->config } ) {

            if ( lc($key) eq 'log' and ref( $self->config->{$key} ) and ref( $self->config->{$key} ) eq 'HASH' ) {

                for my $log_key ( keys %{ $self->config->{$key} } ) {

                    my $val = $self->config->{$key}{$log_key};

                    if ( $log_key =~ /^dir$/i ) {
                        $self->debug( sprintf( "Gefunden: \$self->config->{%s}{%s} -> '%s'", $key, $log_key, $val ) );
                        $self->config->{'log'}{'dir'} = dir->new($val)->absolute->stringify;
                    }

                    if ( $log_key =~ /^stderror$/i ) {
                        $self->debug( sprintf( "Gefunden: \$self->config->{%s}{%s} -> '%s'", $key, $log_key, $val ) );
                        $self->config->{'log'}{'stderror'} = $val;
                    }

                    if ( $log_key =~ /^stdout$/i and $val ) {
                        $self->debug( sprintf( "Gefunden: \$self->config->{%s}{%s} -> '%s'", $key, $log_key, $val ) );
                        $self->config->{'log'}{'stdout'} = $val;
                    }

                }

            }

            my $val = $self->config->{$key};

            if ( $key =~ /^production[_\-]?state$/i ) {
                $self->debug( sprintf( "Gefunden: \$self->config->{%s} -> '%s'", $key, $val ) );
                $self->production_state($val) if $key =~ /^production[_\-]?state$/i;
            }

        }

        $self->config->{'log'}{'dir'} = dir->new( $self->basedir, 'log' )->stringify unless $self->config->{'log'}{'dir'};
        $self->config->{'log'}{'stderror'} = 'error.log' unless exists $self->config->{'log'}{'stderror'};

    }

    $self->used_cmd_params( {} );
    my $used_cmd_params = $self->used_cmd_params;

    my @getopt_attrs = grep {
        $_->does("MooseX::Getopt::Meta::Attribute::Trait")
            or
        $_->name !~ /^_/
    } grep {
        !$_->does('MooseX::Getopt::Meta::Attribute::Trait::NoGetopt')
    } $self->meta->get_all_attributes;

    my %Attribute = ();

    foreach my $attr ( @getopt_attrs ) {

        my $Attr = {};

        my $name = $attr->name;
        my $flag = $attr->name;
        my $aliases = [];

        if ( $attr->does('MooseX::Getopt::Meta::Attribute::Trait') ) {  
            $flag = $attr->cmd_flag if $attr->has_cmd_flag;
            @$aliases = @{ $attr->cmd_aliases } if $attr->has_cmd_aliases;
        }

        for my $opt ( @$aliases, $flag ) {
            my $n_opt = ( length($opt) <= 1 ? '-' : '--' ) . $opt;
            $Attribute{$n_opt} = $name;
            if ( $attr->{'isa'} eq 'Bool' ) {
                $n_opt = '--no' . $opt;
                $Attribute{$n_opt} = $name;
            }
        }

    }

    for my $param ( @{ $self->ARGV } ) {
        if ( $Attribute{$param} ) {
            my $name = $Attribute{$param};
            $used_cmd_params->{$name} = 1;
        }
    }

    unless ( $self->used_cmd_params->{'production_state'} ) {
        my $state = $self->config->{'production_state'} || $self->config->{'production-state'} || undef;
        $self->production_state( $state ) if $state;
    }



    $self->_set_configuration_evaluated(1);

    1;
}

#---------------------------------

=head2 merge_hashes($hashref, $hashref)

Base code to recursively merge two hashes together with right-hand precedence.

=cut

sub merge_hashes {

    my ( $lefthash, $righthash ) = @_;

    return $lefthash unless defined $righthash;

    my %merged = %$lefthash;
    for my $key ( keys %$righthash ) {
        my $right_ref = ( ref $righthash->{ $key } || '' ) eq 'HASH';
        my $left_ref  = ( ( exists $lefthash->{ $key } && ref $lefthash->{ $key } ) || '' ) eq 'HASH';
        if( $right_ref and $left_ref ) {
            $merged{ $key } = merge_hashes(
                $lefthash->{ $key }, $righthash->{ $key }
            );
        }
        else {
            $merged{ $key } = $righthash->{ $key };
        }
    }

    return \%merged;

}

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
