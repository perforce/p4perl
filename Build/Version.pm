#!/usr/bin/perl

#*******************************************************************************
# Copyright (c) 2001-2008, Perforce Software, Inc.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
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

# -----------------------------------------------------------------------------
# Class: 		Version
# Discription: 	Read version information from file
# -----------------------------------------------------------------------------
package Version;
use strict;
use warnings;

# -----------------------------------------------------------------------------
# Public method: 	new( file )
# Discription: 		takes file and extracts fields
# -----------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $file  = shift;

	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{file}    = $file;
	$self->{release} = undef;    # e.g.  2012.1
	$self->{name}    = undef;    # e.g.  MAIN or PREP-TEST_ONLY
	$self->{patch}   = undef;    # e.g.  422835
	$self->{date}    = undef;
	bless( $self, $class );

	# return empty if no file
	return $self if ( !$file );

	# Fetch fields, return undef if parse error
	my $ok = $self->parse($file);
	return undef if ( !$ok );

	return $self;
}

# -----------------------------------------------------------------------------
# Private method: 	parse( )
# Discription: 		extracts fields
# -----------------------------------------------------------------------------
sub parse {
	my $self = shift;
	my $file = shift;

	if ( -e $file ) {
		open( VF, $file ) or die("Can't open $file");
		while (<VF>) {
			if (/^RELEASE\s*=\s*(\d+) (\d+) ?(\S+)? ?(\S+)? ;/) {
				$self->{release} = "$1.$2";
				$self->{name}    = uc($3) if($3);
			}
			if (/^PATCHLEVEL\s*=\s*(\d+)/) {
				$self->{patch} = $1;
			}
			if (/^SUPPDATE\s*=\s*([0-9 ]+)/) {
				my @date = split( / +/, $1 );
				$self->{date} = \@date;
			}
		}
		close(VF);
	}
}

# -----------------------------------------------------------------------------
# Public method: 	Getters
# Discription: 		to fetch fields
# -----------------------------------------------------------------------------
sub getRelease {
	my $self = shift;

	my $rel = $self->{release};
	if ( defined $rel && $rel =~ /^(\d+)(\.|\s)(\d+)/ ) {
		return ( ( $1 << 8 ) | $3 );
	}
	return undef;
}

sub getName {
	my $self = shift;
	return $self->{name};
}

sub getPatch {
	my $self = shift;
	return $self->{patch};
}

sub getDate {
	my $self = shift;
	return $self->{date};
}

# -----------------------------------------------------------------------------
# Public method: 	toString
# Discription: 		return version string (REL.NAME)
# -----------------------------------------------------------------------------
sub toString {
	my $self = shift;

	my $name   = $self->{name};
	my $string = $self->{release};
	$string .= ".$name" if $name;
	$string =~ s/ +$//;
	$string =~ s/ +/./g;

	return $string;
}

# -----------------------------------------------------------------------------
# Public method: 	toTarget
# Discription: 		return path string (REL.PATCH.NAME)
# -----------------------------------------------------------------------------
sub toTarget {
	my $self   = shift;

	my $name  = $self->{name};
	my $patch = $self->{patch};

	my $string = "p4perl-";
	$string .= $self->{release};
	$string .= ".$patch" if $patch;
	$string .= ".$name"  if $name;
	$string =~ s/ +$//;
	$string =~ s/ +/./g;
	
	# replace '/' with '.' for tarball
	$string =~ s/\//./g;
	return $string;
}

# -----------------------------------------------------------------------------
# Public method: 	toPatch
# Discription: 		return version string (REL.NAME/PATCH)
# -----------------------------------------------------------------------------
sub toPatch {
	my $self = shift;

	my $name  = $self->{name};
	my $patch = $self->{patch};

	my $string = $self->{release};
	$string .= ".$name"  if $name;
	$string .= "/$patch" if $patch;
	$string =~ s/ +$//;
	$string =~ s/ +/./g;

	return $string;
}

# -----------------------------------------------------------------------------
# Public method: 	parsePatch
# Discription: 		read patch string (REL.NAME/PATCH) and store
# -----------------------------------------------------------------------------
sub parsePatch {
	my $self   = shift;
	my $string = shift;

	if ( $string =~ /(\d*\.\d*)\.?(.*)?\/?(\d*)?/ ) {
		$self->{release} = $1;
		$self->{name}    = $2;
		$self->{patch}   = $3;
		return 1;
	}

	return 0;
}

1;
