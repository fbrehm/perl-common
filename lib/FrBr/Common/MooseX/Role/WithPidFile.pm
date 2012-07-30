package FrBr::Common::MooseX::Role::WithPidFile;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::WithPidFile

=head1 DESCRIPTION

Fügt der Anwendung die Eigenschaft 'pidfile' hinzu sowie die Methoden zu dessen Management

=cut

#---------------------------------------------------------------------------

use Moose::Role;

use Moose::Util::TypeConstraints;
use Encode qw( decode_utf8 encode_utf8 );

use utf8;

use Carp qw(cluck);
use Path::Class;
use MooseX::Types::Path::Class;

use FrBr::Common::MooseX::Pid::File;

with 'FrBr::Common::MooseX::Role::Types';

#-----------------------------------------

# Versionitis

use version; our $VERSION = qv("0.1.0");

############################################################################

=head1 Benötigte Funktionen

=cut

requires 'init_app';                # im Moose-Objekt FrBr::Common::MooseX:App
requires 'debug';                   # im Moose-Objekt FrBr::Common::MooseX:App
requires 'evaluate_config';         # in der Rolle FrBr::Common::MooseX::Role::Config

############################################################################

=head1 Attribute

Eigene Attribute

=cut

#-------------------------

=head2 piddir

Verzeichnis, in das die PID-Datei abgelegt wird

=cut

has 'piddir' => (
    is              => 'rw',
    isa             => 'Path::Class::Dir',
    traits          => [ 'Getopt' ],
    coerce          => 1,
    lazy            => 1,
    required        => 1,
    builder         => '_build_piddir',
    documentation   => 'Verzeichnis, in das die PID-Datei abgelegt wird',
);

#------

sub _build_piddir {
    my $self = shift;
    return dir( $self->approot, 'tmp' );
}

#-------------------------

=head2 pidfile

Die eigentliche PID-Datei

=cut

has pidfile => (
    is              => 'rw',
    isa             => 'FrBr::Common::MooseX::Pid::File',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    coerce          => 1,
    documentation   => 'Dateiname der PID-Datei, absolut oder relativ zu "piddir"',
    predicate       => 'has_pidfile',
    builder         => '_build_pidfile',
);

#------

sub _build_pidfile {
    my $self = shift;
    return file( $self->progname . ".pid" );
}

#-----------------------------------------

=head2 no_pidfile_action

Es werden keinerlei Aktionen wegen der PID-Datei unternommen,
keine Auswertung, kein Schreiben

=cut

has 'no_pidfile_action' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    required        => 1,
    traits          => [ 'Getopt' ],
    builder         => '_build_no_pidfile_action',
    documentation   => 'Keine PID-Datei-Aktionen.',
    cmd_flag        => 'no-pidfile-action',
    cmd_aliases     => [ 'np', 'no-pidfile', ],
);

#------

sub _build_no_pidfile_action {
    return 0;
}

#-----------------------------------------

=head2 pidfile_written

Flag, das aussagt, dass die aktuelle PID-Datei geschrieben wurde

=cut

has 'pidfile_written' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    required        => 1,
    traits          => [ 'NoGetopt' ],
    builder         => '_build_pidfile_written',
    documentation   => 'Flag, ob die aktuelle PID-Datei geschrieben wurde.',
);

#------

sub _build_pidfile_written {
    return 0;
}

#---------------------------------------------------------------------------

# Methoden dieser Rolle

#---------------------------------------------------------------------------

