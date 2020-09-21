#-------------------------------------------------------------------------------
# Copyright (c) 2001-2008, Perforce Software, Inc.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE SOFTWARE, INC. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-------------------------------------------------------------------------------

=pod

=head1 NAME

P4Perl - Perl interface to the Perforce SCM System.

=head1 SYNOPSIS

  use P4;
  my $p4 = new P4;

  $p4->SetClient( $clientname );
  $p4->SetPort ( $p4port );
  $p4->Connect() or die( "Failed to connect to Perforce Server" );
  
  my $info = $p4->Run( "info" );
  $p4->RunEdit( "file.txt" );
  die( "Failed to open file for edit" ) if $p4->ErrorCount();
  $p4->Disconnect();

=head1 DESCRIPTION

P4Perl is a Perl interface to the Perforce C++ API and allows Perl
users to run Perforce commands and get the responses from the Perforce
Server in Perl hashes and lists. Many methods also accept hashes as
input, so editing Perforce forms in Perl is simple.

Each P4 object represents a connection to a Perforce Server, and 
multiple commands may be executed (serially) over a single connection.

Responses from the server are separated into: output, errors, and
warnings. The output is returned directly by the various 'Run' methods); 
the errors and warnings are available by calling C<Errors()> and
C<Warnings()> respectively.

=cut

package P4;
use strict;
require Exporter;
require DynaLoader;
use AutoLoader;
use P4::Spec;
use P4::DepotFile;
use P4::Revision;
use P4::Integration;
use P4::Resolver;
use P4::IterateSpec;
use Scalar::Util qw( tainted );

use vars qw( @ISA @EXPORT @EXPORT_OK $AUTOLOAD );

@ISA       = qw(Exporter DynaLoader);
@EXPORT_OK = qw( );
@EXPORT    = qw();

#
# Generic error codes, from errornum.h in the Perforce API.
#

$P4::EV_NONE = 0;    # misc

# The fault of the user
$P4::EV_USAGE   = 0x01;    # request not consistent with dox
$P4::EV_UNKNOWN = 0x02;    # using unknown entity
$P4::EV_CONTEXT = 0x03;    # using entity in wrong context
$P4::EV_ILLEGAL = 0x04;    # trying to do something you can't
$P4::EV_NOTYET  = 0x05;    # something must be corrected first
$P4::EV_PROTECT = 0x06;    # protections prevented operation

# No fault at all
$P4::EV_EMPTY = 0x11;      # action returned empty results

# not the fault of the user
$P4::EV_FAULT   = 0x21;    # inexplicable program fault
$P4::EV_CLIENT  = 0x22;    # client side program errors
$P4::EV_ADMIN   = 0x23;    # server administrative action required
$P4::EV_CONFIG  = 0x24;    # client configuration inadequate
$P4::EV_UPGRADE = 0x25;    # client or server too old to interact
$P4::EV_COMM    = 0x26;    # communications error
$P4::EV_TOOBIG  = 0x27;    # not ever Perforce can handle this much

#
# Error severities: taken from error.h in the Perforce API
#
$P4::E_EMPTY  = 0;         # nothing yet
$P4::E_INFO   = 1;         # something good happened
$P4::E_WARN   = 2;         # something not good happened
$P4::E_FAILED = 3;         # user did somthing wrong
$P4::E_FATAL  = 4;         # system broken -- nothing can continue

bootstrap P4;

# Documentation for methods

=pod

=head1 CLASS METHODS

=over

=item new()

Constructs a new P4 object. For example:

  $p4 = new P4;

=item Identify()

Returns a string containing build information including 
P4Perl version and Perforce API version. For example:

  print P4::Identify();

=back

=head1 CONNECTION MANAGEMENT

=over 

=item Connect()

Connects to the server, returning false on failure. For example:

  $p4->Connect() or die( "Failed to connect" )

=item Disconnect()

Terminate the connection and clean up. Should be called before exiting.

=item IsConnected()

Returns true if the client has been connected to the Perforce Server,
and that connection has not been dropped by the server.

=item ServerLevel()

Returns an integer specifying the server protocol level. This is not the
same as, but is closely aligned to, the server version. To find out your
server's protocol level run 'p4 -vrpc=5 info' and look for the server2
protocol variable in the output.

=item SetApiLevel( integer )

Specify the API compatibility level to use for this script. 
This is useful when you want your script to continue to work on
newer server versions, even if the new server adds tagged output
to previously unsupported commands.

