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
 * Name		: p4mergedata.cc
 *
 * Author	: Tony Smith <tony@perforce.com> 
 *
 * Description	: Class for holding merge data
 *
 ******************************************************************************/
#include <clientapi.h>
#include <spec.h>
#include <diff.h>
#include "perlheaders.h"
#include "p4result.h"
#include "p4perldebug.h"
#include "specmgr.h"
#include "p4mergedata.h"

P4MergeData::P4MergeData(ClientUser *ui, ClientMerge *m, StrPtr &hint) {
	this->debug = 0;
	this->ui = ui;
	this->merger = m;
	this->hint = hint;

	// Extract (forcibly) the paths from the RPC buffer.
	StrPtr *t;
	if ((t = ui->varList->GetVar("baseName") ))
		base = t->Text();
	if ((t = ui->varList->GetVar("yourName") ))
		yours = t->Text();
	if ((t = ui->varList->GetVar("theirName") ))
		theirs = t->Text();
}

SV *P4MergeData::GetYourName() {
	return newSVpv(yours.Text(), yours.Length());
}

SV *P4MergeData::GetTheirName() {
	return newSVpv(theirs.Text(), theirs.Length());
}

SV *P4MergeData::GetBaseName() {
	return newSVpv(base.Text(), base.Length());
}

SV *P4MergeData::GetYourPath() {
	StrPtr *yours = merger->GetYourFile()->Path();
	return newSVpv(yours->Text(), yours->Length());
}

SV *P4MergeData::GetTheirPath() {
	if (merger->GetTheirFile()) {
		StrPtr *theirs = merger->GetTheirFile()->Path();
		return newSVpv(theirs->Text(), theirs->Length());
	} else {
		// return empty string, not undef
		return &PL_sv_no;
	}
}

SV *P4MergeData::GetBasePath() {
	if (merger->GetBaseFile()) {
		StrPtr *base = merger->GetBaseFile()->Path();
		return newSVpv(base->Text(), base->Length());
	} else {
		// return empty string, not undef
		return &PL_sv_no;
	}
}

SV *P4MergeData::GetResultPath() {
	if (merger->GetResultFile()) {
		StrPtr *result = merger->GetResultFile()->Path();
		return newSVpv(result->Text(), result->Length());
	} else {
		// return empty string, not undef
		return &PL_sv_no;
	}
}

SV *P4MergeData::GetMergeHint() {
	return newSVpv(hint.Text(), hint.Length());
}

SV *P4MergeData::RunMergeTool() {
	Error e;
	ui->Merge(merger->GetBaseFile(), merger->GetTheirFile(),
			merger->GetYourFile(), merger->GetResultFile(), &e);

	if (e.Test())
		return &PL_sv_no;
	return &PL_sv_yes;
}

StrBuf P4MergeData::GetString() {
	StrBuf result = "P4MergeData\n";

	result << "\tyourName: " << yours << "\n";
	result << "\ttheirName: " << theirs << "\n";
	result << "\tbaseName: " << base << "\n";

	// be defensive, only add the additional information if it exists
	if (merger->GetYourFile())
		result << "\tyourFile: " << merger->GetYourFile()->Name() << "\n";
	if (merger->GetTheirFile())
		result << "\ttheirFile: " << merger->GetTheirFile()->Name() << "\n";
	if (merger->GetBaseFile())
		result << "\tbaseFile: " << merger->GetBaseFile()->Name() << "\n";

	return result;
}
