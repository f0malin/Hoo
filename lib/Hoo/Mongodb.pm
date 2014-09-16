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
    if ($id) {
        $data->{_id} = $id->value;
        return 1;
    } else {
        return 0;
    }
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