The additional tagged output support can change the server's
output, and confound your scripts. Setting the API level to a
specific value allows you to lock the output to an older
format, thus increasing the compatibility of your script.

B<Must be called before calling P4::Connect()>

For example:

  $p4->SetApiLevel( 57 ); # Lock to 2005.1 format
  $p4->Connect() or die( "Failed to connect to Perforce" );
  ...

=back

=head1 CLIENT SETTINGS

=over

=item GetCharset()

Return the name of the current charset in use. Applicable only when
used with Perforce servers running in unicode mode.

=item GetClient()

Returns the current Perforce client name. This may have previously
been set by SetClient(), or may be taken from the environment or
P4CONFIG file if any. If all that fails, it will be your hostname.

=item GetCwd()

Returns the current working directory as your Perforce client sees
it.

=item GetHost()

Returns the client hostname. Defaults to your hostname, but can
be overridden with SetHost()

=item GetMaxLockTime()

Returns the current maxlocktime limit set using SetMaxLockTime(),
or 0 if no limit is in place. Note that the limits set by
the administrator in group specifications are not visible through 
this interface.

=item GetMaxResults()

Returns the current maxresults limit set using SetMaxResults(),
or 0 if no limit is in place. Note that the limits set by
the administrator in group specifications are not visible through 
this interface.

=item GetMaxScanRows()

Returns the current maxscanrows limit set using SetMaxScanRows(),
or 0 if no limit is in place. Note that the limits set by
the administrator in group specifications are not visible through 
this interface.

=item GetPassword()

Returns your Perforce password. Taken from a previous call to 
SetPassword(), the environment ( $ENV{P4PASSWD} ), or a 
P4CONFIG file.

=item GetPort()

Returns the current address for your Perforce server. Taken from 
a previous call to SetPort(), the environment ($ENV{P4PORT}),
or a P4CONFIG file.

=item GetProg()

Get the name of your script. See L</SetProg>, below.

=item GetTicketFile()

Returns the path to the file where the user's login tickets
are stored.

=item GetIgnoreFile()

Returns the specfied path of the ignore file.

=item GetUser()

Returns the Perforce username in use on this client.

=item GetVersion()

Returns the (user-specified) version of your script. See
L<SetVersion()>.

=item IsTagged()

Returns 1 if tagged output is enabled, zero if it is disabled.

=item P4ConfigFile()

Returns the path to the current P4CONFIG file, if any, that is
in effect.

=item SetCharset( $charset )

Specify the character set to use for local files when used with a
Perforce server running in unicode mode. 

Do not use UNLESS your Perforce server is in unicode mode.

Must be called before calling P4::Connect().

For example:

  $p4->SetCharset( "winansi" );
  $p4->SetCharset( "iso8859-1" );
  $p4->SetCharset( "utf8" );
  ...

=item SetClient( $client )

Sets the name of your Perforce client. If you don't call this 
method, then the client name will be determined according to the 
usual Perforce conventions:

    1. Value from file specified by P4CONFIG
    2. Value from $ENV{P4CLIENT}
    3. Hostname

=item SetCwd( $path )

Sets the current working directory for the client. This should
be called after calling Connect().

=item SetHost( $hostname )

Sets the name of the client host - overriding the actual hostname.
This is equivalent to 'p4 -H <hostname>', and really only useful when
you want to run commands as if you were on another machine. If you
don't know when or why you might want to do that, then don't do it.

=item SetMaxLockTime( $value )

Specifies the maximim number of milliseconds for which locks
may be held during queries. Note that once set, this limit remains 
in force. You can remove the restriction by setting it to a value 
of 0.

=item SetMaxResults( $value )

Limit the number of results for subsequent commands to the value
specified. Perforce will abort the command if continuing would
produce more than this number of results. Note that once set,
this limit remains in force. You can remove the restriction by
setting it to a value of 0.

=item SetMaxScanRows( $value )

Limit the number of records Perforce will scan when processing
subsequent commands to the value specified. Perforce will abort 
the command once this number of records has been scanned. Note 
that once set, this limit remains in force. You can remove the 
restriction by setting it to a value of 0.


=item SetPassword( $password )

Specify the password to use when authenticating this user against
the Perforce Server - overrides all defaults. Not to be 
confused with C<RunPassword()>.

=item SetPort( $port )

