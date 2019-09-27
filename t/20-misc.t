use Test::More tests => 11;
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

# First we run a 'p4 counter change' in what should be tagged mode. Then
# we run it again with tagged mode off. Then we turn tagged mode on, but
# run it again turning it temporarily off.

ok( $p4->IsTagged() );
my @r = $p4->RunCounter( 'change' );
ok( ref( $r[ 0 ] ) eq "HASH" );
my $val = $r[ 0 ]->{ 'value' };

$p4->Tagged( 0 );
ok( ! $p4->IsTagged() );

@r = $p4->RunCounter( 'change' );
is( $r[ 0 ], $val );

$p4->Tagged( 1 );
ok( $p4->IsTagged() );

my $sub = sub { @r = $p4->RunCounter( 'change' ) };

$p4->Tagged( 0, $sub );
is( $r[ 0 ], $val );
ok( $p4->IsTagged() );
