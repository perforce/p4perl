/*
Copyright (c) 2001-2010, Perforce Software, Inc.  All rights reserved.

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
*/


// Undef conflicting macros defined by Perl
#undef Error
#undef Null
#undef Stat
#undef Copy

#include "clientapi.h"
#include "perlheaders.h"
#include "strtable.h"
#include "debug.h"
#include "p4perldebug.h"
#include "perlclientapi.h"
#include "p4mergedata.h"
#include "p4mapmaker.h"
#include "p4actionmerge.h"
#include "p4dvcsclient.h"

/*
 * The architecture of this extension is relatively complex. The main Perl
 * class is P4 which is a blessed scalar containing pointers to our C++ 
 * objects which hold all our real data. We try to expose as little as
 * possible of the internals to Perl.
 *
 * As the Perforce API is callback based, we have some tap-dancing to do
 * in order to shim it into Perl space. There are two main C++ classes:
 *
 * 1  PerlClientUser is our subclass of the Perforce ClientUser class. This 
 *    class handles all the user-interface functions needed in the API - i.e.
 *    getting input, writing output/errors etc.
 *
 * 2. PerlClientApi is our interface to the Perforce ClientApi class. It
 *    provides a type-bridge between Perl and C++ and makes sure
 *    that the results it returns are ready for use in Perl space.
 *
 * This module provides the glue between Perl space and C++ space by
 * providing Perl methods that call the C++ methods and return the appropriate
 * results.
 */

#define CLIENT_PTR_NAME 	"_p4client_ptr"

static PerlClientApi *
ExtractClient( SV *var )
{
    if (!(sv_isobject((SV*)var) && sv_derived_from((SV*)var,"P4")))
    {
	warn("Not a P4 object!" );
	return 0;
    }

    HV *	h = (HV *)SvRV( var );
    SV **	c = hv_fetch( h, CLIENT_PTR_NAME, strlen( CLIENT_PTR_NAME ),0);

    if( !c )
    {
	warn( "No '" CLIENT_PTR_NAME "' member found in P4 object!" );
	return 0;
    }

    return INT2PTR( PerlClientApi *, SvIV( *c ) );
}

static P4MergeData *
ExtractMergeData( SV *var )
{
    return INT2PTR( P4MergeData *, SvIV( SvRV( var ) ) );
}

static P4ActionMergeData *
ExtractActionMergeData( SV *var )
{
    return INT2PTR( P4ActionMergeData *, SvIV( SvRV( var ) ) );
}

static P4MapMaker *
ExtractMapMaker( SV *var )
{
    return INT2PTR( P4MapMaker *, SvIV( SvRV( var ) ) );
}

static Error *
ExtractError( SV *var )
{
    return INT2PTR( Error *, SvIV( SvRV( var ) ) );
}


/*
 * P4::Message class - for holding warnings and errors.
 */
MODULE = P4		PACKAGE = P4::Message
VERSIONCHECK: DISABLE
PROTOTYPES:	DISABLE

void
DESTROY( THIS )
	SV	*THIS

	INIT:
	    Error *	e;

	CODE:
	    e = ExtractError( THIS );
	    if( !e ) XSRETURN_UNDEF;
	    delete e;

SV *
GetId( THIS )
	SV *	THIS
	
	INIT:
	    Error *	e;
	    ErrorId *	id;
	CODE:
	    e = ExtractError( THIS );
	    if( (id = e->GetId( 0 ) ) )
	    	RETVAL = newSViv( id->UniqueCode() );
	    else
	    	XSRETURN_UNDEF;
	OUTPUT:
	    RETVAL
		
SV *
GetSeverity( THIS )
	SV *	THIS
	
	INIT:
	    Error *	e;
	CODE:
	    e = ExtractError( THIS );
	    RETVAL = newSViv( e->GetSeverity() );
	OUTPUT:
	    RETVAL

SV *
GetGeneric( THIS )
	SV *	THIS
	
	INIT:
	    Error *	e;
	CODE:
	    e = ExtractError( THIS );
	    RETVAL = newSViv( e->GetGeneric() );
	OUTPUT:
	    RETVAL

SV *
GetText( THIS )
	SV *	THIS
	
	INIT:
	    Error *	e;
	    StrBuf	b;
	CODE:
	    e = ExtractError( THIS );
	    e->Fmt( b, EF_PLAIN );
	    RETVAL = newSVpv( b.Text(), b.Length() );
	OUTPUT:
	    RETVAL

#
# P4::MergeData class - used in RunResolve().
# 
MODULE = P4		PACKAGE = P4::MergeData
VERSIONCHECK: DISABLE
PROTOTYPES:	DISABLE

void
DESTROY( THIS )
	SV	*THIS

	INIT:
	    P4MergeData *	m;

	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    delete m;

