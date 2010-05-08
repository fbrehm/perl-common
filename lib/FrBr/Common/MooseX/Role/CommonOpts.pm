package FrBr::Common::MooseX::Role::CommonOpts;

# $Id$
# $URL$

=head1 NAME

FrBr::Common::MooseX::Role::CommonOpts

=head1 DESCRIPTION

Rolle, um der Basis-Applikation alle Attribute von MooseX::Getopt sowie die
Standard-Kommandozeilenschalter zu verleihen.

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

with 'MooseX::Getopt';
with 'FrBr::Common::MooseX::Role::Types';

#---------------------------------------------------------------------------

# Versionitis

my $Revis = <<'ENDE';
    $Revision$
ENDE
$Revis =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;

use version; our $VERSION = qv("0.1"); $VERSION .= " r" . $Revis;


############################################################################

=head1 Attribute

=cut

#---------------------------------------------------------------------------

has 'show_usage' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    traits          => [ 'Getopt' ],
    builder         => '_build_show_usage',
    documentation   => 'BOOL: Anzeige der Verwendung der Anwendung',
    cmd_flag        => 'help',
    cmd_aliases     => [ '?', 'usage' ],
);

sub _build_show_usage {
    return 0;
}

#---------------------------------------------------------------------------

has 'version' => (
    is              => 'ro',
    isa             => 'Str',
    traits          => [ 'NoGetopt' ],
    builder         => '_build_version',    
    documentation   => 'Versionsstring der Anwendung',
);

sub _build_version {
    return $VERSION;
}

#---------------------------------------------------------------------------

has 'show_version' => (
    is              => 'rw',
    isa             => 'Bool',
    lazy            => 1,
    traits          => [ 'Getopt' ],
    builder         => '_build_show_version',
    documentation   => 'BOOL: Anzeige der Verwendung der Anwendung',
    cmd_flag        => 'version',
    cmd_aliases     => [ 'V' ],
);

sub _build_show_version {
    return 0;
}

#-----------------------------------------

has 'verbose' => (
    is              => 'rw',
    isa             => 'UnsignedInt',
    traits          => [ 'Getopt' ],
    lazy            => 1,
    builder         => '_build_verbose',
    documentation   => 'INT: Ausführlichkeits-Level der Applikation',
    cmd_aliases     => [ 'D' ],
);

has 'verbose_bool' => (
    is              => 'rw',
    isa             => 'Bool',
    traits          => [ 'Getopt' ],
    cmd_flag        => 'v',
    documentation   => 'BOOL: Ausführlichkeits-Level der Applikation',
);

#------

sub _build_verbose {
    return 0;
}

#-------------------------

has 'approot' => (
    is              => 'ro',
    isa             => 'Path::Class::Dir',
    traits          => [ 'NoGetopt' ],
    coerce          => 1,
    builder         => '_build_approot',
    documentation   => 'Stammverzeichnis der Anwendung',
);

#------

sub _build_approot {
    return dir->new( $FindBin::Bin )->parent->absolute;
}

#-------------------------

has 'cmd_params' => (
    is              => 'ro',
    isa             => 'Maybe[ArrayRef[Str]]',
    traits          => [ 'NoGetopt' ],
    lazy            => 0,
    builder         => '_build_cmd_params',
    documentation   => 'Mögliche Kommandozeilenparameter (nicht für GetOpt)',
);

#------

sub _build_cmd_params {
    return undef;
}

#-------------------------

has 'common_opts_evaluated' => (
    is              => 'ro',
    isa             => 'Bool',
    traits          => [ 'NoGetopt' ],
    builder         => '_build_common_opts_evaluated',
    writer          => '_set_common_opts_evaluated',
    documentation   => 'Wurden die allgemeinen Kommandozeilen-Optionen bereits ausgewertet',
);

#------

sub _build_common_opts_evaluated {
    return 0;
}

sub _set_common_opts_evaluated {
    return $_[1];
}

############################################################################

=head1 Benötigte Funktionen

=cut

requires 'debug';

############################################################################

=head1 Methoden und Methoden-Modifizerer

