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
#         project back to disk.  These include <NaturalDocs::Parser->ParseForInformation()> and <NaturalDocs::Menu->Save()>.
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
#   handle: FILEINFOFILEHANDLE
#
#   The file handle for the file information file, <FileInfo.nd>.
#


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
#   File: FileInfo.nd
#
#   An index of the state of the files as of the last parse.  Used to determine if files were added, deleted, or changed.
#
#   Format:
#
#       The beginning of the file is the version it was generated with.  Use the text file functions in <NaturalDocs::Version> to
#       deal with it.
#
#       The second line is the last modification time of <Menu.txt>.
#
#       Each following line is
#
#       > [file name] tab [last modification time] tab [has ND content boolean] tab [default menu title]
#
#       The file name is absolute.
#
#   Revisions:
#
#       1.16:
#
#           - File names are now absolute.  Prior to 1.16, they were relative to the input directory since only one was allowed.
#
#       1.14:
#
#           - The file was renamed from NaturalDocs.files to FileInfo.nd and moved into the Data subdirectory.
#
#       0.95:
#
#           - The file version was changed to match the program version.  Prior to 0.95, the version line was 1.  Test for "1" instead
#             of "1.0" to distinguish.
#


###############################################################################
# Group: Action Functions

#
#   Function: LoadAndDetectChanges
#
#   Loads the project file from disk and compares it against the files in the input directory.  Project is loaded from
#   <FileInfo.nd>.  New and changed files will be added to <FilesToParse()>, and if they have content,
#   <FilesToBuild()>.
#
#   Returns:
#
#       Returns whether the project was changed in any way.
#
sub LoadAndDetectChanges
    {
    my ($self) = @_;

    $self->GetAllSupportedFiles();

    my $fileIsOkay;
    my $rebuildOutput = NaturalDocs::Settings->RebuildOutput();

    my $hasChanged = $rebuildOutput;

    if (!NaturalDocs::Settings->RebuildData() && open(FILEINFOFILEHANDLE, '<' . $self->FileInfoFile()))
        {
        # Check if the file is in the right format.
        my $version = NaturalDocs::Version->FromTextFile(\*FILEINFOFILEHANDLE);

        # The output and the project file need to be rebuilt for 1.16.

        if ($version >= NaturalDocs::Version->FromString('1.16') && $version <= NaturalDocs::Settings->AppVersion())
            {
            $fileIsOkay = 1;
            }
        else
            {
            close(FILEINFOFILEHANDLE);
            $hasChanged = 1;
            };
        };


    if ($fileIsOkay)
        {
        my $line;
        my %indexedFiles;


        # Check if Menu.txt changed.

        $line = <FILEINFOFILEHANDLE>;

        if (! -e $self->MenuFile())
            {
            NaturalDocs::Menu->OnFileChange();
            $hasChanged = 1;
            }
        else
            {
            ::XChomp(\$line);

            if ((stat($self->MenuFile()))[9] != $line)
                {
                NaturalDocs::Menu->OnFileChange();
                $hasChanged = 1;
                };
            };


        # Parse the rest of the file.

        while ($line = <FILEINFOFILEHANDLE>)
            {
            ::XChomp(\$line);
            my ($file, $modification, $hasContent, $menuTitle) = split(/\t/, $line, 4);

            # If the file no longer exists...
            if (!exists $supportedFiles{$file})
                {
                if ($hasContent)
                    {  $filesToPurge{$file} = 1;  };

                $hasChanged = 1;
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

                    # If the file loses its content, this will be removed by SetHasContent().
                    if ($hasContent)
                        {  $filesToBuild{$file} = 1;  };

                    $hasChanged = 1;
                    }

                # If the file hasn't changed but we want to rebuild its output...
                elsif ($rebuildOutput && $hasContent)
                    {
                    $supportedFiles{$file}->SetStatus(::FILE_CHANGED());

                    # If the file loses its content, this will be removed by SetHasContent().
                    $filesToBuild{$file} = 1;
                    $hasChanged = 1;
                    }

                # If the file hasn't changed and we don't want to rebuild its output...
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

        close(FILEINFOFILEHANDLE);


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
                    $hasChanged = 1;
                    };
                };
            };
        }

    # If something's wrong with FileInfo.nd, everything is new.
    else
        {
        NaturalDocs::Menu->OnFileChange();

        foreach my $file (keys %supportedFiles)
            {
            $supportedFiles{$file}->SetStatus(::FILE_NEW());
            $supportedFiles{$file}->SetDefaultMenuTitle($file);
            $supportedFiles{$file}->SetHasContent(undef);
            $filesToParse{$file} = 1;
            # It will be added to filesToBuild if HasContent gets set to true when it's parsed.
            };

        $hasChanged = 1;
        };

    return $hasChanged;
    };


#
#   Function: Save
#
#   Saves the project file to disk.  Everything is saved in <FileInfo.nd>.  <NaturalDocs::Menu->Save()> should
#   be called prior to this function because its last modification time is saved here.
#
sub Save
    {
    my ($self) = @_;

    open(FILEINFOFILEHANDLE, '>' . $self->FileInfoFile())
        or die "Couldn't save project file " . $self->FileInfoFile() . "\n";

    NaturalDocs::Version->ToTextFile(\*FILEINFOFILEHANDLE, NaturalDocs::Settings->AppVersion());

    print FILEINFOFILEHANDLE '' . (stat($self->MenuFile()))[9] . "\n";

    while (my ($fileName, $file) = each %supportedFiles)
        {
        print FILEINFOFILEHANDLE $fileName . "\t"
                              . $file->LastModified() . "\t"
                              . ($file->HasContent() || '0') . "\t"
                              . $file->DefaultMenuTitle() . "\n";
        };

    close(FILEINFOFILEHANDLE);
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
    my ($self, $file) = @_;

    $filesToBuild{$file} = 1;

    if (exists $unbuiltFilesWithContent{$file})
        {  delete $unbuiltFilesWithContent{$file};  };
    };


