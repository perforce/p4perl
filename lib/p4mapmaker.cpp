/*******************************************************************************

Copyright (c) 2008, Perforce Software, Inc.  All rights reserved.

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
 * Name		: p4mapmaker.cpp
 *
 * Author	: Tony Smith <tony@perforce.com>
 *
 * Description	: Class to encapsulate Perforce map manipulation from Perl
 *
 ******************************************************************************/
#include <clientapi.h>
#include <mapapi.h>
#include "perlheaders.h"
#include "p4perldebug.h"
#include "p4mapmaker.h"


P4MapMaker::P4MapMaker()
{
    map = new MapApi;
}

P4MapMaker::~P4MapMaker()
{
    delete map;
}

P4MapMaker::P4MapMaker( const P4MapMaker &m )
{
    StrBuf	l, r;
    const StrPtr *s;
    MapType	t;
    int 	i;

    map = new MapApi;
    for( i = 0; i < m.map->Count(); i++ )
    {
	s = m.map->GetLeft( i );
	if( !s ) break;
	l = *s;

	s = m.map->GetRight( i );
	if( !s ) break;
	r = *s;

	t = m.map->GetType( i );

	map->Insert( l, r, t );
    }
}

P4MapMaker *
P4MapMaker::Join( P4MapMaker *l, P4MapMaker *r)
{
    P4MapMaker *m = new P4MapMaker();
    delete m->map;

    m->map = MapApi::Join( l->map, r->map );
    return m;
}

void
P4MapMaker::Insert( SV * m )
{
    StrBuf	in;
    StrBuf	lbuf;
    StrBuf	r;
    StrRef	l;
    MapType	t = MapInclude;

    in = SvPV( m, PL_na );
    SplitMapping( in, lbuf, r );

    l = lbuf.Text();

    // Look for mapType in lhs only.
    if( l[ 0 ] == '-' )
    {
	l += 1;
	t = MapExclude;
    }
    else if( l[ 0 ] == '+' )
    {
	l += 1;
	t = MapOverlay;
    }

    map->Insert( l, r, t );
}


void
P4MapMaker::Insert( SV * l, SV * r )
{
    StrBuf	left;
    StrBuf	right;
    StrBuf *	dest = &left;
    int		quoted = 0;
    int		index = 0;
    const char *p;
    MapType	t = MapInclude;

    p = SvPV( l, PL_na );
    for( ; ; )
    {
	for( index = 0; *p; p++ )
	{
	    switch( *p )
	    {
	    case '"':
		quoted = !quoted;
		break;

	    case ' ':
	    case '\t':
		// Embedded whitespace ok; leading not.
		if( quoted || index )
		{
		    dest->Extend( *p );
		    index++;
		}
		break;

	    case '-':
		if( !index )
		    t = MapExclude;
		else
		    dest->Extend( *p );
		index++;
		break;

	    case '+':
		if( !index )
		    t = MapOverlay;
		else
		    dest->Extend( *p );
		index++;
		break;

	    default:
		dest->Extend( *p );
		index++;
	    }
	}

	if( dest == &right )
	    break;

	dest = &right;
	p = SvPV( r, PL_na );
	quoted = 0;
    }
    left.Terminate();
    right.Terminate();

    map->Insert( left, right, t );
}

int
P4MapMaker::Count()
{
    return map->Count();
}

void
P4MapMaker::Clear()
{
    map->Clear();
}

void
P4MapMaker::Reverse()
{
    MapApi *		nmap = new MapApi;
    const StrPtr *	l;
    const StrPtr *	r;
    MapType		t;

    for( int i = 0; i < map->Count(); i++ )
    {
	l = map->GetLeft( i );
	r = map->GetRight( i );
	t = map->GetType( i );

	nmap->Insert( *r, *l, t );
    }

    delete map;
    map = nmap;
}

SV *
P4MapMaker::Translate( SV * p, int fwd )
{
    StrBuf	from;
    StrBuf	to;
    MapDir	dir = MapLeftRight;

    if( !fwd )
	dir = MapRightLeft;

    from = SvPV( p, PL_na );
    if( map->Translate( from, to, dir ) )
	return newSVpv( to.Text(), to.Length() );
    return 0;
}

