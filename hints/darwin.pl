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
use Config;

sub identify_osplat
{
	my $plat;
	$plat = `uname -m`;
	chomp $plat;
	$plat = uc $plat;
	$plat = "X86" if $plat eq "I386";
	$plat = "X86_64" if $plat eq "X86_64";
	return $plat;
}

sub identify_osver
{
	my $ver;
	$ver = `uname -r`;
	chomp $ver;
	if( $ver =~ /^(\d+)/ )
	{
	    $ver = $1;
	}
	return $ver;
}

sub set_flags( $$$ )
{
	my $osplat = shift;
	my $osver = shift;
	my $href = shift;

	my $tgt;
	$tgt = $osver - 4;

	$href->{CC} 		= "MACOSX_DEPLOYMENT_TARGET=10.$tgt c++";
	$href->{LD} 		= "MACOSX_DEPLOYMENT_TARGET=10.$tgt c++ -framework CoreFoundation -framework ApplicationServices -framework Carbon";

	if( $osver == 9 )
	{
	    my $c;
	    $c = $Config{ 'ccflags' };
	    $c .= ' -fvisibility-inlines-hidden';
	    $href->{ 'CCFLAGS' } = $c;
	}
} 
	
my $osver;
my $osplat;

$osver = identify_osver();
$osplat = identify_osplat();
set_flags( $osplat, $osver, $self );

$self->{ 'P4PERL_OS_HINT' } = "DARWIN";
$self->{ 'P4PERL_PLAT_HINT' } = $osplat;
$self->{ 'P4PERL_OSVER_HINT' } = $osver;