after 'init_app' => sub {

    my $self = shift;

    $self->debug( "Initialisiere ..." );
    if ( $self->verbose >= 2 ) {

        my $tmp;
        for my $f ( 'piddir', 'no_pidfile_action', 'pidfile_written', ) {
            $tmp = $self->$f();
        }

    }

    unless ( $self->pidfile->file->is_absolute ) {
        $self->pidfile( file( $self->piddir, $self->pidfile->file )->cleanup );
    }

    return if $self->no_pidfile_action;

    my $piddir = $self->pidfile->file->dir;
    $self->debug( sprintf("Checke PID-Verzeichnis '%s' ...", $piddir ) ) if $self->verbose >= 2;
    if ( -d $piddir ) {
        my $resolved = undef;
        eval {
            $resolved = $piddir->resolve;
            $self->debug( sprintf("Resolvdes PID-Verzeichnis '%s' ...", $resolved ) ) if $self->verbose >= 3;
        };
        if ( $@ ) {
            $self->error( $@ );
        }
        $self->piddir( $resolved );
        $piddir = $self->piddir;
        $self->debug( sprintf("Verwende PID-Verzeichnis '%s' ...", $piddir ) ) if $self->verbose >= 3;
        $self->debug( sprintf("Checke PID-File '%s' ...", $self->pidfile->file ) ) if $self->verbose >= 2;
        if ( -f $self->pidfile->file ) {
            eval {
                $resolved = $self->pidfile->file->resolve;
            };
            if ( $@ ) {
                $self->error( $@ );
            }
            $self->pidfile( $resolved );
        }
    }
    else {
        $self->error( sprintf( "Verzeichnis für PID-Datei '%s' existiert nicht oder ist kein Verzeichnis.", $piddir ) );
        exit 14;
    }

    my $pidfile = $self->pidfile->file;
    $self->debug( "Initialisiere PID-Datei ..." );
    $self->debug( sprintf( "PID-Datei: '%s'", $pidfile ) ) if $self->verbose >= 2;

    unless ( -e $pidfile ? -w $pidfile : -w $piddir ) {
        my $msg = sprintf( "Kann nicht in Datei '%s' schreiben.", $pidfile );
        $self->error($msg);
        cluck( $msg ) if $self->verbose;
        exit 15;
    }

    $self->debug( sprintf( "Gucke nach, ob die Datei '%s' existiert ...", $pidfile ) ) if $self->verbose >= 3;
    if ( $self->pidfile->does_file_exist ) {
        $self->debug( sprintf( "Gucke nach, ob die dazugehörige Anwendung noch läuft ..." ) ) if $self->verbose >= 3;
        my $is_running = 0;
        my $invalid_pidfile = 0;
        eval {
            $is_running = $self->pidfile->is_running;
        };
        if ( $@ ) {
            $self->error( $@ );
            $self->pidfile->remove;
            $is_running = 0;
            $invalid_pidfile = 1;
        }
        if ( $is_running ) {
            $self->warn( "Die Anwendung läuft bereits." );
            exit 1;
        }
        $self->warn( sprintf( "Die Anwendung mit der PID %s scheint unbekannterweise verstorben zu sein.", $self->pidfile->pid ) ) unless $invalid_pidfile;
        $self->pidfile->remove;
        $self->pidfile->pid($$);
    }
    else {
        $self->debug( sprintf( "PID-Datei '%s' existiert nicht, alles klar.", $pidfile ) ) if $self->verbose >= 3;
    }

    $self->debug( sprintf( "Schreibe PID %s in Datei '%s' ...", $self->pidfile->pid, $pidfile ) ) if $self->verbose >= 2;
    $self->pidfile->write;
    $self->pidfile_written(1);

};

#---------------------------------

after 'evaluate_config' => sub {

    my $self = shift;

    if ( $self->config and keys %{ $self->config } ) {
        $self->debug( "Werte Konfigurationsdinge aus ..." );
        for my $key ( keys %{ $self->config } ) {
            my $val = $self->config->{$key};
            unless ( $self->used_cmd_params->{'piddir'} ) {
                $self->piddir($val) if $key =~ /^pid[_-]?dir$/i;
            }
            unless ( $self->used_cmd_params->{'pidfile'} ) {
                $self->pidfile($val) if $key =~ /^pid[_-]?file$/i;
            }
        }
    }

};

#---------------------------------

sub DEMOLISH {

    my $self = shift;

    $self->debug( "Ich demoliere mich mal selbst." ) if $self->verbose >= 2;
    if ( $self->pidfile_written ) {
        $self->debug( sprintf( "Lösche PID-Datei '%s' ...", $self->pidfile->file ) );
        $self->pidfile->remove;
    }

}

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
