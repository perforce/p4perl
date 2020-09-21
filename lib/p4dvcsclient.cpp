/*******************************************************************************
 Copyright (c) 2001-2016, Perforce Software, Inc.  All rights reserved.

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
#include <memory>
#include <serverhelperapi.h>
#include "perlheaders.h"
#include "p4result.h"
#include "p4perldebug.h"
#include "clientprog.h"
#include "specmgr.h"
#include "perlclientuser.h"
#include "perlclientapi.h"

#include "p4dvcsclient.h"


using namespace std;

//P4DvcsClient::P4DvcsClient(PerlClientUser * u) : ui(u) {
P4DvcsClient::P4DvcsClient() {
    debug = 0;
    specMgr = new SpecMgr;
    ui = new PerlClientUser(specMgr);
}

P4DvcsClient::~P4DvcsClient() {
}

bool
P4DvcsClient::foundError(Error &e)
{
    if (e.Test()) {
		ui->HandleError( &e );
		return true;
	}

    return false;
}

bool
P4DvcsClient::copyConfig(ServerHelperApi * personalServer, const char * port)
{
    Error e;

    ServerHelperApi remoteServer( &e );
    if( foundError(e) ) return false;

    remoteServer.SetPort( port, &e );
    if( foundError(e) ) return false;

    personalServer->CopyConfiguration( &remoteServer, ui, &e );
    if( foundError(e) ) return false;

    return true;
}

ServerHelperApi *
P4DvcsClient::createServer(const char * user, const char * client, const char * dir)
{
    Error e;

    ServerHelperApi * server = new ServerHelperApi( &e );
    if( foundError(e) ) return NULL;

    server->SetDvcsDir(dir, &e);
    if( foundError(e) ) return NULL;

    if( user ) server->SetUser( user );

    if( client ) server->SetClient( client );

    if( server->Exists(ui, &e)) {
        warn( "Personal Server already exists." );
	    return NULL;
    }
    if( foundError(e) ) return NULL;

    return server;
}


PerlClientApi *
P4DvcsClient::Init(HV * args) {

    SV ** val;

    val = hv_fetch(args, "port", 4, FALSE);
    const char * port = val ? SvPV_nolen(*val) : "";

    val = hv_fetch(args, "user", 4, FALSE);
    const char * user = val ? SvPV_nolen(*val) : "";

    val = hv_fetch(args, "client", 6, FALSE);
    const char * client = val ? SvPV_nolen(*val) : "";

    val = hv_fetch(args, "directory", 9, FALSE);
    const char * dir = val ? SvPV_nolen(*val) : "";

    val = hv_fetch(args, "casesensitive", 13, FALSE);
    long casesensitive = val ? SvIV( *val ) : 0;

    val = hv_fetch(args, "unicode", 7, FALSE);
    long unicode = val ? SvIV( *val ) : 0;


    Error e;

#if __cplusplus>= 201103L  || (defined(_MSC_VER) && _MSC_VER >= 1900)
    unique_ptr<ServerHelperApi> personalServer( createServer(user, client, dir) );
#else
    auto_ptr<ServerHelperApi> personalServer( createServer(user, client, dir) );
#endif

    if( personalServer.get() == NULL ) {
        warn("ServerHelperApi did not return a server.");
	    return NULL;
    }

    if( port ) {
	    if( !copyConfig(personalServer.get(), port)) {
	        warn("Port '%s' not accessable.", port);
	        return NULL;
	    }
    }
    else if( casesensitive == 1 || unicode == 1 ) {
        StrBuf caseFlag = (casesensitive == 0) ? "-C0" : "-C1";
	    personalServer->SetCaseFlag(&caseFlag, &e);
	    personalServer->SetUnicode(unicode);
    }
    else { // default is to use "perforce:1666 if it can be reached
	    if( !copyConfig(personalServer.get(), "perforce:1666")) {
            warn("Default Port 'perforce:1666' not accessable.");
	        return NULL;
	    }
    }

    personalServer->InitLocalServer(ui, &e);
    if( foundError(e) ) {
        warn("Failed to Init local server.");
        return NULL;
    }

    ClientApi * api =  personalServer->GetClient( &e );
    return (PerlClientApi *) api;
}


PerlClientApi *
P4DvcsClient::Clone(HV * args) {

    SV ** val;

    val = hv_fetch(args, "port", 4, FALSE);
    const char * port = val ? SvPV_nolen( *val ) : "";

    val = hv_fetch(args, "user", 4, FALSE);
    const char * user = val ? SvPV_nolen( *val ) : "";

    val = hv_fetch(args, "client", 6, FALSE);
    const char * client = val ? SvPV_nolen( *val ) : "";

    val = hv_fetch(args, "directory", 9, FALSE);
    const char * dir = val ? SvPV_nolen( *val ) : "";

    val = hv_fetch(args, "remote", 6, FALSE);
    const char * remote = val ? SvPV_nolen( *val ) : NULL;

    val = hv_fetch(args, "file", 4, FALSE);
    const char * file = val ? SvPV_nolen( *val ) : NULL;

    val = hv_fetch(args, "noarchive", 9, FALSE);
    long noarchive = val ? SvIV( *val ) : 0;

    val = hv_fetch(args, "depth", 5, FALSE);
    long depth = val ? SvIV( *val ) : 0;

    val = hv_fetch(args, "progress", 8, FALSE);
    SV * progress = val ? *val : NULL;


    Error e;

    #if __cplusplus>= 201103L  || (defined(_MSC_VER) && _MSC_VER >= 1900)
        unique_ptr<ServerHelperApi> personalServer( createServer(user, client, dir) );
    #else
        auto_ptr<ServerHelperApi> personalServer( createServer(user, client, dir) );
    #endif

    if( personalServer.get() == NULL) {
        warn("ServerHelperApi did not return a server.");
	    return NULL;
    }

    if( port == NULL ) {
        warn("Need to specify P4PORT to clone.");
    	return NULL;
    }

    if( progress != NULL ) {
    	ui->SetProgress(progress);
    }

    if( port ) {
	    if( !copyConfig(personalServer.get(), port)) {
	        warn("Port '%s' not accessable.", port);
	        return NULL;
	    }
    }

    ServerHelperApi remoteServer( &e );
    if( foundError(e) ) return NULL;

    remoteServer.SetPort( port, &e );
    if( foundError(e) ) return NULL;

    if( remote && file ) {
	    warn("Only specify one of (remote | file).");
	    return NULL;
    }

    if( remote ) {
	    personalServer->PrepareToCloneRemote( &remoteServer, remote, ui, &e );
	    if( foundError(e) ) return NULL;
    }
    else if ( file ) {
        personalServer->PrepareToCloneFilepath( &remoteServer, file, ui, &e );
	    if( foundError(e) ) return NULL;
    }
    else {
	    warn("Need to specify one of (remote | file).");
        return NULL;
    }

    personalServer->InitLocalServer( ui, &e );
    if( foundError(e) ) return NULL;

    personalServer->CloneFromRemote( depth, noarchive, (char *) 0, ui, &e );
    if( foundError(e) ) return NULL;

    ClientApi * api =  personalServer->GetClient( &e );
    return (PerlClientApi *) api;
}
