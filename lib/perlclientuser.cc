/*******************************************************************************

 Copyright (c) 2001-2012, Perforce Software, Inc.  All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1.  Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.

 2.  Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTR
 IBUTORS "AS IS"
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
 * Name		: perlclientuser.cc
 *
 * Author	: Tony Smith <tony@perforce.com> or <tony@smee.org>
 * 			: Paul Allen <pallen@perforce.com> or <perl@pallen.co.uk>
 *
 * Description	: Perl bindings for the Perforce API. User interface class
 * 		  for getting Perforce results into Perl.
 *
 ******************************************************************************/
#include <clientapi.h>
#include <clientprog.h>
#include <spec.h>
#include <diff.h>
#include "perlheaders.h"
#include "p4result.h"
#include "p4perldebug.h"
#include "specmgr.h"
#include "p4mergedata.h"
#include "p4actionmerge.h"
#include "p4clientprogress.h"
#include "perlclientuser.h"

/*******************************************************************************
 * PerlClientUser - the user interface part. Gets responses from the Perforce
 * server, and converts the data to Perl format for returning to the caller.
 ******************************************************************************/

PerlClientUser::PerlClientUser(SpecMgr *s) {
	debug = 0;
	input = 0;
	track = 0;
	specMgr = s;
	alive = 1;
	handler = 0;
	progress = 0;
}


PerlClientUser::~PerlClientUser() {
//	if (progress) {
//		delete progress;
//	}
}

void PerlClientUser::Reset() {
	results.Reset();
	lastSpecDef.Clear();
	// Leave input alone.

	alive = 1; // yes, we want data from the server
}

void PerlClientUser::Finished() {
	// Reset input coz we should be done with it now. Decrement the ref count
	// so it can be reclaimed.
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::Finished] Cleaning up saved input\n");

	if (input) {
		sv_2mortal(input);
		input = 0;
	}
	resolver = 0;
	handler = 0; // should I use: &PL_sv_undef?
}

/*
 * BIT masks
 */
static const int REPORT = 0;
static const int HANDLED = 1;
static const int CANCEL = 2;
/*			 A:O
 * returns 	[0:0]	0 = added to (O) output
 *			[0:1]	1 = dealt with (don't add to output)
 *			[1:0]	2 = mark for (A) abort (add to (O) output)
 *			[1:1]	3 = mark for (A) abort (don't to output)
 */

bool PerlClientUser::CallOutputMethod(const char * method, SV * data) {
	int answer = REPORT;

	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser:CallOutputMethod]: %s \n", method);

	if (!handler) {
		warn("No P4::Handler object set. Aborting");
		return true;
	}

	// Nasty perl stuff to call 'method' on the 'iterator' class passing 'data'
	dSP;
	int a;

	// setup 'temporaries'
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	XPUSHs(handler);
	XPUSHs(data);
	PUTBACK;

	a = perl_call_method(method, G_SCALAR);
	SPAGAIN; // refresh stack pointer

	if (a >= 1)
		answer = POPi; // pop integer
	PUTBACK;

	// cleanup 'temporaries'
	FREETMPS;
	LEAVE;

	if (answer > 3) {
		// exception: bad value
		alive = 0;
		warn("P4::Handler method return value is out of range");
	} else {
		if (answer & CANCEL) {
			alive = 0;
		}
	}

	return ((answer & HANDLED) == 0);
}

void PerlClientUser::ProcessOutput(const char * method, SV * data) {
	if (handler) {
		if (CallOutputMethod(method, data)) {
			results.AddOutput(data);
			if (P4PERL_DEBUG_FLOW)
				PerlIO_stdoutf(
						"[PerlClientUser:ProcessOutput]: Handler + Output\n");
		}
	} else
		results.AddOutput(data);
}

void PerlClientUser::ProcessMessage(Error *e) {
	if (handler) {
		if (CallOutputMethod("OutputMessage", (SV *) e)) {
			results.AddMessage(e);
		}
	} else
		results.AddMessage(e);
}