Set the port on which your Perforce server is listening. Defaults
to:

    1. Value from file specified by P4CONFIG
    2. Value from $ENV{P4PORT}
    3. perforce:1666

=item SetProg( $program_name )

Set the name of your script. This value is displayed in the server log
on 2004.2 or later servers. Defaults to 'Unnamed P4Perl Script' if
not specified.

=item SetTicketFile( $path )

Set the path to the file in which login tickets are stored. If not
specified, the usual Perforce defaults apply.

=item SetIgnoreFile( $path )

Overrides the P4IGNORE file with the specified path.

=item IsIgnored( $path )

Tests the path to see if the file is ignored.

=item SetUser( $username )

Set the Perforce username to use. Defaults to:

    1. Value from file specified by P4CONFIG
    2. Value from C<$ENV{P4USER}>
    3. OS username

=item SetVersion( $version )

Sets the version string of your program. This can be included
in the Perforce Server's logfile.

=item Tagged( [0|1] )

Enable or disable tagged output. Responses from commands that 
support tagged output will be returned in the form of a hashref 
rather than plain text. This makes parsing the responses to
Perforce commands much simpler.

By default, tagged output is B<enabled>. Tagged output may be 
disabled, or re-enabled at any time.

For example:

	$p4->Tagged( 0 );	# Disabled
	$p4->Tagged( 1 );	# Enabled

=back

=head1 RUNNING COMMANDS

The main interface through which Perforce commands are run is
the C<Run()> method documented below. The syntax of
this method is quite verbose, so P4Perl provides several
shorthand wrappers, some explicitly, and some implicitly which
usually make code more concise and readable. Most people
will want to use those rather than call C<Run()> 
directly.

See the section below on L</"RUN SHORTCUTS">.

=over

=item ErrorCount()

Returns the number of errors encountered during execution of the last
command.

=item Errors()

Returns a list of the error strings received during execution of the
last command.

	foreach my $e ( $p4->Errors() ) 
	{
		print("ERROR: $e\n");
	}

Each item in the list is a string, although a P4::Message object can be
retrieved using $p4->Messages().

=item Run( $cmd, [ $arg, ... ] )

Run a Perforce command returning the results. Since Perforce commands
can partially succeed and partially fail, you should check for errors
using C<ErrorCount()>, and warnings using C<WarningCount()>. 

Run() returns a list in array context, and an array ref in scalar
context.

  $results = $p4->Run( "files", "//depot/...@1" );
  @results = $p4->Run( "changes", "-m1", "//...#have" );

Whether you get an array of strings, or an array of hashrefs
depends on whether the server supports tagged output for the
specific command; though modern servers support tagged output
for almost all commands.

You can disable tagged output, and thus get all your results
as strings, by calling C<< $p4->Tagged( 0 ); >> at any time.

=over

=head2 TIP

When developing, if you want to know what kind of output your
server will supply to any command, run it with '-ztag' on the
command line. For example:

 p4 -ztag describe -s 4321

If the output resembles the format used by 'p4 fstat', then
it's tagged output.

=back

=item RunFilelog( $args ... )

Runs a C<p4 filelog> with the supplied arguments, and returns 
the results as an array of P4::DepotFile objects. Tagged
output for C<p4 filelog> is not easy to read, nor is it easy
to handle programmatically, so this wrapper converts it into
an array of objects to make it easier to work with. For
example:

  foreach $file ( $p4->RunFilelog( "//depot/path/..." ) )
  {
      printf( "%s\n", $file->DepotFile() );
      foreach $rev ( $file->Revisions() )
      {
          printf( "... #%d %s by %s@%s %s\n",
	  	$rev->Rev(), 
		$rev->Action(),
		$rev->User(),
		$rev->Client(),
		$rev->Desc() );

	  foreach $integ ( $rev->Integrations() )
	  {	
	    	printf( "... ... %s %s#%d,%d\n",
			$integ->How(),
			$integ->File(),
			$integ->SRev() + 1,
			$integ->ERev()
			);
	  }
      }
  }

=item RunPassword( $oldpass, $newpass )

Run a C<p4 password> command to change the user's password from
$oldpass to $newpass. Not to be confused with C<SetPassword()>
which specifies the password to be used to authenticate.

=item RunResolve( [$resolver] [, $arg...] )

