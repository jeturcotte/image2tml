package Ruin {

	use Moose;
	use Imager;
	use Colorful qw(panic whine grin);
	use vars qw($VERSION);
	
	$VERSION = 0.01;
	
	has 'width' => (
		is => 'rw',
		isa => 'Int'
	);
	
	has 'height' => (
		is => 'rw',
		isa => 'Int'
	);
	
	has 'depth' => (
		is => 'rw',
		isa => 'Int'
	);
	
	has 'image_location' => (
		is => 'ro',
		isa => 'Str',
		trigger => \&_read_and_test_files
	);
	
	sub _read_and_test_files {
		my ($self, $loc, $old) = @_;
		opendir (DIR, $loc) or die $!;
		my @files;
		while (my $file = readdir(DIR)){
			next unless $file =~ m/\.(png|jpe?g|gif)$/i;
			push @files, $file;
		}
		$self->depth(scalar @files);
		
		foreach my $file(@files){
			my $floc = $self->image_location."/$file";
			my $i = Imager->new(file => $floc)
				or panic("$floc is not a valid image!");
			my $x = $i->getwidth;
			my $y = $i->getheight;
			if ($self->width and $self->height) {
				panic("Inconsistent dimensions starting with layer $file!")
					unless ($x == $self->width and $y == $self->height);
			} else {
				$self->width($x);
				$self->height($y);
			}
			
		}
		
		grin("Ruin successfully initialized at ".$self->width()." voxels wide by ".$self->height()." voxels long by ".$self->depth()." voxels tall");	
	}
}

1;