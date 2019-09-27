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

class ClientApi;
class PerlClientUser;
class SpecMgr;
class Enviro;

class PerlClientApi {
public:

	static SV * Identify();

	PerlClientApi( HV * args );
	~PerlClientApi();

	SV * Connect();
	SV * Disconnect();
	int Connected();
	AV * Run(const char *cmd, int argc, char * const *argv);

	void SetApiLevel(int level);
	SV * SetCharset(const char *c);
	void SetClient(const char *c) {
		client->SetClient(c);
	}
	void SetCwd(const char *c);
	void SetEnv(const char *var, const char *val);
	void SetHost(const char *c) {
		client->SetHost(c);
	}
	void ClearHandler();
	void SetHandler(SV *i);
	void SetProgress(SV *p);
	void SetLanguage(const char *c) {
		client->SetLanguage(c);
	}
	void SetPassword(const char *c) {
		client->SetPassword(c);
	}
	void SetMaxResults(int v) {
		maxResults = v;
	}
	void SetMaxScanRows(int v) {
		maxScanRows = v;
	}
	void SetMaxLockTime(int v) {
		maxLockTime = v;
	}
	void SetPort(const char *c) {
		client->SetPort(c);
	}
	void SetProtocol(const char *var, const char *val);
	void SetTicketFile(const char *t);
	void SetIgnoreFile(const char *t);
	void SetUser(const char *c) {
		client->SetUser(c);
	}
	void SetProg(const char *c) {
		prog.Set(c);
	}
	void SetResolver(SV * r);
	void SetVersion(const char *v) {
		version.Set(v);
	}
	void SetEnviroFile(const char *f);
	int SetTrack(int enable);
	void SetStreams(int enable);

	void SetInput(SV *i);

	SV * GetApiLevel();
	SV * GetCharset();
	SV * GetConfig();
	SV * GetClient();
	SV * GetCwd();
	SV * GetHost();
	SV * GetHandler();
	SV * GetProgress();
	SV * GetEnv(const char *var);
	SV * GetLanguage();
	SV * GetMaxResults();
	SV * GetMaxScanRows();
	SV * GetMaxLockTime();
	SV * GetPassword();
	SV * GetPort();
	SV * GetProg();
	int GetServerLevel();
	SV * GetTicketFile();
	SV * GetIgnoreFile();
	SV * GetUser();
	SV * GetVersion();
	SV * GetEnviroFile();
	int IsIgnored(const char *t);

	// Booleans
	void Tagged(int t);
	int IsStreams() {
		return IsStreamsMode();
	}
	int IsTagged() {
		return IsTag();
	}
	int IsTrack() {
		return IsTrackMode();
	}

	int ServerCaseSensitive();
	int ServerUnicode();

	//
	// Handling command output
	//
	AV * GetOutput();
	AV * GetWarnings();
	AV * GetErrors();
	AV * GetMessages();
	AV * GetTrackOutput();

	I32 GetOutputCount();
	I32 GetWarningCount();
	I32 GetErrorCount();
	I32 GetTrackOutputCount();

	// Spec parsing
	SV * ParseSpec(const char *type, const char *form);
	SV * DefineSpec(const char *type, const char *spec);
	SV * FormatSpec(const char *type, HV *hash);

	// Debugging support
	void SetDebugLevel(int l);
	int GetDebugLevel() {
		return debug;
	}

	//
private:
	void RunCmd(const char *cmd, ClientUser *ui, int argc, char * const *argv);

	enum {
		S_TAGGED = 0x0001,
		S_CONNECTED = 0x0002,
		S_CMDRUN = 0x0004,
		S_UNICODE = 0x0008,
		S_CASEFOLDING = 0x0010,
		S_TRACK = 0x0020,
		S_STREAMS = 0x0040,

		S_INITIAL_STATE = 0x0041,
		S_RESET_MASK = 0x001E,
	};

	void InitFlags() {
		flags = S_INITIAL_STATE;
	}
	void ResetFlags() {
		flags &= ~S_RESET_MASK;
	}

	void SetTag() {
		flags |= S_TAGGED;
	}
	void ClearTag() {
		flags &= ~S_TAGGED;
	}
	int IsTag() {
		return flags & S_TAGGED;
	}

	void SetConnected() {
		flags |= S_CONNECTED;
	}
	void ClearConnected() {
		flags &= ~S_CONNECTED;
	}
	int IsConnected() {
		return flags & S_CONNECTED;
	}

	void SetCmdRun() {
		flags |= S_CMDRUN;
	}
	void ClearCmdRun() {
		flags &= ~S_CMDRUN;
	}
	int IsCmdRun() {
		return flags & S_CMDRUN;
	}

	void SetUnicode() {
		flags |= S_UNICODE;
	}
	void ClearUnicode() {
		flags &= ~S_UNICODE;
	}
	int IsUnicode() {
		return flags & S_UNICODE;
	}

	void SetCaseFold() {
		flags |= S_CASEFOLDING;
	}
	void ClearCaseFold() {
		flags &= ~S_CASEFOLDING;
	}
	int IsCaseFold() {
		return flags & S_CASEFOLDING;
	}

	void SetTrackMode() {
		flags |= S_TRACK;
	}
	void ClearTrackMode() {
		flags &= ~S_TRACK;
	}
	int IsTrackMode() {
		return flags & S_TRACK;
	}

	void SetStreamsMode() {
		flags |= S_STREAMS;
	}
	void ClearStreamsMode() {
		flags &= ~S_STREAMS;
	}
	int IsStreamsMode() {
		return flags & S_STREAMS;
	}

private:
	ClientApi * client;
	PerlClientUser * ui;
	Enviro * enviro;
	SpecMgr * specMgr;
	StrBufDict specDict;
	StrBuf prog;
	StrBuf version;
	StrBuf ticketFile;
	StrBuf ignoreFile;
	int flags;
	int server2;
	int apiLevel;
	int debug;
	int maxResults;
	int maxScanRows;
	int maxLockTime;
};
