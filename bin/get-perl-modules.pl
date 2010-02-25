#!/usr/local/bin/perl

# $Id$
# $URL$

=head1 NAME

B<get-perl-modules.pl> - Stellt eine Liste aller verfuegbarer Perl-Module zusammen.

=head1 SYNOPSIS

B<get-perl-modules.pl> [OPTIONS]

=head1 OPTIONS

=over 4

=item B<-v> - Verbose-Level (Debug-Level)

Wird durch Mehrfach-Aufzaehlung erhoeht.

=item B<-D level> - Debug-Level

Numerische Angabe des Debug-Levels.

I<Hinweis>:

Die Parameter C<-v> und C<-D> wirken sich gleich aus.
Wenn beide angegeben werden, wird der hoehere von beiden verwendet.

=item B<--help>

=item B<-h>

=item B<-?>

Gibt diesen Hilfebildschirm aus und beendet sich.

=item B<--version>

=item B<-V>

Gibt die Versionsnummer dieses Programms aus und beendet sich.

=back

=cut

use strict;
use 5.8.0;
use warnings;

use File::Find;
use File::Spec;
use Data::Dumper;
use Config;
use Pod::Usage;
use Getopt::Long;
use Cwd 'abs_path';

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
Getopt::Long::Configure('bundling');

$| = 1;

my $Revisn = <<'ENDE';
 $Revision$
ENDE
$Revisn =~ s/^.*:\s*(\S+)\s*\$.*/$1/s;
our $VERSION = "1.0." . $Revisn;


my $module = {};

my ( $verbose, $cur_dir, $cmdline_verbose, $DebugLevel, $help, $show_version, $get_module_version );

unless (
    GetOptions(
        "verbose|v+"           => \$cmdline_verbose,
		"get-module-version|get-version|gv" => \$get_module_version,
        "DebugLevel|Debug|D=i" => \$DebugLevel,
        "help|h|?"             => \$help,
        "version|V"            => \$show_version,
    )
  )
{
    pod2usage( { -exitval => 1, -verbose => 1 } );
} ## end unless ( GetOptions( "conf|config|c=s"...

$cmdline_verbose ||= 0;
$cmdline_verbose = $DebugLevel if $DebugLevel and $DebugLevel > $cmdline_verbose;
$verbose = $cmdline_verbose;

if ($help) {
    $verbose ? pod2usage( -exitstatus => 1, -verbose => 2 ) : pod2usage(1);
}

if ($show_version) {
    print "Version $0: " . $VERSION . "\n";
    print "\n";
    exit 0;
}

print "Geladene Module: " . Dumper(\%INC) if $verbose > 1;

my $arch = $Config{'archname'};
my $version = $Config{'version'};

my $cp_lib_dir = $Config{'privlib'};
my $ca_lib_dir = $Config{'archlib'};
my $vp_lib_dir = $Config{'vendorlib'};
my $va_lib_dir = $Config{'vendorarch'};
my $sp_lib_dir = $Config{'sitelib'};
my $sa_lib_dir = $Config{'sitearch'};

if ( $verbose ) {
	print <<ENDE;
Standard-Modul-Verzeichnisse:
Core-Modul-Verzeichnis:        $cp_lib_dir
Core-Arch-Modul-Verzeichnis:   $ca_lib_dir
Vendor-Modul-Verzeichnis:      $vp_lib_dir
Vendor-Arch-Modul-Verzeichnis: $va_lib_dir
Site-Modul-Verzeichnis:        $sp_lib_dir
Site-Arch-Modul-Verzeichnis:   $sa_lib_dir

ENDE
}

print "Include-Verzeichnisse: " . Dumper(\@INC) if $verbose;

for my $d ( @INC ) {

	my $dir = abs_path($d);

    if ( -d $dir ) {
        print "\nDurchsuche Verzeichnis '$dir' ...\n" if $verbose;
        $cur_dir = $dir;
        find( \&wanted, $dir );
    }
	else {
		warn "$dir ist kein Verzeichnis.\n";
	}
}

sub wanted {

    my $file_abs = $File::Find::name;
    if ( -f $file_abs and $file_abs =~ /\.pm$/ ) {
        print "Untersuche '$file_abs' ...\n" if $verbose > 1;
        
        my ( $volume, $file_in_volume, $file_bla ) = File::Spec->splitpath( $file_abs, 1 );
        $file_in_volume =~ s/^$cur_dir\///;
        return if $file_in_volume =~ /^$arch\//;
        return if $file_in_volume =~ /^$version\//;
        my $modname = $file_in_volume;
        $modname =~ s/\.pm$//;
        $modname =~ s#/#::#g;
		$module->{$modname} = {} unless $module->{$modname};
		$module->{$modname}{'locations'} = [] unless $module->{$modname}{'locations'};
		
		#return if $module->{$modname};
        print "Modul '$modname' gefunden in '$cur_dir' ...\n" if $verbose > 1;

		my $location = 'o ';
		my $loc_name = 'other';
		if ( $file_abs =~ /^$sa_lib_dir/ ) {
			$location = 'sa';
			$loc_name = 'site-arch';
		}
		elsif ( $file_abs =~ /^$sp_lib_dir/ ) {
			$location = 's ';
			$loc_name = 'site';
		}
		elsif ( $file_abs =~ /^$va_lib_dir/ ) {
			$location = 'va';
			$loc_name = 'vendor-arch';
		}
		elsif ( $file_abs =~ /^$vp_lib_dir/ ) {
			$location = 'v ';
			$loc_name = 'vendor';
		}
		elsif ( $file_abs =~ /^$ca_lib_dir/ ) {
			$location = 'ca';
			$loc_name = 'core-arch';
		}
		elsif ( $file_abs =~ /^$cp_lib_dir/ ) {
			$location = 'c ';
			$loc_name = 'core';
		}
		$module->{$modname}{'first_location'} = $loc_name;
		my $mod_info = {};
		$mod_info->{'path'} = $file_abs;
		$mod_info->{'loc'}  = $loc_name;

		push @{ $module->{$modname}{'locations'} }, $mod_info;
	
        #$module->{$modname} = $location;
    }

}

print Dumper( $module ) if $verbose > 1;

print "\nGefundene Module:\n\n" if $verbose;

for my $m ( sort { lc($a) cmp lc($b) } keys %$module ) {
    printf " - %s\n", $m;
	for my $mod_info ( @{ $module->{$m}{'locations'} } ) {
		printf "     %-11s %s\n", $mod_info->{'loc'}, $mod_info->{'path'};
	}
    #print $module->{$_} . " " . $_ . "\n";
}

exit 0;

#------------------------------------------------------------------------------------

__END__

=end comment

=head1 DESCRIPTION

Stellt aus allen Modul-Verzeichnissen (@INC) eine Liste der verfuegbaren Perl-Module
zusammen (unabhaengig davon, ob sie funktionieren).

=head1 FILES

Keine.

=head1 SEE ALSO

=over 1

=item I<perl>(8)

=item I<perlmod>

=back

=head1 AUTHOR

Frank Brehm <frank@brehm-online.com>

=cut

