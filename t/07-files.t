use Test::More tests => 21;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
my $p4 = $test->InitClient();

ok( defined( $p4 ) );
$p4->SetProg( $0 );
ok( $p4->Connect() );

#
# Create a subdirectory add some files into it
#
mkdir( "test_files" ) or die( "Can't create subdirectory 'test_files'");
foreach my $f ( qw( foo bar baz ) )
{
    my $p = "test_files/$f";
    open( FH, ">$p" ) or die( "Can't create '$p'" );
    print( FH "This is a test file\n" );
    close( FH );
    $p4->RunAdd( $p );
}
@opened = $p4->RunOpened();
ok( scalar( @opened ) == 3 );

#
# Now submit them using a spec
#
my $change = $p4->FetchChange();
$change->{ 'Description' } = "Adding test files";
$p4->RunSubmit( $change );

@files = $p4->RunFiles( "test_files/..." );
ok( scalar( @files ) == 3 );

@opened = $p4->RunOpened();
ok( scalar( @opened ) == 0 );

#
# Now open our files for edit and resubmit them
#
@files = $p4->RunEdit( "test_files/..." );
ok( scalar( @files ) == 3 );

$change = $p4->FetchChange();
$change->{ 'Description' } = "Editing the test files";
$p4->RunSubmit( $change );

@opened = $p4->RunOpened();
ok( scalar( @opened ) == 0 );

#
# Now lets branch them elsewhere
#
@files = $p4->RunInteg( "test_files/...", "test_branch/..." );
ok( scalar( @files ) == 3 );

$change = $p4->FetchChange();
$change->{ 'Description' } = "Branch the test files";
$p4->RunSubmit( $change );

@opened = $p4->RunOpened();
ok( scalar( @opened ) == 0 );

#
# And branch them again
#
@files = $p4->RunInteg( "test_files/...", "test_branch2/..." );
ok( scalar( @files ) == 3 );

$change = $p4->FetchChange();
$change->{ 'Description' } = "Branch the test files again";
$p4->RunSubmit( $change );

@opened = $p4->RunOpened();
ok( scalar( @opened ) == 0 );

#
# Now lets check out filelog
#
@files = $p4->RunFilelog( "test_files/..." );
ok( scalar( @files ) == 3 );

my $df = $files[ 0 ];
ok( $df->DepotFile() eq "//depot/test_files/bar" );
ok( scalar( @{$df->Revisions()} ) == 2 );

my $rev2 = $df->Revisions();
ok( ref( $rev2 ) eq "ARRAY" );
$rev2 = $rev2->[ 0 ];
ok( $rev2->Rev() == 2 );
ok( scalar( @{ $rev2->Integrations() } == 2 ) );
ok( $rev2->Integrations()->[0]->How() eq "branch into" );
ok( $rev2->Integrations()->[0]->File() eq "//depot/test_branch/bar" );
