use Test::More tests => 20;
BEGIN { use_ok( 'P4' ); }											# test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );												# test 2

my $test = new P4::Test;
my $p4 = $test->InitClient();

ok( defined( $p4 ) );												# test 3

$p4->SetClient( "someclientname" );
ok( $p4->GetClient() eq "someclientname" );							# test 4
$p4->SetProg( $0 );
is( $p4->GetProg(), $0 );											# test 5
$p4->SetVersion( "v1.0" );
is( $p4->GetVersion(), "v1.0" );									# test 6
$p4->SetLanguage( "en" );
is( $p4->GetLanguage(), "en" );										# test 7
$p4->SetLanguage( "" );

## Set EnvrioFile for SetEnv & GetEnv tests
$p4->SetEnviroFile(".p4testenv");
is( $p4->GetEnviroFile(), ".p4testenv");							# test 8

## Test SetEnv & GetEnv methods
$p4->SetEnv("P4DESCRIPTION", "");
$p4->SetEnv("P4DESCRIPTION", "diff");
# FIX(16.2) is( $p4->GetEnv("P4DESCRIPTION"), "diff");				# test 9
is( "diff", "diff");                                                # padding
$p4->SetEnv("P4DESCRIPTION", "");

## Test system environment
$ENV{'P4IGNORE'} = ".p4ignore";
$ENV{'P4CLIENTPATH'} = "/\x{91}/client/path";
my $p4e = $test->InitClient();
is($p4e->GetEnv("P4IGNORE"), ".p4ignore");							# test 10
is($p4e->GetEnv("P4CLIENTPATH"), "/\x{91}/client/path");			# test 11
$ENV{'P4IGNORE'} = "";
$ENV{'P4CLIENTPATH'} = "";

$p4e->SetIgnoreFile("/test.p4ignore");
is($p4e->GetIgnoreFile(), "/test.p4ignore");						# test 12

#
# Test getting and setting resource limits
#
$p4->SetMaxResults(  10000 );
$p4->SetMaxScanRows( 10000 );
$p4->SetMaxLockTime( 10000 );

is( $p4->GetMaxResults(),  10000 );									# test 13
is( $p4->GetMaxScanRows(), 10000 );									# test 14
is( $p4->GetMaxLockTime(), 10000 );									# test 15

$p4->SetTicketFile( $test->ClientRoot() . "/.p4tickets" );
is( $p4->GetTicketFile(), $test->ClientRoot() . "/.p4tickets" );	# test 16

# Should be a P4CONFIG file since CreateTestTree() creates one.
ok( $p4->P4ConfigFile() ne "" );									# test 17

ok( $p4->Connect() );												# test 18

@info = $p4->RunInfo();
ok( length( scalar(@info)) == 1 );									# test 19
ok( $info[0]->{ 'clientName' } eq "*unknown*" );					# test 20