Methoden und Methoden-Modifizerer dieser Rolle

=head around BUILDARGS

=cut

around BUILDARGS => sub {

    my $orig = shift;
    my $class = shift;

    my %Args = @_;

    #warn "Bin in '" . __PACKAGE__ . "'\n";

    # verbose auf verbose_bool setzen
    $Args{'verbose'} = 1 if $Args{'verbose_bool'} and not exists $Args{'verbose'};
    delete $Args{'verbose_bool'} if exists $Args{'verbose_bool'};

    return $class->$orig(%Args);

};

#---------------------------------------------------------------------------

=head 2 after BUILD

wird nach dem BUILD-Prozess des Anwendungsprozesses aufgerufen

=cut

after 'BUILD' => sub {
    my $self = shift;
    $self->evaluate_common_options();
};

#---------------------------------------------------------------------------

sub evaluate_common_options {

    my $self = shift;

    return if $self->common_opts_evaluated;
    $self->debug( "Werte allgemeine Optionen aus." );

    if ( $self->show_usage ) {
        $self->do_show_usage();
        exit 0;
    }
    if ( $self->show_version ) {
        $self->do_show_version();
        exit 0;
    }
    $self->_set_common_opts_evaluated(1);

    return 1;

}

#---------------------------------------------------------------------------

sub do_show_version {

    my $self = shift;

    print "Version: " . $self->version . "\n";

}

#---------------------------------------------------------------------------

sub do_show_usage {

    my $self = shift;

    my @getopt_attrs = grep {
        $_->does("MooseX::Getopt::Meta::Attribute::Trait")
            or
        $_->name !~ /^_/
    } grep {
        !$_->does('MooseX::Getopt::Meta::Attribute::Trait::NoGetopt')
    } $self->meta->get_all_attributes;

    my @Attribute = ();
    my @Short_Opts = ();
    my $max_length = 1;

    foreach my $attr ( @getopt_attrs ) {

        my $Attr = {};
        my $lengt = 1;
        $self->debug( "Attribut-Objekt: ", $attr ) if $self->verbose >= 4;

        $Attr->{'name'} = $attr->name;
        $Attr->{'flag'} = $attr->name;
        $Attr->{'aliases'} = [];
        if ( $attr->does('MooseX::Getopt::Meta::Attribute::Trait') ) {  
            $Attr->{'flag'} = $attr->cmd_flag if $attr->has_cmd_flag;
            my @aliases = ();
            @aliases = @{ $attr->cmd_aliases } if $attr->has_cmd_aliases;
            $Attr->{'aliases'} = \@aliases;
        }

        $Attr->{'doc'} = $attr->has_documentation ? $attr->documentation : '';

        push @Short_Opts, $Attr->{'flag'} if length($Attr->{'flag'}) <= 1;
        for my $alias ( @{ $Attr->{'aliases'} } ) {
            push @Short_Opts, $alias if length($alias) <= 1;
        }
        $Attr->{'show'} = '';
        for my $opt ( @{ $Attr->{'aliases'} }, $Attr->{'flag'} ) {
            $opt = ( length($opt) <= 1 ? '-' : '--' ) . $opt;
            $Attr->{'show'} .= ' ' if $Attr->{'show'} ne '';
            $Attr->{'show'} .= $opt;
        }
        $max_length = length($Attr->{'show'}) if length($Attr->{'show'}) > $max_length;

        $self->debug( "Attribut: ", $Attr ) if $self->verbose >= 3;
        push @Attribute, $Attr;

    }

    printf "Verwendung: %s %s[long options]", basename($0), ( @Short_Opts ? ( '[-' . join( '', @Short_Opts ) . '] ' ) : '' );
    print " [" . join( '|', @{ $self->cmd_params } ) . "]" if $self->cmd_params;
    print "\n";

    for my $Attr ( sort { lc($a->{'name'}) cmp lc($b->{'name'}) } @Attribute ) {
        printf "    %-*s  %s\n", $max_length, $Attr->{'show'}, encode_utf8( $Attr->{'doc'} );
    }

}


#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
