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

#ifdef OS_NT
# define WIN32_LEAN_AND_MEAN
# include <windows.h>
# include <winsvc.h>
# include <ntservice.h>
# undef GetMessage
# undef SetPort
#endif // OS_NT
#define NEED_TIME
#include "clientapi.h"
#include "ignore.h"
#include "hostenv.h"
#include "strtable.h"
#include "debug.h"
#include "spec.h"
#include "enviro.h"
#include "ident.h"
#include "i18napi.h"
#include "perlheaders.h"
#include "p4result.h"
#include "p4perldebug.h"
#include "specmgr.h"
#include "perlclientuser.h"
#include "perlclientapi.h"

static Ident
ident =
{
	IdentMagic "P4PERL" "/" ID_OS "/" ID_REL "/" ID_PATCH " (" ID_API " API)",
	ID_Y "/" ID_M "/" ID_D};

SV *
PerlClientApi::Identify() {
	StrBuf msg;

	ident.GetMessage(&msg);

	// Not mortal, XS will do that for us.
	SV * sv = newSVpv(msg.Text(), msg.Length());

	return sv;
}

PerlClientApi::PerlClientApi( HV * args ) {
	client = new ClientApi;
	specMgr = new SpecMgr;
	ui = new PerlClientUser(specMgr);
	enviro = new Enviro();
	InitFlags();
	debug = 0;
	maxResults = 0;
	maxScanRows = 0;
	maxLockTime = 0;
	server2 = 0;
	apiLevel = atoi(P4Tag::l_client);
	prog = "Unnamed P4Perl script";

	client->SetProtocol("specstring", "");

	//
	// Load any P4CONFIG file
	//
	HostEnv henv;
	StrBuf cwd;

	henv.GetCwd(cwd, enviro);

    //
    // Update CWD if 'directory' is defined
    //
	if( args ) {
	    SV ** val = hv_fetch(args, "directory", 9, FALSE);
	    if( val )
            cwd = SvPV_nolen(*val);
    }

	if (cwd.Length())
		SetCwd(cwd.Text());

	//
	// Load the current ticket file. Start with the default, and then
	// override it if P4TICKETS is set.
	//
	const char *t;

	henv.GetTicketFile(ticketFile, enviro);

	if ((t = enviro->Get("P4TICKETS")))
		ticketFile = t;

	//
	// Load the current P4CHARSET if set.
	//
	if (client->GetCharset().Length())
		SetCharset(client->GetCharset().Text());
}

PerlClientApi::~PerlClientApi() {
	Disconnect();
	delete ui;
	delete client;
	delete specMgr;
	delete enviro;
}

SV *
PerlClientApi::Connect() {
	Error e;

	if (IsConnected())
		return &PL_sv_yes;

	if (IsTrackMode())
		client->SetProtocol("track", "");

	if (P4PERL_DEBUG_CMDS)
		PerlIO_stdoutf("[P4]: Connecting to Perforce\n");

	ResetFlags();

	client->Init(&e);
	if (e.Test())
		ui->HandleError(&e);
	else
		SetConnected();

	return IsConnected() ? &PL_sv_yes : &PL_sv_no;
}

SV *
PerlClientApi::Disconnect() {
	if (!IsConnected())
		return &PL_sv_yes;

	if (P4PERL_DEBUG_CMDS)
		PerlIO_stdoutf("[P4]: Closing connection to Perforce\n");

	Error e;
	client->Final(&e);
	ClearConnected();

	if (e.Test())
		ui->HandleError(&e);
	return e.Test() ? &PL_sv_no : &PL_sv_yes;
}

int PerlClientApi::Connected() {
	if (IsConnected() && !client->Dropped())
		return 1;
	else if (client->Dropped())
		Disconnect();
	return 0;
}

void PerlClientApi::SetInput(SV *i) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("Saving user input for later\n");

	ui->SetInput(i);
}

void PerlClientApi::SetApiLevel(int level) {
	StrBuf l;
	l << level;
	apiLevel = level;
	client->SetProtocol("api", l.Text());
	ui->SetApiLevel(level);
}

SV *
PerlClientApi::SetCharset(const char *c) {
	CharSetApi::CharSet cs = CharSetApi::Lookup(c);
	if (cs == (CharSetApi::CharSet) - 1) {
		warn("Unknown charset ignored. Check your code or P4CHARSET.");
		return &PL_sv_undef;
	}
	if (strcmp(c, "none") != 0) {
	  CharSetApi::CharSet utf8 = CharSetApi::UTF_8;
	  client->SetTrans( utf8, cs, utf8, utf8 );
	  client->SetCharset(c);
	}
	return &PL_sv_yes;
}

void PerlClientApi::SetCwd(const char *c) {
	client->SetCwd(c);
	enviro->Config(StrRef(c));
}

void PerlClientApi::SetEnv(const char *var, const char *val) {
	Error e;

	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("Setting %s to %s\n", var, val);

	enviro->Set(var, val, &e);
	if (e.Test()) {
		ui->HandleError(&e);
	}
}

