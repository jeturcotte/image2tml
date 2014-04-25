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
	
	has 'rule_count' => (
		is => 'rw',
		isa => 'HashRef',
		default => sub {{
			'0.0.0' => 0,
			'255.255.255' => 0
		}}
	);
	
	has 'rule_id' => (
		is => 'rw',
		isa => 'HashRef',
		default => sub {{
			'0.0.0' => 0,
			'255.255.255' => 1
		}}
	);
	
	has 'matrix' => (
		is => 'rw',
		isa => 'ArrayRef',
		default => sub {[]}
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
		
		my $pz = 0;
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
			
			my @slab;
			foreach my $py(0..$self->height-1){
				my @row;
				foreach my $px(0..$self->width-1){
					my ($r, $g, $b, undef) = $i->getpixel(x => $px, y => $py)->rgba();
					my $c = "$r.$g.$b";
					$self->rule_count->{$c} += 1;
					$self->rule_id->{$c} = scalar(keys %{$self->rule_id})+1
						unless defined($self->rule_id->{$c});
					push @row, $self->rule_id->{$c};
				}
				push @slab, join(",",@row);
			}
			
			push @{$self->matrix}, "\nlayer\n".join("\n",@slab)."\nendlayer\n";
			
		}
		
		grin("Ruin successfully initialized with ".scalar(keys %{$self->rule_id})." rules at ".$self->width()." voxels wide by ".$self->height()." voxels long by ".$self->depth()." voxels tall");	
	}
}

1;