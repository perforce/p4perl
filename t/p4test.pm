#-------------------------------------------------------------------------------
# Class for standardising all tests for P4Perl
#-------------------------------------------------------------------------------

package P4::Test;
use Cwd;

our $START_DIR	= cwd();
our $ROOT_DIR	= qw( testroot );
our $P4D	= qw( p4d );

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

