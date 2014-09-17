package Hoo::Mongodb;

use strict;
use warnings;

require "Hoo.pm";
use MongoDB;
use boolean;

our $_db;

sub init {
    for my $pkg (keys %{$Hoo::_meta_classes}) {
        my $fields = $Hoo::_meta_classes->{$pkg}->{fields};
        for my $f (@$fields) {
            my ($fname, $options) = @$f;
            if ($options->{'unique'}) {
                db()->get_collection(pkg_to_col($pkg))->ensure_index({$fname => 1}, {unique => true});
            }
        }
    }
}

sub db {
    if (!defined($_db)) {
        my $client = MongoDB::MongoClient->new('host' => $Hoo::_dsn->{'host'}, 'port' => $Hoo::_dsn->{'port'});
        my $database   = $client->get_database($Hoo::_dsn->{'db'});
        $_db = $database;
    }
    return $_db;
}

##### interfaces #####
sub insert {
    my ($self) = @_;
    my $id = db->get_collection(self_to_col($self))->insert($self);
    if (my $err = got_error()) {
        return $err;
    } else {
        $self->{_id} = $id->value;
        return 0;
    }
}

sub update {
    my ($self) = @_;
    my $cond = {_id => MongoDB::OID->new(value => $self->{_id})};
    delete $self->{_id};
    db->get_collection(self_to_col($self))->update($cond, $self);
    if (my $err = got_error()) {
        return $err;
    } else {
        return 0;
    }
}

sub got_error {
    my $err = db()->last_error();
    if ($err->{'ok'}) {
        if ($err->{'err'}) {
            return $err->{'err'};
        }
    } else {
        return $err->{'errmsg'};
    }
    return 0;
}

sub find_one {
    my ($pkg, $cond) = @_;
    my $o = db->get_collection(pkg_to_col($pkg))->find_one($cond);
    if ($o) {
        $o->{_id} = $o->{_id}->value;
        return $o;
    } else {
        return 0;
    }
}

sub pkg_to_col {
    my $pkg = shift;
    $pkg =~ s/::/_/g;
    return lc $pkg;
}

sub self_to_col {
    my $self = shift;
    return pkg_to_col(ref($self));
}

sub check_duplicate {
    my ($self, $fname) = @_;
    my $cond = {$fname => $self->{$fname}};
    if ($self->{_id}) {
        $cond->{_id} = {'$ne' => MongoDB::OID->new(value => $self->{_id})};
    }
    my $o = db->get_collection(self_to_col($self))->find_one($cond);
    if ($o) {
        return 1;
    } else {
        return 0;
    }
}

1;
