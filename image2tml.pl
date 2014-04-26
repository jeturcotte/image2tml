#!/usr/bin/perl -w

use strict;
use Imager;
use Ruin;
use feature 'say';

my $ruin = Ruin->new(image_location => $ARGV[0] || './png_layers');

#say join("\n", @{$ruin->matrix});
say $ruin->render;