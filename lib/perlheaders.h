/*******************************************************************************
Copyright (c) 2007-2008, Perforce Software, Inc.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE SOFTWARE, INC. BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/

#ifndef PERL_HEADERS_INCLUDED
#  define PERL_HEADERS_INCLUDED

/*
 * This header file encapsulates the hoops we have to jump through to
 * persuade Perl's header files to work with C++, the Perforce API, and
 * some compiler versions.
 */

/*
 * Include math.h here because it's included by some Perl headers and on
 * Win32 it must be included with C++ linkage. Including it here prevents it
 * from being reincluded later when we include the Perl headers with C linkage.
 */
#ifdef OS_NT
#  include <math.h>
#endif

extern "C"
{
#include "EXTERN.h"

/*
 * Disable __attribute__ stuff if gcc < 3.4 is being used; you still get lots 
 * of warnings but at least it compiles again. This is mainly a problem for
 * perl 5.8.8.
 */
#ifdef __GNUC__
#  if __GNUC__ >= 3 && __GNUC_MINOR__ < 4
#    undef HASATTRIBUTE_UNUSED
#    undef HASATTRIBUTE_WARN_UNUSED_RESULT
#    define PERL_UNUSED_DECL
#  endif
#endif

#include "perl.h"
#include "perlio.h"

/*
 * Repeat the above block to undo the evil done by perl.h before we
 * include XSUB.h. Yes, I know this is deeply ugly, but the only alternatives
 * are (a) not to support perl 5.8.8 and (b) to ask people to patch their
 * 5.8.8 perl.h and XSUB.h
 */

#ifdef __GNUC__
#  if __GNUC__ >= 3 && __GNUC_MINOR__ < 4
#    undef HASATTRIBUTE_UNUSED
#    undef HASATTRIBUTE_WARN_UNUSED_RESULT
#    define PERL_UNUSED_DECL
#  endif
#endif

#include "XSUB.h"
}

// Undef conflicting macros defined by Perl
#undef Error
#undef Null
#undef Stat
#undef Copy
#undef IsSet

#endif
