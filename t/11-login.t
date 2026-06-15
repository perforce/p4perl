use Test::More tests => 9;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
my $p4 = $test->InitClient();

# Strong (8+ char) passwords so p4d 2026.1 SBD's security=4 accepts them.
# The bootstrap in p4test.pm has already set the user's password to
# $P4::Test::SUPER_PASSWORD, so the "old" arg to RunPassword must be that.
my $test_pw = 'P4Test!Pwd99';
my $bad_pw  = 'WrongPass!99';

ok( defined( $p4 ) );
$p4->SetProg( $0 );
ok( $p4->Connect() );

$p4->Debug( 0 );

# Change password from the bootstrap-set value to test_pw.
$p4->RunPassword( $P4::Test::SUPER_PASSWORD, $test_pw );
ok( $p4->ErrorCount() == 0 );

# Now disconnect, and reconnect to force authentication update
$p4->Disconnect();
$p4->Connect();

# Now attempt login with bad password.
$p4->SetPassword( $bad_pw );
$p4->RunLogin();
ok( $p4->ErrorCount() == 1 );
my @e = $p4->Errors();
ok( $e[0] =~ /invalid/i || $e[0] =~ /[Aa]uthentication failed/ );

# Now login with the correct password
$p4->SetPassword( $test_pw );
$p4->RunLogin();
ok( $p4->ErrorCount() == 0 );

# Now see how long the ticket is valid for...
$p4->Tagged( 0 );
my @r = $p4->RunLogin( '-s' );
ok( $r[0] =~ /ticket expires in/ );

# Restore the bootstrap-set password so subsequent tests authenticate.
$p4->RunPassword( $test_pw, $P4::Test::SUPER_PASSWORD );
# Re-login so the ticket file has a current ticket (the previous one was
# invalidated by the password change above).
$p4->SetPassword( $P4::Test::SUPER_PASSWORD );
$p4->RunLogin();