Run a C<p4 resolve> command. Interactive resolves require the
$resolver parameter to be an object of a class derived from
P4::Resolver. In these cases, the C<Resolve()> method of this
class will be called to handle the resolve. For example:

  $resolver = new MyResolver;
  $p4->RunResolve( $resolver );

In non-interactive resolves, no C<P4::Resolver> object is 
required. For example:

  $p4->RunResolve( '-at' );

=item RunSubmit( [ $spec | $arg ] ... )

Submits a changelist. If a hashref is passed as one of the 
arguments, it is taken to be the change specification form
and is passed to the server as input to a C<p4 submit -i>.

If no change spec is supplied, then the submit is executed
as it stands.

For example:

    $change = $p4->FetchChange();
    $change->{ "Description" } = "some text...";
    $p4->RunSubmit( $change );

Or with a 2006.2, or later, server:

    $p4->RunSubmit( "-d", "Some description" );

=item SetInput( $arg )

Save the supplied argument as input to be supplied to a subsequent 
command.  The input may be: a hashref, a scalar string or an array 
of hashrefs or scalar strings. Note that if you pass an array the
array will be shifted once each time the Perforce command in
question asks for user input. A good example of this is 
'p4 password' which prompts once for the old password, and then
twice for the new password.

Most people won't need to call this method as the wrappers around
C<Run()> take care of this for you.

=item WarningCount()

Returns the number of warnings issued by the last command.

 $p4->WarningCount();

=item Warnings()

Returns a list of warning strings from the last command.

	foreach my $w ( $p4->Warnings() ) 
	{
		print("WARN: $w\n");
	}

Each item in the list is a string, although a P4::Message object can be
retrieved using $p4->Messages().

=back

=head1 RUN SHORTCUTS

For convenience, and legibility of code, this module makes use
of Perl's AutoLoader to implement several wrappers around
the C<Run()> method. These include:

=over

=item The Delete*() Methods

Explained in the section entitled L</"WORKING WITH PERFORCE FORMS">

=item The Fetch*() Methods

Explained in the section entitled L</"WORKING WITH PERFORCE FORMS">

=item The Format*() Methods

Explained in the section entitled L</"CONVERTING FORMS BETWEEN FORMATS">

=item The Parse*() Methods

Explained in the section entitled L</"CONVERTING FORMS BETWEEN FORMATS">

=item The Run*() Methods

Any method whose name starts with the prefix 'Run' is interpreted as
an instruction to run a Perforce command. The command to run is
taken from the suffix (after the 'Run'), so:

  $p4->RunInfo();

is equivalent to:

  $p4->Run( "info" );

but is more succinct, and easier to read. This technique can be used
to run B<any> Perforce command.

=item The Save*() Methods

Explained in the section entitled L</"WORKING WITH PERFORCE FORMS">

=head1 WORKING WITH PERFORCE FORMS

Perforce forms are collectively known as 'specs'. It's common for
scripts to want to manipulate these forms, and P4Perl has a range
of features to help you to do this. 

Most of the time, P4Perl converts the Perforce forms into Perl
hashes to make accessing form fields by name easy. You can 
update the hashes and pass them back to P4Perl to update the
forms in the Perforce database.

Most of the form manipulation methods interact with the Perforce
Server, but there are two that do not. They are there to support
scripts that need to convert forms from strings to hashes and
vice-versa (commonly when working with spec depot files). These
methods are C<ParseSpec()> and C<FormatSpec()>.

One could use C<< $p4->Run( "client", "-o" ) >> to fetch a 
client specification from Perforce, but P4Perl provides a
shorthand to simplify script code. Similarly, to update
a Perforce client, one could use:

  $p4->SetInput( $hash );
  $p4->Run( "client", "-i" );

However, since this is a common requirement, P4Perl provides
a shorthand for this too. The C<Fetch*()> and C<Save*()> 
methods are explained in more detail in the following 
sections.

=over

=item Fetch<type>( [ $arg, ... ] )

This is a shorthand for running C<< $p4-E<gt>Run( <type>, "-o" ) >>
and returning the first element of the results. The intent
is to simplify and declutter code, making it easier to read
and write. The following examples show how fetching some 
common specification types can be written simply in a script:

    $label	= $p4->FetchLabel( $labelname );
    $change 	= $p4->FetchChange( $changeno );
    $clientspec	= $p4->FetchClient( $clientname );

=item Save<type>( [ $arg, ... ] )

