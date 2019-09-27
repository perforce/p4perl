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
package P4::Integration;
use AutoLoader;
use vars qw( $AUTOLOAD );

=pod

=head1 NAME

P4::Integration

=head1 SYNOPSIS

    use P4;
    $p4 = new P4;
    $p4->Connect() or die( "Failed to connect to Perforce" );
    for $file in ( $p4->RunFilelog( "//depot/some/file" ) )
    {
    	for $rev in ( $file->Revisions() )
	{
	    for $integ in ( $rev->Integrations() )
	    {
	    	...
	    }
	}


=head1 DESCRIPTION

P4::Integration objects represent Perforce integration records.
While users are free to create objects of this class in their
own scripts, their primary use is that they are returned as
part of the output of C<P4::RunFilelog()>.

=head1 METHODS

=cut


=pod

=over

=item new()

=over

C<$integ = new P4::Integration( $how, $file, $srev, $erev );>

Creates a new P4::Integration object representing an 
integration to/from C<$file#$srev+1,$erev>. It's 
important to note that C<$srev> is always one lower 
than its actual value.

=back

=back

=cut
sub new( $$$$ )
{
    my $class = shift;
    my $self = {};
    bless( $self, $class );
    
    $self->How( shift );
    $self->File( shift );
    $self->SRev( shift );
    $self->ERev( shift );
    return $self;
}

#
# Destructor. Nothing to do, but it prevents the AutoLoader
# from getting involved in destruction.
#
sub DESTROY
{
}

# Documentation for methods implemented by the autoloader
=pod

=over

=item How()

=over

C<$integ-E<gt>How()>

Returns a string describing how the integration was 
resolved: 'copy from/into', 'branch from/into', 
'merge from/into' etc.

=back

=item File()

=over

C<$integ-E<gt>File()>

Returns the name of the file that is the source/target
of this integration. 

=back

=item SRev()

=over

C<$integ-E<gt>SRev()>

Returns the starting revision number for this integration.
Note that in the case of reverse integration records
('copy from' etc.), the starting revision value is 
always one lower than its actual value. So if SRev()
returns 0, then the real starting revision is 1.

=back

=item ERev()

=over

C<$integ-E<gt>ERev()>

Returns the ending revision number for this integration.

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
    return $self->{ $field };
}

=pod

=head1 SEE ALSO

L<P4>, L<P4::DepotFile>, L<P4::Revision>, L<P4::Map>,
L<P4::Resolver>, L<P4::Spec>, L<P4::MergeData>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2007-2010, Perforce Software, Inc. All rights reserved.

=cut
1;
__END__
