package Hoo::Mongodb;

use strict;
use warnings;

use MongoDB;

our $_db;

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
    my ($pkg, $data) = @_;
    my $id = db->get_collection(pkg_to_col($pkg))->insert($data);
    if (my $err = got_error()) {
        return $err;
    } else {
        $data->{_id} = $id->value;
        return 0;
    }
}

sub update {
    my ($pkg, $cond, $data) = @_;
    db->get_collection(pkg_to_col($pkg))->update($cond, {'$set' => $data});
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

1;
