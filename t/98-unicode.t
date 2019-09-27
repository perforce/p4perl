use Test::More tests => 8;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
$test->EnableUnicode();
my $p4 = $test->InitClient();

ok( defined( $p4 ) );
$p4->SetProg( $0 );
$p4->SetCharset( 'iso8859-1' );

ok( $p4->Connect() );
ok( $p4->ServerUnicode() );

# Add a test file with a £ sign in it. That has the high bit set
# so we can test it in both iso8859-1 and utf-8

my $tf = "test_files/unicode.txt";
open( FH, ">$tf" );
print( FH "This file cost \xa31\n" );
close( FH );

$p4->RunAdd( $tf );
ok( scalar( () = $p4->RunOpened() ) == 1 );

$p4->RunSubmit( '-d', "Add unicode test file" );
ok( scalar( () = $p4->RunOpened() ) == 0 );

# Now remove the file from the workspace, disconnect, switch to 
# utf8, reconnect and resync the file. Then we'll read it and
# see that the file contains the unicode sequence for the £
# symbol.

$p4->RunSync( $tf . "#none" );
$p4->Disconnect();
$p4->SetCharset( 'utf8' );
$p4->Connect();
$p4->RunSync();

my $buf;
open( FH, "<$tf" );
$buf = <FH>;
chomp( $buf );
close( FH );

ok( $buf eq "This file cost \xc2\xa31" );
