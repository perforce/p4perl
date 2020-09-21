#!/usr/bin/perl

#*******************************************************************************
# Copyright (c) 2001-2008, Perforce Software, Inc.	All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1.  Redistributions of source code must retain the above copyright
#	  notice, this list of conditions and the following disclaimer.
#
# 2.  Redistributions in binary form must reproduce the above copyright
#	  notice, this list of conditions and the following disclaimer in the
#	  documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE SOFTWARE, INC. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#*******************************************************************************

use strict;
use warnings;

use lib '.';    # Make sure we find Build::Version
use Build::Version;
use Config;
use Getopt::Long;
use ExtUtils::MakeMaker;
use Cwd;
use Cwd 'abs_path';

use Data::Dumper;
use File::Copy;
use English;

# --- Supported API version ---------------------------------------------------
our $TARGET_API_VERSION = "2020.1";

# --- GLOBALS -----------------------------------------------------------------
our $ssl_path	= undef;	## SSL path string
our $p4api_path = undef;	## P4API path string
our $p4api		= undef;	## P4API version object
our $p4perl		= undef;	## P4PERL version object

# =============================================================================
# MAIN Function
# Arguments:		apidir	=	<path>			(required)
#					ssl		=	<lib path>		(optional)
# =============================================================================

## Debug options
#	$ExtUtils::MakeMaker::Verbose = 1;

## Fetch arguments
my $apidir = undef;
GetOptions(
	"apidir=s" => \$apidir,
	"ssl:s"	   => \$ssl_path
);


## Attempt to pull 'Version' and doc (for Build)
my $path = "../p4/Version";
copy( $path, "Version" ) if ( -f $path );
my $src = "../p4-doc/user/p4perlnotes.txt";
my $dst = "RELNOTES.txt";
copy( $src, $dst ) if ( -f $src );

## Set globals for api's version and path
print( "Verifying external libraries...\n");
$p4api_path = p4api_find_path($apidir);
$p4api		= p4api_version($p4api_path);
$p4perl		= p4perl_version();

## Makefile Flags
my %make_flags = (
	'NAME'		=> 'P4',
	'VERSION'	=> $p4perl->toString(),
	'PREREQ_PM' => {},							 # e.g., Module::Name => 1.1
	'MYEXTLIB'	=> 'lib/libp4$(LIB_EXT)',
	'XSOPT'		=> '-C++ -prototypes',
	'CONFIGURE' => \&config_sub,
	'DISTVNAME' => $p4perl->toTarget(),
	'PL_FILES'	=> {},
	'clean'		=> { 'FILES' => "p4perl.*" },
);

WriteMakefile(%make_flags);

exit 0;

# ===================================================================== END ===

# -----------------------------------------------------------------------------
# Function:		p4perl_version
# Description:	Returns P4PERL version object
# -----------------------------------------------------------------------------
sub p4perl_version {

	# Read API version file
	my $ver = new Version("Version");
	die("Aborting: Cannot read local p4-perl Version file!") unless $ver;

	# logging...
	print( "  building p4perl version: \t" . $ver->toPatch() . "\n" );
	return $ver;
}

# -----------------------------------------------------------------------------
# Function:		p4api_version
# Description:	Returns P4API version object
# -----------------------------------------------------------------------------
sub p4api_version {
	my $path = shift;

	# Read API version file
	my $ver = new Version("$path/Version");

	# try alternative location or die
	$ver = new Version("$path/sample/Version") if ( !$ver );

	# if no Version string then ask user
	my $tries = 3;
	while ( !$ver && --$tries ) {
		print("Unable to determine API version string\n");
		print("Enter API version (REL.NAME/PATCH): ");
		my $string = <STDIN>;
		$ver = new Version();
		$ver->parsePatch($string);
	}
	die("Aborting: API version not provided") unless $ver;

	# logging...
	print( "  using p4api path: \t\t$path\n");
	print( "  using p4api version: \t\t" . $ver->toPatch() . "\n" );
	return $ver;
}

