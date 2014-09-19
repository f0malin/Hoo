package Dancer2::Plugin::Hoo;

use strict;
use warnings;

use Dancer2::Plugin;

our $VERSION = '0.01';

register hoo_admin => sub {
    my ($dsl, @args) = plugin_args(@_);
    
    
};

register_plugin;

1;
