use Test::More tests => 13;
BEGIN { use_ok('P4'); }    ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");      ## test 2

require_ok("file_hdl");    ## test 3

my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );        ## test 4
ok( $p4->Connect() );      ## test 5

## create callback object
my $file_cb = new file_hdl;

## test set/get methods
$p4->SetHandler($file_cb);
my $h = $p4->GetHandler();
ok( $h->isa(file_hdl) );    ## test 6
is( $h, $file_cb );         ## test 7

## test callback: mode 0 - 'add output'
my @s1 = $p4->RunFiles("//...");
ok( scalar(@s1) == 9 );     ## test 8
my $c1 = $file_cb->getCount('outputStat');
ok( $c1 == 9 );             ## test 9

## test callback: mode 1 - 'no output'
$file_cb->setReturn(1);
$p4->SetHandler($file_cb);
my @s2 = $p4->RunFiles("//...");
ok( scalar(@s2) == 0 );     ## test 10
my $c2 = $file_cb->getCount('outputStat');
ok( $c2 == 9 );             ## test 11

## test break: mode 2/3
diag("\nTest will abort callback, expect an RpcTransport message...");
add_file( $p4, 100 );
$file_cb->setReturn(3);
$p4->SetHandler($file_cb);
my @s3 = $p4->RunFiles("//...");
ok( scalar(@s3) == 0 );     ## test 12
my $c3 = $file_cb->getCount('outputStat');
ok( $c3 < 100 );            ## test 13


sub add_file {
	my $p4  = shift;
	my $max = shift;

	mkdir("more_files") or die("Can't create subdirectory 'more_files'");
	my $id = 0;
	do {
		my $n = "more_files/file.$id.txt";
		open( FH, ">$n" ) or die("Can't create '$n'");
		print( FH "This is a test file\n" );
		close(FH);
		$p4->RunAdd($n);
		$id++;
	} while ( $id <= $max );

	## Submit
	my $change = $p4->FetchChange();
	$change->{'Description'} = "Adding $id test files";
	$p4->RunSubmit($change);
}
