/*******************************************************************************

 Copyright (c) 2012, Perforce Software, Inc.  All rights reserved.

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
 * Name		: p4clientprogress.cpp
 *
 * Author	: Paul Allen <perl@pallen.co.uk> or <pallen@perforce.com>
 *
 * Description	: Subclass for ClientProgress used by Perl ClientProgress.
 * Allows Perforce API to indicate progress of calls to P4Perl
 *
 ******************************************************************************/
#include <clientapi.h>
#include <spec.h>
#include <diff.h>
#include "perlheaders.h"
#include "p4result.h"
#include "p4perldebug.h"
#include "clientprog.h"
#include "p4clientprogress.h"

P4ClientProgress::P4ClientProgress(SV * prog, int type) {
	debug = 0;
	progress = prog;

	Init(type);
}

P4ClientProgress::~P4ClientProgress() {

}

void P4ClientProgress::Init(int type) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4ClientProgress::Init]: %d\n", type);

	// Nasty perl stuff to call 'method' on the 'iterator' class passing 'data'
	dSP;

	// setup 'temporaries'
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(progress);
	XPUSHs(sv_2mortal(newSViv(type)));
	PUTBACK;

	perl_call_method("Init", G_SCALAR);

	// cleanup 'temporaries'
	FREETMPS;
	LEAVE;
}


void P4ClientProgress::Description(const StrPtr *desc, int units) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4ClientProgress::Description]: %s, %d\n",
				desc->Text(), units);

	// Nasty perl stuff to call 'method' on the 'iterator' class passing 'data'
	dSP;

	// setup 'temporaries'
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(progress);
	XPUSHs(sv_2mortal(newSVpv(desc->Text(), desc->Length())));
	XPUSHs(sv_2mortal(newSViv(units)));
	PUTBACK;

	perl_call_method("Description", G_SCALAR);

	// cleanup 'temporaries'
	FREETMPS;
	LEAVE;
}

void P4ClientProgress::Total(long total) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4ClientProgress::Total]: %ld\n", total);

	// Nasty perl stuff to call 'method' on the 'iterator' class passing 'data'
	dSP;

	// setup 'temporaries'
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(progress);
	XPUSHs(sv_2mortal(newSViv(total)));
	PUTBACK;

	perl_call_method("Total", G_SCALAR);

	// cleanup 'temporaries'
	FREETMPS;
	LEAVE;
}

int P4ClientProgress::Update(long update) {
	int position = 0;

	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4ClientProgress:Update]: %ld\n", update);

	// Nasty perl stuff to call 'method' on the 'iterator' class passing 'data'
	dSP;
	int a;

	// setup 'temporaries'
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(progress);
	XPUSHs(sv_2mortal(newSViv(update)));
	PUTBACK;

	a = perl_call_method("Update", G_SCALAR);
	SPAGAIN; // refresh stack pointer

	if (a >= 1)
		position = POPi; // pop integer
	PUTBACK;

	// cleanup 'temporaries'
	FREETMPS;
	LEAVE;

	return position;
}

void P4ClientProgress::Done(int fail) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4ClientProgress::Done]: %d\n", fail);

	// Nasty perl stuff to call 'method' on the 'iterator' class passing 'data'
	dSP;

	// setup 'temporaries'
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(progress);
	XPUSHs(sv_2mortal(newSViv(fail)));
	PUTBACK;

	perl_call_method("Done", G_SCALAR);

	// cleanup 'temporaries'
	FREETMPS;
	LEAVE;
}
