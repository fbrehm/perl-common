package FrBr::Common::MooseX::App;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::App;

=head1 DESCRIPTION

Basismodul fuer alle Anwendungen, die auf Moose beruhen.

=cut

#---------------------------------------------------------------------------

use Moose;

use utf8;

use MooseX::StrictConstructor;

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

use Carp ();

with 'FrBr::Common::MooseX::Role::CommonOpts';

#-----------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.1.0"); $VERSION .= " r" . $Revis;

############################################################################

=head1 ATTRIBUTES

Alle für dieses allgemeine Anwendungsobjekt definierten Attribute/Eigenschaften,
die nicht durch dazugehörige Rollen definiert werden.

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

#---------------------------------------------------------------------------

=head2 production_state

Produktionsstatus der Anwendung (Produktion, Test oder Entwicklung).

Darf nur den Zustand 'prod', 'test' oder 'dev' annehmen.

=cut

subtype 'ProductionState'
    => as 'Str'
    => where { $_ =~ /^prod|test|dev$/ }
    => message { "Der Status '$_' ist nicht 'prod', 'test' oder 'dev'." };

has 'production_state' => (
    is              => 'rw',
    isa             => 'ProductionState',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_production_state',
    documentation   => "Produktionsstatus der Anwendung, darf nur den Zustand 'prod', 'test' oder 'dev' annehmen.",
    cmd_flag        => 'production-state',
    cmd_aliases     => [ 'pstate' ],
);

#------

