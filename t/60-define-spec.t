use Test::More tests => 5;
BEGIN { use_ok('P4'); }             ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");               ## test 2

my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );                 ## test 3
ok( $p4->Connect() );               ## test 4

## Fetch user object and format to string
my $userStr = $p4->FormatUser($p4->FetchUser());

## Add 'Custom' field to spec
$userStr .= "\nCustom: foo\n";

## load custom spec, to simulate %specdef%
my $spec = "User;code:651;rq;ro;seq:1;len:32;;Type;code:659;ro;fmt:R;len:10;;Email;code:652;fmt:R;rq;seq:3;len:32;;Update;code:653;fmt:L;type:date;ro;seq:2;len:20;;Access;code:654;fmt:L;type:date;ro;len:20;;FullName;code:655;fmt:R;type:line;rq;len:32;;JobView;code:656;type:line;len:64;;Password;code:657;len:32;;AuthMethod;code:662;fmt:L;len:10;val:perforce/ldap;;Custom;code:999;fmt:L;len:10;val:bar;;Reviews;code:658;type:wlist;len:64;;";

$p4->DefineSpec('user', $spec);
ok( $p4->ParseUser($userStr) );     ## test 5
