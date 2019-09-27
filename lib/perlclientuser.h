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
 * Name		: perlclientuser.h
 *
 * Author	: Tony Smith <tony@perforce.com> or <tony@smee.org>
 *			: Paul Allen <pallen@perforce.com> or <perl@pallen.co.uk>
 *
 * Description	: Perl bindings for the Perforce API. User interface class
 * 		  for getting Perforce results into Perl.
 *
 ******************************************************************************/

/*******************************************************************************
 * PerlClientUser - the user interface part. Gets responses from the Perforce
 * server, and converts the data to Perl format for returning to the caller.
 ******************************************************************************/
class SpecMgr;
class ClientProgress;

class PerlClientUser: public ClientUser, public KeepAlive {
public:
	PerlClientUser(SpecMgr *s);
	virtual ~PerlClientUser();

	// Client User methods overridden here
	void Message(Error *e);
	void OutputText(const char *data, int length);
	void OutputInfo(char level, const char *data);
	void OutputStat(StrDict *values);
	void OutputBinary(const char *data, int length);
	void InputData(StrBuf *strbuf, Error *e);
	void Diff(FileSys *f1, FileSys *f2, int doPage, char *diffFlags, Error *e);
	void Prompt(const StrPtr &msg, StrBuf &rsp, int noEcho, Error *e);

	int Resolve(ClientMerge *m, Error *e);
	int Resolve(ClientResolveA *m, int preview, Error *e);

	ClientProgress *CreateProgress(int);
	int ProgressIndicator();

	int IsAlive() {
		return alive;
	}

	void Finished();

	// Local methods
	void SetCommand(const char *c) {
		cmd = c;
	}
	void SetInput(SV * i);
	void ClearHandler();
	void SetHandler(SV * i);
	SV * GetHandler();

	void SetProgress(SV * p);
	SV * GetProgress();

	void SetApiLevel(int l);
	void SetTrack(int t) {
		track = t;
	}
	void SetResolver(SV * r) {
		resolver = r;
	}
	P4Result& GetResults() {
		return results;
	}
	I32 ErrorCount();
	void Reset();
	StrPtr & LastSpecDef() {
		return lastSpecDef;
	}

	// Debugging support
	void SetDebugLevel(int d) {
		debug = d;
		results.SetDebugLevel(d);
	}

private:
	SV * MkMergeData(ClientMerge *m, StrPtr &h);
	SV * MkActionMergeData(ClientResolveA *m, StrPtr &hint);
	bool CallOutputMethod(const char * method, SV * data);
	void ProcessOutput(const char * method, SV * data);
	void ProcessMessage(Error *e);

private:
	StrBuf cmd;
	SpecMgr * specMgr;
	P4Result results;
	StrBuf lastSpecDef;
	SV * input;
	SV * resolver;
	SV * handler;
	SV * progress;
	int debug;
	int track;
	int alive;
};

