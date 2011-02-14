#!perl
use strict;
use warnings;

use lib qw(../lib);
use App::commandlinefu;

my $app = App::commandlinefu->new_with_options();
$app->run( @{$app->extra_argv} );