void PerlClientUser::Message(Error *e) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser:Message]: Received message\n");

	results.AddMessage(e);
}

void PerlClientUser::OutputText(const char *data, int length) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::OutputText]: Received %d bytes\n",
				length);

	if (track && length > 3 && data[0] == '-' && data[1] == '-'
			&& data[2] == '-' && data[3] == ' ') {
		int p = 4;
		for (int i = 4; i < length; ++i) {
			if (data[i] == '\n') {
				if (i > p) {
					results.AddTrack(newSVpv(data + p, i - p));
					p = i + 5;
				} else {
					// this was not track data after all,
					// try to rollback the damage done
					results.AddOutput(newSVpv(data, length));
					results.DeleteTrack();

					return;
				}
			}
		}
	} else {
		ProcessOutput("OutputText", newSVpv(data, length));
	}
}

void PerlClientUser::OutputInfo(char level, const char *data) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::OutputInfo]: Received data\n");

	ProcessOutput("OutputInfo", newSVpv(data, 0));
}

void PerlClientUser::OutputBinary(const char *data, int length) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::OutputBinary]: Received %d bytes\n",
				length);

	//
	// Binary is just stored in a string. Since the char * version of
	// P4Result::AddOutput() assumes it can strlen() to find the length,
	// we'll make the String object here.
	//
	ProcessOutput("OutputBinary", newSVpv(data, length));
}

void PerlClientUser::OutputStat(StrDict *values) {
	StrPtr * spec = values->GetVar("specdef");
	StrPtr * data = values->GetVar("data");
	StrPtr * sf = values->GetVar("specFormatted");
	StrDict * dict = values;
	SpecDataTable specData;
	Error e;

	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf(
				"[PerlClientUser::OutputStat]: Received tagged output\n");

	//
	// Determine whether or not the data we've got contains a spec in one form
	// or another. 2000.1 -> 2005.1 servers supplied the form in a data variable
	// and we use the spec variable to parse the form. 2005.2 and later servers
	// supply the spec ready-parsed but set the 'specFormatted' variable to tell
	// the client what's going on. Either way, we need the specdef variable set
	// to enable spec parsing.
	//
	int isspec = spec && (sf || data);

	//
	// Save the spec definition for later
	//
	if (spec)
		specMgr->AddSpecDef(cmd.Text(), spec->Text());

	if (spec && data) {
		// 2000.1 -> 2005.1 server's handle tagged form output by supplying the
		// form as text in the 'data' variable. We need to convert it to a
		// P4::Spec object using the supplied spec.

		if (P4PERL_DEBUG_FORMS)
			PerlIO_stdoutf("[PerlClientUser::OutputStat]: Parsing form\n");

		// Parse up the form. Use the ParseNoValid() interface to prevent
		// errors caused by the use of invalid defaults for select items in
		// jobspecs.

#if P4API_VERSION >= 513538
		Spec s(spec->Text(), "", &e);
#else
		Spec s(spec->Text(), "");
#endif
		if (!e.Test())
			s.ParseNoValid(data->Text(), &specData, &e);
		if (e.Test()) {
			HandleError(&e);
			return;
		}
		dict = specData.Dict();
	}

	//
	// If what we've got is a parsed form, then we'll convert it to a P4::Spec
	// object. Otherwise it's a plain hash.
	//
	SV * r = 0;

	if (isspec) {
		if (P4PERL_DEBUG_FORMS)
			fprintf(
					stderr,
					"[PerlClientUser::OutputStat]: Converting to P4::Spec object\n");
		r = specMgr->StrDictToSpec(dict, spec);
	} else {
		if (P4PERL_DEBUG_FORMS)
			fprintf(stderr,
					"[PerlClientUser::OutputStat]: Converting to hash\n");
		r = specMgr->StrDictToHash(dict);
	}

	ProcessOutput("OutputStat", r);
}

/*
 * Diff support for Perl API. Since the Diff class only writes its output
 * to files, we run the requested diff putting the output into a temporary
 * file. Then we read the file in and add its contents line by line to the 
 * results.
 */

