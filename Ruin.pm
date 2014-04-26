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
		isa => 'ArrayRef[Str]',
		default => sub {[]}
	);
	
	has 'biomesToSpawnIn' => (
		is => 'rw',
		isa => 'ArrayRef[Str]',
		default => sub {[]}
	);

	has 'weight' => (
		is => 'rw',
		isa => 'Int',
		default => 10
	);
	
	has 'embed_into_distance' => (
		is => 'rw',
		isa => 'Int',
		default => 1
	);

	has 'acceptable_target_blocks' => (
		is => 'rw',
		isa => 'ArrayRef[Str]',
		default => sub {["stone", "grass", "dirt", "sand", "gravel"]}
	);
	
	has 'dimensions' => (
		is => 'rw',
		isa => 'Str'
	);

	has 'allowable_overhang' => (
		is => 'rw',
		isa => 'Int',
		default => 10
	);

	has 'max_cut_in' => (
		is => 'rw',
		isa => 'Int',
		default => 2
	);
	
	has 'cut_in_buffer' => (
		is => 'rw',
		isa => 'Int',
		default => 0
	);

	has 'max_leveling' => (
		is => 'rw',
		isa => 'Int',
		default => 2
	);

	has 'leveling_buffer' => (
		is => 'rw',
		isa => 'Int',
		default => 1
	);

	has 'preserve_water' => (
		is => 'rw',
		isa => 'Int',
		default => 0
	);

	has 'preserve_lava' => (
		is => 'rw',
		isa => 'Int',
		default => 0
	);

	has 'preserve_plants' => (
		is => 'rw',
		isa => 'Int',
		default => 1
	);
	
	has 'credits' => (
		is => 'rw',
		isa => 'Str'
	);
	
	has 'template' => (
		is => 'ro',
		isa => 'Str',
		default => "#[credits] - \n[configs]\n\n[rules]\n[layers]"
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
		
		$self->dimensions(join(",",($self->width, $self->height, $self->depth)));
		grin("Ruin successfully initialized a ".$self->dimensions." voxel structure with ".scalar(keys %{$self->rule_id})." rules");

	}
	
	sub render (){
		my $self = shift;
		
		my $final = "".$self->template;
		$final =~ s/\[credits\]/$self->credits/ge;
		$final =~ s/\[configs\]/$self->_render_configs/ge;
		$final =~ s/\[rules\]/$self->_render_rules()/ge;
		$final =~ s/\[layers\]/$self->_render_layers()/ge;
		
		return $final;
	}
	
	sub _render_configs(){
		my $self = shift;
		my @configs;
		foreach my $config(qw(
			biomesToSpawnIn
			weight
			embed_into_distance
			acceptable_target_blocks
			dimensions
			allowable_overhang
			max_cut_in
			cut_in_buffer
			max_leveling
			leveling_buffer
			preserve_water
			preserve_lava
			preserve_plants
		)){
			push @configs, "$config: ".(ref $self->$config eq 'ARRAY' ? join(",",@{$self->$config}) : $self->$config);
		}
		return join("\n",@configs);
	}
	
	sub _render_rules(){
		my $self = shift;
		my @rules;
		foreach my $rule(1..scalar(keys %{$self->rule_id})){
			push @rules, "rule".$rule."=0,100,".(
				$rule eq "1" ? "preserveBlock" : "" 
			);
		}
		return join("\n",@rules);
	}
	
	sub _render_layers(){
		return join("\n", @{$_[0]->matrix});
	}
	
	sub _render_dimensions(){
		my $self = shift;
		return join(",",($self->width, $self->height, $self->depth));
	}
	

}

1;