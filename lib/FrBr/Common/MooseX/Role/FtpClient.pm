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
use DateTime;
use DateTime::Format::Strptime;
use FindBin;

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

############################################################################

=head1 Private Variables

=cut

my $month_map = {
    'jan'   =>  1,
    'feb'   =>  2,
    'mar'   =>  3,
    'apr'   =>  4,
    'may'   =>  5,
    'jun'   =>  6,
    'jul'   =>  7,
    'aug'   =>  8,
    'sep'   =>  9,
    'oct'   => 10,
    'nov'   => 11,
    'dec'   => 12,
};

#our $LocalTZ = DateTime::TimeZone->new( name => 'local' );

############################################################################

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

#-------------------------

=head2 ftp_remote_timezone

Zeitzone auf dem FTP-Server

=cut

has 'ftp_remote_timezone' => (
    is              => 'rw',
    isa             => 'FrBr::Types::TimeZone',
    traits          => [ 'Getopt' ],
    coerce          => 1,
    lazy            => 1,
    required        => 1,
    builder         => '_build_ftp_remote_timezone',
    documentation   => 'Die Zeitzine auf dem FTP-Server',
    cmd_flag        => 'ftp-remote-timezone',
    cmd_aliases     => [ 'remote-timezone' ],
);

#------

sub _build_ftp_remote_timezone {
    return DateTime::TimeZone->new( name => 'UTC' );
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

    my @ConfigKeys = qw( host user password blocksize port timeout passive hash_size local_dir remote_dir remote_timezone );

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

    return if $self->app_initialized;

    $self->debug( "Initialisiere ..." );
    #$self->debug( "Lokale Zeitzone: ", $LocalTZ );

    if ( $self->verbose >= 2 ) {

        my $tmp;
        for my $f ( 'ftp_connected', 'ftp_auto_login', 'ftp_auto_init', 'ftp_host',
                    'ftp_user', 'ftp_password', 'ftp_blocksize', 'ftp_port',
                    'ftp_timeout', 'ftp_passive', 'ftp_hash_size', 'ftp_local_dir',
                    'ftp_remote_dir', 'ftp_remote_timezone', ) {
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

    unless ( $ftp->login( $self->ftp_user, $self->ftp_password ) ) {
        $self->warn( sprintf( "FTP-Login misslungen: %s", $ftp->message ) );
        return undef;
    }

    $self->debug( "FTP-Login erfolgreich." );
    $self->_set_ftp_connected(1);

    $self->debug( sprintf( "Wechsele in das FTP-Verzeichnis '%s' ...", $self->ftp_remote_dir->stringify ) );
    my $result = $ftp->cwd( $self->ftp_remote_dir->stringify );
    $self->error( sprintf( "Konnte nicht in das FTP-Verzeichnis '%s' wechseln: %s", $self->ftp_remote_dir->stringify, $ftp->message ) ) unless $result;

    return $result;

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

=head2 dir_list( [ $dir ] )

Erzeugt ein Verzeichnis-Listing des FTP-Servers entweder des übergebenen Verzeichnisses
oder, wenn keins übergeben, des aktuellen Verzeichnisses.

Die Standard-Verzeichnisse '.' und '..' werden ausgeblendet.

Wenn nicht mit dem FTP-Server verbunden oder darauf angemeldet, stirbt dieses Methode
mit einem Callstack.

Rückgabe:

eine Array-Ref der Form:

    $list = [
        {
            'name' => 'ldap.dump.yearly.gz',
            'type' => 'f',                     # 'f' für normale Datei oder 'd' für Verzeichnis (andere?)
            'perm' => {
                'string' => 'rw-r--r--',
                'user'   => { 'r' => 1, 'w' => 1, 'x' => 0, 's' => 0, },
                'group'  => { 'r' => 1, 'w' => 0, 'x' => 0, 's' => 0, },
                'other'  => { 'r' => 1, 'w' => 0, 'x' => 0, 's' => 0, },
            },
            'num_hardlinks' => 1,
            'user'  => 'b047934',
            'group' => 'cust',
            'size'  => 645639,
            'mtime' => {
                'string' => 'Jan  2 15:24',
                't' => <DateTime-Objekt mit dem aktuellen Jahr als Jahr und Sekunde 0>,
            },
        },
    ];

=cut

sub dir_list {

    my $self = shift;
    my $dir  = shift;

    unless ( $self->has_ftp ) {
        $self->error( "FTP nicht initialisiert." );
        confess "FTP nicht initialisiert.";
    }

    unless ( $self->ftp_connected ) {
        $self->error( "Nicht am FTP-Server angemeldet." );
        confess "Nicht am FTP-Server angemeldet.";
    }

    # "Mar  2 16:35"
    my $Strp = new DateTime::Format::Strptime(
        pattern   => '%b %e %H:%M',
        locale    => 'en_US',
        time_zone => 'Europe/Berlin',
    );


    my $list = [];
    my $olist = defined $dir ? $self->ftp->dir($dir) : $self->ftp->dir;

    for my $orow ( @$olist ) {

        my ( $perm_string, $type, $num_hardlinks, $user, $group, $size, $mtime_str, $name );

        my $row = $orow;
        my $entry = {};

        $row =~ s/^\s*//;
        unless ( ( $perm_string ) = $row =~ /^(\S+)\s+/ ) {
            $self->warn( sprintf( "Keine Permission-Angaben in Zeile '%s' gefunden.", $orow ) );
            next;
        }
        $row =~ s/^\S+\s+//;
        ( $type ) = $perm_string =~ /^(.)/;
        $perm_string =~ s/^.//;
        $type = 'f' if $type eq '-';
        $entry->{'type'} = $type;
        $entry->{'perm'} = {};
        $entry->{'perm'}{'string'} = $perm_string;

        for my $t ( 'user', 'group', 'other' ) {
            $entry->{'perm'}{$t} = {};
            $entry->{'perm'}{$t}{'r'} = undef;
            $entry->{'perm'}{$t}{'w'} = undef;
            $entry->{'perm'}{$t}{'x'} = undef;
            $entry->{'perm'}{$t}{'s'} = undef;
        }

        my ( $uperm, $gperm, $operm ) = $perm_string =~ /^(...)(...)(...)/;

        $entry->{'perm'}{'user'}{'r'} = 1 if $uperm =~ /r/i;
        $entry->{'perm'}{'user'}{'w'} = 1 if $uperm =~ /w/i;
        $entry->{'perm'}{'user'}{'x'} = 1 if $uperm =~ /x/i;
        if ( $uperm =~ /s/i ) {
            $entry->{'perm'}{'user'}{'x'} = 1;
            $entry->{'perm'}{'user'}{'s'} = 1;
        }

        $entry->{'perm'}{'group'}{'r'} = 1 if $gperm =~ /r/i;
        $entry->{'perm'}{'group'}{'w'} = 1 if $gperm =~ /w/i;
        $entry->{'perm'}{'group'}{'x'} = 1 if $gperm =~ /x/i;
        if ( $gperm =~ /s/i ) {
            $entry->{'perm'}{'group'}{'x'} = 1;
            $entry->{'perm'}{'group'}{'s'} = 1;
        }

        $entry->{'perm'}{'other'}{'r'} = 1 if $operm =~ /r/i;
        $entry->{'perm'}{'other'}{'w'} = 1 if $operm =~ /w/i;
        $entry->{'perm'}{'other'}{'x'} = 1 if $operm =~ /x/i;
        if ( $operm =~ /[st]/i ) {
            $entry->{'perm'}{'other'}{'x'} = 1;
            $entry->{'perm'}{'other'}{'s'} = 1;
        }

        unless ( ( $num_hardlinks ) = $row =~ /^(\S+)\s+/ ) {
            $self->warn( sprintf( "Keine Angaben zur Anzahl der Hardlinks in Zeile '%s' gefunden.", $orow ) );
            next;
        }
        $row =~ s/^\S+\s+//;
        $entry->{'num_hardlinks'} = $num_hardlinks;

        unless ( ( $user ) = $row =~ /^(\S+)\s+/ ) {
            $self->warn( sprintf( "Keine Nutzer-Angaben in Zeile '%s' gefunden.", $orow ) );
            next;
        }
        $row =~ s/^\S+\s+//;
        $entry->{'user'} = $user;

        unless ( ( $group ) = $row =~ /^(\S+)\s+/ ) {
            $self->warn( sprintf( "Keine Gruppen-Angaben in Zeile '%s' gefunden.", $orow ) );
            next;
        }
        $row =~ s/^\S+\s+//;
        $entry->{'group'} = $group;

        unless ( ( $size ) = $row =~ /^(\d+)\s+/ ) {
            $self->warn( sprintf( "Keine Größen-Angaben in Zeile '%s' gefunden.", $orow ) );
            next;
        }
        $row =~ s/^\d+\s+//;
        $entry->{'size'} = $size;

        unless ( ( $mtime_str ) = $row =~ /^(\S+\s+\S+\s+\S+)\s+/ ) {
            $self->warn( sprintf( "Keine Dateidatums-Angaben in Zeile '%s' gefunden.", $orow ) );
            next;
        }
        $row =~ s/^\S+\s+\S+\s+\S+\s+//;
        $entry->{'mtime'} = {};
        $entry->{'mtime'}{'string'} = $mtime_str;
        $entry->{'mtime'}{'t'} = $self->_parse_date($mtime_str);

        $name = $row;
        undef $row;
        if ( ( ! defined $name  ) or $name eq '' ) {
            $self->warn( sprintf( "Keine Dateiname in Zeile '%s' gefunden.", $orow ) );
            next;
        }

        if ( $name eq '.' or $name eq '..' ) {
            $self->debug( sprintf( "Die Datei '%s' ist Standard und wird übersprungen.", $name ) );
            next;
        }

        $entry->{'name'} = $name; 

        push @$list, $entry;

    }

    return $list;

}

#---------------------------------------------------------------------------

=head2 _parse_date( $date_str )

Parst ein Datum der Form "May 15 07:43" und gibt es als DateTime-Objekt zurück.

=cut

sub _parse_date {

    my $self = shift;
    my $date_str = shift;

    my ( $month_str, $day, $hour, $minute );

    unless ( ( $month_str, $day, $hour, $minute ) = $date_str =~ /^(\S{3})\S*\s+(\d+)\s+(\d+):(\d+)/ ) {
        $self->warn( sprintf( "Konnte Datum '%s' nicht auseinandernehmen.", $date_str ) );
        return undef;
    }

    $month_str = lc($month_str);

    my $month = $month_map->{$month_str};
    unless ( $month ) {
        $self->warn( sprintf( "Konnte Monatsangabe '%s' in Datum '%s' nicht interpretieren.", $month_str, $date_str ) );
        return undef;
    }

    my $now = DateTime->now()->set_time_zone( $self->local_timezone );

    my $this_year = $now->year;
    my $create_hash = {
        year      => $this_year,
        month     => $month,
        day       => $day + 0,
        hour      => $hour + 0,
        minute    => $minute + 0,
        second    => 0,
        time_zone => $self->ftp_remote_timezone,
    };
    $self->debug( "Erstelle DateTime-Objekt aus folgenden Angaben: ", $create_hash ) if $self->verbose >= 3;

    my $file_dt = DateTime->new( %$create_hash );
    $self->debug( sprintf( "Erstelltes Datum: '%s'", $file_dt->strftime( '%F %T %Z' ) ) ) if $self->verbose >= 3;

    while ( DateTime->compare( $file_dt, $now ) > 0 ) {
        $file_dt->subtract( 'years' => 1 );
        $self->debug( sprintf( "Ziehe ein Jahr ab, neues Datum: '%s'", $file_dt->strftime( '%F %T %Z' ) ) ) if $self->verbose >= 3;
    }

    return $file_dt;

}

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
