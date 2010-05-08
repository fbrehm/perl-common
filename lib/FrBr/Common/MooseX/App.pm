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
use Moose::Util::TypeConstraints;
use Log::Log4perl;
use Path::Class;
use File::Basename;
use FindBin;
use Encode qw( decode_utf8 encode_utf8 );
use Data::Dump;

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

#-----------------------------------------

=head2 watch_delay_log_conf

Alle wieviel Sekunden soll nach Änderung der Konfigurationsdatei für Log4perl gesehen werden

=cut

has 'watch_delay_log_conf' => (
    is              => 'rw',
    isa             => 'UnsignedInt',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    builder         => '_build_watch_delay_log_conf',
    documentation   => 'INT: Alle wieviel Sekunden soll nach Änderung der Konfigurationsdatei für Log4perl gesehen werden',
    cmd_flag        => 'watch-delay-log-conf',
    cmd_aliases     => 'watch-delay',
);

#------

sub _build_watch_delay_log_conf {
    return 60;
}

#-----------------------------------------

has 'logger' => (
    is              => 'rw',
    isa             => 'Log::Log4perl::Logger',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    default         => sub { my $self = shift; return Log::Log4perl->get_logger(ref($self)) }
);

sub log {
    return Log::Log4perl->get_logger($_[1]) if ($_[1] && !ref($_[1]));
    return $_[0]->logger;
}

#---------------------------------------------------------------------------

# Ändern der Eigenschaften einiger geerbter Attribute

#---------------------------------------------------------------------------

=head1 METHODS

Methoden dieser Rolle sowie Methodenmodifizierer

=cut

around BUILDARGS => sub {

    my $orig = shift;
    my $class = shift;

    my %Args = @_;

    #warn "Bin in '" . __PACKAGE__ . "'\n";

    return $class->$orig(%Args);

};

#---------------------------------------------------------------------------

before BUILD => sub {

    my $self = shift;
    $self->_init_log();

};

#---------------------------------

sub _init_log {

    my $self = shift;

    # Initialisierung Log::Log4Perl ...
    my $log4perl_cfg;
    if ( $self->does( 'FrBr::Common::MooseX::Config' ) ) {
        $log4perl_cfg = file( $self->cfg_dir, 'log4perl_local.conf' );
    }
    else {
        $log4perl_cfg = file( $self->basedir, 'log4perl_local.conf' );
    }
    warn sprintf( "Suche nach Log-Config-Datei %s ...\n", $log4perl_cfg ) if $self->verbose >= 2;
    unless ( -f $log4perl_cfg->stringify ) {
        if ( $self->does( 'FrBr::Common::MooseX::Config' ) ) {
            $log4perl_cfg = file( $self->cfg_dir, 'log4perl.conf' );
        }
        else {
            $log4perl_cfg = file( $self->basedir, 'log4perl.conf' );
        }
        warn sprintf( "Suche nach Log-Config-Datei %s ...\n", $log4perl_cfg ) if $self->verbose >= 2;
        undef $log4perl_cfg unless -f $log4perl_cfg->stringify;
    }
    if ( $log4perl_cfg ) {
        my $delay = $self->watch_delay_log_conf;
        if ($delay) {
            Log::Log4perl::init_and_watch( $log4perl_cfg->stringify, $delay );
        } else {
            Log::Log4perl::init( $log4perl_cfg->stringify );
        }
        $self->debug( "Verwende $log4perl_cfg als Konfigurationsdatei für Log::Log4Perl." );
    }
    else {
        my $app = $self->progname;
        my $conf_hash = {
            'log4perl.rootLogger'   => ( $self->verbose ? 'DEBUG' : 'INFO' ) . ', ScreenApp',
            # Normaler Screen-Appender auf StdErr
            'log4perl.appender.ScreenApp' => 'Log::Log4perl::Appender::Screen',
            'log4perl.appender.ScreenApp.stderr' => 1,
            #'log4perl.appender.ScreenApp.utf8'   => 1,
            'log4perl.appender.ScreenApp.layout' => 'PatternLayout',
            'log4perl.appender.ScreenApp.layout.ConversionPattern' => '[%d] [' . $app . '] [%p] %m%n',
        };
        Log::Log4perl->init($conf_hash);
        $self->debug( "Standardkonfiguration für Log::Log4Perl initialisiert." );
    }

    $SIG{__WARN__} = sub { $self->_log( __PACKAGE__, 'warn',  2, \@_ ); };

}

#---------------------------------

{

    my @levels = ( 'debug', 'info', 'warn', 'error', 'fatal' );

    for my $level ( @levels ) {

        no strict 'refs';

        *{$level} = sub {

            my ( $self, @message ) = @_;
            my ( $package, $filename, $line ) = caller;

            return if $level eq 'debug' and $self->verbose < 1;

            my $msg = [];
            for my $m ( @message ) {
                next unless defined $m;
                if ( ref($m) ) {
                    $m = Data::Dump::dump($m);
                }
                push @$msg, $m;
            }

            my $depth = $Log::Log4perl::caller_depth;
            $depth = 1 unless $depth > 0;
            $depth++;
            $self->_log( $package, $level, $depth, $msg );

        };

    }

}

#---------------------------------

sub _log {

    my $self = shift;

    local $SIG{CHLD} = 'DEFAULT';

    my ( $package, $type, $depth, $message ) = @_;

    my @Msg = ();
    for my $m ( @$message ) {
        push @Msg, encode_utf8($m);
    }

    local $Log::Log4perl::caller_depth = $depth;
    $self->log($package)->$type( @Msg );

}

#---------------------------------

sub Moose::Meta::Attribute::new {
    my ($class, $name, %options) = @_;
    $class->_process_options($name, \%options) unless $options{__hack_no_process_options}; # used from clone()... YECHKKK FIXME ICKY YUCK GROSS

    delete $options{__hack_no_process_options};

    return $class->SUPER::new($name, %options);
}



#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
