#-------------------------------------------------------------------------------
# Class for standardising all tests for P4Perl
#-------------------------------------------------------------------------------

package P4::Test;
use Cwd;
use P4;

our $START_DIR	= cwd();
our $ROOT_DIR	= qw( testroot );
our $P4D	= qw( p4d );

# On p4d 2026.1+ (Secure By Default), password authentication is enforced
# from the very first connection. The one unauthenticated operation
# allowed on a fresh server is `p4 passwd '' <new>` to set the initial
# super user password. Tests bootstrap this once when the testroot is
# created so all subsequent commands authenticate via the cached ticket.
our $SUPER_PASSWORD = 'P4Perl!Super1';

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    my $root = $self->ServerRoot();
    $self->{ 'P4PORT' } = "rsh:$P4D -r $root -L log -vserver=3 -i";
    $self->{ 'P4CLIENT' } = "test-client";

    delete $ENV{ 'PWD' };
    return $self;
}

sub InitClient()
{
    my $self = shift;
    chdir( $self->ClientRoot() ) or die( "Can't go to client workspace" );

    my $p4 = new P4;
    $p4->SetPort( $self->{ 'P4PORT' } );
    $p4->SetClient( $self->{ 'P4CLIENT' } );
    $p4->SetCwd( $self->ClientRoot() );	 # Make sure the client knows 
    					 # where it is.
    $p4->ClearHandler();
    return $p4;
}

sub CreateTestTree()
{
    my $self = shift;

    if( -d $self->ServerRoot() )
    {
	#printf( "Removing old test tree!" );
	$self->CleanupTestTree() or die( "Can't remove old test tree" );
    }

    mkdir( $self->ServerRoot() );
    mkdir( $self->ClientRoot() );
    $self->CreateP4ConfigFile();
    $self->BootstrapSuperUser();
}

# Set the initial super user password and cache a ticket so all subsequent
# test connections can authenticate. Required on p4d 2026.1+ (SBD). Safe
# on older p4d — eval rescues any failure. Uses a single P4 instance to
# avoid spawning a second p4d child whose SIGCHLD could interrupt other
# tests' pipe reads.
sub BootstrapSuperUser
{
    my $self = shift;
    my $p4 = new P4;
    $p4->SetPort( $self->{ 'P4PORT' } );
    $p4->SetClient( $self->{ 'P4CLIENT' } );

    eval {
	$p4->Connect() or return;
	# Best-effort: ensure user record exists before passwd. On SBD this
	# may fail (pre-auth commands rejected); passwd creates the user.
	eval {
	    my $user_spec = $p4->FetchUser();
	    $p4->SaveUser( $user_spec, '-f' ) if $user_spec;
	};
	$p4->RunPassword( '', $SUPER_PASSWORD );
	$p4->SetPassword( $SUPER_PASSWORD );
	$p4->RunLogin();
    };
    eval { $p4->Disconnect() if $p4->IsConnected(); };
}

sub CleanupTestTree()
{
    my $self = shift;
    $self->Rmdir( $self->ServerRoot() );
}


sub ServerRoot()
{
    return $START_DIR . "/" . $ROOT_DIR;
}

sub ClientRoot()
{
    my $self = shift;
    return $self->ServerRoot() . "/workspace";
}

sub EnableUnicode()
{
    my $self = shift;
    my $cmd = "$P4D -r" . $self->ServerRoot() . " -xi";

    `$cmd`;
}

# Private


sub Rmdir( $ )
{
    my $self = shift;
    my $path = shift;

    opendir( DH, $path ) or die( "Can't read directory $path" );
    my @entries = readdir( DH );
    closedir( DH );

    foreach my $d ( @entries )
    {
	next if( $d eq "." || $d eq ".." );

	my $p = "$path/$d";
	if( -d $p )
	{
	    $self->Rmdir( $p );
	}
	else
	{
	    unlink( $p ) or die( "Can't remove file $p" );
	}
    }
    rmdir( $path ) or die( "Can't remove directory $path" );
}

sub CreateP4ConfigFile()
{
    my $self = shift;
    my $cfg_file = P4ConfigFileName();

    return unless defined( $cfg_file );
    $cfg_file = $self->ServerRoot() . '/' . $cfg_file;
    my $p4port	 = $self->{ 'P4PORT' };
    my $p4client = $self->{ 'P4CLIENT' };
    open( FH, ">$cfg_file" ) or die( "Can't create P4CONFIG file" );
    print( FH "P4PORT=$p4port\n" );
    print( FH "P4CLIENT=$p4client\n" );
    close( FH );
}

sub P4ConfigFileName()
{
    return $ENV{'P4CONFIG'} if defined $ENV{'P4CONFIG'};
    my $c = `p4 set P4CONFIG`;
    if( $c =~ /^P4CONFIG=(.*) \(.*\)/ ) 
    {
	return $1;
    }
    return undef;
}

1;

