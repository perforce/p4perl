use Test::More tests => 11;
BEGIN { use_ok('P4'); }                         ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");                           ## test 2


my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );                             ## test 3
ok( $p4->Connect() );                           ## test 4

##
## DVCS Init test
##
my %init;
$init{"port"} = $p4->GetPort();
$init{"user"} = $p4->GetUser();
$init{"client"} = $p4->GetClient();
$init{"directory"} = $test->ClientRoot() . "/init";
$init{"casesensitive"} = 1;
$init{"unicode"} = 0;

my $dvcs1 = P4->Init(\%init);
ok( defined($dvcs1) );                          ## test 5

ok( $dvcs1->GetPort() =~ "rsh:" );              ## test 6
is( $dvcs1->GetCwd(), $init{"directory"} );     ## test 7

ok( $dvcs1->Connect() );                        ## test 8

@depots = $dvcs1->RunDepots();
ok( scalar( @depots ) == 1 );                   ## test 9

$dvcs1->Disconnect();

##
## DVCS Clone test
##
$p4->RunConfigure( 'set', 'server.allowfetch=3' );
$p4->RunConfigure( 'set', 'server.allowpush=3' );

## need to disconnect to enable the configure variables (fix 16.2)
$p4->Disconnect();
$p4->Connect();

my %clone;
$clone{"port"} = $p4->GetPort();
$clone{"user"} = $p4->GetUser();
$clone{"directory"} = $test->ClientRoot() . "/clone";
$clone{"file"} = "//depot/test_files/...";

my $dvcs2 = P4->Clone(\%clone);
ok( $dvcs2->Connect() );                        ## test 10

@files = $dvcs2->RunFiles('//...');
ok( scalar( @files ) > 1 );                     ## test 11

$dvcs2->Disconnect();