Saves an object of the specified type (passed as either a
string, or a hashref) into the Perforce database. In fact,
this method is just a convenient shorthand for:

    $p4->SetInput( $spec ); 
    $p4->Run( "cmd", "-i");
    
For example:

    $p4->SaveLabel( $label );
    $p4->SaveChange( $changeno );
    $p4->SaveClient( $clientspec );

=item Delete<type>( [ $flag, ... ], $name )

Deletes the named object from the Perforce repository. The
name of the object is mandatory, and may be preceeded by 
zero or more flags to be passed to the Perforce command 
line. For example:

    $p4->DeleteClient( "foo" );	     # runs 'p4 client -d foo'
    $p4->DeleteChange( "-f", 1234 ); # runs 'p4 change -d -f 1234'

=back

=head3 CONVERTING FORMS BETWEEN FORMATS

Sometimes, we have a form in a hash format, and we want it in
a string; sometimes we have a string, and want a hash. In 
those situations, the following methods will help.

=over

=item FormatSpec( $type, $hash )

Converts a Perforce form of the specified type (client/label etc.)
held in the supplied hash into its string representation. Note that 
shortcut methods are available that obviate the need to supply the 
type argument. The following two examples are equivalent:

    $string = $p4->FormatSpec( "client", $hash );
    $string = $p4->FormatClient( $hash );

See below for more information on the abbreviated form.

=item Format<type>( $hash )

Shorthand for C<< $p4->FormatSpec( <type>, $hash ) >>.
For example:

    $change	= $p4->FetchChange();
    $change->{ 'Description' } = 'Some description';
    $form 	= $p4->FormatChange( $change );
    printf( "Submitting this change:\n\n%s\n", $form );
    $p4->RunSubmit( $change );

=item ParseSpec( $type, $string )

Converts a Perforce form of the specified type (client/label etc.)
in the supplied string into a hash and returns a reference to 
that hash. Note that shortcut methods are available to avoid the
need to supply the type argument. The following two examples are
equivalent:

    $hash = $p4->ParseSpec( "client", $string );
    $hash = $p4->ParseClient( $clientspec );

See below for more information on the abbreviated form.

=item Parse<type>( $string )

Shorthand for C<< $p4->ParseSpec( <type>, $string ) >>. For
example:

    $hash = $p4->ParseClient( $string );
    $hash = $p4->ParseLabel( $string );
    $hash = $p4->ParseBranch( $string );
    $hash = $p4->ParseProtect( $string );
    
=back

=head1 DVCS Support

=over

=item Init

The factory method Init takes a hash of paramiters and initilises
an empty DVCS server, then returns a P4 object.  The new DVCS server
will be created in the specified "directory".

For example, to create a DVCS instance in a local directory 'dvcs':

	my %init;
	$init{"port"} 			= "perforce:1666";
	$init{"user"} 			= "paul";
	$init{"client"} 		= "paul_ws";
	$init{"directory"} 		= "dvcs";
	$init{"casesensitive"} 	= 1;
	$init{"unicode"} 		= 0;

	my $dvcs = P4->Init(\%init);

The returned P4 object $dvcs, can be used for all the normal Perforce
perations relavent to a DVCS instance, e.g.

	my $status = $dvcs->RunStatus();

=item Clone

The factory method Clone takes a full copy of the history (a clone)
from the specified Perforce Server and populates a new DVCS instance.

For example, clone all of //depot/projA/... from a perforce:1666 server:

	my %clone;
	$clone{"port"} 			= "perforce:1666";
	$clone{"user"} 			= "paul";
	$clone{"directory"} 	= "dvcs";
	$clone{"file"} 			= "//depot/projA/...";

	my $dvcs = P4->Clone(\%clone);

If a Progress class is provided in the hash key "progress", then the
progress callbacks are fired during the clone operation.

	package MyProgress;
	{
		use base qw( P4::Progress );
		...
	}
	1;

	package main;
	my %clone;
	...
	$clone{"progress"}		= new MyProgress;

	my $dvcs = P4->Clone(\%clone);

See L<P4::Progress> for details.

=back

=head1 DEBUGGING 

=over 

=item Debug( [ level ] )

Gets and optionally sets the debug level. Without an argument, it 
just returns the current debug level. With an argument, it first updates
the debug level and then returns the new value. For example:

 $p4->Debug( 1 );
 $client->Debug( 0 );
 print( "Debug level = ", $client->Debug(), "\n" );

=back

