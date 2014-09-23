package Dancer2::Plugin::Hoo;

use strict;
use warnings;

use Dancer2::Plugin;
use Text::Xslate qw(mark_raw);

our $VERSION = '0.01';

our $tx = Text::Xslate->new(path => "views/hoo");

register hoo_admin => sub {
    my ($dsl, $prefix) = plugin_args(@_);
    $prefix ||= "/adm";
    for my $pkg (keys %$Hoo::_meta_classes) {
        $dsl->any(['get', 'post'] => $prefix . "/" . lc($pkg) . "/create" => sub {
            return $tx->render("hello.tt", {pkg => $pkg});
        });
    }
};

register_plugin;

1;
