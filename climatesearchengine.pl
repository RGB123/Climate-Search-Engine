#------------------------------------------------------------------------------
# CLIMATE SEARCH ENGINE
# 
# By: Richard Bekeris
# GitHub Repository: https://github.com/RGB123/cse
# Last Modified: 8 Feb 2018
# 
# Optimized for: ActivePerl 5.22.4
#
# This program contains 4 modules:
# * STARTUP
# * RECORD LOOKUP
# * DEFAULT SEARCH
# * CUSTOM SEARCH
#
# STARTUP: Opens CSV file, parses and stores climate data in memory,
# and returns average/standard deviation for each category.
#
# RECORD LOOKUP: Allows user to search climate data records, check for any
# missing/erroneous data.
#
# DEFAULT SEARCH: Allows user to specify a city name, and search engine will
# attempt to find a unique match. If found, the engine will calculate a
# ranked list of cities whose climate is most similar to the search input. The 
# user can then generate a PNG map displaying the locations of the top 10 
# results (this is performed by CSE Output Generator program).
#
# CUSTOM SEARCH: Allows user to specify their own search criteria for the 
# various climate data categories (temperature, rainfall, humidity, etc.)
# and assign weights to each category. The search engine will then calculate
# a ranked list of cities whose climate is most similar to the search input.
# Map-generating capabilities have not been added yet.
#
# Climate Data Source(s): Weatherbase.com, Weatherspark.com, Wikipedia.org
# Dependencies: climatedataworld-stats.csv, cse_output.pl
#

use warnings;
use strict;

#------------------------------------------------------------------------------
# OPENING CSV DATA FILE

print "\nCLIMATE SEARCH ENGINE - STARTUP\n";
print "-------------------------------------\n";
sleep(1);

my $file;
my $climate_data;

# If user specifies a custom data file:
if ($ARGV[0])
{
	# Attempt to open user-specified data file:
	$file = $ARGV[0];
	open ($climate_data, "<", $file) || die "* Could not open data file $file!\n";
}
else
{
	# Open default data file:
	my $file = 'climatedataworld-stats.csv';
	open ($climate_data, "<", $file) || die "* Could not open data file $file!\n";
}

# Check if data file successfully opened:
if ($climate_data)
{
	print "\n* Climate data file successfully opened.\n";
}

#-------------------------------------------------------------------------#
# DATA FILE PARSER

my %climate_profiles;
my $entry_count = 0;
my $line_count = 0;
	
# Initialize variables for standard deviations of climate parameters:
#my ($sd_line, $sd_pop, $sd_elev, $sd_avg_temp, 
#	$sd_high_temp, $sd_low_temp, $sd_rain, $sd_snow, 
#	$sd_humid, $sd_wind);

# Extract data from .CSV file:
while (my $in = <$climate_data>)
{
	chomp $in;
	
	# If this is the first line:
	if ($line_count == 0)
	{
		# Skip the first (header) line:
		$line_count += 1;
	}
	else
	{
		# Split input lines on comma, assign to climate parameter variables:
		my ($city, $population_k, $elevation_m, $avg_temp_C, $high_temp_C, 
		$low_temp_C, $rainfall_cm, $snowfall_cm, $rel_humidity, $wind_kmh, $continent,
		$lat, $long) = split ",", $in;
	
		# Push variables from input line into anonymous array, referenced by 
		# climate_profiles hash:
		$climate_profiles{$city} =	[	$population_k, $elevation_m, 
										$avg_temp_C, $high_temp_C,
										$low_temp_C, $rainfall_cm, 
										$snowfall_cm, $rel_humidity,
										$wind_kmh, $continent, $lat,
										$long ];
	
		# Count the number of entries and number of lines:
		$entry_count += 1;
		$line_count += 1;
	}
} 
					  
# If data file had successfully opened, but no entries were compiled, exit program:
if ($entry_count == 0)
{
	print "* No entries compiled, please check file format and restart program.\n";
	exit 0;
}
close $climate_data;

# Report number of entries compiled:
print "* Data for $entry_count locations was compiled.\n\n";
sleep(1);

#-------------------------------------------------------------------------------------
# CALCULATING AVERAGES AND STANDARD DEVIATIONS

# Declare variable names for references to access climate data:
my ($pop_ref, $elev_ref, $avg_temp_ref, $high_temp_ref, $low_temp_ref,
	$rain_ref, $snow_ref, $humid_ref, $wind_ref, $cont_ref);

# Declare variables and array for storing averages:
my ($avg_pop, $avg_elev, $avg_avg_temp, 
	$avg_high_temp, $avg_low_temp, $avg_rain, 
	$avg_snow, $avg_humid, $avg_wind) = (0, 0, 0, 0, 0, 0, 0, 0, 0);
	
my @climate_avgs = ($avg_pop, $avg_elev, $avg_avg_temp, $avg_high_temp, $avg_low_temp,
					$avg_rain, $avg_snow, $avg_humid, $avg_wind);

# Loop through all climate records, calculate totals for each variable, then
# divide by number of records to obtain the average:
foreach my $city (keys %climate_profiles)
{
	$pop_ref 			= $climate_profiles{$city}->[0];
	$elev_ref 			= $climate_profiles{$city}->[1];
	$avg_temp_ref 		= $climate_profiles{$city}->[2];
	$high_temp_ref 		= $climate_profiles{$city}->[3];
	$low_temp_ref 		= $climate_profiles{$city}->[4];
	$rain_ref 			= $climate_profiles{$city}->[5];
	$snow_ref 			= $climate_profiles{$city}->[6];
	$humid_ref 			= $climate_profiles{$city}->[7];
	$wind_ref 			= $climate_profiles{$city}->[8];
	
	$climate_avgs[0] 	+= $pop_ref;
	$climate_avgs[1] 	+= $elev_ref;
	$climate_avgs[2] 	+= $avg_temp_ref;
	$climate_avgs[3] 	+= $high_temp_ref;
	$climate_avgs[4] 	+= $low_temp_ref;
	$climate_avgs[5]	+= $rain_ref;
	$climate_avgs[6]	+= $snow_ref;
	$climate_avgs[7] 	+= $humid_ref;
	$climate_avgs[8]	+= $wind_ref;
}

foreach my $avg (@climate_avgs)
{
	$avg = $avg / $entry_count;
}

# Declare variables and array for storing standard deviations:
my ($sd_pop, $sd_elev, $sd_avg_temp, 
	$sd_high_temp, $sd_low_temp, $sd_rain, 
	$sd_snow, $sd_humid, $sd_wind) = (0, 0, 0, 0, 0, 0, 0, 0, 0);

my @climate_stdevs = (	$sd_pop, $sd_elev, $sd_avg_temp, 
						$sd_high_temp, $sd_low_temp, $sd_rain, 
						$sd_snow, $sd_humid, $sd_wind);

my ($pop_sq_diff, $elev_sq_diff, $avg_temp_sq_diff, $high_temp_sq_diff,
	$low_temp_sq_diff, $rain_sq_diff, $snow_sq_diff, $humid_sq_diff, $wind_sq_diff);
						
