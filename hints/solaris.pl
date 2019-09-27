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

sub identify_osplat {
	my $plat;
	$plat = `isainfo -b`;
	chomp $plat;
	$plat = "X86"    if $plat eq "32";
	$plat = "X86_64" if $plat eq "64";
	return $plat;
}

if ( $Config{'gccversion'} eq '' ) {
	print <<EOS;

********************************************************************************
The Perforce C++ API is built with gcc on Solaris, while your perl is
built with the "$Config{ 'ccversion' }" compiler. This build environment
is incompatible with the Perforce C++ API, so this build WILL FAIL.

You can download a compatible build of Perl from http://www.sunfreeware.com
********************************************************************************

EOS
}
elsif ( !defined $ENV{'LD_LIBRARY_PATH'} ) {
	print <<EOS;

Warning: You may need to set LD_LIBRARY_PATH to point to the location of 
your libstdc++.so library before you can use P4Perl successfully.

EOS
}

$self->{CC} = "g++";
$self->{LD} = "g++";
$self->{DEFINE} .= " -Dsolaris";
$self->{LIBS} = ["-lsocket -lnsl"];

#
# Solaris version numbers need special handling. Version 2.10 is Solaris 10, so
# we need to give Makefile.PL a hint.
#
$self->{P4PERL_OSVER_HINT} = $Config{osvers};
$self->{P4PERL_OSVER_HINT} =~ s/^2\.//;
$self->{P4PERL_PLAT_HINT} = identify_osplat();
