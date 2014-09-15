use strict;
use warnings;

package Cat;

use Hoo;

has 'name' => (
    type => 'text',
    default => 'Tom',
    wrong_option => 'balala'
);

has 'color' => (
    type => 'select',
    options => ['b' => 'black', 'bl' => 'blue', 'r' => 'red'],
    wrong_option2 => 'foo bar',
);

package main;

use Data::Dumper qw(Dumper);

print Dumper($Hoo::_meta_classes), "\n";