void PerlClientUser::Diff(FileSys *f1, FileSys *f2, int doPage, char *diffFlags,
		Error *e) {

	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::Diff]: Comparing files\n");

	//
	// Duck binary files. Much the same as ClientUser::Diff, we just
	// put the output into Perl space rather than stdout.
	//
	if (!f1->IsTextual() || !f2->IsTextual()) {
		if (f1->Compare(f2, e))
			results.AddOutput(newSVpv("(... files differ ...)", 0));
		return;
	}

	// Time to diff the two text files. Need to ensure that the
	// files are in binary mode, so we have to create new FileSys
	// objects to do this.

	FileSys *f1_bin = FileSys::Create(FST_BINARY);
	FileSys *f2_bin = FileSys::Create(FST_BINARY);
	FileSys *t = FileSys::CreateGlobalTemp(f1->GetType());

	f1_bin->Set(f1->Name());
	f2_bin->Set(f2->Name());

	{
		//
		// In its own block to make sure that the diff object is deleted
		// before we delete the FileSys objects.
		//
#ifndef OS_NEXT
		::
		#endif
		Diff d;

		d.SetInput(f1_bin, f2_bin, diffFlags, e);
		if (!e->Test())
			d.SetOutput(t->Name(), e);
		if (!e->Test())
			d.DiffWithFlags(diffFlags);
		d.CloseOutput(e);

		// OK, now we have the diff output, read it in and add it to
		// the output.
		if (!e->Test())
			t->Open(FOM_READ, e);
		if (!e->Test()) {
			StrBuf b;
			while (t->ReadLine(&b, e))
				results.AddOutput(newSVpv(b.Text(), b.Length()));
		}
	}

	delete t;
	delete f1_bin;
	delete f2_bin;

	if (e->Test())
		HandleError(e);
}

/*
 * Resolve support. This sucker works by calling a method on a stored
 * instance of a class - the method is called once for each resolve
 * and returns the merge answer: "am", "at", "ay", etc.
 */
int PerlClientUser::Resolve(ClientMerge *m, Error *e) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::Resolve(Action)]: Resolving... \n");

	//
	// If no resolver has been set, abort the resolve...
	//
	if (!resolver) {
		warn("No P4::Resolver object supplied. Aborting resolve");
		return CMS_QUIT;
	}

	//
	// First detect what the merger thinks the result ought to be
	//
	StrBuf t;
	MergeStatus autoMerge = m->AutoResolve(CMF_FORCE);

	// Now convert that to a string;
	switch (autoMerge) {
	case CMS_QUIT:
		t = "q";
		break;
	case CMS_SKIP:
		t = "s";
		break;
	case CMS_MERGED:
		t = "am";
		break;
	case CMS_EDIT:
		t = "e";
		break;
	case CMS_YOURS:
		t = "ay";
		break;
	case CMS_THEIRS:
		t = "at";
		break;
	}

	SV * mergeData = MkMergeData(m, t);

	StrBuf reply;
	for (int loop = 0; loop < 10; loop++) {
		int n;

		//
		// Now call the resolver, and pass down the mergeData object
		// so they can see what's going on.
		//
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(sp);

		XPUSHs(resolver);
		XPUSHs(mergeData);

		PUTBACK;

		reply.Clear();
		n = perl_call_method("Resolve", G_SCALAR);

		SPAGAIN;

		if (n >= 1)
			reply = POPp;

		// Cleanup
		PUTBACK;
		FREETMPS;
		LEAVE;

		if (!reply.Length())
			continue;
		else if (reply == "ay")
			return CMS_YOURS;
		else if (reply == "at")
			return CMS_THEIRS;
		else if (reply == "am")
			return CMS_MERGED;
		else if (reply == "ae")
			return CMS_EDIT;
		else if (reply == "s")
			return CMS_SKIP;
		else if (reply == "q")
			return CMS_QUIT;
		else
			warn("Invalid 'p4 resolve' response.");

	}

	warn("Aborting resolve after 10 attempts");
	return CMS_QUIT;
}