# Loop through all city records to calculate standard deviations:
foreach my $city (keys %climate_profiles)
{
	$pop_ref 			= $climate_profiles{$city}->[0];
	$elev_ref 			= $climate_profiles{$city}->[1];
	$avg_temp_ref 		= $climate_profiles{$city}->[2];
	$high_temp_ref 		= $climate_profiles{$city}->[3];
	$low_temp_ref 		= $climate_profiles{$city}->[4];
	$rain_ref 			= $climate_profiles{$city}->[5];
	$snow_ref 			= $climate_profiles{$city}->[6];
	$humid_ref 			= $climate_profiles{$city}->[7];
	$wind_ref 			= $climate_profiles{$city}->[8];
	
	$pop_sq_diff 		= ( ($pop_ref - $climate_avgs[0]) ** 2 );
	$elev_sq_diff		= ( ($elev_ref - $climate_avgs[1]) ** 2 );
	$avg_temp_sq_diff	= ( ($avg_temp_ref - $climate_avgs[2]) ** 2 );
	$high_temp_sq_diff 	= ( ($high_temp_ref - $climate_avgs[3]) ** 2 );
	$low_temp_sq_diff	= ( ($low_temp_ref - $climate_avgs[4]) ** 2 );
	$rain_sq_diff		= ( ($rain_ref - $climate_avgs[5]) ** 2 );
	$snow_sq_diff		= ( ($snow_ref - $climate_avgs[6]) ** 2 );
	$humid_sq_diff		= ( ($humid_ref - $climate_avgs[7]) ** 2 );
	$wind_sq_diff		= ( ($wind_ref - $climate_avgs[8]) ** 2 );
	
	$climate_stdevs[0] += $pop_sq_diff;
	$climate_stdevs[1] += $elev_sq_diff;
	$climate_stdevs[2] += $avg_temp_sq_diff;
	$climate_stdevs[3] += $high_temp_sq_diff;
	$climate_stdevs[4] += $low_temp_sq_diff;
	$climate_stdevs[5] += $rain_sq_diff;
	$climate_stdevs[6] += $snow_sq_diff;
	$climate_stdevs[7] += $humid_sq_diff;
	$climate_stdevs[8] += $wind_sq_diff;
}

foreach my $stdev (@climate_stdevs)
{
	$stdev = sqrt( $stdev / ($entry_count - 1) );
}

# Print out the statistics header:
printf "\n%-25s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n",
"STATISTIC", "Population", "Elevation", "Avg Temp", "High Temp",
"Low Temp", "Rainfall", "Snowfall", "Humidity", "Windspeed";
# Print out the averages and standard deviations for each attribute:
printf "%-25s %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f\n",
"Average:", "$climate_avgs[0]", "$climate_avgs[1]", "$climate_avgs[2]", 
"$climate_avgs[3]", "$climate_avgs[4]", "$climate_avgs[5]", "$climate_avgs[6]", 
"$climate_avgs[7]", "$climate_avgs[8]";
printf "%-25s %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f\n",
"Standard Deviation:", "$climate_stdevs[0]", "$climate_stdevs[1]", "$climate_stdevs[2]", 
"$climate_stdevs[3]", "$climate_stdevs[4]", "$climate_stdevs[5]", "$climate_stdevs[6]", 
"$climate_stdevs[7]", "$climate_stdevs[8]";
sleep(1);

print "\n* Startup complete! Initializing Record Lookup module...\n\n";
sleep(1);

#------------------------------------------------------------------------------#
# Instructions and tips for Climate Record Search module:

print "CLIMATE SEARCH ENGINE - RECORD LOOKUP\n";
print "-------------------------------------\n\n";
sleep(1);

#---------------------------------------------------------------------------------------------#

# RECORD LOOKUP PROMPT AND LOOP

my $record_lookup = 0;
my $done_lookup = 0;
my $found_count = 0;
my $keyword_count = 0;

# Loop for performing Record Lookup:
while ($done_lookup == 0)
{
	# Always reset match count at beginning of loop:
	$found_count = 0;
	# Print search prompt:
	print "Enter a location name or type 'continue' to proceed to Default Search module: ";
	$record_lookup = <STDIN>;
	chomp $record_lookup;
	
	# Exit statement:
	exit 0 if ($record_lookup =~ m/^quit$/i);
	
	# If user types 'continue':
	if ($record_lookup =~ m/^continue$/i)
	{
		# Record Lookup is done, exit loop:
		$done_lookup = 1;
		last;
	}
	
	# Convert common alternative place names here, so that they match the database format:
	$record_lookup =~ s/\bnyc\b/New York/i;
	$record_lookup =~ s/bay area/San Francisco/i;
	$record_lookup =~ s/united states/USA/i;
	$record_lookup =~ s/\bUS\b/USA/i;
	$record_lookup =~ s/new zealand/NZ/i;
	$record_lookup =~ s/united kingdom/UK/i;
	$record_lookup =~ s/central african republic/CAR/i;
	$record_lookup =~ s/democratic republic of the congo/DRC/i;
	# Change common abbreviations to full spellings (periods optional):
	$record_lookup =~ s/\b(st[.]* )/Saint /i;
	$record_lookup =~ s/\b(ft[.]* )/Fort /i;
	$record_lookup =~ s/\b(ste[.]* )/Sainte /i;
	$record_lookup =~ s/\b(mt[.]* )/Mount /i;
	# If included, convert special characters to spaces so they don't mess with searching:
	$record_lookup =~ s/[\W]/ /g;
	
	# Split user input into array of keywords, based on space:
	my @user_keywords = split " ", $record_lookup;
	
	# Loop through all city records:
	foreach my $city (sort keys %climate_profiles)
	{
		
		# Reset keyword count at beginning of loop:
		$keyword_count = 0;
		# For each keyword entered by user:
		foreach my $keyword (@user_keywords)
		{
			# Regex: check if keyword is 2-3 capital letters (interpreted as state/country initials)
			# AND check if record name contains user input (case-sensitive)
			# preceded by a space (that's how it knows it's referring to a state or country):
			if ($keyword =~ m/^[A-Z]{2,3}$/ && $city =~ m/\Q$keyword/)
			{
				# Increment keyword count:
				$keyword_count += 1;
			}
			# Regex: if keyword is NOT 2-3 capital letters
			# AND record name contains user input (case-insensitive):
			elsif ($keyword !~ m/^[A-Z]{2,3}$/ && $city =~ m/\Q$keyword/i)
			{
				# Increment keyword count:
				$keyword_count += 1;
			}
		}
		
		# If all user-defined keywords have been matched:
		if ( $keyword_count == scalar @user_keywords)
		{	
			# Print out the search result header:
			printf "\n%-35s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s\n",
			"City ST Country", "Population", "Elevation", "Avg Temp", "High Temp",
			"Low Temp", "Rainfall", "Snowfall", "Humidity", "Windspeed";
			# Print out the matching city record:
			printf "%-35s %-10s %-10s %-10.10s %-10.10s %-10.10s %-10.10s %-10.10s %-10.10s %-10.10s\n",
			"$city", "$climate_profiles{$city}->[0] k", "$climate_profiles{$city}->[1] m", 
			"$climate_profiles{$city}->[2] C", "$climate_profiles{$city}->[3] C", "$climate_profiles{$city}->[4] C", 
			"$climate_profiles{$city}->[5] cm", "$climate_profiles{$city}->[6] cm", "$climate_profiles{$city}->[7] \%", 
			"$climate_profiles{$city}->[8] km/h";
			
			# Increment the number of matching cities found:
			$found_count += 1;
		}
	}
	
	# Error statement if no matches were found:
	if ($found_count == 0)
	{
		print "\n* No data found matching your query. Please check spelling/format or try another search term.\n\n";
	}
	# If at least one match found, print the number of matches:
	elsif ($found_count >= 1)
	{
		print "\n* Number of matches found: $found_count\n\n";
	}
}

