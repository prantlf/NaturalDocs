###############################################################################
#
#   Package: NaturalDocs::Project
#
###############################################################################
#
#   A package that manages information about the files in the source tree, as well as the list of files that have to be parsed
#   and built.
#
#   Usage and Dependencies:
#
#       - Prior to initialization, <NaturalDocs::Settings> and <NaturalDocs::Languages> must be initialized and
#        <NaturalDocs::Menu>'s event handlers must be available.
#
#       - To initialize, call <LoadAndDetectChanges()>.  All other functions will then be available.
#
#       - All operations that can change project file information or the files themselves must be performed before saving the
#         project back to disk.  These include <NaturalDocs::Parser::ParseForInformation()> and <NaturalDocs::Menu::Save()>.
#
#       - To save the changes to disk, call <Save()>.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use NaturalDocs::Project::File;

use strict;
use integer;

package NaturalDocs::Project;


###############################################################################
# Group: Variables

#
#   hash: supportedFiles
#
#   A hash of all the supported files in the input directory.  The keys are the file names, and the values are
#   <NaturalDocs::Project::File> objects.
#
my %supportedFiles;

#
#   hash: filesToParse
#
#   An existence hash of all the files that need to be parsed.
#
my %filesToParse;

#
#   hash: filesToBuild
#
#   An existence hash of all the files that need to be built.
#
my %filesToBuild;

#
#   hash: filesToPurge
#
#   An existence hash of files that had Natural Docs content last time, but now either don't exist or no longer have content.
#
my %filesToPurge;

#
#   hash: unbuiltFilesWithContent
#
#   An existence hashref of all the files that have Natural Docs content but are not part of <filesToBuild>.
#
my %unbuiltFilesWithContent;


###############################################################################
# Group: Files

#
#   File: NaturalDocs.files
#
#   An index of the state of the files as of the last parse.  Used to determine if files were added, deleted, or changed.
#
#   Format:
#
#       The first line is <NaturalDocs::Settings::AppVersion()>.
#
#       The second line is the last modification time of <NaturalDocs_Menu.txt>.
#
#       Each following line is [file name]\t[last modification time]\t[has ND content boolean]\t[default menu title].
#


###############################################################################
# Group: Action Functions

#
#   Function: LoadAndDetectChanges
#
#   Loads the project file from disk and compares it against the files in the input directory.  Project is loaded from
#   <NaturalDocs.files>.  New and changed files will be added to <FilesToParse()>, and if they have content,
#   <FilesToBuild()>.
#
#   Returns:
#
#       Returns whether the project was changed in any way.
#
sub LoadAndDetectChanges
    {
    GetAllSupportedFiles();

    my $indexFile;
    my $fileIsOkay;

    if (!NaturalDocs::Settings::RebuildAll() && open($indexFile, '<' . ProjectFile()))
        {
        # Check if the file is in the right format.
        my $version = <$indexFile>;
        chomp($version);

        # Currently, the file format hasn't changed in public releases, so anything <= the current version is fine.
        # If the version is "1" with no ".x", that means 0.91 and prior because we were using a separate FileVersion() function then.

        if ($version <= NaturalDocs::Settings::AppVersion() || $version eq '1')
            {  $fileIsOkay = 1;  }
        else
            {  close($indexFile);  };
        };


    if ($fileIsOkay)
        {
        my $line;
        my %indexedFiles;


        # Check if NaturalDocs_Menu.txt changed.

        $line = <$indexFile>;

        if (! -e MenuFile())
            {  NaturalDocs::Menu::OnFileChange();  }
        else
            {
            chomp($line);

            if ((stat(MenuFile()))[9] != $line)
                {  NaturalDocs::Menu::OnFileChange();  };
            };


        # Parse the rest of the file.

        while ($line = <$indexFile>)
            {
            chomp($line);
            my ($file, $modification, $hasContent, $menuTitle) = split(/\t/, $line, 4);

            # If the file no longer exists...
            if (!exists $supportedFiles{$file})
                {
                if ($hasContent)
                    {  $filesToPurge{$file} = 1;  };
                }

            # If the file still exists...
            else
                {
                $indexedFiles{$file} = 1;

                # If the file changed...
                if ($supportedFiles{$file}->LastModified() != $modification)
                    {
                    $supportedFiles{$file}->SetStatus(::FILE_CHANGED());
                    $filesToParse{$file} = 1;

                    if ($hasContent)
                        {  $filesToBuild{$file} = 1;  };
                    }

                # If the file hasn't changed...
                else
                    {
                    $supportedFiles{$file}->SetStatus(::FILE_SAME());

                    if ($hasContent)
                        {  $unbuiltFilesWithContent{$file} = 1;  };
                    };

                $supportedFiles{$file}->SetHasContent($hasContent);
                $supportedFiles{$file}->SetDefaultMenuTitle($menuTitle);
                };
            };

        close($indexFile);


        # Check for added files.

        if (scalar keys %supportedFiles > scalar keys %indexedFiles)
            {
            foreach my $file (keys %supportedFiles)
                {
                if (!exists $indexedFiles{$file})
                    {
                    $supportedFiles{$file}->SetStatus(::FILE_NEW());
                    $supportedFiles{$file}->SetDefaultMenuTitle($file);
                    $supportedFiles{$file}->SetHasContent(undef);
                    $filesToParse{$file} = 1;
                    # It will be added to filesToBuild if HasContent gets set to true when it's parsed.
                    };
                };
            };
        }

    # If something's wrong with NaturalDocs.files, everything is new.
    else
        {
        NaturalDocs::Menu::OnFileChange();

        foreach my $file (keys %supportedFiles)
            {
            $supportedFiles{$file}->SetStatus(::FILE_NEW());
            $supportedFiles{$file}->SetDefaultMenuTitle($file);
            $supportedFiles{$file}->SetHasContent(undef);
            $filesToParse{$file} = 1;
            # It will be added to filesToBuild if HasContent gets set to true when it's parsed.
            };
        };

    return (scalar keys %filesToParse != 0 || NaturalDocs::Menu::HasChanged() || scalar keys %filesToPurge != 0);
    };


