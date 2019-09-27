use Test::More tests => 23;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
my $map = new P4::Map;

ok( defined( $map ) );
ok( $map->IsEmpty() );

$map->Insert( "//depot/main/...", "//ws/main/..." );
is( $map->Count(), 1, "Map has one entry" );
ok( !$map->IsEmpty() );

$map->Insert( "//depot/live/... //ws/live/..." );
is( $map->Count(), 2, "Map has two entries" );

# This one forces some disambiguation
$map->Insert( "//depot/bad/...", "//ws/live/bad/..." );
is( $map->Count(), 4, "Map has four entries" );

# Basic translation
$p = $map->Translate( "//depot/main/foo/bar" );
is( $p, "//ws/main/foo/bar", "Translated depot path" );

$p = $map->Translate( "//ws/main/foo/bar", 0 );
is( $p, "//depot/main/foo/bar", "Translated in reverse direction" );

# Map inclusion
ok( $map->Includes( "//ws/main/foo/bar" ) );

# Map joining
$ws_map = new P4::Map;
$ws_map->Insert( "//ws/...", "/home/user/ws/..." );
ok( !$ws_map->IsEmpty() );

$root_map = P4::Map::Join( $map, $ws_map );
ok( !$root_map->IsEmpty() );

# Now translate a depot path to a local path
$p = $root_map->Translate( "//depot/main/foo/bar" );
is( $p, "/home/user/ws/main/foo/bar" );

# Now reverse the map and translate again
$root_map = $root_map->Reverse();
$p = $root_map->Translate( "/home/user/ws/main/foo/bar" );
is( $p, "//depot/main/foo/bar" );

# Now clear the map and check it's empty
ok( !$map->IsEmpty() );
$map->Clear();
ok( $map->IsEmpty() );

# Check array construction and quoted mappings
$map = new P4::Map( [ '"//depot/space dir1/..." "//ws/space dir1/..."' ,
		      '"//depot/space dir2/..." "//ws/space dir2/..."' ,
		      '"//depot/space dir3/..." "//ws/space dir3/..."' ] );

$map->Insert( "//depot/space dir4/...", "//ws/space dir4/..." );
$map->Insert( '"//depot/space dir5/..."', '"//ws/space dir5/..."' );

is( $map->Count(), 5, "Map has 5 entries" );
$p = $map->Translate( "//depot/space dir1/file" );
is( $p, "//ws/space dir1/file" );
$p = $map->Translate( "//depot/space dir2/file" );
is( $p, "//ws/space dir2/file" );
$p = $map->Translate( "//depot/space dir3/file" );
is( $p, "//ws/space dir3/file" );
$p = $map->Translate( "//depot/space dir4/file" );
is( $p, "//ws/space dir4/file" );
$p = $map->Translate( "//depot/space dir5/file" );
is( $p, "//ws/space dir5/file" );
