package FrBr::Common::MooseX::FtpClient;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::FtpClient;

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

use utf8;

use Carp ();

with 'FrBr::Common::MooseX::App';

#---------------------------------------------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.1"); $VERSION .= " r" . $Revis;

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
    return $_[0];
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
    return $_[0];
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

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
