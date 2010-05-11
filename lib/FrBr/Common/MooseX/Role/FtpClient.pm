package FrBr::Common::MooseX::Role::FtpClient;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::FtpClient;

=head1 DESCRIPTION

Rollen-Modul zum Einbinden eines FTP-Clients

=cut

#---------------------------------------------------------------------------

use Moose::Role;

#use MooseX::Getopt::Meta::Attribute;
#use MooseX::Getopt::Meta::Attribute::NoGetopt;
use Moose::Util::TypeConstraints;
use Encode qw( decode_utf8 encode_utf8 );
use Net::FTP;
use Net::Domain qw( domainname );

use utf8;

use Carp qw( cluck );

#with 'FrBr::Common::MooseX::App';

#---------------------------------------------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.2"); $VERSION .= " r" . $Revis;

############################################################################

=head1 Benötigte Funktionen

=cut

requires 'debug';                   # im Moose-Objekt FrBr::Common::MooseX:App
requires 'init_app';                # im Moose-Objekt FrBr::Common::MooseX:App
requires 'evaluate_config';         # in der Rolle FrBr::Common::MooseX::Role::Config

############################################################################

=head1 TYPES

Alle nur von dieser Rolle verwendeten Datentypen

=over4

=item I<Net::FTP>

=cut

subtype 'Net::FTP'
    => as 'Object'
    => where { $_->isa('Net::FTP') }
    => message { "Das übergebene Objekt muss vom Typ 'Net::FTP' sein" };

=back

=head1 ATTRIBUTES

Alle durch diese Rolle definierten Attribute

=head2 ftp

Das Net::FTP-Objekt als eigentlicher FTP-Client.

=cut

has 'ftp' => (
    is              => 'ro',
    isa             => 'Net::FTP',
    traits          => [ 'NoGetopt' ],
    lazy            => 0,
    clearer         => '_clear_ftp',
    predicate       => 'has_ftp',
    writer          => '_set_ftp',
    documentation   => 'Das Net::FTP-Objekt als eigentlicher FTP-Client.',
);

#--------------------

sub _set_ftp {
    return $_[1];
}

#---------------------------------------------------------------------------

=head2 ftp_connected

Flag, ob der FTP-Client gerade mit dem Server verbunden ist.

=cut

has 'ftp_connected' => (
    is              => 'ro',
    isa             => 'Bool',
    lazy            => 1,
    traits          => [ 'NoGetopt' ],
    builder         => '_build_ftp_connected',
    writer          => '_set_ftp_connected',
    documentation   => 'BOOL: Flag, ob der FTP-Client gerade mit dem Server verbunden ist.',
);

#--------------------

sub _build_ftp_connected {
    return 0;
}

sub _set_ftp_connected {
    return $_[1];
}

#---------------------------------------------------------------------------

=head2 ftp_auto_login

Flag, ob der sich der FTP-Client automatisch anmelden soll, nachdem er initialisiert wurde.

=cut

has 'ftp_auto_login' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    traits          => [ 'NoGetopt' ],
    builder         => '_build_ftp_auto_login',
    documentation   => 'BOOL: Flag, ob sich der FTP-Client automatisch anmelden soll, nachdem er initialisiert wurde.',
);

#--------------------

sub _build_ftp_auto_login {
    return 0;
}

#---------------------------------------------------------------------------

=head2 ftp_auto_init

Flag, ob das Net::FTP-Objekt bei der Objektinitialisierung mit initialisiert werden soll

=cut

has 'ftp_auto_init' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    traits          => [ 'NoGetopt' ],
    builder         => '_build_ftp_auto_init',
    documentation   => 'BOOL: Flag, ob das Net::FTP-Objekt bei der Objektinitialisierung mit initialisiert werden soll.',
);

#--------------------

sub _build_ftp_auto_init {
    return 1;
}

#---------------------------------------------------------------------------

=head2 ftp_host

Der Hostname oder die IP-Adresse des FTP-Servers

=cut

