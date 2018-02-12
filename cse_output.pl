#------------------------------------------------------------------------------
# CLIMATE SEARCH ENGINE - OUTPUT GENERATOR
#
# By: Richard Bekeris
# GitHub Repository: https://github.com/RGB123/cse
# Last Modified: 8 Feb 2018
#
# Optimized for: ActivePerl 5.22.4
#
# This is a separate script (cse_output.pl) that is invoked
# when the user chooses to map their search results in the main program
# (climatesearchengine.pl). It uses GD::Simple to open the world map JPEG file 
# (equi-world-map.jpg), draws the locations of the search results, saves the 
# output as a PNG file, and displays it on the screen. Control is reverted back
# to the main script after this.
#
# Map Source: https://upload.wikimedia.org/wikipedia/commons/8/83/Equirectangular_projection_SW.jpg
# 
# Dependencies: GD::Simple, climatesearchengine.pl (and coord file generated
# by it), equi-world-map.jpg
#
#------------------------------------------------------------------------------

use strict;
use warnings;
use GD::Simple;
use File::Copy;

my $coords;
my $coord_file = $ARGV[0];

my $city_profile = $ARGV[1];

my $map_file = "equi-world-map.jpg";

my %coord_profiles;

if ($ARGV[0])
{
	# Attempt to open coordinate data file:
	open ($coords, "<", $coord_file) || die "* Could not open coordinate data file!\n";
}
else
{
	print "* Could not detect coordinate data file. Please try again!\n";
}

my $x_coord;
my $y_coord;

my $line_count = 0;

while (my $in = <$coords>)
{
	chomp $in;
	
	my ($city, $lat, $long) = split ",", $in;
	
	# Convert longitude/latitude to pixel coordinates for world map JPG (2038x1018):
	$x_coord = ($long + 180) * (2038/360);
	$y_coord = (-($lat) + 90) * (1018/180);
	
	if ($line_count <= 10)
	{
		# Store longitude/latitude and x/y coordinates in hash:
		$coord_profiles{$city} = [ $long, $lat, $x_coord, $y_coord ];
	}
	
	$line_count += 1;
}

close $coords;

# Open world map JPG file (make sure it is Equirectangular Projection):
my $world_map = GD::Simple->newFromJpeg('equi-world-map.jpg');

my $city_count = 0;

# Draw a marker for each city in the data file at the correct position:
foreach my $city (keys %coord_profiles)
{
	$world_map->moveTo( $coord_profiles{$city}->[2], 
						$coord_profiles{$city}->[3] );
	
	$city_count += 1;
	
	my $match_city = $city;
	$match_city =~ s/[\W]//g;
	
	# Draw top 10 matches, with original city colored blue:
	if ($match_city eq $ARGV[1])
	{
		$world_map->bgcolor('white');
		$world_map->fgcolor('black');
		$world_map->ellipse(30,30);
	}
	else
	{
		$world_map->bgcolor('gray');
		$world_map->fgcolor('black');
		$world_map->ellipse(25,25);
	}
}

my $out_file;

# Create timestamp to add onto file name:
my $timestamp = localtime();
$timestamp =~ s/[\W]//g;

# Create the timestamped output file to save the map:
open ($out_file, '>', "cse_map_$timestamp-$ARGV[1].png") or die "* Could not create JPG output file!\n";
binmode $out_file;

# Save world map w/ markers to new PNG file:
print $out_file $world_map->png;

close $out_file;

my $map = "cse_map_$timestamp-$ARGV[1].png";
my $csv = $ARGV[0];

# Print edited map to console:
system $map;

# Ask user if they want to save map and its associated data file:
print "\nDo you want to save the map and associated data? [Y/N]: ";
my $save_map = <STDIN>;

# If user says 'No', close map file and delete it along with output file:
if ($save_map =~ m/^[Nn]$/)
{
	# Close and delete the map and CSV file:
	close $map;
	unlink $map, $coords;
}
else
{	
	# Close and move the map and CSV file to the 'results' folder:
	close $map;
	
	system "if not exist results mkdir results";
	system "move $map %cd%/results" || die "* Could not move the map file!\n";
	system "move $csv %cd%/results" || die "* Could not move the CSV file!\n";
	
}