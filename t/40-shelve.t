use Test::More tests => 12;
BEGIN { use_ok('P4'); }    ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");      ## test 2


my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );        ## test 3
ok( $p4->Connect() );      ## test 4

## Create pending change and grab number 
my $changespec = $p4->FetchChange();
$changespec->{ 'Description' } = "Shelving test";
my @change = $p4->SaveChange( $changespec );
@words = split(' ',$change[0]);
$changeNumber = $words[1];
ok( $changeNumber > 1 );						## test 5

## Add files to pending change
mkdir( "shelve" ) or die( "Can't create subdirectory 'shelve'");
my $file = "shelve/foo.txt";
open( FH, ">$file" ) or die( "Can't create '$file'" );
print( FH "This is a test file\n" );
close(FH);
my @add = $p4->RunAdd( "-c", $changeNumber, $file );
ok( $add[0]->{workRev} == 1 );					## test 6

## Shelve file
my @slv = $p4->RunShelve("-c", $changeNumber);
ok( $slv[0]->{change} == $changeNumber );		## test 7

## Look for shelf
my @slf = $p4->RunChanges("-sshelved");
ok( $slf[0]->{change} == $changeNumber );		## test 8

## Revert open file
my @rvt = $p4->RunRevert($file);
ok( $rvt[0]->{action} eq "abandoned" );			## test 9
unlink($file);

## Unshelve file
my @uslv = $p4->RunUnshelve("-s", $changeNumber);
ok( $uslv[0]->{action} eq "add" );				## test 10

## Delete shelf
$p4->RunShelve("-d", "-c", $changeNumber);
@slf = $p4->RunChanges("-sshelved");
ok( scalar( @slf ) == 0 );						## test 11

## Cleanup
@rvt = $p4->RunRevert($file);
ok( $rvt[0]->{action} eq "abandoned" );			## test 12
unlink($file);
