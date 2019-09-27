/*******************************************************************************

Copyright (c) 2009, Perforce Software, Inc.  All rights reserved.

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

/*******************************************************************************
 * Name		: p4specdata.cpp
 *
 * Author	: Tony Smith <tony@perforce.com> or <tony@smee.org>
 *
 * Description	: Perl bindings for the Perforce API. SpecData subclass for
 * 		  P4Perl. This class allows for manipulation of Spec data
 * 		  stored in a Perl hash using the standard Perforce classes
 *
 ******************************************************************************/

#include <clientapi.h>
#include <spec.h>
#include "perlheaders.h"
#include "p4perldebug.h"
#include "p4specdata.h"

//
// We're expecting a blessed hashref, but we only need to store the 
// underlying HV
//
SpecDataPerl::SpecDataPerl( SV * h )
{
    if( !SvROK( h ) || SvTYPE( SvRV( h ) ) != SVt_PVHV )
    {
	warn( "Not a P4::Spec object. Ignoring..." );
	hash = 0;
	return;
    }
    hash = (HV*) SvRV( h );
}

SpecDataPerl::SpecDataPerl( HV * h )
{
    hash = h;
}
    
StrPtr *
SpecDataPerl::GetLine( SpecElem *sd, int x, const char **cmt )
{
	*cmt = 0;
	SV * val;
	SV **svp;
	AV * av;
	StrBuf t;

	if( !hash )
	{
	   warn( "Can't fetch values from non-P4::Spec object." );
	   return 0;
	}

	svp = hv_fetch( hash, sd->tag.Text(), sd->tag.Length(), 0 );
	if( !svp ) return 0;

	val = *svp;

	if( !sd->IsList() )
	{
	    last = SvPV_nolen( val );
	    return &last;
	}

	// It's a list, which means we should have an array value here
	
    	if( !SvROK( val ) || SvTYPE( SvRV( val ) ) != SVt_PVAV )
	{
	    warn( "%s should be an array element. Ignoring...", 
		    sd->tag.Text() );
	    return 0;
	}

	av = (AV*) SvRV( val );
	svp = av_fetch( av, x, 0 );

	if( !svp ) return 0;
	if( !SvPOK( *svp ) )
	{
	    warn( "Cannot convert %s field to text. Ignoring...",
	       sd->tag.Text() );
	    return 0;
	}

	last = SvPV_nolen( *svp );
	return &last;
}

void	
SpecDataPerl::SetLine( SpecElem *sd, int x, const StrPtr *v, Error *e )
{
	SV ** 	svp;
	SV * 	key;
	SV *	val;
	AV *	av;
	SV *	rv;
	StrBuf	t;

	if( !hash ) 
	{
	    warn( "Can't store values in non P4::Spec object" );
	    return;
	}

	key = newSVpv( sd->tag.Text(), sd->tag.Length() );
	val = newSVpv( v->Text(), v->Length() );

	if( sd->IsList() )
	{
	    svp = hv_fetch( hash, sd->tag.Text(), sd->tag.Length(), 0 );
	    if( !svp )
	    {
		av = newAV();
		rv = newRV_noinc( (SV*) av );
		hv_store( hash, sd->tag.Text(), sd->tag.Length(), (SV*)rv, 0);
	    }
	    else if( !SvROK( *svp ) || SvTYPE( SvRV( *svp ) ) != SVt_PVAV )
	    {
		warn( "%s: not an array reference.", sd->tag.Text() );
		return;
	    }
	    else
	    {
		av = (AV*) SvRV( *svp );
	    }

	    av_store( av, x, val );
	}
	else
	{
	    hv_store( hash, sd->tag.Text(), sd->tag.Length(), val, 0 );
	}
	return;
}