/*
 * Action resolve support.
 */
int PerlClientUser::Resolve(ClientResolveA *m, int preview, Error *e) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::Resolve]: Resolving... \n");

	//
	// If no resolver has been set, abort the resolve...
	//
	if (!resolver) {
		warn("No P4::Resolver (action) object supplied. Aborting resolve");
		return CMS_QUIT;
	}

	//
	// First detect what the merger thinks the result ought to be
	//
	StrBuf t;
	MergeStatus autoMerge = m->AutoResolve(CMF_FORCE);

	// Now convert that to a string;
	switch (autoMerge) {
	case CMS_QUIT:
		t = "q";
		break;
	case CMS_SKIP:
		t = "s";
		break;
	case CMS_MERGED:
		t = "am";
		break;
	case CMS_EDIT:
	    t = "e";
	    break;
	case CMS_YOURS:
		t = "ay";
		break;
	case CMS_THEIRS:
		t = "at";
		break;
	}

	SV * mergeData = MkActionMergeData(m, t);

	StrBuf reply;
	for (int loop = 0; loop < 10; loop++) {
		int n;

		//
		// Now call the resolver, and pass down the mergeData object
		// so they can see what's going on.
		//
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(sp);

		XPUSHs(resolver);
		XPUSHs(mergeData);

		PUTBACK;

		reply.Clear();
		n = perl_call_method("ActionResolve", G_SCALAR);

		SPAGAIN;

		if (n >= 1)
			reply = POPp;

		// Cleanup
		PUTBACK;
		FREETMPS;
		LEAVE;

		if (!reply.Length())
			continue;
		else if (reply == "ay")
			return CMS_YOURS;
		else if (reply == "at")
			return CMS_THEIRS;
		else if (reply == "am")
			return CMS_MERGED;
		else if (reply == "ae")
        	return CMS_EDIT;
		else if (reply == "s")
			return CMS_SKIP;
		else if (reply == "q")
			return CMS_QUIT;
		else
			warn("Invalid 'p4 resolve' response.");

	}

	warn("Aborting resolve after 10 attempts");
	return CMS_QUIT;
}

/*
 * Prompt the user for input
 */
void PerlClientUser::Prompt(const StrPtr &msg, StrBuf &rsp, int noEcho,
		Error *e) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::Prompt]: Using supplied input\n");

	InputData(&rsp, e);
}

/*
 * convert input from the user into a form digestible to Perforce. This
 * involves either (a) converting any supplied hash to a Perforce form, or
 * (b) reading whatever we were given as a string.
 */

void PerlClientUser::InputData(StrBuf *strbuf, Error *e) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::InputData]: Using supplied input\n");

	if (!input) {
		warn("Perforce asked for input, but none had been supplied!");
		return;
	}

	//
	// Check that what we've got is a reference. It really ought to be
	// because of the way SetInput is coded, but just to make sure.
	//
	if (!SvROK(input)) {
		warn("Bad input data encountered! What did you pass to SetInput()?");
		return;
	}

	//
	// Now de-reference it and try to figure out if we're looking at a PV,
	// an HV, or an AV. If it's an array, then it may be an array of PVs or
	// an array of HVs, so we shift it by one and use the first element.
	//
	SV *s = SvRV(input);
	if (SvTYPE(s) == SVt_PVAV) {
		if (P4PERL_DEBUG_DATA)
			PerlIO_stdoutf("[PerlClientUser::InputData]: Using first element "
					"of supplied array.\n");

		s = av_shift((AV *) s);
		if (!s) {
			warn("Ran out of input for Perforce command!");
			return;
		}
		//
		// If what was in the array is a reference, dereference it now.
		//
		if (SvROK(s))
			s = SvRV(s);
	}

	if (SvTYPE(s) == SVt_PVHV) {
		if (P4PERL_DEBUG_DATA)
			PerlIO_stdoutf("[PerlClientUser::InputData]: Input is a hashref."
					" Formatting...\n");
		StrPtr * specDef = varList->GetVar("specdef");
		specMgr->AddSpecDef(cmd.Text(), specDef->Text());
		specMgr->SpecToString(cmd.Text(), (HV *) s, *strbuf, e);
		return;
	}

	// Otherwise, we assume it's a string - a reasonable assumption
	if (P4PERL_DEBUG_DATA)
		PerlIO_stdoutf("[PerlClientUser::InputData]: Input is a string...\n");
	strbuf->Set(SvPV_nolen(s));
}