#------------------------------------------------------------------------------#

# DEFAULT SEARCH MODULE

print "\n* Initializing Default Search module...\n";
sleep(2);

print "\nCLIMATE SEARCH ENGINE - DEFAULT SEARCH\n";
print "--------------------------------------\n\n";
sleep(1);

print "Options:\n\n";

print "* To find cities with the most dissimilar climates, include a minus sign with\n";
print "  your input (e.g. '-London UK').\n\n";

print "* To include/exclude only results from the same country as your chosen city, use the\n";
print "  '<' or '>' symbol, respectively (e.g. '<Beijing' or '>Seattle WA').\n\n";

print "* To include/exclude only results from the same continent/region as your chosen city, use\n";
print "  the '\/' or '\\' symbol, respectively (e.g. '\/Buenos Aires' or '\\Madrid').\n\n";

print "* If you want to specify your own parameters and weights, use the Custom Search module.\n\n";

# Used in error statement if user finds more than one matching city:
my @cities_found;

# Initialize hashes to hold diff-scores and residuals for each city:
my %def_diff_scores;
my %def_diff_profiles;
my %removed_profiles;

# Initialize variables here to prevent compile errors:
my $done_default = 0;

my $def_city = 0;
my $def_diff_score = 0;
my $keyword_match_count = 0;

my $def_country;
my $def_continent;

# Control variables for country/continent search modifiers:
my $exclude_country = 0;
my $country_only = 0;
my $exclude_continent = 0;
my $continent_only = 0;

# Pre-defined display limit for search results:
my $def_result_limit = 30;

my @map_locations;