#
#   Function: Save
#
#   Saves the project file to disk.  Everything is saved in <NaturalDocs.files>.  <NaturalDocs::Menu::Save()> should
#   be called prior to this function because its last modification time is saved here.
#
sub Save
    {
    my $indexFile;
    open($indexFile, '>' . ProjectFile())
        or die "Couldn't save project file " . ProjectFile() . "\n";

    print $indexFile '' . NaturalDocs::Settings::AppVersion() . "\n"
                             . (stat(MenuFile()))[9] . "\n";

    while (my ($fileName, $file) = each %supportedFiles)
        {
        print $indexFile $fileName . "\t"
                              . $file->LastModified() . "\t"
                              . ($file->HasContent() || '0') . "\t"
                              . $file->DefaultMenuTitle() . "\n";
        };

    close($indexFile);
    };


#
#   Function: RebuildFile
#
#   Adds the file to the list of files to build.  Assumes the file contains Natural Docs content.
#
#   Parameters:
#
#       file - The name of the file to build or rebuild.
#
sub RebuildFile #(file)
    {
    my $file = shift;

    $filesToBuild{$file} = 1;

    if (exists $unbuiltFilesWithContent{$file})
        {  delete $unbuiltFilesWithContent{$file};  };
    };


#
#   Function: ReparseEverything
#
#   Adds all supported files to the list of files to parse.
#
sub ReparseEverything
    {
    foreach my $file (keys %supportedFiles)
        {
        $filesToParse{$file} = 1;
        };
    };


###############################################################################
# Group: Information Functions

# Function: ProjectFile
# Returns the full path to the project's data file.
sub ProjectFile
    {  return NaturalDocs::File::JoinPath( NaturalDocs::Settings::ProjectDirectory(), 'NaturalDocs.files' );  };

# Function: SymbolTableFile
# Returns the full path to the symbol table's data file.
sub SymbolTableFile
    {  return NaturalDocs::File::JoinPath( NaturalDocs::Settings::ProjectDirectory(), 'NaturalDocs.sym' );  };

# Function: MenuFile
# Returns the full path to the project's menu file.
sub MenuFile
    {  return NaturalDocs::File::JoinPath( NaturalDocs::Settings::ProjectDirectory(), 'NaturalDocs_Menu.txt' );  };

# Function: PreviousMenuStateFile
# Returns the full path to the project's previous menu state file.
sub PreviousMenuStateFile
    {  return NaturalDocs::File::JoinPath( NaturalDocs::Settings::ProjectDirectory(), 'NaturalDocs.m' );  };

# Function: MenuBackupFile
# Returns the full path to the project's menu backup file, which is used to save the original menu in some situations.
sub MenuBackupFile
    {  return NaturalDocs::File::JoinPath( NaturalDocs::Settings::ProjectDirectory(), 'NaturalDocs_MenuBackup.txt' );  };

# Function: FilesToParse
# Returns an existence hashref of the list of files to parse.  This is not a copy of the data, so don't change it.
sub FilesToParse
    {  return \%filesToParse;  };

# Function: FilesToBuild
# Returns an existence hashref of the list of files to build.  This is not a copy of the data, so don't change it.
sub FilesToBuild
    {  return \%filesToBuild;  };

# Function: FilesToPurge
# Returns an existence hashref of the list of files that had content last time, but now either don't anymore or were deleted.
# This is not a copy of the data, so don't change it.
sub FilesToPurge
    {  return \%filesToPurge;  };

# Function: UnbuiltFilesWithContent
# Returns an existence hashref of files that have Natural Docs content but are not part of <FilesToBuild()>.  This is not a copy of
# the data so don't change it.
sub UnbuiltFilesWithContent
    {  return \%unbuiltFilesWithContent;  };