SV *
YourName( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetYourName();
	OUTPUT:
	    RETVAL

SV *
TheirName( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetTheirName();
	OUTPUT:
	    RETVAL

SV *
BaseName( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetBaseName();
	OUTPUT:
	    RETVAL

SV *
YourPath( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetYourPath();
	OUTPUT:
	    RETVAL

SV *
TheirPath( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetTheirPath();
	OUTPUT:
	    RETVAL

SV *
BasePath( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetBasePath();
	OUTPUT:
	    RETVAL

SV *
ResultPath( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetResultPath();
	OUTPUT:
	    RETVAL

SV *
MergeHint( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetMergeHint();
	OUTPUT:
	    RETVAL

SV *
RunMergeTool( THIS )
	SV 	*THIS

	INIT:
	    P4MergeData *	m;
	CODE:
	    m = ExtractMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->RunMergeTool();
	OUTPUT:
	    RETVAL


# ---------------------------------------------------------------------------
# P4::ActionMergeData class - used in RunResolve().
# ---------------------------------------------------------------------------
MODULE = P4		PACKAGE = P4::ActionMergeData
VERSIONCHECK: DISABLE
PROTOTYPES:	DISABLE

void
DESTROY( THIS )
	SV	*THIS

	INIT:
	    P4ActionMergeData *	m;

	CODE:
	    m = ExtractActionMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    delete m;
	    	    
SV *
MergeInfo( THIS )
	SV *THIS
	
	INIT:
	    P4ActionMergeData *	m;
	PPCODE:
	    m = ExtractActionMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    ST(0) = m->GetMergeInfo();
	    XSRETURN(1);	
	    	    
SV *
MergeAction( THIS )
	SV 	*THIS

	INIT:
	    P4ActionMergeData *	m;
	CODE:
	    m = ExtractActionMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetMergeAction();
	OUTPUT:
	    RETVAL
	    
SV *
YourAction( THIS )
	SV 	*THIS

	INIT:
	    P4ActionMergeData *	m;
	CODE:
	    m = ExtractActionMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetYourAction();
	OUTPUT:
	    RETVAL
	    
SV *
TheirAction( THIS )
	SV 	*THIS

	INIT:
	    P4ActionMergeData *	m;
	CODE:
	    m = ExtractActionMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetTheirAction();
	OUTPUT:
	    RETVAL
	    
SV *
Type( THIS )
	SV 	*THIS

	INIT:
	    P4ActionMergeData *	m;
	CODE:
	    m = ExtractActionMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetType();
	OUTPUT:
	    RETVAL	    
	    
SV *
MergeHint( THIS )
	SV 	*THIS

	INIT:
	    P4ActionMergeData *	m;
	CODE:
	    m = ExtractActionMergeData( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    RETVAL = m->GetMergeHint();
	OUTPUT:
	    RETVAL		 

#
# Now, we switch to the P4::Map class.
#
MODULE = P4	PACKAGE = P4::Map
VERSIONCHECK: DISABLE
PROTOTYPES:	DISABLE

SV *
new( CLASS, ... )
	char *CLASS;

	INIT:
	    HV *		stash;
	    P4MapMaker *	m;
	    I32			va_start = 1;
	    I32			argc;
	    I32			stindex;
	    I32			argindex;
	    AV *		av = 0;
	    SV *		sv = 0;
	    SV **		svp = 0;
	    I32			i;


	CODE:
	    /*
	     * Create a P4MapMaker object and stash a pointer to it
	     * in an IV.
	     */
	    m = new P4MapMaker();
	    RETVAL = newSViv( PTR2IV( m ) );

	    /* Return a blessed reference to the IV */
	    RETVAL = newRV_noinc( RETVAL );
	    stash = gv_stashpv( CLASS, TRUE );
	    sv_bless( RETVAL, stash );

	    /* Check to see if there's another argument passed */
	    argc = items - va_start;
	    stindex = va_start;

	    for ( ; argc; argc--, stindex++ )
	    {
		sv = ST( stindex );
		/* Array Ref? */
		if( SvROK( sv ) && SvTYPE( SvRV( sv ) ) == SVt_PVAV )
		{
		    av = (AV *) SvRV( sv );
		}
		/* Straight Array - possible? */
		else if( SvTYPE( sv ) == SVt_PVAV )
		{
		    av = (AV *) SvRV( sv );
		}
		/* String */
		else if( SvPOK( sv ) )
		{
		    av = 0;
		    m->Insert( sv );
		}
		else
		{
		    warn( "Skipped non-string or array parameter" );
		    continue;
		}

		if( ! av ) continue;

		for( i = 0; i <= av_len( av ); i++ )
		{
		    svp = av_fetch( av, i, 0 );

		    if( !svp )
			continue;

		    if( !SvPOK( *svp ) ) 
		    {
			warn( "Skipped non-string in array parameter..." );
			continue;
		    }
		    
		    m->Insert( *svp );
		}
	    }

	OUTPUT:
	    RETVAL

void
DESTROY( THIS )
	SV	*THIS

	INIT:
	    P4MapMaker *	m;

	CODE:
	    m = ExtractMapMaker( THIS );
	    if( !m ) XSRETURN_UNDEF;
	    delete m;


SV *
Join( map1, map2 )
	SV *	map1
	SV *	map2

	INIT:
	    P4MapMaker *	m1;
	    P4MapMaker *	m2;
	    P4MapMaker *	j;
	    HV *		stash;

	CODE:
	    m1 = ExtractMapMaker( map1 );
	    m2 = ExtractMapMaker( map2 );

	    j = P4MapMaker::Join( m1, m2 );

	    RETVAL = newSViv( PTR2IV( j ) );

	    /* Return a blessed reference to the IV */
	    RETVAL = newRV_noinc( RETVAL );
	    stash = gv_stashpv( "P4::Map", TRUE );
	    sv_bless( RETVAL, stash );
	    
	OUTPUT:
	    RETVAL
	    
void
Insert( THIS, lhs, ... )
	SV *	THIS
	SV *	lhs
	INIT:
	    P4MapMaker *	m;
	    SV *		rhs = 0;
	    I32			va_start = 2;
	    I32			argc;
	    I32			stindex;
	    I32			argindex;
	    I32			i;
	    STRLEN		len = 0;

	CODE:
	    m = ExtractMapMaker( THIS );
	    
	    /* Check to see if there's another argument passed */
	    i = argc = items - va_start;
	    stindex = va_start;

	    if ( argc )
	    {
		if( !SvPOK( ST( stindex ) ) )
		{
		    warn( "Expected string argument" );
		    XSRETURN_EMPTY;
		}

		rhs = (SV *)ST(stindex);
		m->Insert( lhs, rhs );
	    }
	    else
	    {
		m->Insert( lhs );
	    }


SV *
Reverse( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;
	    P4MapMaker *	m2;
	    SV *		rval;
	    HV *		stash;

	CODE:
	    m = ExtractMapMaker( THIS );
	    m2 = new P4MapMaker( *m );
	    m2->Reverse();

	    RETVAL = newSViv( PTR2IV( m2 ) );

	    /* Return a blessed reference to the IV */
	    RETVAL = newRV_noinc( RETVAL );
	    stash = gv_stashpv( "P4::Map", TRUE );
	    sv_bless( RETVAL, stash );
	    
	OUTPUT:
	    RETVAL

void
Clear( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;

	CODE:
	    m = ExtractMapMaker( THIS );
	    m->Clear();

SV *
Count( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;

	CODE:
	    m = ExtractMapMaker( THIS );
	    RETVAL = newSViv( m->Count() );

	OUTPUT:
	    RETVAL

SV *
IsEmpty( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;

	CODE:
	    m = ExtractMapMaker( THIS );
	    if( m->Count() )
		RETVAL = &PL_sv_no;
	    else
		RETVAL = &PL_sv_yes;

	OUTPUT:
	    RETVAL

SV *
Translate( THIS, ... )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;
	    I32			va_start = 1;
	    I32			argc;
	    I32			stindex;
	    I32			argindex;
	    I32			i;
	    SV *		string;
	    STRLEN		len = 0;
	    int			fwd = 1;

	CODE:
	    m = ExtractMapMaker( THIS );

	    argc = items - va_start;
	    stindex = va_start;

	    if( argc < 1 )
		croak("Usage: P4::Map::Translate( THIS, $string [, $fwd=1] )" );

	    if( !SvPOK( ST( stindex ) ) )
		croak("Usage: P4::Map::Translate( THIS, $string [, $fwd=1] )" );

	    string = ST( stindex++ );

	    if( argc == 2 )
	    {
		if( !SvIOK( ST( stindex ) ) )
		    croak("Usage: P4::Map::Translate( THIS, $string [, $fwd=1] )" );
		fwd = SvIV( ST( stindex ) );
	    }

	    RETVAL = m->Translate( string, fwd );
	    if( ! RETVAL )
		RETVAL = &PL_sv_undef;

	OUTPUT:
	    RETVAL
	    
SV *
Includes( THIS, string )
	SV *	THIS
	SV *	string
	INIT:
	    P4MapMaker *	m;
	    SV *		s;

	CODE:
	    RETVAL = &PL_sv_no;
	    m = ExtractMapMaker( THIS );
	    s = m->Translate( string );
	    if( s )
	    {
		sv_2mortal( s );
		RETVAL = &PL_sv_yes;
	    }
	    else
	    {
		s = m->Translate( string, 0 );
		if( s )
		{
		    sv_2mortal( s );
		    RETVAL = &PL_sv_yes;
		}
	    }

	OUTPUT:
	    RETVAL


SV *
Lhs( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;
	    AV *		lhs;
	    SV **		svp;
	    I32			i;
	    I32			wantarray = ( GIMME_V == G_ARRAY );

	PPCODE:
	    m = ExtractMapMaker( THIS );
	    lhs = m->Lhs();

	    if( wantarray )
	    {
		for( i = 0; i <= av_len( lhs ); i++ )
		{
		    svp = av_fetch( lhs, i, 0); 
		    if( !svp ) continue;
		    XPUSHs( *svp );
		}
	    }
	    else
	    {
		XPUSHs( newRV_noinc( (SV*)lhs ) );
	    }


SV *
Rhs( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;
	    AV *		rhs;
	    SV **		svp;
	    I32			i;
	    I32			wantarray = ( GIMME_V == G_ARRAY );

	PPCODE:
	    m = ExtractMapMaker( THIS );
	    rhs = m->Rhs();

	    if( wantarray )
	    {
		for( i = 0; i <= av_len( rhs ); i++ )
		{
		    svp = av_fetch( rhs, i, 0); 
		    if( !svp ) continue;
		    XPUSHs( *svp );
		}
	    }
	    else
	    {
		XPUSHs( newRV_noinc( (SV*)rhs ) );
	    }


SV *
AsArray( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;
	    AV *		a;
	    SV **		svp;
	    I32			i;
	    I32			wantarray = ( GIMME_V == G_ARRAY );

	PPCODE:
	    m = ExtractMapMaker( THIS );
	    a = m->ToA();

	    if( wantarray )
	    {
		for( i = 0; i <= av_len( a ); i++ )
		{
		    svp = av_fetch( a, i, 0); 
		    if( !svp ) continue;
		    XPUSHs( *svp );
		}
	    }
	    else
	    {
		XPUSHs( newRV_noinc( (SV*)a ) );
	    }


SV *
Dump( THIS )
	SV *	THIS
	INIT:
	    P4MapMaker *	m;

	CODE:
	    m = ExtractMapMaker( THIS );
	    RETVAL = m->Dump();

	OUTPUT:
	    RETVAL


#------------------------------------------------------------------------------
# Now switch into the P4 package
#------------------------------------------------------------------------------
MODULE = P4	PACKAGE = P4
VERSIONCHECK: DISABLE
PROTOTYPES:	DISABLE

SV *
new( CLASS )
	char *CLASS;

	INIT:
	    SV *		iv;
	    HV *		myself;
	    HV *		stash;
	    PerlClientApi *	c;

	CODE:
	    /*
	     * Create a PerlClientApi object and stash a pointer to it
	     * in an HV.
	     */
	    c = new PerlClientApi( NULL );
	    iv = newSViv( PTR2IV( c ) );

	    myself = newHV();
	    hv_store( myself, CLIENT_PTR_NAME, strlen( CLIENT_PTR_NAME ), iv, 0 );

	    /* Return a blessed reference to the HV */
	    RETVAL = newRV_noinc( (SV *)myself );
	    stash = gv_stashpv( CLASS, TRUE );
	    sv_bless( (SV *)RETVAL, stash );

	OUTPUT:
	    RETVAL

void
DESTROY( THIS )
	SV	*THIS

	INIT:
	    PerlClientApi	*c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    delete c;

SV *
Identify()
	CODE:
	    RETVAL = PerlClientApi::Identify();

	OUTPUT:
	    RETVAL

SV *
IsConnected( THIS )
	SV	*THIS
	INIT:
	    PerlClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = newSViv( c->Connected() );
	OUTPUT:
	    RETVAL

SV *
IsIgnored( THIS, path )
	SV	 *THIS
	char *path
	
	INIT:
	    PerlClientApi	*c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = newSViv( c->IsIgnored( path ) );
	OUTPUT:
	    RETVAL

void
Disconnect( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->Disconnect();

SV *
GetApiLevel( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetApiLevel();
	OUTPUT:
	    RETVAL

SV *
GetCharset( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetCharset();
	OUTPUT:
	    RETVAL

SV *
GetClient( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi*	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetClient();
	OUTPUT:
	    RETVAL

SV *
GetCwd( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetCwd();
	OUTPUT:
	    RETVAL

SV *
GetEnv( THIS, var )
	SV 	*THIS
	const char *var

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetEnv( var ); 
	OUTPUT:
	    RETVAL

SV *
GetHost( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetHost();
	OUTPUT:
	    RETVAL

SV *
GetHandler( THIS )
	SV *THIS
	
	INIT:
	    PerlClientApi *	c;
	PPCODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    ST(0) = c->GetHandler();
	    XSRETURN(1);		

SV *
GetProgress( THIS )
	SV *THIS
	
	INIT:
	    PerlClientApi *	c;
	PPCODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    ST(0) = c->GetProgress();
	    XSRETURN(1);	
	    
SV *
GetLanguage( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetLanguage();
	OUTPUT:
	    RETVAL


SV *
GetMaxResults( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetMaxResults();
	OUTPUT:
	    RETVAL

SV *
GetMaxScanRows( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetMaxScanRows();
	OUTPUT:
	    RETVAL

SV *
GetMaxLockTime( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetMaxLockTime();
	OUTPUT:
	    RETVAL


SV *
GetPassword( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetPassword();
	OUTPUT:
	    RETVAL

SV *
GetPort( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetPort();
	OUTPUT:
	    RETVAL

SV *
GetProg( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetProg();
	OUTPUT:
	    RETVAL

SV *
GetTicketFile( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetTicketFile();
	OUTPUT:
	    RETVAL

SV *
GetIgnoreFile( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetIgnoreFile();
	OUTPUT:
	    RETVAL

SV *
GetEnviroFile( THIS )
    SV 	*THIS

    INIT:
        PerlClientApi *	c;
    CODE:
        c = ExtractClient( THIS );
        if( !c ) XSRETURN_UNDEF;
        RETVAL = c->GetEnviroFile();
    OUTPUT:
        RETVAL

SV *
GetUser( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetUser();
	OUTPUT:
	    RETVAL

SV *
GetVersion( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetVersion();
	OUTPUT:
	    RETVAL

SV *
Connect( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->Connect();
	OUTPUT:
	    RETVAL

SV *
P4ConfigFile( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi*	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetConfig();
	OUTPUT:
	    RETVAL

SV *
_Run( THIS, cmd, ... )
	SV *THIS
	SV *cmd
	INIT:
	    PerlClientApi *	c;

	    I32			va_start = 2;
	    I32			debug = 0;
	    I32			argc;
	    I32			stindex;
	    I32			argindex;
	    I32			i;
	    I32			wantarray = ( GIMME_V == G_ARRAY );
	    STRLEN		len = 0;
	    char *		currarg;
	    char **		cmdargs = NULL;
	    SV *		sv;
	    SV **		svp;
	    AV *		results;

	PPCODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    debug = c->GetDebugLevel();

	    /*
	     * First check that the client has been initialised. Otherwise
	     * the result tends to be a SEGV
	     */
	    if ( !c->Connected() )
	    {
		warn("P4::Run() - Not connected. Call P4::Connect() first" );
		XSRETURN_UNDEF;
	    }

	    i = argc = items - va_start;
	    if ( argc )
	    {
		New( 0, cmdargs, argc, char * );
		for ( stindex = va_start, argindex = 0; 
			i; 
			i--, stindex++ )
		{
		    if ( SvPOK( ST(stindex) ) )
		    {
			currarg = SvPV( ST(stindex), len );
			cmdargs[argindex++] =  currarg ;
		    }
		    else if ( SvIOK( ST(stindex) ) )
		    {
			/*
			 * Be friendly and convert numeric args to 
		         * char *'s. Use Perl to reclaim the storage.
		         * automatically by declaring them as mortal SV's
		         */
			STRLEN	len;
			sv = newSVpv( form("%d", (int)SvIV( ST(stindex))),0 );
			sv = sv_2mortal( sv );
			currarg = SvPV( sv, len );
			cmdargs[argindex++] = currarg;
		    }
		    else if( SvROK( ST(stindex) ) )
		    {
			if( sv_derived_from( ST(stindex), "P4::Resolver" ) )
			{
			    c->SetResolver( ST(stindex) );
			    argc--;
			}
			else
			{
			    warn( "Invalid argument to P4::Run. Aborting command" );
			    XSRETURN_UNDEF;
			}
		    }
		    else if( SvTYPE( ST(stindex) ) == SVt_PVLV )
		    {
			/*
			 * In theory, this is tainted data
			 */
		        warn( "Argument %d to P4::Run() is tainted!",
					(int) argindex );
		    }
		    else
		    {
			/*
		         * Can't handle other arg types
		         */
			PerlIO_stdoutf( "\tArg[ %d ] unknown type %d\n", 
				(int) argindex, 
				SvTYPE( ST(stindex) ) );
		        warn( "Invalid argument to P4::Run. Aborting command" );
			XSRETURN_UNDEF;
		    }
		}
	    }

	    len = 0;
	    currarg = SvPV( cmd, len );
	    
	    /*
             * Run the command, and then convert the output into
             * a LIST if the caller is in array context. In scalar
	     * context, we return an array reference.
             */ 
	    results = c->Run( currarg, argc, cmdargs );
	    if( wantarray )
	    {
		for( i = 0; i <= av_len( results ); i++ )
		{
		    svp = av_fetch( results, i, 0); 
		    if( !svp ) continue;
		    XPUSHs( *svp );
		}
	    }
	    else
	    {
		XPUSHs( newRV_noinc( (SV*)results ) );
	    }
	    if ( cmdargs )Safefree( cmdargs );

SV *
Debug( THIS, ... )
	SV * 	THIS

	INIT:
	    PerlClientApi *	c;

	    I32			va_start = 1;
	    int			level = 0;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    if( items > va_start )
	    {
		// Setting the debug level
		if( SvPOK( ST( va_start ) ) )
		{
		    level = atoi( SvPV( ST( va_start ), PL_na ) );
		}
		else if( SvIOK( ST( va_start ) ) )
		{
		    level = SvIV( ST( va_start ) );
		}
		else
		{
		    warn( "Argument to P4::Debug() must be an integer" );
		    XSRETURN_UNDEF;
		}
		c->SetDebugLevel( level );
	    }
	    RETVAL = newSViv( c->GetDebugLevel() );

	OUTPUT:
	    RETVAL
	    
void
Errors( THIS )
	SV * 	THIS

	INIT:
	    PerlClientApi *	c;
	    AV *		a;
	    SV **		s;
	    int			i;

	PPCODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    a = c->GetErrors();
	    for( i = 0; i <= av_len( a ); i++ )
	    {
		s = av_fetch( a, i, 0); 
		if( !s ) continue;
		XPUSHs( *s );
	    }

I32
ErrorCount( THIS )
	SV * 	THIS

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->GetErrorCount();
	OUTPUT:
	    RETVAL
	
SV *
FormatSpec( THIS, type, hash )
	SV *	THIS
	SV *	type
	SV *	hash

	INIT:
	    PerlClientApi *	c;
	    HV *		h;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    if( SvROK( hash ) )
		hash = SvRV( hash );

	    if( SvTYPE( hash ) == SVt_PVHV )
	    {
		h = (HV*) hash;
	    }
	    else
	    {
		warn( "Argument to FormatSpec must be hashref" );
		XSRETURN_UNDEF;
	    }

	    RETVAL = c->FormatSpec( SvPV( type, PL_na ), h );
	OUTPUT:
	    RETVAL

I32
IsStreams( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->IsStreams();
	OUTPUT:
	    RETVAL

I32
IsTrack( THIS )
	SV 	*THIS

	INIT:
	    PerlClientApi *	c;
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->IsTrack();
	OUTPUT:
	    RETVAL

I32
IsTagged( THIS )
	SV *	THIS

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = c->IsTagged();
	OUTPUT:
	    RETVAL

void
Messages( THIS )
	SV * 	THIS
	
	INIT:
		PerlClientApi *	c;
		AV *			a;
		SV **			s;
		int				i;
	
	PPCODE:
		c = ExtractClient( THIS );
		if( !c ) XSRETURN_UNDEF;
		a = c->GetMessages();
		for( i = 0; i <= av_len( a ); i++ )
		{
			s = av_fetch( a, i, 0); 
			if( !s ) continue;
			XPUSHs( *s );
		}

SV *
ParseSpec( THIS, type, buf )
	SV *	THIS
	SV *	type
	SV *	buf

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    RETVAL = c->ParseSpec( SvPV( type, PL_na ), SvPV( buf, PL_na ) );
	OUTPUT:
	    RETVAL

SV *
DefineSpec( THIS, type, spec )
	SV *	THIS
	SV *	type
	SV *	spec

	INIT:
	    PerlClientApi	*c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    RETVAL = c->DefineSpec( SvPV( type, PL_na ), SvPV( spec, PL_na ) );
	OUTPUT:
	    RETVAL

SV *
ServerCaseSensitive( THIS )
	SV *	THIS

	INIT:
	    PerlClientApi	*c;
	    int			 t;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    t = c->ServerCaseSensitive();
	    if( t < 0 )
	    {
		warn( "P4::ServerCaseSensitive(): Not connected to a Perforce Server." );
		XSRETURN_UNDEF;
	    }
	    RETVAL = newSViv( t );

	OUTPUT:
	    RETVAL

SV *
ServerUnicode( THIS )
	SV *	THIS

	INIT:
	    PerlClientApi	*c;
	    int			 t;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    t = c->ServerUnicode();
	    if( t < 0 )
	    {
		warn( "P4::ServerUnicode(): Not connected to a Perforce Server." );
		XSRETURN_UNDEF;
	    }
	    RETVAL = newSViv( t );

	OUTPUT:
	    RETVAL

SV *
ServerLevel( THIS )
	SV *	THIS

	INIT:
	    PerlClientApi	*c;
	    int			t;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    t = c->GetServerLevel();
	    if( t < 0 )
	    {
		warn( "P4::GetServerLevel(): Not connected to a Perforce Server." );
		XSRETURN_UNDEF;
	    }

	    RETVAL = newSViv( c->GetServerLevel() );

	OUTPUT:
	    RETVAL


void
SetApiLevel( THIS,  level )
	SV *	THIS
	SV *	level

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    if( !SvIOK( level ) )
	    {
		warn( "API level must be an integer" );
		XSRETURN_UNDEF;
	    }

	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;

	    c->SetApiLevel( SvIV( level ) );


void
SetCharset( THIS,  charset )
	SV *	THIS
	char *	charset

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetCharset( charset );


void
SetClient( THIS, clientName )
	SV	*THIS
	char 	*clientName

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetClient( clientName );

SV *
Init( CLASS, args )
	char *	    CLASS
	HV *        args

    INIT:
        SV              * iv;
        HV              * myself;
        HV              * stash;
        P4DvcsClient    * dv;

        PerlClientApi   * c;

    CODE:
        /*
         * Create a P4DvcsClient object
         */
        dv = new P4DvcsClient();
        if( !dv ) XSRETURN_UNDEF;
        dv->Init( args );

	    /*
	     * Fetch a PerlClientApi object and stash a pointer to it
	     * in an HV.
	     */
        c = new PerlClientApi( args );
        iv = newSViv( PTR2IV( c ) );

        myself = newHV();
        hv_store( myself, CLIENT_PTR_NAME, strlen( CLIENT_PTR_NAME ), iv, 0 );

        /* Return a blessed reference to the HV */
        RETVAL = newRV_noinc( (SV *)myself );
        stash = gv_stashpv( CLASS, TRUE );
        sv_bless( (SV *)RETVAL, stash );

    OUTPUT:
        RETVAL


SV *
Clone( CLASS, args )
	char *	    CLASS
	HV *        args

    INIT:
        SV              * iv;
        HV              * myself;
        HV              * stash;
        P4DvcsClient    * dv;

        PerlClientApi   * c;

    CODE:
        /*
         * Create a P4DvcsClient object
         */
        dv = new P4DvcsClient();
        if( !dv ) XSRETURN_UNDEF;
        dv->Clone( args );

	    /*
	     * Fetch a PerlClientApi object and stash a pointer to it
	     * in an HV.
	     */
        c = new PerlClientApi( args );
        iv = newSViv( PTR2IV( c ) );

        myself = newHV();
        hv_store( myself, CLIENT_PTR_NAME, strlen( CLIENT_PTR_NAME ), iv, 0 );

        /* Return a blessed reference to the HV */
        RETVAL = newRV_noinc( (SV *)myself );
        stash = gv_stashpv( CLASS, TRUE );
        sv_bless( (SV *)RETVAL, stash );

    OUTPUT:
        RETVAL

void
_SetCwd( THIS, cwd )
	SV *	THIS
	char *	cwd

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetCwd( cwd );

void
SetEnv( THIS, var, val )
	SV *	THIS
	const char *var
	const char *val
	
	INIT:
		PerlClientApi * c;
		
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetEnv( var, val );		

void
SetHost( THIS, hostname )
	SV *	THIS
	char *	hostname

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetHost( hostname );

void
SetInput( THIS, value )
	SV *	THIS
	SV *	value

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetInput( value );

void
ClearHandler( THIS )
	SV *	THIS
	
	INIT:
		PerlClientApi * c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->ClearHandler();		

void
SetHandler( THIS, value )
	SV *	THIS
	SV *	value
	
	INIT:
		PerlClientApi * c;
		
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetHandler( value );		

SV *
SetProgress( THIS, value )
	SV *	THIS
	SV *	value
	
	INIT:
	    PerlClientApi *	c;
	    
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetProgress( value );	

void
SetLanguage( THIS, lang )
	SV *	THIS
	const char * lang
	INIT:
	    PerlClientApi *	c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetLanguage( lang );

void
SetMaxResults( THIS, value )
	SV *	THIS
	int 	value
	INIT:
	    PerlClientApi *	c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetMaxResults( value );


void
SetMaxScanRows( THIS, value )
	SV *	THIS
	int 	value
	INIT:
	    PerlClientApi *	c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetMaxScanRows( value );

void
SetMaxLockTime( THIS, value )
	SV *	THIS
	int 	value
	INIT:
	    PerlClientApi *	c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetMaxLockTime( value );


void
SetPassword( THIS, password )
	SV *	THIS
	char *	password
	INIT:
	    PerlClientApi *	c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetPassword( password );


void
SetPort( THIS,  address )
	SV *	THIS
	char *	address

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    if( c->Connected() )
		warn( "Can't change port once you've connected." );
	    else
		c->SetPort( address );

void
SetProg( THIS,  name )
	SV *	THIS
	char *	name

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetProg( name );

void
SetProtocol( THIS,  var, val )
	SV *	THIS
	char *	var
	char *  val

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetProtocol( var, val );


void
SetStreams( THIS, flag )
        SV *    THIS
        int     flag

        INIT:
            PerlClientApi *     c;

        CODE:
            c = ExtractClient( THIS );
            if( !c ) XSRETURN_UNDEF;
	    c->SetStreams( flag );

void
SetTicketFile( THIS,  path )
	SV *	THIS
	char *	path

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetTicketFile( path );

void
SetIgnoreFile( THIS,  path )
	SV *	THIS
	char *	path

	INIT:
	    PerlClientApi	*c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetIgnoreFile( path );

void
SetEnviroFile( THIS, file )
	SV *	THIS
	char *	file

	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetEnviroFile( file );

I32
SetTrack( THIS, flag )
        SV *    THIS
        int     flag

        INIT:
            PerlClientApi *     c;

        CODE:
            c = ExtractClient( THIS );
            if( !c ) XSRETURN_UNDEF;
            RETVAL = 0;
            if( c->Connected() )
            	warn( "Can't enable/disable performance tracking once you've connected.");
            else
		RETVAL = c->SetTrack( flag );

	OUTPUT:
	    RETVAL

void
SetUser( THIS, username )
	SV *	THIS
	char *	username

	INIT:
	    PerlClientApi *	c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetUser( username );

void
SetVersion( THIS, version )
	SV *	THIS
	char *	version

	INIT:
	    PerlClientApi *	c;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    c->SetVersion( version );

SV *
Tagged( THIS, flag, ... )
	SV *	THIS
	int	flag

	INIT:
	    PerlClientApi	*c;
	    I32			va_start = 2;
	    I32			argc;
	    I32			stindex;
	    SV *		cv;
	    int			old_tagged;
	
	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) return;

	    /* Check to see if there's another argument passed */
	    argc = items - va_start;

	    if( !argc )
	    {
	        c->Tagged( flag );
	        return;
	    }
		
	    stindex = va_start;
	    cv = ST( stindex );

	    old_tagged = c->IsTagged();

	    dSP;
	    ENTER;
	    SAVETMPS;
	    PUSHMARK( sp );

	    // Perl will die for us if the user has passed something other
	    // than a CV here. No need for us to check.
	    c->Tagged( flag );
	    PUTBACK ;
	    perl_call_sv( cv, G_SCALAR );

	    // Cleanup
	    SPAGAIN;
	    RETVAL = newSVsv(POPs);
	    PUTBACK;
	    FREETMPS;
	    LEAVE;

	    c->Tagged( old_tagged );

	OUTPUT:
	    RETVAL



AV *
TrackOutput( THIS )
	SV *	THIS

	INIT:
	    PerlClientApi *	c;
	    AV *		output;
	    I32			i;
	    SV**		svp;
	    I32			wantarray = ( GIMME_V == G_ARRAY );
	    
	PPCODE:
	    /*
	     * This function needs to return a list or an array ref, so
	     * the return stack is built manually.
	     */
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    output = c->GetTrackOutput();
    	    /*
             * Return a LIST if the caller is in array context. In scalar
	     * context, we return an array reference.
             */ 
	    if( wantarray )
	    {
		for( i = 0; i <= av_len( output ); i++ )
		{
		    svp = av_fetch( output, i, 0); 
		    if( !svp ) continue;
		    XPUSHs( *svp );
		}
	    }
	    else
	    {
		XPUSHs( newRV_noinc( (SV*)output ) );
	    }

SV *
WarningCount( THIS )
	SV *	THIS

    	INIT:
	    PerlClientApi *	c;

	CODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    RETVAL = newSViv( c->GetWarningCount() );

	OUTPUT:
	    RETVAL

void
Warnings( THIS )
	SV * 	THIS

	INIT:
	    PerlClientApi *	c;
	    AV *		a;
	    SV **		s;
	    int			i;

	PPCODE:
	    c = ExtractClient( THIS );
	    if( !c ) XSRETURN_UNDEF;
	    a = c->GetWarnings();
	    for( i = 0; i <= av_len( a ); i++ )
	    {
		s = av_fetch( a, i, 0); 
		if( !s ) continue;
		XPUSHs( *s );
	    }


BOOT:
/* define global VERSION constant */
SV *sv = get_sv( "P4::VERSION", GV_ADD );
sv_setpv( sv, ID_REL );
sv = get_sv( "P4::PATCHLEVEL", GV_ADD );
sv_setpv( sv, ID_PATCH );
sv = get_sv( "P4::OS", GV_ADD );
sv_setpv( sv, ID_OS );
/* 
 * These are not needed but they squelch a rather ugly warning about
 * the variables being used only once 
 */
sv = get_sv( "P4::VERSION", GV_ADD );
sv = get_sv( "P4::PATCHLEVEL", GV_ADD );
sv = get_sv( "P4::OS", GV_ADD );