# Default Search Prompt and Loop:
while ($done_default == 0)
{
	# Set modifiers to zero (false) at beginning of each loop:
	$exclude_country = 0;
	$country_only = 0;
	$exclude_continent = 0;
	$continent_only = 0;
	
	# Empty the match count at the beginning of each loop:
	$keyword_match_count = 0;
	
	# Empty the cities_found array at the beginning of each loop:
	@cities_found = ();
	@map_locations = ();
	
	# Initialize default weights:
	my ($def_weight_pop, $def_weight_elev, $def_weight_avg_temp,
		$def_weight_high_temp, $def_weight_low_temp, $def_weight_rain,
		$def_weight_snow, $def_weight_humid, $def_weight_wind) = 
		(0, 1, 1, 1, 1, 1, 1, 1, 1);
	
	# Initialize climate parameter variables:
	my ($def_pop, $def_elev, $def_avg_temp, 
		$def_high_temp, $def_low_temp, $def_rain, 
		$def_snow, $def_humid, $def_wind) = 
		(0, 0, 0, 0, 0, 0, 0, 0, 0);
	
	# Default Search prompt:
	print "\nEnter a location name, or type 'custom' to start the Custom Search module: ";
	my $def_search = <STDIN>;
	chomp $def_search;
	
	# Exit statement:
	exit 0 if ($def_search =~ m/^quit$/i);
	
	# Stop default search, begin custom search if user types in 'custom':
	if ($def_search =~ m/^custom$/i)
	{
		$done_default = 1;
		last;
	}
	
	# Regex: if user input includes a minus sign:
	if ($def_search =~ m/[-]/)
	{
		# Change all default weights to negative values to search
		# for most dissimilar results:
		($def_weight_pop, $def_weight_elev, $def_weight_avg_temp,
		$def_weight_high_temp, $def_weight_low_temp, $def_weight_rain,
		$def_weight_snow, $def_weight_humid, $def_weight_wind) = 
		(0, -1, -1, -1, -1, -1, -1, -1, -1);
	}
	
	# Records from the same country will be excluded:
	($exclude_country = 1) if ($def_search =~ m/[>]/);
	
	# Records not from the same country will be excluded:
	($country_only = 1) if ($def_search =~ m/[<]/);
	
	# Records from the same continent will be excluded:
	($exclude_continent = 1) if ($def_search =~ m/[\\]/);
	
	# Records not from the same continent will be excluded:
	($continent_only = 1) if ($def_search =~ m/[\/]/);
	
	# Regex: Error statement if user includes both '<' and '>':
	if ($def_search =~ m/[>]/ && $def_search =~ m/[<]/)
	{
		# Clear user input so that it cannot proceed with matching:
		$def_search = 0;
		print "\n* Error: Using '<' and '>' at the same time will filter out all results.\n";
		print "  Remove one of the modifiers from your input and try again!\n";
	}
	
	# Regex: Error statement if user includes both '<' and '>':
	if ($def_search =~ m/[\/]/ && $def_search =~ m/[\\]/)
	{
		# Clear user input so that it cannot proceed with matching:
		$def_search = 0;
		print "\n* Error: Using '\/' and '\\' at the same time will filter out all results.\n";
		print "  Remove one of the modifiers from your input and try again!\n";
	}
	
	# Regex: Error statement if user includes '<' and '\':
	if ($def_search =~ m/[<]/ && $def_search =~ m/[\\]/)
	{
		# Clear user input so that it cannot proceed with matching:
		$def_search = 0;
		print "\n* Error: Using '<' and '\\' at the same time will filter out all results.\n";
		print "  Remove one of the modifiers from your input and try again!\n";
	}
	
	# If included, convert special characters to spaces so they do not mess with searching:
	$def_search =~ s/[\W]/ /g;
	# Convert common alternative place names here, so that they match the database format:
	$def_search =~ s/\bnyc\b/New York/i;
	$def_search =~ s/bay area/San Francisco/i;
	$def_search =~ s/united states/USA/i;
	$def_search =~ s/\bUS\b/USA/i;
	$def_search =~ s/new zealand/NZ/i;
	$def_search =~ s/united kingdom/UK/i;
	$def_search =~ s/central african republic/CAR/i;
	$def_search =~ s/democratic republic of the congo/DRC/i;
	# Change common abbreviations to full spelling (periods optional):
	$def_search =~ s/\b(st[.]* )/Saint /i;
	$def_search =~ s/\b(ft[.]* )/Fort /i;
	$def_search =~ s/\b(ste[.]* )/Sainte /i;
	$def_search =~ s/\b(mt[.]* )/Mount /i;
	
	#----------------------------------------------------------------#
	
	# PARSING AND MATCHING USER INPUT KEYWORDS
	
	# Split the user input into keywords, separated by space:
	my @default_keywords = split " ", $def_search;
	
	# Loop through climate records looking for user input matches:
	foreach my $city (sort keys %climate_profiles)
	{
		
		# Reset keyword count at beginning of loop:
		$keyword_count = 0;
		# For each keyword entered by user:
		foreach my $keyword (@default_keywords)
		{
			# Regex: check if keyword is 2-3 capital letters (interpreted as state/country initials)
			# AND check if record name contains user input (case-sensitive)
			# preceded by a space (that's how it knows the input is referring to a state or country):
			($keyword_count += 1) if ($keyword =~ m/^[A-Z]{2,3}$/ && $city =~ m/\Q$keyword/);
			
			# Regex: if keyword is NOT 2-3 capital letters
			# AND record name contains user input (case-insensitive):
			($keyword_count += 1) if ($keyword !~ m/^[A-Z]{2,3}$/ && $city =~ m/\Q$keyword/i);
		}
		
		# If number of matched keywords equals the number of keywords
		# specified by the user:
		if ($keyword_count == scalar @default_keywords)
		{
			# Increment keyword count:
			$keyword_match_count += 1;
			# Assign the values for the matching record as the default search criteria:
			(	$def_pop, $def_elev, $def_avg_temp, 
				$def_high_temp, $def_low_temp, $def_rain, 
				$def_snow, $def_humid, $def_wind	) = 
			(	$climate_profiles{$city}->[0], $climate_profiles{$city}->[1],
				$climate_profiles{$city}->[2], $climate_profiles{$city}->[3],
				$climate_profiles{$city}->[4], $climate_profiles{$city}->[5],
				$climate_profiles{$city}->[6], $climate_profiles{$city}->[7],
				$climate_profiles{$city}->[8] 	);
			
			# Assign city name:
			$def_city = $city;
			# Add matching city names to an array:
			push @cities_found, $def_city;
		}
	}
	
	#--------------------------------------------------------------------------------------#
	
	# CALCULATING DIFFERENCE SCORES
	
	CALCDIFF:
	# If only one matching climate record was found:
	if ($keyword_match_count == 1)
	{
		# Proceed to calculate difference scores for all cities in database:
		print "\n* Found matching record: $cities_found[0]. Calculating difference scores...\n";
		sleep(1);
		
		# activated when '/' modifier is included in user input:
		if ($exclude_continent == 1)
		{
			# Retrieve continent from climate_profiles hash:
			$def_continent = $climate_profiles{$cities_found[0]}->[9];
			print "\n* Excluding results from $def_continent...\n";
			sleep(1);
		}
		
		# activated when '\' modifier is included in user input:
		if ($continent_only == 1)
		{
			# Retrieve continent from climate_profiles hash
			$def_continent = $climate_profiles{$cities_found[0]}->[9];
			print "\n* Limiting search scope to $def_continent...\n";
			sleep(1);
		}
		
		# Loop activated when '>' modifier is included in user input:
		if ($exclude_country == 1)
		{
			# Split user-selected city's name into words, save the last word as the country name:
			my @def_words = split " ", $cities_found[0];
			$def_country = $def_words[-1];
			print "\n* Excluding results from $def_country...\n";
			sleep(1);
		}
		
		# activated when '<' modifier is included in user input:
		if ($country_only == 1)
		{
			# Split user-selected city's name into words, save the last word as the country name:
			my @def_words = split " ", $cities_found[0];
			$def_country = $def_words[-1];
			print "\n* Limiting search scope to $def_country...\n";
			sleep(1);
		}
		
		# Print message if user specifies to use negative weights:
		if ($def_weight_elev < 0)
		{
			print "\n* Using negative weights to find most dissimilar results...\n";
			sleep(1);
		}
		
		# Loop to remove results based on '/' and '\' modifiers:
		foreach my $city (keys %climate_profiles)
		{
			# Regex: if user input contains '\' and a climate record matches the
			# continent of the user-selected city:
			if ($exclude_continent == 1 && $climate_profiles{$city}->[9] =~ m/$def_continent/)
			{
				# Move record to removed_profiles temporarily, delete from climate_profiles:
				$removed_profiles{$city} = $climate_profiles{$city};
				delete $climate_profiles{$city};
			}
			# Regex: if user input contains '/' and a climate record does not match the
			# continent of the user-selected city:
			elsif ($continent_only == 1 && $climate_profiles{$city}->[9] !~ m/$def_continent/)
			{
				# Move record to removed_profiles temporarily, delete from climate_profiles:
				$removed_profiles{$city} = $climate_profiles{$city};
				delete $climate_profiles{$city};
			}
		}
		
		# Loop to remove results based on '>' and '<' modifiers:
		foreach my $city (keys %climate_profiles)
		{
			# Regex: if user input contains '>' and a climate record matches
			# the country of the user-selected city:
			if ($exclude_country == 1 && $city =~ m/\b$def_country\b/)
			{
				# Move record to removed_profiles temporarily, delete from climate_profiles:
				$removed_profiles{$city} = $climate_profiles{$city};
				delete $climate_profiles{$city};
			}
			# Regex: if user input contains '<' and a climate record does not match the
			# country of the user-selected city:
			elsif ($country_only == 1 && $city !~ m/\b$def_country\b/)
			{
				# Move record to removed_profiles temporarily, delete from climate_profiles:
				$removed_profiles{$city} = $climate_profiles{$city};
				delete $climate_profiles{$city};
			}
		}
		
		foreach my $city (keys %climate_profiles)
		{
			# Copy cities (keys) to diff_profiles hash, and add placeholder values for each category entry:
			$def_diff_profiles{$city} = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
			
			# Calculate standardized/weighted residual for each category (residual between user input and each entry):
			$def_diff_profiles{$city}->[0] = log( abs( $def_pop - $climate_profiles{$city}->[0] ) / $climate_stdevs[0] + 1 ) * $def_weight_pop;
			$def_diff_profiles{$city}->[1] = log( abs( $def_elev - $climate_profiles{$city}->[1] ) / $climate_stdevs[1] + 1 ) * $def_weight_elev;
			$def_diff_profiles{$city}->[2] = abs( $def_avg_temp - $climate_profiles{$city}->[2] ) / $climate_stdevs[2] * $def_weight_avg_temp;
			$def_diff_profiles{$city}->[3] = abs( $def_high_temp - $climate_profiles{$city}->[3] ) / $climate_stdevs[3] * $def_weight_high_temp;
			$def_diff_profiles{$city}->[4] = abs( $def_low_temp - $climate_profiles{$city}->[4] ) / $climate_stdevs[4] * $def_weight_low_temp;
			$def_diff_profiles{$city}->[5] = log( abs( $def_rain - $climate_profiles{$city}->[5] ) / $climate_stdevs[5] + 1 ) * $def_weight_rain;
			$def_diff_profiles{$city}->[6] = log( abs( $def_snow - $climate_profiles{$city}->[6] ) / $climate_stdevs[6] + 1 ) * $def_weight_snow;
			$def_diff_profiles{$city}->[7] = abs( $def_humid - $climate_profiles{$city}->[7] ) / $climate_stdevs[7] * $def_weight_humid;
			$def_diff_profiles{$city}->[8] = abs( $def_wind - $climate_profiles{$city}->[8] ) / $climate_stdevs[8] * $def_weight_wind;
			# Note: By default, Population is weighted per thousand people.
			# Pop, Elev, Rain, and Snowfall are also weighted logarithmically. 
			# All the rest are weighted normally.
			
			# Calculate difference score for each city, add to hash of diff-scores:
			$def_diff_score = 0;
			foreach my $category ( @{$def_diff_profiles{$city}} )
			{
				# Add up the residuals for all categories:
				$def_diff_score += $category;
			}
			
			# Add total difference score to hash:
			$def_diff_scores{$city} = $def_diff_score;
		}
		
		#-----------------------------------------------------------------------------------#
		
		# PRINTING DEFAULT SEARCH RESULTS
		
		print "\nSEARCH CRITERIA:\n\n";
		
		# Print category names:
		printf "%35s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n",
		"Attributes:", "Population", "Elevation", "Avg Temp", "High Temp", "Low Temp", 
		"Rainfall", "Snowfall", "Humidity", "Windspeed";
		# Print out user-defined search criteria:
		printf "%35s %10s %10s %10.10s %10.10s %10.10s %10.10s %10.10s %10.10s %10.10s\n",
		"$def_city:", "$def_pop k", "$def_elev m", "$def_avg_temp C", "$def_high_temp C", 
					"$def_low_temp C", "$def_rain cm", "$def_snow cm", "$def_humid \%", 
					"$def_wind km/h";
		sleep(2);
		
		print "\nSEARCH RESULTS:\n\n";
		
		# Print headers for search result categories:
		printf "%35s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n\n",
		"City ST Country", "Population", "Elevation", "Avg Temp", "High Temp",
		"Low Temp", "Rainfall", "Snowfall", "Humidity", "Windspeed", "DIFF-SCORE";
		
		# Print out sorted climate data for each city (up to display limit), along with difference score:
		my $def_result_count = 0;
		foreach my $profile ( 	sort { $def_diff_scores{$a} <=> $def_diff_scores{$b} } keys %def_diff_scores)
		{
			push @map_locations, [$profile, $climate_profiles{$profile}->[10], $climate_profiles{$profile}->[11]];
			
			printf "%35s %10d %10d %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.2f\n",
			$profile, "$climate_profiles{$profile}->[0]000", $climate_profiles{$profile}->[1], 
			$climate_profiles{$profile}->[2], $climate_profiles{$profile}->[3], 
			$climate_profiles{$profile}->[4], $climate_profiles{$profile}->[5], 
			$climate_profiles{$profile}->[6], $climate_profiles{$profile}->[7], 
			$climate_profiles{$profile}->[8], $def_diff_scores{$profile};
			
			$def_result_count += 1;
			# Print new line every 10 results to space out the results:
			print "\n" if ($def_result_count % 10 == 0);
			# Stops printing once the display limit is reached:
			last if ($def_result_count == $def_result_limit);
		}
		
		print "Do you want to plot your top 10 matches on a map? [Y/N]: ";
		my $plot_data = <STDIN>;
		
		# Write city/lat/long data to a CSV file, open a Python script
		# to plot the data on a map:
		if ($plot_data =~ m/^[yY]$/)
		{	
			# Open/write the locations to be mapped to output file :
			my $loc_file;
			my $timestamp = localtime();
			$timestamp =~ s/[\W]//g;
			$cities_found[0] =~ s/[\W]//g;
			
			open( $loc_file, ">", "cse_matches_$timestamp-$cities_found[0].csv" ) || die "* Could not create output file!\n";
			
			# Sends city/state/country name and lat/long coordinates to output CSV file:
			foreach my $city (@map_locations)
			{
				print $loc_file "$$city[0],$$city[1],$$city[2]\n";
			}
			
			# Close the completed output file:
			close( $loc_file );
			
			# Execute Output generator script, with CSV file and full city name as arguments:
			system "cse_output.pl cse_matches_$timestamp-$cities_found[0].csv $cities_found[0]";
		}
		
		# Restore removed profiles at the end of each loop:
		foreach my $city (keys %removed_profiles)
		{
			$climate_profiles{$city} = $removed_profiles{$city};
			delete $removed_profiles{$city};
		}
		# Clear the def_diff_profiles and def_diff_scores hashes at the end of each loop:
		foreach my $city (keys %def_diff_profiles)
		{
			delete $def_diff_profiles{$city};
			delete $def_diff_scores{$city};
		}			
	}
	#--------------------------------------------------------------------------
	# HANDLING SEARCH MISTAKES

	# If more than one matching record is found:
	if ($keyword_match_count > 1)
	{
		# List the matching records:
		print "\n* Your search criteria matched more than one city:\n\n";
		
		my $found_counter = 0;
		foreach my $found_city (@cities_found)
		{
			$found_counter += 1;
			print "* $found_counter - $found_city\n";
		}
		
		# Flag that determines if user has made a valid selection:
		my $city_chosen = 0;
		
		while ($city_chosen == 0)
		{
			# Print error statement:
			print "\n* Type in the number corresponding to your desired result to proceed: ";
			my $city_choice = <STDIN>;
			exit 0 if ($city_choice =~ m/^quit$/i);
			
			# If user specifies number corresponding to a city:
			if ($city_choice =~ m/^[0-9]+$/ && $city_choice <= $found_counter)
			{
				# Assign matching city as the search criteria:
				@cities_found = $cities_found[$city_choice - 1];
				my $city_match = $cities_found[0];
			
				# Assign city attributes to the search profile:
				(	$def_city, $def_pop, $def_elev, $def_avg_temp, 
					$def_high_temp, $def_low_temp, $def_rain, 
					$def_snow, $def_humid, $def_wind	) = 
				(	$city_match, $climate_profiles{$city_match}->[0], 
					$climate_profiles{$city_match}->[1], $climate_profiles{$city_match}->[2], 
					$climate_profiles{$city_match}->[3], $climate_profiles{$city_match}->[4], 
					$climate_profiles{$city_match}->[5], $climate_profiles{$city_match}->[6], 
					$climate_profiles{$city_match}->[7], $climate_profiles{$city_match}->[8] 	);
			
				# Proceed to calculating difference scores:
				$keyword_match_count = 1;
				goto CALCDIFF;
			}
			# If user makes mistake in choosing city to search with:
			else
			{
				print "\n* Error: select a number that matches one of the options above.\n";
				sleep(1);
				next;
			}
		}
	}
	
	# If no exact matching records are found:
	elsif ($keyword_match_count == 0)
	{
		# Check each keyword individually to see if it matches a record:
		foreach my $keyword (@default_keywords)
		{
			foreach my $city (keys %climate_profiles)
			{
				if ($city =~ m/\Q$keyword/i)
				{
					push @cities_found, $city;
					
					(	$def_pop, $def_elev, $def_avg_temp, 
						$def_high_temp, $def_low_temp, $def_rain, 
						$def_snow, $def_humid, $def_wind	) = 
					(	$climate_profiles{$city}->[0], $climate_profiles{$city}->[1],
						$climate_profiles{$city}->[2], $climate_profiles{$city}->[3],
						$climate_profiles{$city}->[4], $climate_profiles{$city}->[5],
						$climate_profiles{$city}->[6], $climate_profiles{$city}->[7],
						$climate_profiles{$city}->[8] 	);
				}
			}
		}
		
		# If multiple partially matching records was found:
		if (@cities_found > 1)
		{
			print "\n* No exact matches found for your search input. Did you mean: \n";
			foreach my $found_city (@cities_found)
			{
				print "$found_city\n";
			}
		}
		# If no partially matching records were found:
		elsif (@cities_found == 0)
		{
			# Print error statement:
			print "\n* No cities found matching your search criteria. Check spelling and modifier usage and try again!\n\n";
		}
		
		# If a single partially matching record was found:
		elsif (@cities_found == 1)
		{
			print "\n* One partially matching record found: $cities_found[0]\n";
			print "\nDo you want to perform search with this record?[y/n]: ";
			my $partial_search = <STDIN>;
			
			if ($partial_search =~ m/^y$/)
			{
				$keyword_match_count = 1;
				
				goto CALCDIFF;
			}
			else
			{
				next;
			}
		}
	}
}

