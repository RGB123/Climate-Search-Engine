#------------------------------------------------------------------------------
# CLIMATE SEARCH ENGINE
# 
# Author: Richard Bekeris
# GitHub Repository: https://github.com/RGB123/Climate-Search-Engine
# Last Modified: 12 Feb 2018
# Optimized for: ActivePerl 5.22.4
#
# INSTALLATION
# ------------
#
# 1. Download/Install ActivePerl Community Edition 5.22.4: https://www.activestate.com/activeperl/downloads
#    (make sure to enable the option for associating '.pl' extension with Perl files, 
#     so you can execute the script directly)
#
# 2. Download/Install GD::Simple from CPAN: http://search.cpan.org/~lds/GD-2.49/GD/Simple.pm
#    (easy way: type 'ppm install GD::Simple' at the command line once Step 1 is completed)
#
# 3. Create a new directory, and download/save the following resources to it:
#    * climatesearchengine.pl
#    * cse_output.pl
#    * climatedataworld-stats.csv
#    * equi-world-map.jpg
#    * Readme.txt
#
# EXECUTION
# ---------
#
# Initiate the 'climatesearchengine.pl' script by double-clicking it, or by
# running it from the command line (CMD.exe).
#
# This program has not been tested on systems other than Windows 10, 
# and makes use of Windows-specific system calls.
#
# DESCRIPTION
# -----------
#
# This program contains 5 modules:
# 1. STARTUP
# 2. RECORD LOOKUP
# 3. DEFAULT SEARCH
# 4. CUSTOM SEARCH
# 5. OUTPUT GENERATOR
#
# 1. STARTUP: Opens CSV file, parses and stores climate data in memory,
# and returns average/standard deviation for each category.
#
# 2. RECORD LOOKUP: Allows user to search climate data records, check for any
# missing/erroneous data.
#
# 3. DEFAULT SEARCH: Allows user to specify a city name, and search engine will
# attempt to find a unique match. If found, the engine will calculate a
# ranked list of cities whose climate is most similar to the search input. The 
# user can then generate a PNG map displaying the locations of the top 10 
# results (this is performed by CSE Output Generator program).
#
# 4. CUSTOM SEARCH: Allows user to specify their own search criteria for the 
# various climate data categories (temperature, rainfall, humidity, etc.)
# and assign weights to each category. The search engine will then calculate
# a ranked list of cities whose climate is most similar to the search input.
# Note: Map-generating capabilities have not been added to this module yet.
#
# 5. OUTPUT GENERATOR: This is a separate script (cse_output.pl) that is invoked
# when the user chooses to map their search results in the main program
# (climatesearchengine.pl). It uses GD::Simple to open the world map JPEG file 
# (equi-world-map.jpg), draws the locations of the search results, saves the 
# output as a PNG file, and displays it on the screen. Control is reverted back
# to the main script after this.
#
# CUSTOM DATA FILES
# -----------------
#
# Although a CSV data file is provided (climatedataworld-stats.csv), you may
# choose to provide your own custom data source. This can be accomplished as
# long as you keep the following in mind:
#
# 1. Only CSV files are compatible.
#
# 2. To get the Climate Search Engine to use your data file, run it from
#    the command line, and pass in the CSV file name as an argument.
#
# 3. The CSV file must include a header line with the following categories,
#    and data entries must adhere to the metric/SI units provided:
#    a. Name
#    b. Population (k)
#    c. Elevation (m)
#    d. Average Annual Temperature (C)
#    e. Highest Average Monthly High Temperature (C)
#    f. Lowest Average Monthly Low Temperature (C)
#    g. Average Annual Rainfall (cm)
#    h. Average Annual Snowfall (cm)
#    i. Average Annual Relative Humidity (%)
#    j. Average Annual Windspeed (kmh)
#    k. Continent/Region
#    l. Latitude (+/-)
#    m. Longitude (+/-)
#
# SOURCES & DEPENDENCIES
# ----------------------
#
# I do not take credit for the data gathered or generated through use of this program. All rights
# reserved for the respective owners:
#
# Climate Data Sources: Weatherbase.com, Weatherspark.com, Wikipedia.org
# World Map Source: https://upload.wikimedia.org/wikipedia/commons/8/83/Equirectangular_projection_SW.jpg
# Dependencies: ActivePerl Community Edition, GD::Simple, Windows OS
#
# LICENSING
# ---------
#
# No license added for the time being. All Rights Reserved to Author (Richard Bekeris). 
# Commercial/Private use or modification without the Author's consent is prohibited.
#