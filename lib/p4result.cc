/*******************************************************************************

Copyright (c) 2001-2008, Perforce Software, Inc.  All rights reserved.

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
 * Name		: p4result.cc
 *
 * Author	: Tony Smith <tony@perforce.com> or <tony@smee.org>
 *
 * Description	: Ruby class for holding results of Perforce commands 
 *
 ******************************************************************************/
#include <clientapi.h>
#include "perlheaders.h"
#include "p4perldebug.h"
#include "p4result.h"

P4Result::P4Result() {
    debug  = 0;
    apiLevel = atoi(P4Tag::l_client);
    Init();
}

void P4Result::Init() {
    output = newAV();
    errors = newAV();
    warnings = newAV();
    messages = newAV();
    track = newAV();
}

P4Result::~P4Result() {
	av_undef(output);
	av_undef(warnings);
	av_undef(errors);
	av_undef(messages);
	av_undef(track);
}

void P4Result::Clear() {
	av_clear(output);
	av_clear(warnings);
	av_clear(errors);
	av_clear(messages);
	av_clear(track);
}

//
// Clean up our output and return it. Here, we decrement the reference 
// count as we're not going to hold on to our output any longer than
// necessary.
//
AV *
P4Result::GetOutput()
{ 
    AV *o = output;
    output = newAV();

    return (AV*) sv_2mortal( (SV*)o );
}

void P4Result::Reset() {
    Clear();
    Init();
}

void P4Result::AddOutput(SV * out) {
    if( P4PERL_DEBUG_DATA )
	PerlIO_stdoutf( "[P4Result::AddOutput]: (perl object)\n" );

    av_push( output, out );
}

void P4Result::AddMessage(Error *e) {
    StrBuf	m;
    e->Fmt( &m, EF_PLAIN );

    int s;
    s = e->GetSeverity();

    if( P4PERL_DEBUG_DATA )
    	PerlIO_stdoutf( "[P4Result::Message]: %s\n", m.Text() );

    // 
    // Empty and informational messages are pushed out as output as nothing
    // worthy of error handling has occurred. Warnings go into the warnings
    // list and the rest are lumped together as errors.
    //

    AV *dest = (s == E_WARN) ? warnings : errors;
    if ( s == E_EMPTY || s == E_INFO )
    	dest = output;
    else if( s == E_WARN )
    	dest = warnings;
    else
    	dest = errors;

    av_push( dest, newSVpv( m.Text(), m.Length() ) );

    // 
    // Now create a P4::Error object and insert it into the messages array.
    //

    // Deep copy the error object. We have to do that because the backing
    // dictionary for the error is the client itself, and that'll be
    // re-used for the next error message.
    Error *ne = new Error;
    *ne = *e;

    SV *sv = newSViv( PTR2IV( ne ) );
    sv = newRV_noinc( sv );
    HV *stash = gv_stashpv( "P4::Message", TRUE );
    sv_bless( sv, stash );
    av_push( messages, sv );
}

void P4Result::AddTrack(const char *msg) {
    if( P4PERL_DEBUG_DATA )
	PerlIO_stdoutf( "[P4Result::AddTrack]: %s\n", msg );

    av_push( output, newSVpv( msg, 0 ) );
}

void P4Result::DeleteTrack() {
    av_clear( track );
}

void P4Result::AddTrack(SV * t) {
    if( P4PERL_DEBUG_DATA )
	PerlIO_stdoutf( "[P4Result::AddTrack]: (perl object)\n" );

    av_push( track, t );
}

I32 P4Result::OutputCount() {
    return av_len( output ) + 1;
}

I32 P4Result::ErrorCount() {
    return av_len( errors ) + 1;
}

I32 P4Result::WarningCount() {
    return av_len( warnings ) + 1;
}

I32 P4Result::TrackCount() {
    return av_len( track ) + 1;
}