#------------------------------------------------------------------------------------------#

# CUSTOM SEARCH MODULE

print "\n* Initializing Custom Search module...\n";
sleep(2);

print "\nCLIMATE SEARCH ENGINE - CUSTOM SEARCH\n";
print "-------------------------------------\n\n";
sleep(1);

print "Instructions:\n";

# Checks if user is finished with custom search (0 by default):
my $done_custom = 0;
# Counts number of custom parameters and weights assigned:
my $params_assigned = 0;
my $weights_assigned = 0;

# While loop for Custom Search:
while ($done_custom == 0)
{
	print "\nAssign values for the following parameters:\n\n";
	
	print "* Population (in thousands)\n";
	print "* Elevation (in meters)\n";
	print "* Average Annual Temperature (in Celsius)\n";
	print "* Highest Monthly High Temperature (in Celsius)\n";
	print "* Lowest Monthly Low Temperature (in Celsius)\n";
	print "* Average Annual Rainfall (in centimeters)\n";
	print "* Average Annual Snowfall (in centimeters)\n";
	print "* Average Relative \% Humidity\n";
	print "* Average Annual Windspeed (in km/h)\n";
	
	# Reset user parameter count to zero before each loop:
	$params_assigned = 0;
	
	# Initialize variables for custom parameters and weights:
	my ($user_pop, $user_elev, $user_avg_temp, 
		$user_high_temp, $user_low_temp, $user_rain, 
		$user_snow, $user_humid, $user_wind);
	
	my ($weight_pop, $weight_elev, $weight_avg_temp, 
		$weight_high_temp, $weight_low_temp, $weight_rain, 
		$weight_snow, $weight_humid, $weight_wind);
	
	# While loop for climate parameters (continues until all 9 parameters are entered correctly):
	while ($params_assigned < 9)
	{
		# Keeps track of how many parameters were not defined by user:
		my $params_undef = 0;
		
		# Climate parameter prompt:
		print	"\nEnter parameters here, separated by spaces: ";
		my $user_inputs = <STDIN>;
		chomp $user_inputs;
		
		# Exit statement:
		exit 0 if ($user_inputs =~ m/^quit$/i);
		
		# Split and assign user inputs to named variables, based on space:
		($user_pop, $user_elev, $user_avg_temp, 
		 $user_high_temp, $user_low_temp, $user_rain, 
		 $user_snow, $user_humid, $user_wind) 
		 = split " ", $user_inputs;
			
		# Error statement when one of the search parameters is not assigned a value:
		if (!defined $user_pop || !defined $user_elev || !defined $user_avg_temp || 
			!defined $user_high_temp || !defined $user_low_temp || !defined $user_rain ||
			!defined $user_snow || !defined $user_humid || !defined $user_wind)
		{
			print "\n* Error: one or more parameters were not defined. Please check your input and try again!\n";
			$params_undef = 1;
		}
		
		# If all parameters are defined, proceed to check if format is correct:
		if ($params_undef == 0)
		{
			# Regex: If population is not a positive number < 100,000 (decimals optional):
			if ($user_pop !~ m/^[0-9]{1,5}\.?[0-9]*$/)
			{
				print "\n* Population: Incorrect format! Please enter a positive number (must be < 100,000).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If elevation is not a positive/negative number (decimals optional):
			if ($user_elev !~ m/^[-]?[0-9]{1,4}\.?[0-9]*$/)
			{
				print "\n* Elevation: Incorrect format! Please enter a positive/negative number (must be < 10,000).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If avg. temp, is not a negative/positive number < 1000 (decimals optional):
			if ($user_avg_temp !~ m/^[-]?[0-9]{1,3}\.?[0-9]*$/)
			{
				print "\n* Average Temperature: Incorrect format! Please enter a positive/negative number (must be < 1000).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If high temp. is not a positive/negative number < 1000 (decimals optional):
			if ($user_high_temp !~ m/^[-]?[0-9]{1,3}\.?[0-9]*$/)
			{
				print "\n* High Temperature: Incorrect format! Please enter a positive/negative number (must be < 1000).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If low temp. is not a positive/negative number < 1000 (decimals optional):
			if ($user_low_temp !~ m/^[-]?[0-9]{1,3}\.?[0-9]*$/)
			{
				print "\n* Low Temperature: Incorrect format! Please enter a positive/negative number for temperature (must be < 1000).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If rainfall is not a positive number < 1000 (decimals optional):
			if ($user_rain !~ m/^[0-9]{1,3}\.?[0-9]*$/)
			{
				print "\n* Rainfall: Incorrect format! Please enter a positive number (must be < 1000).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If snowfall is not a positive number < 1000 (decimals optional):
			if ($user_snow !~ m/^[0-9]{1,3}\.?[0-9]*$/)
			{
				print "\n* Snowfall: Incorrect format! Please enter a positive number (must be < 1000).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If humidity is not a positive number < 100 (decimals optional):
			if ($user_humid !~ m/^[0-9]{1,2}\.?[0-9]*$/)
			{
				print "\n* Humidity: Incorrect format! Please enter a positive number (must be < 100).\n";
			}
			else
			{
				$params_assigned += 1;
			}
			
			# Regex: If windspeed is not a positive number < 100 (decimals optional):
			if ($user_wind !~ m/^[0-9]{1,2}\.?[0-9]*$/)
			{
				print "\n* Windspeed: Incorrect format! Please enter a positive number (must be < 100).\n";
			}
			else
			{
				$params_assigned += 1;
			}
		}
	}
	sleep(1);
	
	# Once user parameters have been correctly assigned, begin weight assignment:
	if ($params_assigned == 9)
	{
		print "\nAssign weights for the following parameters:\n\n";
		
		print "* Population (in thousands)\n";
		print "* Elevation (in meters)\n";
		print "* Average Annual Temperature (in Celsius)\n";
		print "* Highest Monthly High Temperature (in Celsius)\n";
		print "* Lowest Monthly Low Temperature (in Celsius)\n";
		print "* Average Annual Rainfall (in centimeters)\n";
		print "* Average Annual Snowfall (in centimeters)\n";
		print "* Average Relative \% Humidity\n";
		print "* Average Annual Windspeed (in km/h)\n";
	}
	
	# Reset weights assigned count to zero before each loop:
	$weights_assigned = 0;
	
	# While loop for assigning weights (continues until weights for all 9 parameters are assigned):
	while ($weights_assigned < 9)
	{
		# Checks if any weights were not defined by user:
		my $weights_undef = 0;
		
		# Weight assignment prompt:
		print "\nEnter weights here, separated by spaces: ";
		my $user_weights = <STDIN>;
		chomp $user_weights;
		
		# Exit statement:
		exit 0 if ($user_weights =~ m/^quit$/i);
		
		# Split and assign user inputs to named variables, based on space:
		($weight_pop, $weight_elev, $weight_avg_temp, 
		 $weight_high_temp, $weight_low_temp, $weight_rain, 
		 $weight_snow, $weight_humid, $weight_wind) 
		 = split " ", $user_weights;
		
		# Error statement when one of the search parameters is not assigned a value:
		if (!defined $weight_pop || !defined $weight_elev || !defined $weight_avg_temp || 
			!defined $weight_high_temp || !defined $weight_low_temp || !defined $weight_rain ||
			!defined $weight_snow || !defined $weight_humid || !defined $weight_wind)
		{
			print "One or more parameters were not defined. Please check your input and try again!\n";
			$weights_undef = 1;
		}
		
		# If all weights were defined, proceed to check if formats are correct:
		if ($weights_undef == 0)
		{
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_pop =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Population: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_elev =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Elevation: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_avg_temp =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Average Temp: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_high_temp =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Average Temp: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_low_temp =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Low Temperature: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_rain =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Rainfall: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_snow =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Snowfall: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_humid =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Humidity: Incorrect weight format! Please enter a positive/negative number.\n";
			}
			
			# Regex: Assigned weight must be a positive/negative number (decimals optional):
			if ($weight_wind =~ m/^[-]?[0-9]+\.?[0-9]*$/)
			{
				$weights_assigned += 1;
			}
			else
			{
				print "\n* Windspeed: Incorrect weight format! Please enter a positive/negative number.\n";
			}
		}
	}
	sleep(1);
	
	#----------------------------------------------------------------------------------------#
	
	# CONTINENT/REGION FILTER
	
	my $done_regions_filtered = 0;
	my $moved_count = 0;
	my $remain_count = 0;
	my $regions_delete_count = 0;
	
	# Loop for continent/region filter:
	while ($done_regions_filtered == 0)
	{
		print "\nSelect the regions you want to include in your search:\n\n";
		print "* 1 - Africa\n";
		print "* 2 - Asia\n";
		print "* 3 - Europe\n";
		print "* 4 - Middle East\n";
		print "* 5 - Oceania\n";
		print "* 6 - Latin America & Caribbean\n";
		print "* 7 - North America\n";
		print "* 8 - South America\n";
		print "* 9 - Antarctica\n";
		
		print "\nType in the corresponding number(s), or leave blank to search all of them: ";
		my $user_regions = <STDIN>;
		chomp $user_regions;
		
		# Exit statement:
		exit 0 if ($user_regions =~ m/^quit$/i);
		
		# Regex: if user input is blank:
		if ($user_regions =~ m/^(?![\s\S])$/)
		{
			# Don't filter any results, exit loop:
			$done_regions_filtered = 1;
			last;
		}
		# Regex: if user input includes non-numeric characters:
		elsif ($user_regions =~ m/[\D]/i)
		{
			# Print error statement:
			print "\n* Error: Please use only numbers in your input!\n";
		}
		else
		{
			# Regex: Substitute the continent/region name for the number(s) provided by user:
			$user_regions =~ s/1/Africa/;
			$user_regions =~ s/2/Asia/;
			$user_regions =~ s/3/Europe/;
			$user_regions =~ s/4/Middle East/;
			$user_regions =~ s/5/Oceania/;
			$user_regions =~ s/6/Latin America/;
			$user_regions =~ s/7/North America/;
			$user_regions =~ s/8/South America/;
			$user_regions =~ s/9/Antarctica/;
			
			# Loop through the climate records, and remove any records that don't match:
			foreach my $city (keys %climate_profiles)
			{
				# Store continent/region name as variable for each climate record:
				my $region_name = $climate_profiles{$city}->[9];
				
				# Regex: if (interpreted) user input does not match
				# the region name for a certain record AND is not blank:
				if ($user_regions !~ m/$region_name/)
				{
					$removed_profiles{$city} = $climate_profiles{$city};
					delete $climate_profiles{$city};
					
					# Increment count of deleted records:
					$regions_delete_count += 1;
				}
			}
			# Done filtering, exit loop:
			$done_regions_filtered = 1;
		}
	}
	# Calculate number of remaining climate entries:
	$remain_count = scalar keys %climate_profiles;
	sleep(1);
	
	print "\n* $regions_delete_count climate records were removed from search results, $remain_count climate records remaining.\n";
	sleep(1);
	
	#----------------------------------------------------------------------------------------#
	
	# MIN/MAX POPULATION FILTER
	
	# Default population range (which will include all possible populations):
	my @pop_range = (0, 99999);
	my $pop_filtered = 0;
	my $pop_delete_count = 0;
	
	# While loop for population filter:
	while ($pop_filtered == 0)
	{
		# Population filter prompt:
		print "\nSet minimum/maximum population (format: #####,#####), or leave blank: ";
		my $min_max_pop = <STDIN>;
		chomp $min_max_pop;
		
		# Exit statement:
		exit 0 if ($min_max_pop =~ m/^quit$/i);
		
		# Split user input on comma:
		@pop_range = split ',', $min_max_pop;
		
		# Regex: Make sure user input matches format (#####,#####), and 1st number is smaller than 2nd:
		if ($min_max_pop =~ m/^([0-9]{1,5}),([0-9]{1,5})$/ && $1 < $2)
		{
			# Loop through all climate entries:
			foreach my $city (keys %climate_profiles)
			{
				# Remove any entry with a population below the minimum or above the maximum,
				# but also store them in another hash so that they can be restored for the next loop:
				if ( 	$climate_profiles{$city}->[0] < $pop_range[0]	|| 
						$climate_profiles{$city}->[0] > $pop_range[1] 	)
				{
					$removed_profiles{$city} = $climate_profiles{$city};
					delete $climate_profiles{$city};
					
					# Increment count of deleted records:
					$pop_delete_count += 1;
				}
			}
			# Filtering complete, exit loop:
			$pop_filtered = 1;
		}
		# If user input is blank:
		elsif ($min_max_pop =~ m/^(?![\s\S])$/)
		{
			# Don't filter any results, exit loop:
			$pop_filtered = 1;
		}
		# Error statement if numbers are not in order, or are equal:
		elsif ($pop_range[0] >= $pop_range[1])
		{
			print "\n* Incorrect format! First number must be smaller than second number.\n";
		}
		# General error statement:
		else
		{
			print "\n* Incorrect format! Please enter two numbers separated by a comma.\n";
		}
	}
	
	# Calculate number of remaining climate entries:
	$remain_count = scalar keys %climate_profiles;
	sleep(1);
	
	print "\n* $pop_delete_count climate records were removed from search results, $remain_count climate records remaining.\n";
	sleep(1);
	
	#-------------------------------------------------------------------------------#
	
	# SETTING DISPLAY LIMIT
	
	# By default, the number of results to be displayed is 
	# equal to the number of entries compiled:
	my $display_limit = $entry_count;
	my $display_limit_set = 0;
	
	# While loop for setting display limit:
	while ($display_limit_set == 0)
	{
		# Display limit prompt:
		print "\nEnter a limit for the number of results to display: ";
		my $user_limit = <STDIN>;
		chomp $user_limit;
		
		# Exit statement:
		exit 0 if ($user_limit =~ m/^quit$/i);
		
		# Regex: user input must be a whole positive number:
		if ($user_limit =~ m/^[0-9]+$/)
		{
			# Set display limit equal to user input:
			$display_limit = $user_limit;
		}
		# Regex: if user input is left blank or set to zero:
		elsif ($user_limit =~ m/\A\z/ || $user_limit =~ m/^0$/)
		{
			# Result limit remains equal to number of entries:
			$display_limit = $entry_count;
		}
		# If user input cannot be interpreted, default display limit will be used:
		else
		{
			print "\n* Input not recognized, default limit will be used...\n";
			$display_limit = 30;
		}
		# Exit loop:
		$display_limit_set = 1;
	}
	sleep(1);

	#--------------------------------------------------------------------------#
	
	# CALCULATING DIFFERENCE SCORES
	
	# Initialize hash for containing residuals for each climate record:
	my %diff_profiles;
	
	# Copy keys to diff_profiles hash, and add placeholder names for each category entry:
	foreach my $city (keys %climate_profiles)
	{
		$diff_profiles{$city} = [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
	}
	
	# Initialize hash of difference scores (cities will be keys):
	my %diff_scores;
	# For each city entry in the climate_profiles hash:
	foreach my $city (keys %climate_profiles)
	{
		# Calculate standardized/weighted residual for each category (diff. between user input and each entry):
		$diff_profiles{$city}->[0] = log( abs( $user_pop - $climate_profiles{$city}->[0] ) / $climate_stdevs[0] + 1 ) * $weight_pop;
		$diff_profiles{$city}->[1] = log( abs( $user_elev - $climate_profiles{$city}->[1] ) / $climate_stdevs[1] + 1 )* $weight_elev;
		$diff_profiles{$city}->[2] = abs( $user_avg_temp - $climate_profiles{$city}->[2] ) / $climate_stdevs[2] * $weight_avg_temp;
		$diff_profiles{$city}->[3] = abs( $user_high_temp - $climate_profiles{$city}->[3] ) / $climate_stdevs[3] * $weight_high_temp;
		$diff_profiles{$city}->[4] = abs( $user_low_temp - $climate_profiles{$city}->[4] ) / $climate_stdevs[4] * $weight_low_temp;
		$diff_profiles{$city}->[5] = log( abs( $user_rain - $climate_profiles{$city}->[5] ) / $climate_stdevs[5] + 1 ) * $weight_rain;
		$diff_profiles{$city}->[6] = log( abs( $user_snow - $climate_profiles{$city}->[6] ) / $climate_stdevs[6] + 1 ) * $weight_snow;
		$diff_profiles{$city}->[7] = abs( $user_humid - $climate_profiles{$city}->[7] ) / $climate_stdevs[7] * $weight_humid;
		$diff_profiles{$city}->[8] = abs( $user_wind - $climate_profiles{$city}->[8] ) / $climate_stdevs[8] * $weight_wind;
		# Note: By default, Population is weighted per thousand people. 
		# Pop, Elev, Rain, and Snowfall are also weighted logarithmically to reduce impact of outliers. 
		# All the rest are weighted normally.
		
		# Calculate difference score for each city, add to hash of diff-scores:
		my $diff_score = 0;
		foreach my $category ( @{$diff_profiles{$city}} )
		{
			# Sum up the difference scores for each category:
			$diff_score += $category;
		}
		# Assign difference score to diff_scores hash:
		$diff_scores{$city} = $diff_score;	
	}
	
	#------------------------------------------------------------------------------------#
	
	# PRINTING CUSTOM SEARCH RESULTS
	
	print "\n\nSEARCH CRITERIA:\n\n";
	
	# Print category names:
	printf "%35s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n\n",
	"Attributes:", "Population", "Elevation", "Avg Temp", "High Temp", "Low Temp", 
	"Rainfall", "Snowfall", "Humidity", "Windspeed";
	# Print out user-defined search criteria:
	printf "%35s %10s %10s %10.10s %10.10s %10.10s %10.10s %10.10s %10.10s %10.10s\n",
	"Input:", 	"$user_pop k", "$user_elev m", "$user_avg_temp C", "$user_high_temp C", 
				"$user_low_temp C", "$user_rain cm", "$user_snow cm", "$user_humid \%", 
				"$user_wind km/h";
	# Print user-defined weights for each category:
	printf "%35s %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f\n\n", 
	"Weights:", 	$weight_pop, $weight_elev, $weight_avg_temp, $weight_high_temp, 
					$weight_low_temp, $weight_rain, $weight_snow, $weight_humid, 
					$weight_wind;
	sleep(2);
	
	print "\nSEARCH RESULTS:\n\n";
			
	# Print headers for search result categories:
	printf "%35s %10s %10s %10s %10s %10s %10s %10s %10s %10s %10s\n\n",
	"City ST Country", "Population", "Elevation", "Avg Temp", "High Temp",
	"Low Temp", "Rainfall", "Snowfall", "Humidity", "Windspeed", "DIFFSCORE";
	
	# Print out sorted climate data for each city (up to display limit), along with difference score:
	my $result_count = 0;
	foreach my $profile ( 	sort { $diff_scores{$a} <=> $diff_scores{$b} } keys %diff_scores)
	{
		printf "%35s %10d %10d %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.1f %10.2f\n",
		$profile, "$climate_profiles{$profile}->[0]000", $climate_profiles{$profile}->[1], 
		$climate_profiles{$profile}->[2], $climate_profiles{$profile}->[3], 
		$climate_profiles{$profile}->[4], $climate_profiles{$profile}->[5], 
		$climate_profiles{$profile}->[6], $climate_profiles{$profile}->[7], 
		$climate_profiles{$profile}->[8], $diff_scores{$profile};
		
		$result_count += 1;
		
		# Print carriage return every 10 results:
		print "\n" if ($result_count % 10 == 0);
		# Stop printing once display limit has been reached:
		last if ($result_count == $display_limit);
	}
	
	# Restore records that were removed during the population filtering,
	# and empty the removed_profiles hash:
	foreach my $city (keys %removed_profiles)
	{
		$climate_profiles{$city} = $removed_profiles{$city};
		delete $removed_profiles{$city};
	}
	sleep(1);
	
	#--------------------------------------------------------------------------------------------#
	
	# STARTING ANOTHER CUSTOM SEARCH
	
	# Ask user to perform another custom search, or quit the program:
	print "\nTo perform another custom search, type in 'custom'. Otherwise, program will quit: ";
	my $search_again = <STDIN>;
	chomp $search_again;
	
	# Exit statements:
	exit 0 if ($search_again =~ m/^quit$/i);
	exit 0 if ($search_again !~ m/^custom$/i);
}