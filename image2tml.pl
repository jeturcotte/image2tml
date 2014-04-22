#!/usr/bin/perl -w

use strict;
use Imager;
use feature 'say';

my $layers = $ARGV[0] || './png_layers';
my @layers;

opendir (DIR, $layers) or die $!;

while (my $file = readdir(DIR)){
	next unless $file =~ m/\.(png|jpe?g|gif)$/i;
	push @layers, $file;
}

say '';
dammit("At least one layer image file is required at $layers!") unless scalar @layers;
woohoo('Found '.scalar(@layers).' layer file'.(scalar(@layers)==1?'':'s')." in $layers");

@layers = each_layer_tested(sort @layers);

closedir DIR;

sub each_layer_tested {
	my @layers = @_;
	my $x = 0;
	my $y = 0;
	my @pixel_layers;
	foreach my $layer (@layers){
		oops("\t...testing $layers/$layer");
		my $image = tested_image_file($layers."/".$layer);
		($x, $y) = tested_image_dimensions($image, $x, $y);
	}
	woohoo("TEST OK! Each layer has the same ".$x.",$y pixel dimenions!");
}

sub tested_image_file(){
	my $image = shift or dammit("Image file name required!");
	return Imager->new(file => "$image") or dammit("$_ is not a valid image!");
}

sub tested_image_dimensions(){
	my ($image, $x, $y) = @_;
	my $tx = $image->getwidth();
	my $ty = $image->getheight();
	dammit('Image dimensions do not match previous!') if ($x && $y && $tx != $x && $ty != $y);
	return ($tx, $ty);
}

sub oops {
	say "\x1b[33m".(shift || 'Unknown error')."\x1b[0m";
}

sub dammit {
	die "\x1b[1m\x1b[31m".(shift || 'Fatal error')."\x1b[0m\n";
}

sub woohoo {
	say "\x1b[32m".shift."\x1b[0m";
}