#
#   Function: ReparseEverything
#
#   Adds all supported files to the list of files to parse.  This does not necessarily mean these files are going to be rebuilt.
#
sub ReparseEverything
    {
    my ($self) = @_;

    foreach my $file (keys %supportedFiles)
        {
        $filesToParse{$file} = 1;
        };
    };

#
#   Function: RebuildEverything
#
#   Adds all supported files to the list of files to build.  This does not necessarily mean these files are going to be reparsed.
#
sub RebuildEverything
    {
    my ($self) = @_;

    foreach my $file (keys %unbuiltFilesWithContent)
        {
        $filesToBuild{$file} = 1;
        };

    %unbuiltFilesWithContent = ( );
    };

#
#   Function: MigrateOldFiles
#
#   If the project uses the old file names used prior to 1.14, it converts them to the new file names.
#
sub MigrateOldFiles
    {
    my ($self) = @_;

    my $projectDirectory = NaturalDocs::Settings->ProjectDirectory();

    # We use the menu file as a test to see if we're using the new format.
    if (-e NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs_Menu.txt'))
        {
        # The Data subdirectory would have been created by NaturalDocs::Settings.

        rename( NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs_Menu.txt'), $self->MenuFile() );

        if (-e NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs.sym'))
            {  rename( NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs.sym'), $self->SymbolTableFile() );  };

        if (-e NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs.files'))
            {  rename( NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs.files'), $self->FileInfoFile() );  };

        if (-e NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs.m'))
            {  rename( NaturalDocs::File->JoinPaths($projectDirectory, 'NaturalDocs.m'), $self->PreviousMenuStateFile() );  };
        };
    };


###############################################################################
# Group: Information Functions

# Function: FileInfoFile
# Returns the full path to the file information file.
sub FileInfoFile
    {  return NaturalDocs::File->JoinPaths( NaturalDocs::Settings->ProjectDataDirectory(), 'FileInfo.nd' );  };

# Function: SymbolTableFile
# Returns the full path to the symbol table's data file.
sub SymbolTableFile
    {  return NaturalDocs::File->JoinPaths( NaturalDocs::Settings->ProjectDataDirectory(), 'SymbolTable.nd' );  };

# Function: MenuFile
# Returns the full path to the project's menu file.
sub MenuFile
    {  return NaturalDocs::File->JoinPaths( NaturalDocs::Settings->ProjectDirectory(), 'Menu.txt' );  };

# Function: SettingsFile
# Returns the full path to the project's settings file.
sub SettingsFile
    {  return NaturalDocs::File->JoinPaths( NaturalDocs::Settings->ProjectDirectory(), 'Settings.txt' );  };

# Function: PreviousMenuStateFile
# Returns the full path to the project's previous menu state file.
sub PreviousMenuStateFile
    {  return NaturalDocs::File->JoinPaths( NaturalDocs::Settings->ProjectDataDirectory(), 'PreviousMenuState.nd' );  };

# Function: MenuBackupFile
# Returns the full path to the project's menu backup file, which is used to save the original menu in some situations.
sub MenuBackupFile
    {  return NaturalDocs::File->JoinPaths( NaturalDocs::Settings->ProjectDirectory(), 'Menu_Backup.txt' );  };

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
    my ($self, $file) = @_;

    if (exists $supportedFiles{$file})
        {  return $supportedFiles{$file}->HasContent();  }
    else
        {  return undef;  };
    };

#
#   Function: StatusOf
#
#   Returns the status of the passed file.  Will be one of the <File Status Constants>.
#
sub StatusOf #(file)
    {
    my ($self, $file) = @_;

    if (exists $supportedFiles{$file})
        {  return $supportedFiles{$file}->Status();  }
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
    my ($self, $file) = @_;

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
    my ($self, $file, $hasContent) = @_;

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
    my ($self, $file, $menuTitle) = @_;

    if (exists $supportedFiles{$file} && $supportedFiles{$file}->DefaultMenuTitle() ne $menuTitle)
        {
        $supportedFiles{$file}->SetDefaultMenuTitle($menuTitle);
        NaturalDocs::Menu->OnDefaultTitleChange($file);
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
sub GetAllSupportedFiles
    {
    my ($self) = @_;

    my @directories = @{NaturalDocs::Settings->InputDirectories()};
    my $menuFile = $self->MenuFile();
    my $menuBackup = $self->MenuBackupFile();

    while (scalar @directories)
        {
        my $directory = pop @directories;

        opendir DIRECTORYHANDLE, $directory;
        my @entries = readdir DIRECTORYHANDLE;
        closedir DIRECTORYHANDLE;

        @entries = NaturalDocs::File->NoUpwards(@entries);

        foreach my $entry (@entries)
            {
            my $fullEntry = NaturalDocs::File->JoinPaths($directory, $entry);

            # If an entry is a directory, recurse.
            if (-d $fullEntry)
                {
                # Join again with the noFile flag set in case the platform handles them differently.
                push @directories, NaturalDocs::File->JoinPaths($directory, $entry, 1);
                }

            # Otherwise add it if it's a supported extension.  We need to explicitly ignore the menu files because they're text files and
            # their syntax is similar to Natural Docs content.
            else
                {
                if (NaturalDocs::Languages->IsSupported($fullEntry) && $fullEntry ne $menuFile && $fullEntry ne $menuBackup)
                    {
                    $supportedFiles{$fullEntry} = NaturalDocs::Project::File->New(undef, (stat($fullEntry))[9], undef, undef);
                    };
                };
            };
        };
    };


1;