=head1 COMPATIBILITY WITH PREVIOUS VERSIONS

This version of P4Perl is based on P4Perl from the Perforce Public
Depot, but many method names and behaviours have been changed in order
to be consistent with other Perforce Scripting interfaces. Consequently,
some effort will be required to port legacy P4Perl scripts to the
new interface.

The differences are documented in the P4Perl release notes in the file
'RELNOTES', included in the source distribution.

=head1 SEE ALSO

L<perl>, L<P4::DepotFile>, L<P4::Revision>, L<P4::Integration>,
L<P4::Resolver>, L<P4::MergeData>, L<P4::Message>, L<P4::Progress>

=head1 COPYRIGHT

Copyright (c) 2001-2008 Perforce Software. All rights reserved.

=cut

#
# Execute a command. The return value depends on the context of the call.
#
# Returns a list of results
#
sub Run {
	my $self = shift;

	# Check for tainted data if in taint mode
	foreach my $arg (@_) {
		if ( tainted($arg) ) {
			die("Can't pass tainted arguments to Perforce commands!");
		}
	}

	return $self->_Run(@_);
}

# Change the current working directory. Returns undef on failure.
sub SetCwd( $ ) {
	my $self = shift;
	my $cwd  = shift;

	# First we chdir to the dir if it exists. If successful, then we
	# update the PWD environment variable (if defined) and call the
	# API equivalent function, now named _SetCwd()
	return undef unless chdir($cwd);
	$ENV{"PWD"} = $cwd if ( defined( $ENV{"PWD"} ) );
	$self->_SetCwd($cwd);
	return $cwd;
}

#
# Run 'p4 login' using the password supplied by the user
#
sub RunLogin {
	my $self = shift;
	$self->SetInput( $self->GetPassword() );
	return $self->Run( "login", @_ );
}

#
# Run 'p4 passwd' to change the password
#
sub RunPassword {
	my $self    = shift;
	my $oldpass = shift;
	my $newpass = shift;

	my $args = [ $oldpass, $newpass, $newpass ];
	if ( $oldpass eq "" ) {

		# No old password, so set new one.
		$args = [ $newpass, $newpass ];
	}
	$self->SetInput($args);
	return $self->Run("password");
}

#
# Run 'p4 tickets' to fetch a hash of tickets
#
sub RunTickets {
	my $self = shift;

	my $path = $self->GetTicketFile();

	if ( -e $path ) {
		open( FILE, "<", $path ) or die $!;

		my @tickets;
		while (<FILE>) {
			chomp $_;
			$_ =~ /([^=]*)=(.*):([^:]*)$/;
			my %part = ( 'Host' => $1, 'User' => $2, 'Ticket' => $3 );
			push( @tickets, \%part );
		}
		close(FILE);
		return \@tickets;
	}
}

#*******************************************************************************
#* Useful shortcut methods to make common actions easier to code. Nothing
#* here that can't be done using the already defined methods.
#*******************************************************************************

# RunSubmit	- "p4 submit -i"
#
# Submit a changelist to the server. if one of the supplied arguments is a
# hashref, then it will be assumed to contain the change form ready to be
# sent to the server.
#
# Synopsis:	$p4->RunSubmit( args... );
sub RunSubmit( $@ ) {
	my $self = shift;
	my @args;
	my $haveSpec = 0;

	foreach my $arg (@_) {
		if ( ref($arg) eq "HASH" || ref($arg) eq "P4::Spec" ) {
			$self->SetInput(shift);
			$haveSpec++;
		}
		else {
			push( @args, $arg );
		}
	}
	unshift( @args, "-i" ) if ($haveSpec);
	$self->Run( "submit", @args );
}

#
# RunFileLog() (note capital L). This is a common error in people's scripts,
# so here we'll define it as an alias for RunFilelog, but warn them.
#
sub RunFileLog( $@ ) {
	my $self = shift;
	warn("Use RunFilelog() instead of RunFileLog()...");
	return $self->RunFilelog(@_);
}

#
#
# RunFilelog(): Converts the hard-to-parse output of 'p4 filelog' into
# an array of P4::DepotFile objects which are easier to work with.
#

