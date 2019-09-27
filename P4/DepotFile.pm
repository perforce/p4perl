#-------------------------------------------------------------------------------
# Copyright (c) 2007-2010, Perforce Software, Inc.  All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE SOFTWARE, INC. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-------------------------------------------------------------------------------
package P4::DepotFile;
use AutoLoader;
use P4::Revision;
use P4::Integration;
use vars qw( $AUTOLOAD );

=pod

=head1 NAME

P4::DepotFile

=head1 SYNOPSIS

    use P4;
    $p4 = new P4;
    $p4->Connect() or die( "Failed to connect to Perforce" );
    for $file in ( $p4->RunFilelog( "//depot/some/file" ) )
    {
	...
    }

=head1 DESCRIPTION

P4::DepotFile objects are used to present information about
files in the Perforce repository to the user. They are returned
by C<P4::RunFilelog()>.

=head1 METHODS

=cut

=pod

=over

=item new()

=over

C<$df = new P4::DepotFile( $depotFile );>

Constructs a new P4::DepotFile object for the specified depot file.

=back

=back

=cut
sub new( $ )
{
    my $class = shift;
    my $name = shift;
    my $self = {};
    bless( $self, $class );

    $self->DepotFile( $name );
    $self->{ 'revisions' } = [];
    return $self;
}


=pod

=over

=item NewRevision()

=over

C<$df-E<gt>NewRevision();>

Creates a new revision of the depotFile and returns is to the
caller. This is a private method. Not intended for use in user 
scripts.

=back

=back

=cut
sub NewRevision()
{
    my $self = shift;
    my $rev = new P4::Revision( $self->DepotFile() );
    push( @{$self->{ 'revisions' }}, $rev );
    return $rev;
}

#
# Destructor. Nothing to do, but it prevents the AutoLoader
# from getting involved in destruction.
#
sub DESTROY
{
}

# Documentation for methods implemented by the AutoLoader

=pod

=over

=item DepotFile()

=over

C<$df-E<gt>DepotFile();>

Returns the name of the depot file.

=back

=back

=over

=item Revisions()

=over

C<$df-E<gt>Revisions();>

Returns an array of P4::Revision objects representing
all the revisions records for this revision.

=back

=back

=cut


sub AUTOLOAD
{
    my $self = shift;
    my $field;
    ($field = $AUTOLOAD ) =~ s/.*:://;
    $field = lc $field;

    if( scalar( @_ ) )
    {
	$self->{ $field } = shift;
    }
    if( wantarray && ref( $self->{ $field } ) eq "ARRAY" )
    {
	return @{ $self->{ $field } };
    }
    return $self->{ $field };
}

=pod

=head1 SEE ALSO

L<P4>, L<P4::Revision>, L<P4::Integration>, L<P4::Map>,
L<P4::Resolver>, L<P4::Spec>, L<P4::MergeData>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2007-2010, Perforce Software, Inc. All rights reserved.

=cut
1;
__END__