has 'ftp_host' => (
    is              => 'rw',
    isa             => 'Str',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_host',
    documentation   => 'String: der Hostname oder die IP-Adresse des FTP-Servers',
    cmd_flag        => 'ftp-host',
    cmd_aliases     => [ 'H', 'host' ],
);

#--------------------

sub _build_ftp_host {
    return 'localhost';
}

#---------------------------------------------------------------------------

=head2 ftp_user

Der FTP-Nutzername, default zu 'anonymous'.

=cut

has 'ftp_user' => (
    is              => 'rw',
    isa             => 'Str',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_user',
    documentation   => 'String: Nutzername des FTP-Nutzers',
    cmd_flag        => 'ftp-user',
    cmd_aliases     => [ 'U', 'user' ],
);

#--------------------

sub _build_ftp_user {
    return 'anonymous';
}

#---------------------------------------------------------------------------

=head2 ftp_password

Das Passwort des FTP-Nutzers

=cut

has 'ftp_password' => (
    is              => 'rw',
    isa             => 'Str',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_password',
    documentation   => 'String: Passort des FTP-Nutzers',
    cmd_flag        => 'ftp-password',
    cmd_aliases     => [ 'P', 'password' ],
);

#--------------------

sub _build_ftp_password {
    my $email = 'anonymous@' . domainname();
    return $email;
}

#---------------------------------------------------------------------------

=head2 ftp_blocksize

Die Blockgröße in Bytes, die Net::FTP für den Datentransfer verwendet.

=cut

has 'ftp_blocksize' => (
    is              => 'rw',
    isa             => 'Int',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_blocksize',
    documentation   => 'Int: die Blockgröße in Bytes, die Net::FTP für den Datentransfer verwendet (default: 10240).',
    cmd_flag        => 'ftp-blocksize',
    cmd_aliases     => [ 'blocksize' ],
);

#--------------------

sub _build_ftp_blocksize {
    return 10_240;
}

#---------------------------------------------------------------------------

=head2 ftp_port

Die Portadresse des FTP-Servers.

=cut

has 'ftp_port' => (
    is              => 'rw',
    isa             => 'Int',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_port',
    documentation   => 'Int: die Portadresse des FTP-Servers (default: 21).',
    cmd_flag        => 'ftp-port',
    cmd_aliases     => [ 'port', 'P' ],
);

#--------------------

sub _build_ftp_port {
    return 21;
}

#---------------------------------------------------------------------------

=head2 ftp_timeout

Der Timeout in Sekunden für FTP-Prozesse (default: 120)

=cut

has 'ftp_timeout' => (
    is              => 'rw',
    isa             => 'Int',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_timeout',
    documentation   => 'Int: der Timeout in Sekunden für FTP-Prozesse (default: 120).',
    cmd_flag        => 'ftp-timeout',
    cmd_aliases     => [ 'timeout', 'T' ],
);

#--------------------

sub _build_ftp_timeout {
    return 120;
}

#---------------------------------------------------------------------------

=head2 ftp_passive

Flag, dass der FTP-Client eine passive FTP-Verbindung zum Server aufbauen soll.

=cut

has 'ftp_passive' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    required        => 1,
    traits          => [ 'Getopt' ],
    builder         => '_build_ftp_passive',
    documentation   => 'BOOL: Flag, dass der FTP-Client eine passive FTP-Verbindung zum Server aufbauen soll.',
    cmd_flag        => 'ftp-passive',
    cmd_aliases     => [ 'passive' ],
);

#--------------------

sub _build_ftp_passive {
    return 0;
}

#---------------------------------------------------------------------------

=head2 ftp_hash_size

