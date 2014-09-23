use strict;
use warnings;

use Test::More tests => 32;


package Cat;

use Hoo;

has 'name' => (
    type => 'text',
    default => 'Tom',
    required => 1,
    unique => 1,
    wrong_option => 'balala'
);

has 'color' => (
    type => 'select',
    options => ['b' => 'black', 'bl' => 'blue', 'r' => 'red'],
    wrong_option2 => 'foo bar',
    default => 'bl',
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

has 'score' => (
    type => 'num',
    label => 'my score'
);

package main;

use Data::Dumper qw(Dumper);

#diag Dumper(Cat->meta_class);
use Hoo;

Hoo::init(engine => "Hoo::Mongodb", host => 'localhost', port => '27017', db => 'hoo_test');

my $c = Cat->new(name => 'Jerry3', color => 'bl', wrong_field => 'hahaha');
is(Cat->meta_class->{fields}->[0]->[1]->{type}, "text", "has-field-option");
is($c->meta_class->{fields}->[0]->[1]->{default}, "Tom", "has-field-option");
is($c->meta_class->{fields}->[0]->[1]->{wrong_option}, undef, "has-field-wrong-option");

is($c->get('name'), 'Jerry3', "new");
is($c->get('color'), 'bl', "new");
is($c->get('wrong_field'), undef, "new-wrong-field");

my $errors = $c->validate;
#diag ref $c;

is(ref($c), "Cat", "new-type");
diag Dumper $errors;
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

Hoo::Mongodb::db()->get_collection('cat')->remove();
my $d = Cat->new(name => "Jerry", age => "7");
is $d->get("_id"), undef, "save-no-id-yet";
$errors = $d->save();
diag Dumper $errors;
diag $d->get("_id");
is ref($d->get("_id")), "MongoDB::OID", "id";
is $d->get("color"), "bl", "default";
ok $d->get("_id"), "save-have-id-now";

my $f = Cat->new(name => "Jerry", color => "b", age => "28");
$errors = $f->save();
ok $errors, "unique";
is $f->get("_id"), undef, "unique";
diag Dumper($errors);

# find one
my $g = Cat->find_one({name => "Jerry"});
is ref($g), "Cat", "find_one-package";
is $g->get("age"), 7, "find_one-data";
is $g->get("color"), "bl", "find_one-default";
is ref($g->get("_id")), "MongoDB::OID", "id";
diag $g->get("_id");

# status
is $g->get("status"), 1, "status";

# update
$g->set("age" => "8");
$g->save();
my $h = Cat->find_one({"name" => "Jerry"});
is $h->get("age"), 8, "update";
is $h->get("name"), "Jerry", "update";

my $i = Cat->new(name => 'Tom', score => '35d');
$errors = $i->validate;
diag Dumper $errors;
ok $errors->[0] =~ /number/, "num-validate";
$i->set(score => '3.6');
$errors = $i->save;
is $errors, 0, "num-conversion";
