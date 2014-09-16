use strict;
use warnings;

use Test::More tests => 17;

package Cat;

use Hoo;

has 'name' => (
    type => 'text',
    default => 'Tom',
    required => 1,
    wrong_option => 'balala'
);

has 'color' => (
    type => 'select',
    options => ['b' => 'black', 'bl' => 'blue', 'r' => 'red'],
    wrong_option2 => 'foo bar',
);

has 'age' => (
    type => 'int',
    validate => sub {
        my ($self, $v, $label, $name) = @_;
        if ($v > 99) {
            return sprintf(t("%s too old"), $label);
        } else {
            return 0;
        }
    },
);

package main;

use Data::Dumper qw(Dumper);

#diag Dumper(Cat->meta_class);

my $c = Cat->new(name => 'Jerry', color => 'bl', wrong_field => 'hahaha');
is(Cat->meta_class->{fields}->[0]->[1]->{type}, "text", "has-field-option");
is($c->meta_class->{fields}->[0]->[1]->{default}, "Tom", "has-field-option");
is($c->meta_class->{fields}->[0]->[1]->{wrong_option}, undef, "has-field-wrong-option");

is($c->get('name'), 'Jerry', "new");
is($c->get('color'), 'bl', "new");
is($c->get('wrong_field'), undef, "new-wrong-field");

my $errors = $c->validate;
#diag ref $c;

is(ref($c), "Cat", "new-type");

is $errors, 0, "validate-succeed";

$c->set(color => "bb", name => "", age => "3");
is $c->get("name"), "", "set";
is $c->get("color"), "bb", "set";
$errors = $c->validate;
ok $errors, "validate-errors";
is scalar(@$errors), 2, "validate-errors-count";
ok $errors->[0] =~ /required/i, "validate-error-required";
ok $errors->[1] =~ /wrong option/i, "validate-error-select";
$c->set(age => "bb");
$errors = $c->validate;
is scalar(@$errors), 3, "validate-errors-count";
ok $errors->[2] =~ /int/i, "validate-error-int";

$c->set(age => 120);
$errors = $c->validate;
ok $errors->[2] =~ /too old/i, "validate-error-validate";
