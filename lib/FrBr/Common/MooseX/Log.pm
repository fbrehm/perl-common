package FrBr::Common::MooseX::Log;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Log;

=head1 DESCRIPTION

Rollen-Modul zum Einbinden von Loggingmöglichkeiten per Log::Log4perl

=cut

#---------------------------------------------------------------------------

use Moose::Role;

use MooseX::Getopt::Meta::Attribute;
use MooseX::Getopt::Meta::Attribute::NoGetopt;
use Log::Log4perl;
use MooseX::Types::Path::Class;
use Path::Class;
use File::Basename;
use FindBin;
use Encode qw( decode_utf8 encode_utf8 );
use Data::Dump;

use utf8;

use Carp ();

with 'MooseX::Log::Log4perl';
with 'FrBr::Common::MooseX::Types';

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

#---------------------------------------------------------------------------

=head1 METHODS

Methoden dieser Rolle sowie Methodenmodifizierer

=cut

#around BUILDARGS => sub {
#
#    my $orig = shift;
#    my $class = shift;
#
#    my %Args = @_;
#
#    #warn "Bin in '" . __PACKAGE__ . "'\n";
#
#    # verbose auf verbose_bool setzen
#    $Args{'verbose'} = 1 if $Args{'verbose_bool'} and not exists $Args{'verbose'};
#    delete $Args{'verbose_bool'} if exists $Args{'verbose_bool'};
#
#    return $class->$orig(%Args);
#
#};

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

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