sub _build_production_state {
    return 'prod';
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

#-------------------------

=head2 app_initialized

Wurde die Anwendung initialisiert

=cut

has app_initialized => (
    is              => 'rw',
    isa             => 'Bool',
    traits          => [ 'NoGetopt' ],
    lazy            => 1,
    required        => 1,
    builder         => '_build_app_initialized',
    documentation   => 'Wurde die Anwendung initialisiert?',
);

#------

sub _build_app_initialized {
    return 0;
}

#-----------------------------------------

=head2 log4perl_cfg_file

Dateiname der Konfiguration für Log::Log4perl, relativ zum Anwendungs- bzw. zum Konfigurationsverzeichnis.

=cut

has 'log4perl_cfg_file' => (
    is              => 'ro',
    isa             => 'Str',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    builder         => '_build_log4perl_cfg_file',
    documentation   => "Dateiname der Konfiguration für Log::Log4perl, relativ zum Anwendungs- bzw. zum Konfigurationsverzeichnis.",
    cmd_flag        => 'log4perl-cfg-file',
    cmd_aliases     => [ 'log4perl-cfg', 'log4perl' ],
);

#------

sub _build_log4perl_cfg_file {
    return 'log4perl.conf';
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

#############################################################################################

# Ändern der Eigenschaften einiger geerbter Attribute


sub _build_version {
    return $VERSION;
}

#############################################################################################

=head1 METHODS

Methoden und Methoden-Modifizierer

=head2 OK()

Gibt immer 0 zurück

=head2 ERROR()

Gibt immer 1 zurück

=head2 FATAL

Gibt immer 2 zurück

=cut

sub OK    { 0 }
sub ERROR { 1 }
sub FATAL { 2 }

#---------------------------------

=head2 BUILD()

Konstruktor

=cut

sub BUILD {

    my $self = shift;

#    # Darstellen der Objektstruktur
#    if ( $self->verbose >= 2 ) {
#        # Aufwecken der faulen Hunde
#        my $tmp;
#        $tmp = $self->progname;
#        $tmp = $self->basedir;
#        $self->debug( "Anwendungsobjekt vor der Db-Schema-Initialisierung: ", $self );
#    }

}

#---------------------------------------------------------------------------

before BUILD => sub {

    my $self = shift;
    $self->_init_log();

    $self->exit_code( OK() );

};

#---------------------------------

=head2 after BUILD ...

=cut

after 'BUILD' => sub {

    my $self = shift;
    $self->init_app() unless $self->app_initialized;

    $self->debug( "Anwendungsobjekt: ", $self ) if $self->verbose >= 3;
    $self->debug( "Bereit zum Kampf - äh - was auch immer." );

};

#---------------------------------

=head2 init_app( )

Initialisiert nach dem BUILD alles.

=cut

sub init_app {

    my $self = shift;

    $self->debug( "Initialisiere Anwendung ..." );
    $self->app_initialized(1);
}

#---------------------------------

sub _init_log {

    my $self = shift;

    # Initialisierung Log::Log4Perl ...
    my $log4perl_cfg_file = $self->log4perl_cfg_file;
    my $log4perl_local_cfg = $log4perl_cfg_file;
    my $log4perl_cfg;

    # Name von $log4perl_local_cfg  ausgehend von $log4perl_cfg generieren
    {
        my ( $base, $ext );
        if ( ( $base, $ext ) = $log4perl_local_cfg =~ /^(.*)\.([^\.]+)$/s ) {
            $log4perl_local_cfg = $base . "_local." . $ext;
        }
        else {
            $log4perl_local_cfg .= "_local";
        }
    }

    if ( $self->does( 'FrBr::Common::MooseX::Role::Config' ) ) {
        $log4perl_cfg = file( $self->cfg_dir, $log4perl_local_cfg );
    }
    else {
        $log4perl_cfg = file( $self->basedir, $log4perl_local_cfg );
    }

    # Suche nach der Log-Config-Datei ...
    warn sprintf( "Suche nach Log-Config-Datei %s ...\n", $log4perl_cfg ) if $self->verbose >= 2;
    unless ( -f $log4perl_cfg->stringify ) {
        # Nach der normalen Variante von log4perl.conf gucken ...
        if ( $self->does( 'FrBr::Common::MooseX::Role::Config' ) ) {
            $log4perl_cfg = file( $self->cfg_dir, $log4perl_cfg_file );
        }
        else {
            $log4perl_cfg = file( $self->basedir, $log4perl_cfg_file );
        }
        warn sprintf( "Suche nach Log-Config-Datei %s ...\n", $log4perl_cfg ) if $self->verbose >= 2;
        undef $log4perl_cfg unless -f $log4perl_cfg->stringify;
    }

    if ( $log4perl_cfg ) {
        # Log-Config-Datei gefunden
        my $delay = $self->watch_delay_log_conf;
        if ($delay) {
            Log::Log4perl::init_and_watch( $log4perl_cfg->stringify, $delay );
        } else {
            Log::Log4perl::init( $log4perl_cfg->stringify );
        }
        $self->debug( sprintf( "Verwende '%s' als Konfigurationsdatei für Log::Log4Perl.", $log4perl_cfg ) );
    }
    else {
        # oder auch nicht
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

#    $SIG{__WARN__} = sub { $self->_log( __PACKAGE__, 'warn',  2, \@_ ); };

}

#---------------------------------

=head2 _log( $package, $type, $depth, $message )

Lokale Funktion, die von den Log::Log4perl-Wrappern aufgerufen wird
und die Informationen an die entsprechenden Log::Log4perl-Methoden übergibt.

=cut

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

=head2 debug( @message )

Wrapper-Methode für Log::Log4perl::debug()

=cut

sub debug {

    my ( $self, @message ) = @_;
    my ( $package, $filename, $line ) = caller;

    return if $self->verbose < 1;

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
    $self->_log( $package, 'debug', $depth, $msg );

}

#---------------------------------

=head2 is_debug( )

Wrapper-Methode für Log::Log4perl::is_debug()

=cut

#---------------------------------

sub is_debug {

    my ( $self, @message ) = @_;
    my ( $package, $filename, $line ) = caller;

    my $logger = $self->logger($package);
    return $logger->is_debug;

}

#---------------------------------

#sub Moose::Meta::Attribute::new {
#    my ($class, $name, %options) = @_;
#    $class->_process_options($name, \%options) unless $options{__hack_no_process_options}; # used from clone()... YECHKKK FIXME ICKY YUCK GROSS
#
#    delete $options{__hack_no_process_options};
#
#    return $class->SUPER::new($name, %options);
#}

###################################################################################

# Code, der beim Laden dieses Moduls ausgeführt wird:

=head2 info( @message )

Wrapper-Methode für Log::Log4perl::info()

=head2 is_info( )

Wrapper-Methode für Log::Log4perl::is_info()

=head2 warn( @message )

Wrapper-Methode für Log::Log4perl::warn()

=head2 is_warn( )

Wrapper-Methode für Log::Log4perl::is_warn()

=head2 error( @message )

Wrapper-Methode für Log::Log4perl::error()

=head2 is_error( )

Wrapper-Methode für Log::Log4perl::is_error()

=head2 fatal( @message )

Wrapper-Methode für Log::Log4perl::fatal()

=head2 is_fatal( )

Wrapper-Methode für Log::Log4perl::is_fatal()

=cut

#---------------------------------

{   

    my @levels = ( 'info', 'warn', 'error', 'fatal' );

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

        *{"is_$level"} = sub {

            my ( $self, @message ) = @_;
            my ( $package, $filename, $line ) = caller;

            my $logger = $self->logger($package);
            my $func   = "is_" . $level;
            return $logger->$func;

        };


    }

}

#---------------------------------------------------------------------------

no Moose::Role;
__PACKAGE__->meta->make_immutable;

1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
