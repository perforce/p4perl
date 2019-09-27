use Test::More tests => 9;
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

$p4->Debug( 0 );

# First set a password on our account
$p4->RunPassword( "", "foo" );
ok( $p4->ErrorCount() == 0 );

# Now disconnect, and reconnect to force authentication update
$p4->Disconnect();
$p4->Connect();

# Now attempt login with bad password. Note, if P4Perl is built
# with an API older than 2010.2, this will fail.
$p4->SetPassword( "bar" );
$p4->RunLogin();
ok( $p4->ErrorCount() == 1 );
@e = $p4->Errors();
ok( $e[0] =~ /invalid/ );

# Now login with the correct password
$p4->SetPassword( "foo" );
$p4->RunLogin();
ok( $p4->ErrorCount() == 0 );

# Now see how long the ticket is valid for...
$p4->Tagged( 0 );
my @r = $p4->RunLogin( '-s' );
ok( $r[0] =~ /ticket expires in/ );