sub RunFilelog( $@ ) {
	my $self = shift;
	my @results;
	foreach my $r ( $self->Run( "filelog", @_ ) ) {
		if ( ref( $r eq "HASH" ) ) {
			push( @results, $r );
			next;
		}

		my $df = new P4::DepotFile( $r->{'depotFile'} );
		push( @results, $df );

		my $rcount = scalar( @{ $r->{'rev'} } );
		for ( my $i = 0 ; $i < $rcount ; $i++ ) {

			# Create a new revision object
			my $rev = $df->NewRevision();

			foreach my $key ( keys %$r ) {
				next unless ( ref( $r->{$key} ) eq "ARRAY" );
				next unless defined( $r->{$key}[$i] );
				next if ref( $r->{$key}[$i] );
				$rev->SetAttribute( $key, $r->{$key}[$i] );
			}

			# Now see if there are integration records to add
			next unless $r->{'how'};
			next unless $r->{'how'}[$i];

			my $icount = scalar( @{ $r->{'how'}[$i] } );
			for ( my $j = 0 ; $j < $icount ; $j++ ) {
				my $how  = $r->{'how'}[$i][$j];
				my $file = $r->{'file'}[$i][$j];
				my $srev = $r->{'srev'}[$i][$j];
				my $erev = $r->{'erev'}[$i][$j];

				$srev =~ s/^#//;
				$erev =~ s/^#//;
				$srev = 0 if $srev eq "none";
				$erev = 0 if $erev eq "none";

				$rev->Integration( $how, $file, $srev, $erev );
			}
		}
	}
	return @results if (wantarray);
	return \@results;
}

# Makes the Perforce commands usable as methods on the object for
# cleaner syntax. If it's not a valid method, you'll find out when
# Perforce recommends you read the help.
#
# Also implements Fetch/Save methods for common Perforce commands. e.g.
#
#	$label = $p4->FetchLabel( "labelname" );
#	$change = $p4->FetchChange( [ changeno ] );
#
#	$p4->SaveChange( $change );
#	$p4->SaveUser( $p4->GetUser( "username" ) );
#
# Use with care as it's not too clever. SaveSubmit is perfectly valid as
# far as this code is concerned, but it doesn't do much!
#
sub AUTOLOAD {
	my $self = shift;
	my $cmd;
	( $cmd = $AUTOLOAD ) =~ s/.*:://;
	$cmd = lc $cmd;

	if ( $cmd =~ /^save(\w+)/i ) {
		die("save$1 requires an argument!") if ( !scalar(@_) );
		$self->SetInput(shift);
		return $self->Run( $1, "-i", @_ );
	}
	elsif ( $cmd =~ /^Fetch(\w+)/i ) {

		# Run returns an array, but in the case of the fetch
		# methods, we shift it to get the first entry unless
		# the caller is in array context.
		my @r = $self->Run( $1, "-o", @_ );
		return @r if wantarray;
		return shift(@r);
	}
	elsif ( $cmd =~ /^delete(\w+)/i ) {
		die("Delete$1 requires an argument!") if ( !scalar(@_) );
		return $self->Run( $1, "-d", @_ );
	}
	elsif ( $cmd =~ /^parse(\w+)/i ) {
		die("Parse$1 requires an argument!") if ( !scalar(@_) );
		my $form = $_[0];
		my $comment;
		foreach my $l ( split(/\r\n?|\n/, $form) ) {
			if ($l =~ /^#/) {
				$comment .=  $l . "\n";
			}
		}
        my $spec = $self->ParseSpec( $1, $form );
        # If there is a problem with processing the spec, we will
        # get undefined returned, need to catch it before we add comments.
        unless (defined $spec){
            die("Invalid specification");
        } 
        $spec->{'comment'} = $comment;
        return $spec;
	}
	elsif ( $cmd =~ /^format(\w+)/i ) {
		die("Format$1 requires an argument!") if ( !scalar(@_) );
		my $spec = $_[0];
		my $form = $self->FormatSpec( $1, $spec );
		$form = $spec->{'comment'} . $form if ( $spec->{'comment'} );
		return $form;
	}
	elsif ( $cmd =~ /^iterate(\w+)/i ) {
		return P4::IterateSpec->new( $self, $1, @_ );
	}
	elsif ( $cmd =~ /^iterate/i ) {
		die("Iterate requires an argument!") if ( !scalar(@_) );
		return P4::IterateSpec->new( $self, @_ );
	}
	elsif ( $cmd =~ /^run(\w+)/i ) {
		return $self->Run( $1, @_ );
	}
	else {
		die("No $cmd method in P4 class");
	}
}

1;
__END__