void PerlClientApi::SetProtocol(const char *var, const char *val) {
	client->SetProtocol(var, val);
}

SV *
PerlClientApi::GetApiLevel() {
	return newSViv(apiLevel);
}

SV *
PerlClientApi::GetCharset() {
	const StrPtr &c = client->GetCharset();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetConfig() {
	const StrPtr &c = client->GetConfig();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetClient() {
	const StrPtr &c = client->GetClient();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetCwd() {
	const StrPtr &c = client->GetCwd();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetEnv(const char *var) {
	char *val = enviro->Get(var);
	if (val)
		return newSVpv(val, 0);
	return &PL_sv_undef;
}

SV *
PerlClientApi::GetHost() {
	const StrPtr &c = client->GetHost();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetHandler() {
	return ui->GetHandler();
}

SV *
PerlClientApi::GetProgress() {
	return ui->GetProgress();
}

SV *
PerlClientApi::GetLanguage() {
	const StrPtr &c = client->GetLanguage();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetMaxResults() {
	return newSViv(maxResults);
}

SV *
PerlClientApi::GetMaxScanRows() {
	return newSViv(maxScanRows);
}

SV *
PerlClientApi::GetMaxLockTime() {
	return newSViv(maxLockTime);
}

SV *
PerlClientApi::GetPassword() {
	const StrPtr &c = client->GetPassword();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetPort() {
	const StrPtr &c = client->GetPort();
	return newSVpv(c.Text(), c.Length());
}

SV *
PerlClientApi::GetProg() {
	return newSVpv(prog.Text(), prog.Length());
}

SV *
PerlClientApi::GetVersion() {
	return newSVpv(version.Text(), version.Length());
}

int PerlClientApi::GetServerLevel() {
	if (!IsConnected())
		return -1;

	if (!IsCmdRun())
		Run("info", 0, 0);
	return server2;
}

int PerlClientApi::ServerCaseSensitive() {
	if (!IsConnected())
		return -1;

	if (!IsCmdRun())
		Run("info", 0, 0);
	return !IsCaseFold();
}

int PerlClientApi::ServerUnicode() {
	if (!IsConnected())
		return -1;

	if (!IsCmdRun())
		Run("info", 0, 0);
	return IsUnicode();
}

void PerlClientApi::Tagged(int t) {
	if (t)
		SetTag();
	else
		ClearTag();
}

int PerlClientApi::SetTrack(int enable) {
	if (IsConnected())
		return 0;

	if (enable) {
		SetTrackMode();
		ui->SetTrack(1);
	} else {
		ClearTrackMode();
		ui->SetTrack(0);
	}
	return 1;
}

void PerlClientApi::SetStreams(int enable) {
	if (enable)
		SetStreamsMode();
	else
		ClearStreamsMode();
}

void PerlClientApi::SetTicketFile(const char *t) {
	client->SetTicketFile(t);
	ticketFile = t;
}

SV *
PerlClientApi::GetTicketFile() {
	return newSVpv(ticketFile.Text(), ticketFile.Length());
}

void PerlClientApi::SetIgnoreFile(const char *t) {
	client->SetIgnoreFile(t);
	ignoreFile = t;
}

SV *
PerlClientApi::GetIgnoreFile() {
	return newSVpv(ignoreFile.Text(), ignoreFile.Length());
}

int
PerlClientApi::IsIgnored(const char *t) {
    StrRef p = t;
    if ( client->GetIgnore()->Reject( p, client->GetIgnoreFile() ) ) {
    	return 1;
    }
    return 0;
}

void PerlClientApi::SetEnviroFile(const char *f) {
    enviro->SetEnviroFile( f );
    enviro->Reload();
}

SV *
PerlClientApi::GetEnviroFile() {
    const StrPtr *f = enviro->GetEnviroFile();
    if (f) {
	    return newSVpv(f->Text(), f->Length());
    }
    else {
    	return &PL_sv_undef;
    }
}

SV *
PerlClientApi::GetUser() {
	const StrPtr &c = client->GetUser();
	return newSVpv(c.Text(), c.Length());
}

AV *
PerlClientApi::GetOutput() {
	return ui->GetResults().GetOutput();
}

AV *
PerlClientApi::GetWarnings() {
	return ui->GetResults().GetWarnings();
}

AV *
PerlClientApi::GetErrors() {
	return ui->GetResults().GetErrors();
}

AV *
PerlClientApi::GetMessages() {
	return ui->GetResults().GetMessages();
}

AV *
PerlClientApi::GetTrackOutput() {
	return ui->GetResults().GetTrack();
}

I32 PerlClientApi::GetOutputCount() {
	return ui->GetResults().OutputCount();
}

I32 PerlClientApi::GetWarningCount() {
	return ui->GetResults().WarningCount();
}

I32 PerlClientApi::GetErrorCount() {
	return ui->GetResults().ErrorCount();
}

I32 PerlClientApi::GetTrackOutputCount() {
	return ui->GetResults().TrackCount();
}

void PerlClientApi::SetDebugLevel(int l) {
	debug = l;
	ui->SetDebugLevel(l);
	specMgr->SetDebug(l);
	if (P4PERL_DEBUG_RPC)
		p4debug.SetLevel(DT_RPC, 5);
	else
		p4debug.SetLevel(DT_RPC, 0);
}

void PerlClientApi::ClearHandler() {
	ui->ClearHandler();
}

void PerlClientApi::SetHandler(SV * i) {
	if (sv_isobject(i)) {
		ui->SetHandler(i);
		client->SetBreak(ui);
	} else {
		ui->ClearHandler();
		client->SetBreak(NULL);
	}
}

void PerlClientApi::SetProgress(SV * p) {
	if (sv_isobject(p)) {
		ui->SetProgress(p);
	} else {
		warn("Unable to SetProgress, not an object.");
	}
}

void PerlClientApi::SetResolver(SV * r) {
	ui->SetResolver(r);
}

AV *
PerlClientApi::Run(const char *cmd, int argc, char * const *argv) {
	StrBuf cmdstr;

	ui->Reset();
	ui->SetCommand(cmd);

	if (P4PERL_DEBUG_CMDS) {
		cmdstr << cmd;
		char * const *a = argv;
		for (int i = 0; i < argc; i++, a++)
			cmdstr << " " << *a;

		PerlIO_stdoutf("[P4]: Executing: 'p4 %s'\n", cmdstr.Text());
	}

	RunCmd(cmd, ui, argc, argv);

	//
	// Save the specdef for this command...
	//
	if (ui->LastSpecDef().Length())
		specDict.SetVar(cmd, ui->LastSpecDef());

	if (P4PERL_DEBUG_CMDS)
		PerlIO_stdoutf("[P4]: Completed: 'p4 %s'\n", cmdstr.Text());

	return GetOutput();
}

void PerlClientApi::RunCmd(const char *cmd, ClientUser *ui, int argc,
		char * const *argv) {
	client->SetProg(prog.Text());
	if (version.Length())
		client->SetVersion(&version);

	if (IsTag())
		client->SetVar("tag");

	if (IsStreamsMode() && apiLevel > 69)
		client->SetVar("enableStreams", "");

	// If maxresults or maxscanrows is set, enforce them now
	if (maxResults)
		client->SetVar("maxResults", maxResults);
	if (maxScanRows)
		client->SetVar("maxScanRows", maxScanRows);
	if (maxLockTime)
		client->SetVar("maxLockTime", maxLockTime);

    // If progress is set, set the progress var
    if( ((PerlClientUser*)ui)->GetProgress() != 0 )
    	client->SetVar( P4Tag::v_progress, 1);

	client->SetArgv(argc, argv);
	client->Run(cmd, ui);

	// Have to request server2 protocol *after* a command has been run.
	// Do this once only

	if (!IsCmdRun()) {
		StrPtr *s = 0;
		if ((s = client->GetProtocol(P4Tag::v_server2)))
			server2 = s->Atoi();

		if ((s = client->GetProtocol(P4Tag::v_unicode)))
			if (s->Atoi())
				SetUnicode();

		if ((s = client->GetProtocol(P4Tag::v_nocase)))
			SetCaseFold();
	}
	SetCmdRun();
}

//
// Convert a spec in string form into a hash and return a reference to that
// hash.
//
SV *
PerlClientApi::ParseSpec(const char *type, const char *form) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4]: Parsing a %s form\n", type);

	Error e;
	SV *spec = specMgr->StringToSpec(type, form, &e);
	if (e.Test()) {
		ui->HandleError(&e);
		return &PL_sv_undef;
	}

	return spec;

}

//
// Sets the spec field in the cache, used for triggers with the new 16.1 ability
// to pass the spec definition.
//
SV *
PerlClientApi::DefineSpec(const char *type, const char *spec) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4]: Loading a %s form\n", type);

    specMgr->AddSpecDef(type, spec);

	return &PL_sv_yes;

}

//
// Convert a spec in hash form into its string representation
//
SV *
PerlClientApi::FormatSpec(const char *type, HV *hash) {
	if (P4PERL_DEBUG_FLOW)
		PerlIO_stdoutf("[P4]: Formatting a %s form\n", type);

	// Got a specdef so now we can attempt to convert.
	StrBuf buf;
	Error e;
	specMgr->SpecToString(type, hash, buf, &e);
	if (e.Test()) {
		StrBuf m;
		m = "P4::FormatSpec(): Error converting hash to a string.";
		warn("%s", m.Text());
		e.Fmt(m, EF_PLAIN);
		warn("%s", m.Text());
		return &PL_sv_undef;
	}

	return newSVpv(buf.Text(), buf.Length());
}

