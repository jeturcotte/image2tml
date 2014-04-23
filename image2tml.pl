#!/usr/bin/perl -w

use strict;
use Imager;
use Ruin;
use Colorful;
use feature 'say';

my $ruin = Ruin->new(image_location => $ARGV[0] || './png_layers');
