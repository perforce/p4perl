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
package P4::Map;

=pod

=head1 NAME

P4::Map

=head1 SYNOPSIS

    use P4;

    $map = new P4::Map;
    $map->Insert( "//depot/...", "//workspace/depot/..." );
    $map->Insert( "//gizmo/...", "//workspace/gizmo/..." );
    ...


=head1 DESCRIPTION

The P4::Map class allows you to construct and manipulate Perforce
mappings in the same way that the Perforce Server does. It requires
no connection to the server in order to work with mappings.

=head1 CLASS METHODS

=over

=item new( [ $arrayref ] )

Constructs a new P4::Map object. If passed an array reference,
the mappings in the array (one mapping per entry) are loaded
into the Map object. 

=item Join( $map1, $map2 )

Join two maps together returning a new map containing the 
left-hand-side of $map1 joined to the right-hand-side of
$map2.

=back

=head1 INSTANCE METHODS

=over

=item Insert( $string [, $string ] )

Inserts a mapping into the Map. If passed a single argument,
it is assumed to contain both the left-hand, and right-hand
sides of the mapping. If passed two arguments, the first is
the left-hand-side, the second the right-hand-side.

Note that, in the one-argument form, mappings with embedded
spaces must be quoted; in the two-argument form, quotes
are optional.

=item Count()

Returns the number of entries in the Map. Note that there
may be more entries than you inserted due to the way that
ambiguous mappings are resolved internally.

=item Clear()

Empties the Map object of all mappings.

=item IsEmpty()

Returns non-zero if the Map object contains no mappings.

=item Includes( $string )

Returns non-zero if the specified string is visible through
either side of the mapping.

=item Reverse()

Reverses the mapping: swapping the left-hand-side with
the right-hand-side and vice-versa.

=item Translate( $string [, $fwd=1 ] )

Translates the supplied string through the mappings and
returns the result. The optional second parameter specifies
the direction of translation: forward=1, reverse=0; the 
default is to translate in the forward direction.

=item Lhs()

Return an array containing the left-hand-side of the mapping
only.

=item Rhs()

Return an array containing the right-hand-side of the mapping
only.

=item AsArray()

Return the mapping as an array of strings: one mapping per
entry in the array.

=back

=head1 SEE ALSO

L<P4>, L<P4::DepotFile>, L<P4::Revision>, L<P4::Integration>, 
L<P4::Resolver>, L<P4::Spec>, L<P4::MergeData>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2008-2010, Perforce Software, Inc. All rights reserved.

=cut
1;
__END__