Alle wieviele Bytes soll während der Übertragung ein Hash-Zeichen (#) auf STDERR geschrieben werden,
wenn $self->ftp_show_hashes auf TRUE gesetzt ist (default: 1024).

=cut

has 'ftp_hash_size' => (
    is              => 'rw',
    isa             => 'Int',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_hash_size',
    documentation   => 'Int: alle wieviele Bytes soll während der Übertragung ein Hash-Zeichen (#) auf STDERR geschrieben werden (default: 1024).',
    cmd_flag        => 'ftp-hash-size',
    cmd_aliases     => [ 'hash-size' ],
);

#--------------------

sub _build_ftp_hash_size {
    return 1024;
}

#-------------------------

=head2 ftp_local_dir

Lokales Datenverzeichnis

=cut

has 'ftp_local_dir' => (
    is              => 'rw',
    isa             => 'Path::Class::Dir',
    traits          => [ 'Getopt' ],
    coerce          => 1,
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_local_dir',
    documentation   => 'Lokales Datenverzeichnis',
    cmd_flag        => 'ftp-local-dir',
    cmd_aliases     => [ 'local-dir' ],
);

#------

sub _build_ftp_local_dir {
    return dir->new( $FindBin::Bin, 'data' )->absolute;
}

#-------------------------

=head2 ftp_remote_dir

Datenverzeichnis auf dem FTP-Server

=cut

has 'ftp_remote_dir' => (
    is              => 'rw',
    isa             => 'Path::Class::Dir',
    traits          => [ 'Getopt' ],
    coerce          => 1,
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_remote_dir',
    documentation   => 'Datenverzeichnis auf dem FTP-Server',
    cmd_flag        => 'ftp-remote-dir',
    cmd_aliases     => [ 'remote-dir' ],
);

#------

sub _build_ftp_remote_dir {
    return dir->new( '/' );
}

############################################################################

=head1 METHODS

Methoden dieser Rolle

=cut

#---------------------------------------------------------------------------

after 'evaluate_config' => sub {

    my $self = shift;

    #return if $self->configuration_evaluated;
    $self->debug( "Werte FTP-Konfigurationsdinge aus ..." );
    return unless $self->config and keys %{ $self->config };

    my @ConfigKeys = qw( host user password blocksize port timeout passive hash_size local_dir remote_dir );

    for my $key ( keys %{ $self->config } ) {

        my $val = $self->config->{$key};

        for my $p ( @ConfigKeys ) {
            my $f = 'ftp_' . $p;
            my $r = $p;
            $r =~ s/_/\[_-\]\?/g;
            $r = "^ftp[_\-]?$r\$";
            $self->debug( sprintf( "Regex 1: '%s'", $r ) ) if $self->verbose >= 4;
            unless ( $self->used_cmd_params->{$f} ) {
                if ( $key =~ /$r/i ) {
                    $self->debug( sprintf( "Gefunden: \$self->config->{%s} -> '%s'", $key, ( defined $val ? $val : '<undef>' ) ) ) if $self->verbose >= 2;
                    $self->$f($val);
                }
            }
        }

    }

    for my $key ( keys %{ $self->config } ) {
        if ( lc($key) eq 'ftp' and ref( $self->config->{$key} ) and ref( $self->config->{$key} ) eq 'HASH' ) {
            for my $ftp_key ( keys %{ $self->config->{$key} } ) {

                my $val = $self->config->{$key}{$ftp_key};

                for my $p ( @ConfigKeys ) {

                    my $f = 'ftp_' . $p;
                    my $r = $p;
                    $r =~ s/_/\[_-\]\?/g;
                    $r = "^$r\$";
                    $self->debug( sprintf( "Regex 2: '%s'", $r ) ) if $self->verbose >= 4;

                    unless ( $self->used_cmd_params->{$f} ) {
                        if ( $ftp_key =~ /$r/i ) {
                            $self->debug( sprintf( "Gefunden: \$self->config->{%s}{%s} -> '%s'", $key, $ftp_key, ( defined $val ? $val : '<undef>' ) ) ) if $self->verbose >= 2;
                            $self->$f($val);
                        }
                    }

                }

            }
        }
    }

};

#---------------------------------------------------------------------------

after 'init_app' => sub {

    my $self = shift;

    $self->debug( "Initialisiere ..." );
    if ( $self->verbose >= 2 ) {

        my $tmp;
        for my $f ( 'ftp_connected', 'ftp_auto_login', 'ftp_auto_init', 'ftp_host',
                    'ftp_user', 'ftp_password', 'ftp_blocksize', 'ftp_port',
                    'ftp_timeout', 'ftp_passive', 'ftp_hash_size', 'ftp_local_dir',
                    'ftp_remote_dir', ) {
            $tmp = $self->$f();
        }

    }

    $self->init_ftp() if $self->ftp_auto_init;

};

#---------------------------------------------------------------------------

=head2 init_ftp( )

Initialisiert das Net::FTP-Objekt

=cut

sub init_ftp {

    my $self = shift;

    cluck( "Guck mal: " ) if $self->verbose >= 4;

    # Wechsel in das lokale Arbeitsverzeichnis
    $self->debug( sprintf( "Wechsel in das Arbeitsverzeichnis '%s' ...", $self->ftp_local_dir->stringify ) );
    unless ( chdir $self->ftp_local_dir->stringify ) {
        $self->error( sprintf( "Konnte nicht nach '%s' wechseln: %s", $self->ftp_local_dir->stringify, $! ) );
        return undef;
    }

    $self->debug( "Initialisiere Net::FTP-Objekt ..." );

    my $ftp_params = {
        'Host'      => $self->ftp_host,
        'BlockSize' => $self->ftp_blocksize,
        'Port'      => $self->ftp_port,
        'Timeout'   => $self->ftp_timeout,
        'Debug'     => ( $self->verbose >= 2 ? 1 : 0 ),
        'Passive'   => $self->ftp_passive,
    };
    $self->debug( "Initialisierungs-Parameter FTP: ", $ftp_params ) if $self->verbose >= 2;

    my $ftp = Net::FTP->new( %$ftp_params );
    unless ( $ftp ) {
        my $err = $@ || $!;
        $self->warn( "Fehler bei der Initialisierung des FTP-Objekts: " . $err );
        return undef;
    }

    $self->_set_ftp($ftp);

    if ( $self->ftp_auto_login ) {
        $self->login_ftp();
    }

    return $ftp;

}

#---------------------------------------------------------------------------

=head2 login_ftp( )

Anmeldung am FTP-Server

=cut

sub login_ftp {

    my $self = shift;

    unless ( $self->ftp ) {
        my $auto_login = $self->ftp_auto_login;
        $self->ftp_auto_login(0);
        $self->init_ftp();
        $self->ftp_auto_login($auto_login);
    }

    $self->debug( "Login am FTP-Server ..." );

    unless ( $self->ftp ) {
        $self->warn( "Kann mich nicht ohne FTP-Server anmelden: ", $! );
        cluck "Kann mich nicht ohne FTP-Server anmelden: " . $! . "\n" if $self->verbose;
        return undef;
    }
    my $ftp = $self->ftp;

    if ( $ftp->login( $self->ftp_user, $self->ftp_password ) ) {
        $self->debug( "FTP-Login erfolgreich." );
        $self->_set_ftp_connected(1);
        return 1;
    }
    else {
        $self->warn( sprintf( "FTP-Login misslungen: %s", $ftp->message ) );
    }

    return undef;

}

#---------------------------------------------------------------------------

=head2 logout_ftp( )

Abmeldung am FTP-Server

=cut

sub logout_ftp {

    my $self = shift;

    my $ftp = $self->ftp;
    unless ( $ftp ) {
        $self->debug( "Kein FTP-Objekt zum Abmelden da." );
        return;
    }

    $self->debug( "Abmeldung vom FTP-Server ..." );
    $ftp->quit;
    $self->_set_ftp_connected(0);

    $self->_clear_ftp();

}

#---------------------------------------------------------------------------

=head2 DEMOLISH( )

Destruktor

=cut

sub DEMOLISH {

    my $self = shift;

    if ( $self->ftp ) {
        $self->debug( "Selbstzerstörung FTP ..." );  
        $self->logout_ftp;
    }
    $self->debug( "Verschwinde ..." );

}

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