# Function: FilesWithContent
# Returns and existence hashref of the files that have Natural Docs content.
sub FilesWithContent
    {
    # Don't keep this one internally, but there's an easy way to make it.
    return { %filesToBuild, %unbuiltFilesWithContent };
    };


#
#   Function: HasContent
#
#   Returns whether the file contains Natural Docs content.
#
sub HasContent #(file)
    {
    my $file = shift;

    if (exists $supportedFiles{$file})
        {  return $supportedFiles{$file}->HasContent();  }
    else
        {  return undef;  };
    };

#
#   Function: StatusOf
#
#   Returns the status of the passed file.  Will be onen of the <File Status Constants>.
#
sub StatusOf #(file)
    {
    my $file = shift;

    if (exists $supportedFiles{$file})
        {  return $supportedFiles{$file}->HasContent();  }
    else
        {  return ::FILE_DOESNTEXIST();  };
    };

#
#   Function: DefaultMenuTitleOf
#
#   Returns the default menu title of the file.  If one isn't specified, it returns the file name.
#
#   Parameters:
#
#       file - The name of the file.
#
sub DefaultMenuTitleOf #(file)
    {
    my $file = shift;

    if (exists $supportedFiles{$file})
        {  return $supportedFiles{$file}->DefaultMenuTitle();  }
    else
        {  return $file;  };
    };


#
#   Function: SetHasContent
#
#   Sets whether the file has Natural Docs content or not.
#
#   Parameters:
#
#       file - The file being modified.
#       hasContent - Whether the file now has Natural Docs content or not.
#
sub SetHasContent #(file, hasContent)
    {
    my $file = shift;
    my $hasContent = shift;

    if (exists $supportedFiles{$file} && $supportedFiles{$file}->HasContent() != $hasContent)
        {
        # If the file now has content...
        if ($hasContent)
            {
            $filesToBuild{$file} = 1;
            }

        # If the file's content has been removed...
        else
            {
            delete $filesToBuild{$file};  # may not be there
            $filesToPurge{$file} = 1;
            };

        $supportedFiles{$file}->SetHasContent($hasContent);
        };
    };

#
#   Function: SetDefaultMenuTitle
#
#   Sets the file's default menu title.
#
#   Parameters:
#
#       file - The file which is having its title changed.
#       menuTitle - The new menu title.
#
sub SetDefaultMenuTitle #(file, menuTitle)
    {
    my $file = shift;
    my $menuTitle = shift;

    if (exists $supportedFiles{$file} && $supportedFiles{$file}->DefaultMenuTitle() ne $menuTitle)
        {
        $supportedFiles{$file}->SetDefaultMenuTitle($menuTitle);
        NaturalDocs::Menu::OnDefaultTitleChange($file, $menuTitle);
        };
    };


###############################################################################
# Group: Support Functions

#
#   Function: GetAllSupportedFiles
#
#   Gets all the supported files in the passed directory and its subdirectories and puts them into <supportedFiles>.  The only
#   attribute that will be set is <NaturalDocs::Project::File->LastModified()>.
#
#   Parameters:
#
#       directory  - This is for the function's own recursive use only.  Do not specify.
#
sub GetAllSupportedFiles #(directory)
    {
    my $directory = shift;

    if (!defined $directory)
        {  $directory = NaturalDocs::Settings::InputDirectory();  };


    # We need to ignore the menu file if we're at the project directory.

    my $menuFile;

    if ($directory eq NaturalDocs::Settings::ProjectDirectory())
        {  $menuFile = MenuFile();  };


    my $directoryHandle;

    opendir $directoryHandle, $directory;
    my @entries = readdir $directoryHandle;
    closedir $directoryHandle;

    @entries = NaturalDocs::File::NoUpwards(@entries);

    foreach my $entry (@entries)
        {
        my $fullEntry = NaturalDocs::File::JoinPath($directory, $entry);

        # If an entry is a directory, recurse.
        if (-d $fullEntry)
            {
            # Join again with the noFile flag set in case the platform handles them differently.
            GetAllSupportedFiles( NaturalDocs::File::JoinPath($directory, $entry, 1) );
            }

        # Otherwise add it if it's a supported extension.  We need to explicitly ignore the menu files because they're text files and
        # their syntax is similar to Natural Docs content.
        else
            {
            my $relativeName = NaturalDocs::File::MakeRelativePath(NaturalDocs::Settings::InputDirectory(), $fullEntry);

            if (NaturalDocs::Languages::IsSupported($relativeName) &&
                 (!defined $menuFile || $fullEntry ne $menuFile) )
                {
                $supportedFiles{$relativeName} = NaturalDocs::Project::File::New(undef, (stat($fullEntry))[9], undef, undef);
                };
            };
        };
    };


1;