/*
 * Accept input from Perl for later use. We just save what we're given here 
 * because we may not have the specdef available to parse it with at this time.
 * To deal with Perl's horrible reference count system, we create a new 
 * reference here to whatever we're given. That way we'll increment the
 * reference count of the object when it's given to us, and we have to
 * decrement the refcount when we're done with this object. Ugly, but hey,
 * that's Perl!
 */

void PerlClientUser::SetInput(SV * i) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::SetInput]: Stashing input for "
				"later\n");

	SV *t = i;
	if (SvROK(i))
		t = SvRV(i);

	input = newRV(t);
}

void PerlClientUser::ClearHandler() {
	// Check if handler is already set and remove
	if (handler) {
		sv_free(handler);
	}
}

void PerlClientUser::SetHandler(SV * i) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::SetHandler]: setting...\n");

	handler = i;
	alive = 1;
}

SV *
PerlClientUser::GetHandler() {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::GetHandler]: getting...\n");

	return handler;
}

void PerlClientUser::SetApiLevel(int l) {
	// We don't use this (yet), but P4Result does...
	results.SetApiLevel(l);
}

/*
 * Simple method to check if a progress indicator has been
 * registered to this ClientUser. Return 0 if not valid
 */
int PerlClientUser::ProgressIndicator()
{
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser:ProgressIndicator]:\n");

	int result = (progress != 0);
	return result;
}

/*
 * Return the ClientProgress.
 */
ClientProgress *
PerlClientUser::CreateProgress(int type)
		{
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser:CreateProgress]: type: %d\n", type);

	if (progress == 0) {
		return 0;
	}
	return new P4ClientProgress(progress, type);
}

/*
 * Set a ClientProgress for the current ClientUser.
 */
void PerlClientUser::SetProgress(SV * p)
		{
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser:SetProgress]: setting...\n");

	progress = p;
	alive = 1;
	return;
}

/*
 * Set a ClientProgress for the current ClientUser.
 */
SV *
PerlClientUser::GetProgress()
{
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser:GetProgress]: getting...\n");

	return progress;
}

SV *
PerlClientUser::MkMergeData(ClientMerge *m, StrPtr &h) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::MkMergeData]: Creating MergeData "
				"object\n");

	P4MergeData *md = new P4MergeData(this, m, h);
	SV *sv = newSViv(PTR2IV(md));

	//
	// Now create a reference to the IV, and bless it into the right class.
	// This is a constructor by the back door...
	//

	HV * stash = gv_stashpv("P4::MergeData", TRUE);
	sv = newRV_noinc(sv);
	sv_bless(sv, stash);
	return sv;
}

SV *
PerlClientUser::MkActionMergeData(ClientResolveA *m, StrPtr &h) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[PerlClientUser::MkActionMergeData]: Creating "
				"ActionMergeData object\n");

	// retrieve the last entry in the result array
	AV *output = results.GetOutputInternal();
	int len = av_len(output); // returns length -1, empty = -1
	SV **info = av_fetch(output, len, 0);

	P4ActionMergeData *md = new P4ActionMergeData(this, m, h, *info);
	SV *sv = newSViv(PTR2IV(md));

	//
	// Now create a reference to the IV, and bless it into the right class.
	// This is a constructor by the back door...
	//

	HV * stash = gv_stashpv("P4::ActionMergeData", TRUE);
	sv = newRV_noinc(sv);
	sv_bless(sv, stash);
	return sv;
}

