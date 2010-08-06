package FrBr::Common::MooseX::Pid::File;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Pid::File;

=head1 DESCRIPTION

PID-Management über eine PID-Datei

Beruht auf MooseX::Daemonize::Pid::File

=cut

#---------------------------------------------------------------------------

use Moose;

use utf8;

use strict;    # because Kwalitee is pedantic

use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;
use MooseX::Getopt::OptionTypeMap;
use Encode qw( decode_utf8 encode_utf8 is_utf8 );

#-----------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.1.0"); $VERSION .= " r" . $Revis;

#-----------------------------------------

coerce 'FrBr::Common::MooseX::Pid::File'
    => from 'Str'
        => via { FrBr::Common::MooseX::Pid::File->new( file => $_ ) }
    => from 'ArrayRef'
        => via { FrBr::Common::MooseX::Pid::File->new( file => $_ ) }
    => from 'Path::Class::File'
        => via { FrBr::Common::MooseX::Pid::File->new( file => $_ ) };

#-----------------------------------------

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'FrBr::Common::MooseX::Pid::File' => '=s',
);

extends 'FrBr::Common::MooseX::Pid';

has '+pid' => (
    default => sub {
        my $self = shift;
        my $p = $$;
        if ( $self->does_file_exist ) {
            my $content = $self->file->slurp(chomp => 1);
            if ( $content ) {
                if ( $content =~ /^\s*(\d+)/ ) {
                    $p = $1;
                }
                else {
                    my $c = decode_utf8($content);
                    $c = substr( $c, 0, 46 ) . " ..." if length($c) >= 50;
                    die sprintf( "Undefinierbarer Inhalt '%s' in Datei '%s'.\n", $c, $self->file );
                }
            }
        }
        return $p;
    }
);

has 'file' => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    coerce   => 1,
    required => 1,
    handles  => [ 'remove' ]
);

sub does_file_exist { -s (shift)->file }

sub write {
    my $self = shift;
    my $fh = $self->file->openw;
    $fh->print($self->pid . "\n");
    $fh->close;
}

override 'is_running' => sub {
    return 0 unless (shift)->does_file_exist;
    super();
};

__PACKAGE__->meta->make_immutable;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
