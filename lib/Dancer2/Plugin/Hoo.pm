package Dancer2::Plugin::Hoo;

use strict;
use warnings;

use Dancer2::Plugin;
use Text::Xslate qw(mark_raw);

our $VERSION = '0.01';

our $tx = Text::Xslate->new(path => "views/hoo", module => ['Text::Xslate::Bridge::Star']);

register hoo_admin => sub {
    my ($dsl, $prefix) = plugin_args(@_);
    $prefix ||= "/adm";
    my @pkgs = ();
    for my $pkg (keys %$Hoo::_meta_classes) {
        $dsl->any(['get', 'post'] => $prefix . "/" . lc($pkg) . "/create" => sub {
                      my $errors;
                      if ($dsl->request->is_post()) {
                          my $o = $pkg->new($dsl->params);
                          $errors = $o->save();
                          if (!$errors) {
                              $dsl->redirect($prefix . "/" . lc($pkg));
                              return;
                          }
                      }
                      my $params = $dsl->params();
                      my %ref_data;
                      for my $f (@{$pkg->meta_class->{'fields'}}) {
                          my ($fname, $foptions) = @$f;
                          if ($foptions->{type} eq 'ref') {
                              my $refpkg = $foptions->{'ref'};
                              my @refobjs = $refpkg->find();
                              $ref_data{$fname} = [];
                              my $first_fld_of_this_ref = $refpkg->meta_class()->{'fields'}->[0]->[0];
                              for my $refo (@refobjs) {
                                  push @{$ref_data{$fname}}, [$refo->id_to_str(), $refo->get($first_fld_of_this_ref)];
                              }
                          }
                      }
                      return $tx->render("create.tx", {'ref_data' => \%ref_data, 'params' => $params, errors => $errors, meta => $pkg->meta_class});
                  }
              );
        $dsl->get($prefix . "/" . lc($pkg) => sub {
                      my @objs = $pkg->find();
                      return $tx->render("list.tx", {objs => \@objs, prefix => $prefix, pkg => $pkg, meta => $pkg->meta_class});
                  }
              );
        push @pkgs, [$pkg, $pkg->label()];
    }
    $dsl->get($prefix => sub {
                  return $tx->render("index.tx", {prefix => $prefix, pkgs => \@pkgs});
              }
          );
};

register_plugin;

1;