# -----------------------------------------------------------------------------
# Function:		p4api_find_path
# Description:	Returns full path to P4API.
# -----------------------------------------------------------------------------
sub p4api_find_path {
	my $path = shift;

	# return full path if it exists
	if ( defined($path) ) {
		$path = abs_path($path);
		if ( is_api_dir($path) ) {
			return $path;
		}
	}

	# Ask user for P4API path
	$path = undef;
	my $tries = 3;
	while ( !defined($path) && --$tries ) {
		print("Enter the path to the Perforce API: ");
		$path = <STDIN>;
		chomp ($path);
		$path = undef if($path eq "");

		# Filthy support for ~/ type paths ( NOT ~user/ though! )
		if($path) {
			$path =~ s#\~/#$ENV{HOME}/#;
			$path = abs_path($path);
			$path = undef unless ( is_api_dir($path) );
		}
	}

	die("Aborting - no API directory provided") unless $path;
	return $path;
}

# -----------------------------------------------------------------------------
# Function:		is_api_dir
# Description:	Test to see if 'Version' file is in a known location
# -----------------------------------------------------------------------------
sub is_api_dir {
	my $dir = shift;
	return 0 unless ( -d $dir );
	return 1 if ( -e "$dir/Version" );
	return 1 if ( -e "$dir/sample/Version" );
	return 0;
}

# -----------------------------------------------------------------------------
# Function:		check_api_version
# Description:	checks Version object; returns 1 if ok, 0 if not compattable
# -----------------------------------------------------------------------------
sub check_api_version {

	my $ver = shift;

	my $target = new Version();
	$target->parsePatch($TARGET_API_VERSION);

	my $v = $ver->getRelease();
	my $t = $target->getRelease();

	return 1 if ( $v == $t );

	my $string = $ver->toString();
	print <<EOF;

This version of P4Perl was designed for use with the $TARGET_API_VERSION
release of the Perforce C++ API. Using it with other releases may not work,
and is not supported. ($string)

EOF
	print("Do you wish to continue anyway? (y/n): ");
	my $answer = <STDIN>;
	chomp($answer);
	return 0 unless $answer eq "y";
	return 1;
}

# -----------------------------------------------------------------------------
# Function:		define
# Description:	Define Make Macos (qq strings)
# -----------------------------------------------------------------------------
sub define( $$;$$ ) {
	my $href   = shift;
	my $var	   = shift;
	my $val	   = shift;
	my $string = shift;

	if ( !$val ) {
		$href->{'DEFINE'} .= qq{ -D$var};
	}
	elsif ($string) {
		$href->{'DEFINE'} .= qq{ -D$var="\\"$val\\""};
	}
	else {
		$href->{'DEFINE'} .= qq{ -D$var="$val"};
	}
}

