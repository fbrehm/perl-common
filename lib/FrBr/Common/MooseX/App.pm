package FrBr::Common::MooseX::App;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::App;

=head1 DESCRIPTION

Rollen-Modul zur Definition allgemeiner Eigenschaften einer Anwendung

=cut

#---------------------------------------------------------------------------

use Moose::Role;

use MooseX::Getopt::Meta::Attribute;
use MooseX::Getopt::Meta::Attribute::NoGetopt;
use MooseX::Types::Path::Class;
use Path::Class;
use File::Basename;
use FindBin;
use Encode qw( decode_utf8 encode_utf8 );

use utf8;

use Carp ();

with 'FrBr::Common::MooseX::Types';
with 'FrBr::Common::MooseX::CommonOpts';

sub OK    () { 0 }
sub ERROR () { 1 }
sub FATAL () { 2 }

#-------------------------


#---------------------------------------------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.1"); $VERSION .= " r" . $Revis;

############################################################################

=head1 ATTRIBUTES

Alle durch diese Rolle definierten Attribute

=cut

#---------------------------------------------------------------------------

=head2 progname

Programmname. Wird zum Beispiel für die PID-Datei verwendet.

=cut

has progname => (
    isa             => 'Str',
    is              => 'ro',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_progname',
    documentation   => 'Programmname. Wird zum Beispiel für die PID-Datei verwendet.',
);

#------

sub _build_progname {
    my $basename = basename($0);
    $basename =~ s/\.pl$//i;
    return $basename;
}

#-------------------------

=head2 basedir

Stammverzeichnis der Anwendung

=cut

has 'basedir' => (
    is              => 'ro',
    isa             => 'Path::Class::Dir',
    traits          => [ 'Getopt' ],
    coerce          => 1,
    lazy            => 1,
    required        => 1,
    builder         => '_build_basedir',
    documentation   => 'Stammverzeichnis der Anwendung',
    cmd_aliases     => [ 'base' ],
);

#------

sub _build_basedir {
    return dir->new( $FindBin::Bin )->parent->absolute;
}

#-------------------------

=head2 exit_code

Stammverzeichnis der Anwendung

=cut

has exit_code => (
    is              => 'rw',
    isa             => 'UnsignedInt',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_exit_code',
    documentation   => 'Exitcode der Anwendung (gegenüber der Shell)',
);

#------

sub _build_exit_code {
    return 0;
}

#---------------------------------------------------------------------------

with 'FrBr::Common::MooseX::Log';

#---------------------------------------------------------------------------

=head1 METHODS

Methoden dieser Rolle sowie Methodenmodifizierer

=cut

around BUILDARGS => sub {

    my $orig = shift;
    my $class = shift;

    my %Args = @_;

    #warn "Bin in '" . __PACKAGE__ . "'\n";

    # verbose auf verbose_bool setzen
#    $Args{'verbose'} = 1 if $Args{'verbose_bool'} and not exists $Args{'verbose'};
#    delete $Args{'verbose_bool'} if exists $Args{'verbose_bool'};

    return $class->$orig(%Args);

};

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
