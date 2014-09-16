package Hoo;

use 5.006;
use strict;
use warnings FATAL => 'all';

use base qw(Exporter);
use Carp qw(croak);
use Smart::Comments '###';

=head1 NAME

Hoo - The great new Hoo!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our @EXPORT_OK = qw(has t);
our @EXPORT = @EXPORT_OK;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Hoo;

    my $foo = Hoo->new();
    ...

=cut

our $_meta_classes = {};
our $_engine = "mongodb";

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 has

=cut

sub has {
    my $name = shift;
    my %options = @_;
    my $field_options = {};
    $field_options->{'type'} = $options{'type'};
    $field_options->{'required'} = $options{'required'};
    $field_options->{'validate'} = $options{'validate'};
    $field_options->{'options'} = $options{'options'};
    $field_options->{'unique'} = $options{'unique'};
    $field_options->{'default'} = $options{'default'};
    $field_options->{'label'} = $options{'label'};
    $field_options->{'control'} = $options{'control'};
    my ($pkg) = caller();
    push @{$_meta_classes->{$pkg}->{'fields'}}, [$name, $field_options];
}

sub import {
    my ($pkg) = caller;
    no strict 'refs';
    @{$pkg."::ISA"} = qw(Hoo);
    use strict;
    Hoo->export_to_level(1, @_);
}

sub engine {
    $_engine = shift;
}

sub t {
    return shift;
}

=head2 new

=cut

sub new {
    my $pkg = shift;
    my $self = bless {}, $pkg;
    $self->set(@_);
    return $self;
}

sub set {
    my $self = shift;
    my %params = @_;
    for my $key (keys %params) {
        if ($self->is_my_field($key)) {
            $self->{$key} = $params{$key};
        }
    }
}

sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

sub validate {
    my ($self) = @_;
    my $fields = $self->meta_class->{fields};
    my @errors;
    for my $f (@$fields) {
        my ($name, $options) = @$f;
        my $v = $self->{$name};
        my $label = $options->{label};
        $label = got_label_from($name) unless $label;
        # required
        if ($options->{required}) {
            if (!defined($v) || $v eq '') {
                push @errors, sprintf(t("%s required"), $label);
                next;
            }
        }
        # have value
        if ($v) {
            # type
            my $type = $options->{type};
            if ($type eq 'int') {
                if ($v !~ m{^\d+$}) {
                    push @errors, sprintf(t("%s must be integer"), $label);
                    next;
                }
            } elsif ($type eq 'select') {
                if (!$self->in_options($v, $options->{options})) {
                    push @errors, sprintf(t("%s got wrong option: %s"), $label, $v);
                    next;
                }
            }
            # validate
            my $validate = $options->{validate};
            if ($validate && ref($validate) eq 'CODE') {
                my $ret = $validate->($self, $v, $label, $name);
                if ($ret) {
                    push @errors, $ret;
                    next;
                }
            }
        }
    }
    if (@errors) {
        return \@errors;
    } else {
        return 0;
    }
}

sub got_label_from {
    my $name = shift;
    my @parts = split /[_\-]+/, $name;
    @parts = map {ucfirst $_} @parts;
    return join " ", @parts;
}

sub in_options {
    my ($self, $value, $options) = @_;
    my @options = @$options;
    my @options2 = @options;
    while (my ($key, $label) = splice(@options2, 0, 2)) {
        if ($key eq $value) {
            return 1;
        }
    }
    return 0;
}

sub is_my_field {
    my ($self, $key) = @_;
    my $fields = $self->meta_class->{fields};
    for my $f (@$fields) {
        if ($key eq $f->[0]) {
            return 1;
        }
    }
    return 0;
}

sub meta_class {
    my $pkg = shift;
    $pkg = ref($pkg) if ref($pkg);
    return $_meta_classes->{$pkg};
}

=head1 AUTHOR

Achilles Xu, C<< <formalin14 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hoo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hoo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hoo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hoo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hoo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hoo>

=item * Search CPAN

L<http://search.cpan.org/dist/Hoo/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Achilles Xu.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Hoo
