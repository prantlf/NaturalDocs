###############################################################################
#
#   Package: NaturalDocs::Builder
#
###############################################################################
#
#   A package that takes parsed source file and builds the output for it.
#
#   Usage and Dependencies:
#
#       - <Add()> can be called immediately.
#       - <OutputPackages()> can be called once all sub-packages have been registered via <Add()>.  Since this is normally done
#         in their INIT functions, <OutputPackages()> should be available to all normal functions immediately.
#
#       - Prior to calling <Run()>, <NaturalDocs::Settings>, <NaturalDocs::Project>, and <NaturalDocs::Menu> must be initialized.
#         If files need to be built (i.e. <NaturalDocs::Project::FilesToBuild()> returns something) <NaturalDocs::Parser> must be
#         initialized and <NaturalDocs::SymbolTable> must be initialized and fully resolved.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL


use strict;
use integer;

package NaturalDocs::Builder;


###############################################################################
# Group: Variables

#
#   Array: outputPackages
#
#   An array of the output packages available for use.
#
my @outputPackages;


###############################################################################
# Group: Functions


#
#   Function: OutputPackages
#
#   Returns an arrayref of the output packages available for use.  The arrayref is not a copy of the data, so don't change it.
#
#   Add output packages to this list with the <Add()> function.
#
sub OutputPackages
    {
    return \@outputPackages;
    };



#
#   Function: Add
#
#   Adds an output package to those available for use.  All output packages must call this function in order to be recognized.
#
#   Parameters:
#
#       package - The package name.
#
sub Add #(package)
    {
    my $package = shift;

    # Output packages shouldn't register themselves more than once, so we don't need to check for it.
    push @outputPackages, $package;
    };


#
#   Function: Run
#
#   Runs the build process.  This must be called *every time* Natural Docs is run, regardless of whether any source files changed
#   or not.  Some output packages have dependencies on files outside of the source tree that need to be checked.
#
#   Since there are multiple stages to the build process, this function will handle its own status messages.  There's no need to print
#   "Building files..." or something similar beforehand.
#
sub Run
    {
    # Determine what we're doing.

    my @outputFormats = keys %{NaturalDocs::Settings::OutputFormats()};
    my $filesToBuild = NaturalDocs::Project::FilesToBuild();

    my $numberToPurge = scalar keys %{NaturalDocs::Project::FilesToPurge()};
    my $numberToBuild = scalar keys %$filesToBuild;

    my %indexesToBuild;
    my %indexesToPurge;

    my $currentIndexes = NaturalDocs::Menu::Indexes();
    my $previousIndexes = NaturalDocs::Menu::PreviousIndexes();

    foreach my $index (keys %$currentIndexes)
        {
        if (NaturalDocs::Settings::RebuildAll() || NaturalDocs::SymbolTable::IndexChanged($index eq '*' ? undef : $index) ||
            !exists $previousIndexes->{$index})
            {
            $indexesToBuild{$index} = 1;
            };
        };

    # All indexes that still exist should have been deleted.
    foreach my $index (keys %$previousIndexes)
        {
        if (!exists $currentIndexes->{$index})
            {
            $indexesToPurge{$index} = 1;
            };
        };

    my $numberOfIndexesToBuild = scalar keys %indexesToBuild;
    my $numberOfIndexesToPurge = scalar keys %indexesToPurge;


    # Start the build process

    foreach my $format (@outputFormats)
        {
        $format->BeginBuild($numberToPurge || $numberToBuild || $numberOfIndexesToBuild || $numberOfIndexesToPurge ||
                                       NaturalDocs::Menu::HasChanged());
        };

    if ($numberToPurge)
        {
        if (!NaturalDocs::Settings::IsQuiet())
            {  print 'Purging ' . $numberToPurge . ' file' . ($numberToPurge > 1 ? 's' : '') . "...\n";  };

        foreach my $format (@outputFormats)
            {  $format->PurgeFiles();  };
        };

    if ($numberOfIndexesToPurge)
        {
        if (!NaturalDocs::Settings::IsQuiet())
            {  print 'Purging ' . $numberOfIndexesToPurge . ' index' . ($numberOfIndexesToPurge > 1 ? 'es' : '') . "...\n";  };

        foreach my $format (@outputFormats)
            {  $format->PurgeIndexes(\%indexesToPurge);  };
        };

    if ($numberToBuild)
        {
        if (!NaturalDocs::Settings::IsQuiet())
            {  print 'Building ' . $numberToBuild . ' file' . ($numberToBuild > 1 ? 's' : '') . "...\n";  };

        foreach my $file (keys %$filesToBuild)
            {
            my $parsedFile = NaturalDocs::Parser::ParseForBuild($file);

            foreach my $format (@outputFormats)
                {  $format->BuildFile($file, $parsedFile);  };
            };
        };

    if ($numberOfIndexesToBuild)
        {
        if (!NaturalDocs::Settings::IsQuiet())
            {  print 'Building ' . $numberOfIndexesToBuild . ' index' . ($numberOfIndexesToBuild != 1 ? 'es' : '') . "...\n";  };

        foreach my $index (keys %indexesToBuild)
            {
            foreach my $format (@outputFormats)
                {  $format->BuildIndex($index eq '*' ? undef : $index);  };
            };
        };

    if (NaturalDocs::Menu::HasChanged())
        {
        if (!NaturalDocs::Settings::IsQuiet())
            {  print "Updating menu...\n";  };

        foreach my $format (@outputFormats)
            {  $format->UpdateMenu();  };
        };

    foreach my $format (@outputFormats)
        {
        $format->EndBuild($numberToPurge || $numberToBuild || $numberOfIndexesToBuild || $numberOfIndexesToPurge ||
                                       NaturalDocs::Menu::HasChanged());
        };
    };


1;