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
package P4::Revision;
use P4::Integration;
use AutoLoader;
use vars qw( $AUTOLOAD );
=pod

=head1 NAME

P4::Revision

=head1 SYNOPSIS

    use P4;
    $p4 = new P4;
    $p4->Connect() or die( "Failed to connect to Perforce" );
    for $file in ( $p4->RunFilelog( "//depot/some/file" ) )
    {
    	for $rev in ( $file->Revisions() )
	{
	    ...
	}


=head1 DESCRIPTION

P4::Revision objects represent revisions of files in a
Perforce repository.  While users are free to create objects 
of this class in their own scripts, their primary use is 
that they are returned as part of the output of 
C<P4::RunFilelog()>.

=head1 BUILT-IN METHODS

=cut

=pod

=over

=item new()

=over

C<$rev = new P4::Revision( $depotFile );>

Constructs a new P4::Revision object for the specified file.

=back

=back

=cut

sub new( $ )
{
    my $class = shift;
    my $self = {};
    bless( $self, $class );
    $self->DepotFile( shift );
    $self->{ 'integrations' } = [];
    return $self;
}

#
# Destructor. Nothing to do, but it prevents the AutoLoader
# from getting involved in destruction.
#
sub DESTROY
{
}

=pod

=over

=item SetAttribute()

=over

C<$rev-E<gt>SetAttribute( $name, $value );>

Sets the value of the named attribute for this revision. This
is a private method. Not intended for use in user scripts.

=back

=back

=cut

sub SetAttribute( $$ )
{
    my $self = shift;
    my $field = shift;
    my $value = shift;

    $self->{ lc $field } = $value;
}

=pod

=over

=item Integration()

=over

C<$rev-E<gt>Integration( $how, $file, $srev, $erev );>

Adds a new integration record for this revision. See
L<P4::Integration>.

=back

=back

=cut

sub Integration( $$$$ )
{
    my $self = shift;
    my $how  = shift;
    my $file = shift;
    my $srev = shift;
    my $erev = shift;

    my $integ = new P4::Integration( $how, $file, $srev, $erev );
    push( @{ $self->Integrations() }, $integ );
    return $integ;
}

# Documentation for methods implemented by the AutoLoader

=pod

=over

=item Integrations()

=over

C<$rev-E<gt>Integrations();>

Returns an array of P4::Integration objects representing
all the integration records for this revision.

=back

=back

=head1 OTHER METHODS

This module uses Perl's AutoLoader to implement methods
that get and set the attributes of a revision. So, 
attributes such as the revision number, change number, 
user, client etc. are available simply by calling a
method of the same name. A partial list of available
attributes is:

=over

C<< $rev->Rev() >>	- The revision number

C<< $rev->Change() >>	- The changelist number

C<< $rev->Type() >>	- The Perforce filetype

C<< $rev->Time() >>	- The timestamp

C<< $rev->User() >>	- The submitting user

C<< $rev->Client() >>	- The submitting client

C<< $rev->FileSize() >>	- The size of the file

C<< $rev->Digest() >>	- The MD5 digest

C<< $rev->Desc() >>	- First 31 chars of description

=back

Whether or not a given attribute is available depends on
the way in which the object was constructed, and sometimes
on the version of the server. For example, servers older
than 2005.1 do not report the MD5 digest of revisions to
the client; in this case, the attribute will be 
undefined.

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

L<P4>, L<P4::DepotFile>, L<P4::Integration>, L<P4::Map>,
L<P4::Resolver>, L<P4::Spec>, L<P4::MergeData>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2007-2010, Perforce Software, Inc. All rights reserved.

=cut
1;
__END__
