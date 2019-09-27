use Test::More tests => 2;
BEGIN { use_ok( 'P4' ); }

# Now test that 'p4d' is in the path. We'll rely heavily on 
# this in later tests.
ok( length( `p4d -h` ) > 0 );