# -----------------------------------------------------------------------------
# Function:		add_p4_libs
# Description:	Add the Perforce libraries to the linker configuration
# -----------------------------------------------------------------------------
sub add_p4_libs( $$$$ ) {
	my $cfg	   = shift;	   # Perl's pre-set config
	my $flags  = shift;	   # Flags we want to add
	my $apidir = shift;	   # Our API directory
	my $ssldir = shift;	   # Our SSL directory
	my $os	 = uc( $Config{osname} );	 # LINUX, DARWIN, MSWIN32
	my $arch = $Config{ptrsize} * 8;	 # 32 or 64

	# Generate path list and string
	my @paths;
	push( @paths, "$apidir/lib" ) if ( -d "$apidir/lib" );

	if ( defined $ssldir && -d $ssldir ) {
		push( @paths, $ssldir );
		print("	 using ssl path: \t\t$ssldir\n");
	}
	elsif ( defined $ssldir ) {
		print("	 ssl defined:\t\t\t(using system path)\n");
	}

	# Pull in appropriate paths for MinGW on Windows
	if ( $os eq "MSWIN32" && $Config{cc} =~ /gcc/i ) {
		my $mingw_libpath = $Config{libpth};
		my $sitelib = $Config{sitelibexp};
		$sitelib =~ s#\\#/#g;
		$mingw_libpath =~ s#\\#/#g;
		$mingw_libpath =~ s#.*:##g;
		$mingw_libpath = $sitelib . "/auto" . $mingw_libpath;
		push( @paths, $mingw_libpath );
	}

	my $libpath = join( " -L", "", @paths );

	# Build library list
	my @libs = ( "client", "rpc", "supp" );

	# [MSWIN32]
	if ( $os eq "MSWIN32" && $Config{cc} !~ /gcc/i ) {
		push( @libs, "libeay32" );
		push( @libs, "ssleay32" );
	}

	# [MSWIN32] and NOT MinGW
	elsif ( $os eq "MSWIN32" ) {
		push( @libs, "ssl" );
		push( @libs, "crypto" );
		push( @libs, "crypt32" );
	}

	# [LINUX]
	elsif ( $os eq "LINUX" ) {
		push( @libs, "rt" );
		push( @libs, "ssl" );
		push( @libs, "crypto" );
	}

	# [DEFAULT]
	else {
		push( @libs, "ssl" );
		push( @libs, "crypto" );
	}

	# Generate library string
	# note: the empty field "" adds -l to the first element
	my $liblist = join( " -l", "", @libs );

	$flags->{'LIBS'} = [];
	if ( defined( $cfg->{LIBS} ) ) {
		my $libs = $cfg->{LIBS};
		foreach my $libset (@$libs) {
			push( @{ $flags->{LIBS} }, "$libpath $liblist $libset" );
		}
	}
	else {
		push( @{ $flags->{LIBS} }, "$libpath $liblist" );
	}
}

# -----------------------------------------------------------------------------
# Function:		add_p4_hdrs
# Description:	Add the Perforce headers to the includes
# -----------------------------------------------------------------------------
sub add_p4_hdrs( $$ ) {
	my $flags	= shift;
	my $apipath = shift;

	$apipath = "$apipath/include/p4" if ( -d "$apipath/include/p4" );
	$flags->{'INC'} = "-I$apipath -Ilib";
}

# -----------------------------------------------------------------------------
# Function:		get_platform
# Description:	return a string for the platform we are on. Anything specific
#				to one platform should go in its hints file.
# -----------------------------------------------------------------------------
sub get_platform {
	my $href = shift;

	# Read $Config{ 'archname' ), which looks like this:
	#
	#	i86pc-solaris-64int (solaris10x86_64 )
	#	x86_64-linux-gnu-thread-multi (linux26x86_64)
	#	MSWin32-x86-multi-thread (ntx86) - note os/plat reversal!!!
	#
	# So, we get the osname from Config, then we use whichever of the
	# first two fields in archname is NOT the os as the platform.
	#
	my $os = $Config{'osname'};
	my @fields = split( /-/, $Config{'archname'} );

	print( "  with archname: \t\t" . $Config{'archname'} . "\n");

	my $plat;
	$plat = $fields[0] if ( $os eq $fields[1] );
	$plat = $fields[1] if ( $os eq $fields[0] );

	# Now convert the platform identifier to Perforce style for known
	# differences in terminology
	$plat = "x86"	if ( $plat =~ /[xi]86pc/ );
	$plat = "x86"	if ( $plat =~ /[xi]\d?86$/ );
	$plat = "sparc" if ( $plat =~ /sun/ );
	$plat = uc($plat);

	# Override derived value with hints from the hints file
	if ( defined( $href->{'P4PERL_PLAT_HINT'} ) ) {
		$plat = $href->{'P4PERL_PLAT_HINT'};
		delete( $href->{'P4PERL_PLAT_HINT'} );
	}

	print("	 using os: \t\t\t$os\n");
	print("	 using platform: \t\t$plat\n");
	return $plat;
}

