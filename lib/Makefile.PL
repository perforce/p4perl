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

use ExtUtils::MakeMaker;
use English;
use Config;

# Parent passes down options
my $opts = $_[0];


WriteMakefile (
	   NAME   => 'P4::lib',
	   SKIP   => [qw(all static static_lib dynamic dynamic_lib)],
	   DEFINE => $opts->{'DEFINE'},
	   INC    => $opts->{'INC'},
	   CC	  => $opts->{'CC'},
	   CCFLAGS => $opts->{'CCFLAGS'},
	 );



sub MY::top_targets {
my $header = '
all :: static

pure_all :: static

static ::       libp4$(LIB_EXT)

libp4$(LIB_EXT): $(O_FILES)
';

my $trailer;
if( $^O eq "MSWin32" )
{
	# MinGW is like GCC as opposed to Visual Studio
	if ( $Config{cc} =~ /gcc/i ) {
	    $trailer = '	$(AR) cr libp4$(LIB_EXT) $(O_FILES)';
	} else {
	    $trailer = '	$(AR) /OUT:libp4$(LIB_EXT) $(O_FILES)';
	}
}
else
{
	$trailer = '	$(AR) cr libp4$(LIB_EXT) $(O_FILES)';
	$trailer .= "\n";
	$trailer .= '	$(RANLIB) libp4$(LIB_EXT)';
}

$header . $trailer;
}