AV *
P4MapMaker::Lhs()
{
    AV *		a = newAV();
    StrBuf		s;
    const StrPtr *	l;
    MapType		t;
    int			quote;

    for( int i = 0; i < map->Count(); i++ )
    {
	s.Clear();
	quote = 0;

	l = map->GetLeft( i );
	t = map->GetType( i );

	if( l->Contains( StrRef( " " ) ) )
	{
	    quote++;
	    s << "\"";
	}

	switch( t )
	{
	case MapInclude:
	    break;
	case MapExclude:
	    s << "-";
	    break;
	case MapOverlay:
	    s << "+";
	    break;
	case MapOneToMany:
        s << "&";
	    break;
	};

	s << l->Text();
	if( quote ) s << "\"";

	av_push( a, newSVpv( s.Text(), s.Length() ) );
    }
    return a;
}

AV *
P4MapMaker::Rhs()
{
    AV *		a = newAV();
    StrBuf		s;
    const StrPtr *	r;
    int			quote;

    for( int i = 0; i < map->Count(); i++ )
    {
	s.Clear();
	quote = 0;

	r = map->GetRight( i );

	if( r->Contains( StrRef( " " ) ) )
	{
	    quote++;
	    s << "\"";
	}

	s << r->Text();
	if( quote ) s << "\"";

	av_push( a, newSVpv( s.Text(), s.Length() ) );
    }
    return a;
}

AV *
P4MapMaker::ToA()
{
    AV *		a = newAV();
    StrBuf		s;
    const StrPtr *	l;
    const StrPtr *	r;
    MapType		t;
    int			quote;

    for( int i = 0; i < map->Count(); i++ )
    {
	s.Clear();
	quote = 0;

	l = map->GetLeft( i );
	r = map->GetRight( i );
	t = map->GetType( i );

	if( l->Contains( StrRef( " " ) ) ||
	    r->Contains( StrRef( " " ) ) )
	{
	    quote++;
	    s << "\"";
	}

	switch( t )
	{
	case MapInclude:
	    break;
	case MapExclude:
	    s << "-";
	    break;
	case MapOverlay:
	    s << "+";
	    break;
	case MapOneToMany:
        s << "&";
	    break;
	};

	s << l->Text();

	if( quote ) s << "\" \"";
	else s << " ";

	s << r->Text();
	if( quote ) s << "\"";

	av_push( a, newSVpv( s.Text(), s.Length() ) );
    }
    return a;
}

SV *
P4MapMaker::Dump()
{
    StrBuf b;

    if( !map->Count() )
    {
	b << "(empty)";
	return newSVpv( b.Text(), b.Length() );
    }

    const StrPtr *l, *r;
    int	  t;

    b << "\n";

    for( int i = 0; i < map->Count(); i++ )
    {

	l = map->GetLeft( i );
	r = map->GetRight( i );
	t = map->GetType( i );

	b << "\t";
	switch( t )
	{
	case MapExclude:
	    b << "-";
	    break;

	case MapOverlay:
	    b << "+";
	    break;

	case MapOneToMany:
        b << "&";
        break;

	case MapInclude:
	    break;
	}

	b << l->Text();
	b << " ";
	b << r->Text();
	b << "\n";
    }

    return newSVpv( b.Text(), b.Length() );
}

//
// Take a single string containing either a half-map, or both halves of
// a mapping and split it in two. If there's only one half of a mapping in
// the input, then l, and r are set to the same value as 'in'. If 'in'
// contains two halves, then they are split.
//
void
P4MapMaker::SplitMapping( const StrPtr &in, StrBuf &l, StrBuf &r )
{
    char *	pos;
    int		quoted = 0;
    int		split = 0;
    StrBuf *	dest = &l;

    pos = in.Text();

    l.Clear();
    r.Clear();

    while( *pos )
    {
	switch( *pos )
	{
	case '"':
	    quoted = !quoted;
	    break;

	case ' ':
	    if( !quoted && !split )
	    {
		// whitespace in the middle. skip it, and start updating
		// the destination
		split = 1;
		dest->Terminate();
		dest = &r;
	    }
	    else if( !quoted )
	    {
		// Trailing space on rhs. ignore
	    }
	    else
	    {
		// Embedded space
		dest->Extend( *pos );
	    }
	    break;

	default:
	    dest->Extend( *pos );
	}
	pos++;
    }
    l.Terminate();
    r.Terminate();

    if( !r.Length() )
	r = l;
}