# -----------------------------------------------------------------------------
# Function:		get_os
# Description:	return a string for the os we are on
# -----------------------------------------------------------------------------
sub get_os {
	my $href = shift;
	my $os	 = $Config{'osname'};

	# Now convert the OS to Perforce style for known differences.
	$os = "NT" if ( $os eq "MSWin32" );

	# Default is our guestimate.
	$os = uc($os);

	# Override derived value with hints from the hints file
	if ( defined( $href->{'P4PERL_OS_HINT'} ) ) {
		$os = $href->{'P4PERL_OS_HINT'};
		delete( $href->{'P4PERL_OS_HINT'} );
	}

	return $os;
}

# -----------------------------------------------------------------------------
# Function:		get_osver
# Description:	return a string for the os version we are on
# -----------------------------------------------------------------------------
sub get_osver {
	my $href = shift;
	my $os	 = get_os();
	my $osver;

	# Identify the OS version. We take the first two numbers in the
	# dotted string. On NT, we don't bother.
	if ( $os eq "NT" ) {
		$osver = "";
	}
	else {
		$osver = $Config{'osvers'};
		$osver =~ s/^(\d+)\.(\d+).*/$1$2/;
	}

	# Override derived value with hints from the hints file
	if ( defined( $href->{'P4PERL_OSVER_HINT'} ) ) {
		$osver = $href->{'P4PERL_OSVER_HINT'};
		delete( $href->{'P4PERL_OSVER_HINT'} );
	}
	return $osver;
}

# -----------------------------------------------------------------------------
# Function:		config_sub
# Description:	Called by WriteMakefile - adds the Perforce API path to the
#				header includes and libs
# -----------------------------------------------------------------------------
sub config_sub {
	my $class = shift;
	my $href  = shift;

	# Work out what platform we're running on
	my $plat  = get_platform($href);
	my $os	  = get_os($href);
	my $osver = get_osver($href);

	# Define Ident macros
	define( $href, "ID_OS",	   $os . $osver . $plat,	1 );
	define( $href, "ID_REL",   $p4perl->toString(),		1 );
	define( $href, "ID_PATCH", $p4perl->getPatch(),		1 );
	define( $href, "ID_Y",	   $p4perl->getDate()->[0], 1 );
	define( $href, "ID_M",	   $p4perl->getDate()->[1], 1 );
	define( $href, "ID_D",	   $p4perl->getDate()->[2], 1 );

	# Define OS_* macros
	define( $href, "OS_$os" );
	define( $href, "OS_$os$osver" );
	define( $href, "OS_$os$osver$plat" );
	define( $href, "OS_$os$plat" );

	# Now find the API!
	my $flags = {};

	# Abort if the user's decided not to press ahead with a newer
	# version of the API than this version was written for
	exit(1) unless ( check_api_version($p4api) );

	define( $href, "P4API_VERSION", $p4api->getRelease() );
	define( $href, "ID_API", $p4api->toPatch(), 1 );

	add_p4_libs( $href, $flags, $p4api_path, $ssl_path );
	add_p4_hdrs( $flags, $p4api_path );

	# Post distribution move
	my $source = $p4perl->toTarget() . ".tar.gz";
	my $target = "p4perl.tar.gz";

	if ( $os eq 'NT' ) {
		$flags->{'dist'}{'POSTOP'} = "ren $source $target";
		$flags->{'DISTVNAME'} = $p4perl->toTarget();
	}
	else {
		$flags->{'dist'}{'POSTOP'} = "mv -f $source $target";
		$flags->{'DISTVNAME'} = $p4perl->toTarget();
	}

	return $flags;
}

# Ensure that the clientuserperl interface gets built.
sub MY::postamble {
	'
$(MYEXTLIB): lib/Makefile
	cd lib && $(MAKE) $(PASSTHRU)

';
}
