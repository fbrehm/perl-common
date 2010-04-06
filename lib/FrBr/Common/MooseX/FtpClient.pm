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

use Encode qw( decode_utf8 encode_utf8 );

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

=head1 ATTRIBUTES

Alle durch diese Rolle definierten Attribute

=cut

#---------------------------------------------------------------------------

no Moose::Role;
1;

__END__

# vim: noai: filetype=perl ts=4 sw=4 : expandtab
