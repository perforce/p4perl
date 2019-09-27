#-------------------------------------------------------------------------------
# Copyright (c) 2008-2010, Perforce Software, Inc.  All rights reserved.
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
package P4::Spec;
use AutoLoader;
use vars qw( $AUTOLOAD );

=pod

=head1 NAME

P4::Spec

=head1 SYNOPSIS

    use P4;
    $p4 = new P4;
    $p4->Connect() or die( "Failed to connect to Perforce" );
    $spec = $p4->FetchClient();


=head1 DESCRIPTION

P4::Spec objects are used to encapsulate Perforce form handling.
They are returned by all methods that cause the server to output
a form.

=head1 METHODS

=cut

=pod

=over

=item new()

=over

C<$df = new P4::Spec( $fieldMap );>

Constructs a new P4::Spec object for a form containing the specified
fields (fieldMap is a hashref where the keys of the hash are the
field names that are permitted in forms of this type.

=back

=back

=cut
sub new( $ )
{
    my $class = shift;
    my $fieldmap = shift;
    my $self = {};
    bless( $self, $class );

    $self->{ '_fields_' } = $fieldmap;
    return $self;
}

=pod

=over

=item PermittedFields()

=over

C<@fields = $spec->PermittedFields();>

Returns a list of the field names that are permitted in specs
of this type.

=back

=back

=cut
sub PermittedFields()
{
    my $self = shift;
    values %{ $self->{ '_fields_' } };
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

=head1 MANIPULATING FORMS

The C<P4::Spec> class uses Perl's AutoLoader to simplify
form manipulation. Form fields can be accessed by simply
calling a method with the same name as the field prefixed
by an underscore (_).

=cut


sub AUTOLOAD
{
    my $self = shift;
    my $field;
    my $key;

    ($field = $AUTOLOAD ) =~ s/.*::_//;
    $key = lc $field;

    if( defined $self->{ '_fields_' }->{ $key } )
    {
	$field =  $self->{ '_fields_' }->{ $key };
    }

    if( scalar( @_ ) )
    {
	my $value = shift;
	if( defined $self->{ $field } )
	{
	    $self->{ $field } = $value;
	}
	elsif( defined $self->{ '_fields_' }->{ $key } )
	{
	    $self->{ $field } = $value;
	}
	else
	{
	    die( "No $field field in forms of this type" )
	}
    }

    if( wantarray && ref( $self->{ $field } ) eq "ARRAY" )
    {
	return @{ $self->{ $field } };
    }
    return $self->{ $field };
}

=pod

=head1 SEE ALSO

L<P4>, L<P4::DepotFile>, L<P4::Revision>, L<P4::Integration>, L<P4::Map>,
L<P4::Resolver>, L<P4::MergeData>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2008-2010, Perforce Software, Inc. All rights reserved.

=cut
1;
__END__
