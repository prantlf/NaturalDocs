###############################################################################
#
#   Package: NaturalDocs::ClassHierarchy
#
###############################################################################
#
#   A package that handles all the gory details of managing the class hierarchy.  It handles the hierarchy itself, which files define
#   them, rebuilding the files that are affected by changes, and loading and saving them to a file.
#
#   Usage and Dependencies:
#
#       - <NaturalDocs::Settings> and <NaturalDocs::Project> must be initialized before use.
#
#       - <NaturalDocs::SymbolTable> must be initialized before <Load()> is called.  It must reflect the state as of the last time
#          Natural Docs was run.
#
#       - <Load()> must be called to initialize the package.  At this point, the <Information Functions> will return the state as
#         of the last time Natural Docs was run.  You are free to resolve <NaturalDocs::SymbolTable()> afterwards.
#
#       - <Purge()> must be called, and then <NaturalDocs::Parser->ParseForInformation()> must be called on all files that
#         have changed so it can fully resolve the hierarchy via the <Modification Functions()>.  Afterwards the
#         <Information Functions> will reflect the current state of the code.
#
#       - <Save()> must be called to commit any changes to the symbol table back to disk.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL


use strict;
use integer;

use NaturalDocs::ClassHierarchy::Class;
use NaturalDocs::ClassHierarchy::File;

package NaturalDocs::ClassHierarchy;


###############################################################################
# Group: Variables

#
#   handle: CLASS_HIERARCHY_FILEHANDLE
#   The file handle used with <ClassHierarchy.nd>.
#

#
#   hash: classes
#
#   A hash of all the classes.  The keys are the class names, and the values are <NaturalDocs::ClassHierarchy::Classes>.
#
my %classes;

#
#   hash: files
#
#   A hash of the hierarchy information referenced by file.  The keys are the file names, and the values are
#   <NaturalDocs::ClassHierarchy::Files>.
#
my %files;

#   object: watchedFile
#
#   A <NaturalDocs::ClassHierarchy::File> object of the file being watched for changes.  This is compared to the version in <files>
#   to see if anything was changed since the last parse.
#
my $watchedFile;

#
#   string: watchedFileName
#
#   The file name of the watched file, if any.  If there is no watched file, this will be undef.
#
my $watchedFileName;



###############################################################################
# Group: Files


#
#   File: ClassHierarchy.nd
#
#   Stores the class hierarchy on disk.
#
#   Format:
#
#       > [BINARY_FORMAT]
#
#       The firs byte is the <BINARY_FORMAT> constant.
#
#       > [app version]
#
#       Next is the binary application version it was generated with.  Manage with <NaturalDocs::Version>.
#
#       > [AString16: class]
#
#       Next we begin a class segment.  These continue until the end of the file.  The class segment starts of with the class' name.
#
#       > [UInt32: number of files]
#       > [AString16: file] ...
#
#       Next there is the number of files that define that class.  It's a UInt32, which seems like overkill, but I could imagine every
#       file in a huge C++ project being under the same namespace, and thus contributing its own definition.  It's theoretically
#       possible.
#
#       Following the number is that many file names.  You must remember the index of each file, as they will be important later.
#       Indexes start at one.
#
#       > [UInt8: number of parents]
#       > ( [AString16: parent] [UInt32: file index] ... [UInt32: 0] ) ...
#
#       Next there is the number of parents defined for this class.  For each one, we define a parent segment, which consists of
#       its name, and then a zero-terminated string of indexes of the files that define that parent as part of that class.  The indexes
#       start at one, and are into the list of files we saw previously.
#
#       Note that we do store class segments for classes without parents, but not for undefined classes.
#
#       This concludes a class segment.  These segments continue until the end of the file.
#
#   Revisions:
#
#       1.2:
#
#           - This file was introduced in 1.2.
#


###############################################################################
# Group: File Functions


#
#   Function: Load
#
#   Loads the class hierarchy from disk.
#
sub Load
    {
    my ($self) = @_;

    my $fileIsOkay = 1;
    my $fileName = NaturalDocs::Project->ClassHierarchyFile();

    if (NaturalDocs::Settings->RebuildData() || !open(CLASS_HIERARCHY_FILEHANDLE, '<' . $fileName))
        {  $fileIsOkay = undef;  }
    else
        {
        # See if it's binary.
        binmode(CLASS_HIERARCHY_FILEHANDLE);

        my $firstChar;
        read(CLASS_HIERARCHY_FILEHANDLE, $firstChar, 1);

        if ($firstChar != ::BINARY_FORMAT())
            {
            close(CLASS_HIERARCHY_FILEHANDLE);
            $fileIsOkay = undef;
            }
        else
            {
            my $version = NaturalDocs::Version->FromBinaryFile(\*CLASS_HIERARCHY_FILEHANDLE);

            # The file format has not changed since it was introduced.

            if ($version > NaturalDocs::Settings->AppVersion())
                {
                close(CLASS_HIERARCHY_FILEHANDLE);
                $fileIsOkay = undef;
                };
            };
        };


    if (!$fileIsOkay)
        {
        NaturalDocs::Project->ReparseEverything();
        }
    else
        {
        my $raw;

        # [AString16: class]

        while (read(CLASS_HIERARCHY_FILEHANDLE, $raw, 2))
            {
            my $classLength = unpack('n', $raw);

            my $class;
            read(CLASS_HIERARCHY_FILEHANDLE, $class, $classLength);

            # [UInt32: number of files]

            read(CLASS_HIERARCHY_FILEHANDLE, $raw, 4);
            my $numberOfFiles = unpack('N', $raw);

            my @files;

            while ($numberOfFiles)
                {
                # [AString16: file]

                read(CLASS_HIERARCHY_FILEHANDLE, $raw, 2);
                my $fileLength = unpack('n', $raw);

                my $file;
                read(CLASS_HIERARCHY_FILEHANDLE, $file, $fileLength);

                push @files, $file;
                $self->AddClass($file, $class);

                $numberOfFiles--;
                };

            # [UInt8: number of parents]

            read(CLASS_HIERARCHY_FILEHANDLE, $raw, 1);
            my $numberOfParents = unpack('C', $raw);

            while ($numberOfParents)
                {
                # [AString16: parent]

                read(CLASS_HIERARCHY_FILEHANDLE, $raw, 2);
                my $parentLength = unpack('n', $raw);

                my $parent;
                read(CLASS_HIERARCHY_FILEHANDLE, $parent, $parentLength);

                for (;;)
                    {
                    # [UInt32: file index or 0]

                    read(CLASS_HIERARCHY_FILEHANDLE, $raw, 4);
                    my $fileIndex = unpack('N', $raw);

                    if ($fileIndex == 0)
                        {  last;  }

                    $self->AddParent( $files[$fileIndex - 1], $class, $parent, 1 );
                    };

                $numberOfParents--;
                };
            };

        close(CLASS_HIERARCHY_FILEHANDLE);
        };
    };


#
#   Function: Save
#
#   Saves the class hierarchy to disk.
#
sub Save
    {
    my ($self) = @_;

    open (CLASS_HIERARCHY_FILEHANDLE, '>' . NaturalDocs::Project->ClassHierarchyFile())
        or die "Couldn't save " . NaturalDocs::Project->ClassHierarchyFile() . ".\n";

    binmode(CLASS_HIERARCHY_FILEHANDLE);

    print CLASS_HIERARCHY_FILEHANDLE '' . ::BINARY_FORMAT();
    NaturalDocs::Version->ToBinaryFile(\*CLASS_HIERARCHY_FILEHANDLE, NaturalDocs::Settings->AppVersion());

    while (my ($class, $classObject) = each %classes)
        {
        if ($classObject->IsDefined())
            {
            # [AString16: class]
            # [UInt32: number of files]

            my @definitions = $classObject->Definitions();
            my %definitionIndexes;

            print CLASS_HIERARCHY_FILEHANDLE pack('nA*N', length($class), $class, scalar @definitions);

            for (my $i = 0; $i < scalar @definitions; $i++)
                {
                # [AString16: file]
                print CLASS_HIERARCHY_FILEHANDLE pack('nA*', length($definitions[$i]), $definitions[$i]);
                $definitionIndexes{$definitions[$i]} = $i + 1;
                };

            # [UInt8: number of parents]

            my @parents = $classObject->Parents();
            print CLASS_HIERARCHY_FILEHANDLE pack('C', scalar @parents);

            foreach my $parent (@parents)
                {
                # [AString16: parent]
                print CLASS_HIERARCHY_FILEHANDLE pack('nA*', length($parent), $parent);

                # [UInt32: file index]

                my @parentDefinitions = $classObject->ParentDefinitions($parent);

                foreach my $parentDefinition (@parentDefinitions)
                    {
                    print CLASS_HIERARCHY_FILEHANDLE pack('N', $definitionIndexes{$parentDefinition});
                    };

                # [UInt32: 0]
                print CLASS_HIERARCHY_FILEHANDLE pack('N', 0);
                };
            };
        };

    close(CLASS_HIERARCHY_FILEHANDLE);
    };


#
#   Function: Purge
#
#   Purges the hierarchy of files that no longer have Natural Docs content.
#
sub Purge
    {
    my ($self) = @_;

    my $filesToPurge = NaturalDocs::Project->FilesToPurge();

    foreach my $file (keys %$filesToPurge)
        {
        $self->DeleteFile($file);
        };
    };


###############################################################################
# Group: Modification Functions


#
#   Function: AddClass
#
#   Adds a class to the hierarchy.
#
#   Parameters:
#
#       file - The file the class was defined in.
#       class - The class name.
#
sub AddClass #(file, class)
    {
    my ($self, $file, $class) = @_;

    if (!exists $files{$file})
        {  $files{$file} = NaturalDocs::ClassHierarchy::File->New();  };

    $files{$file}->AddClass($class);

    if (!exists $classes{$class})
        {  $classes{$class} = NaturalDocs::ClassHierarchy::Class->New();  };

    $classes{$class}->AddDefinition($file);

    # Note that we don't need to rebuild the file if this is the first definition of a class that was already someone's parent.  The
    # SymbolTable reference will be fulfilled instead, which will do everything for us.
    };


#
#   Function: AddParent
#
#   Adds a class-parent relationship to the hierarchy.  Unless dontRebuild is set, this will put any files whose hierarchy output will
#   change on the build list.  This also adds a reference in <NaturalDocs::SymbolTable> between the files so that if the summary
#   or definition of one class changes, both files will be affected.
#
#   Parameters:
#
#       file - The file the class was defined in.
#       class - The class name.
#       parent - The parent class name.
#       dontRebuild - If this flag is set, files will not be rebuilt when changes occur.  This is mainly for use by <Load()>, you
#                           probably should never set it externally.
#
sub AddParent #(file, class, parent, dontRebuild)
    {
    my ($self, $file, $class, $parent, $dontRebuild) = @_;

    if (!exists $files{$file})
        {  $files{$file} = NaturalDocs::ClassHierarchy::File->New();  };

    $files{$file}->AddClass($class);
    $files{$file}->AddParent($class, $parent);


    if (!exists $classes{$class})
        {  $classes{$class} = NaturalDocs::ClassHierarchy::Class->New();  };
    if (!exists $classes{$parent})
        {  $classes{$parent} = NaturalDocs::ClassHierarchy::Class->New();  };

    $classes{$class}->AddDefinition($file);

    # If this is the first time this parent was defined for this class...
    if ($classes{$class}->AddParent($file, $parent))
        {
        $classes{$parent}->AddChild($class);

        # Update all files that define this class.
        my @classFiles = $classes{$class}->Definitions();

        foreach my $classFile (@classFiles)
            {
            NaturalDocs::SymbolTable->AddReference(undef, $parent, $classFile);

            if (!$dontRebuild)
                {  NaturalDocs::Project->RebuildFile($classFile);  };
            };

        # Update all files that define the parent.
        my @parentFiles = $classes{$parent}->Definitions();

        foreach my $parentFile (@parentFiles)
            {
            NaturalDocs::SymbolTable->AddReference(undef, $class, $parentFile);

            if (!$dontRebuild)
                {  NaturalDocs::Project->RebuildFile($parentFile);  };
            };
        }

    # If this parent was defined before...
    else
        {
        # Just add a link between this file and the parent.
        NaturalDocs::SymbolTable->AddReference(undef, $parent, $file);

        if (!$dontRebuild)
            {  NaturalDocs::Project->RebuildFile($file);  };
        };


    # Watched file.

    if (defined $watchedFileName)
        {
        $watchedFile->AddClass($class);
        $watchedFile->AddParent($class, $parent);
        };
    };


#
#   Function: WatchFileForChanges
#
#   Watches a file for changes, which can then be applied by <AnalyzeChanges()>.  Definitions are not deleted via a DeleteClass()
#   function.  Instead, a file is watched for changes, reparsed, and then a comparison is made to look for definitions that
#   disappeared and any other relevant changes.
#
#   Parameters:
#
#       file - The file name to watch.
#
sub WatchFileForChanges #(file)
    {
    my ($self, $file) = @_;

    $watchedFile = NaturalDocs::ClassHierarchy::File->New();
    $watchedFileName = $file;
    };


#
#   Function: AnalyzeChanges
#
#   Checks the watched file for any changes that occured since the last time is was parsed, and updates the hierarchy as
#   necessary.  Also sends any files that are affected to <NaturalDocs::Project->RebuildFile()>.
#
sub AnalyzeChanges
    {
    my ($self) = @_;

    # If the file didn't have any classes before, and it still doesn't, it wont be in %files.
    if (exists $files{$watchedFileName})
        {
        my @originalClasses = $files{$watchedFileName}->Classes();

        foreach my $originalClass (@originalClasses)
            {
            # If the class isn't there the second time around...
            if (!$watchedFile->HasClass($originalClass))
                {  $self->DeleteClass($watchedFileName, $originalClass);  }

            else
                {
                my @originalParents = $files{$watchedFileName}->ParentsOf($originalClass);

                foreach my $originalParent (@originalParents)
                    {
                    # If the parent wasn't there the second time around...
                    if (!$watchedFile->HasParent($originalClass, $originalParent))
                        {  $self->DeleteParent($watchedFileName, $originalClass, $originalParent);  };
                    };
                };
            };
        };


    $watchedFile = undef;
    $watchedFileName = undef;
    };



###############################################################################
# Group: Information Functions


#
#   Function: ParentsOf
#   Returns an array of the passed class' parents, or an empty array if none.
#
sub ParentsOf #(class)
    {
    my ($self, $class) = @_;

    if (exists $classes{$class})
        {  return $classes{$class}->Parents();  }
    else
        {  return ( );  };
    };

#
#   Function: ChildrenOf
#   Returns an array of the passed class' children, or an empty array if none.
#
sub ChildrenOf #(class)
    {
    my ($self, $class) = @_;

    if (exists $classes{$class})
        {  return $classes{$class}->Children();  }
    else
        {  return ( );  };
    };



###############################################################################
# Group: Support Functions


#
#   Function: DeleteFile
#
#   Deletes a file and everything defined in it.
#
#   Parameters:
#
#       file - The file name.
#
sub DeleteFile #(file)
    {
    my ($self, $file) = @_;

    if (!exists $files{$file})
        {  return;  };

    my @classes = $files{$file}->Classes();
    foreach my $class (@classes)
        {
        $self->DeleteClass($file, $class);
        };

    delete $files{$file};
    };

#
#   Function: DeleteClass
#
#   Deletes a class definition from a file.  Will also delete any parent definitions from this class and file.
#
#   Parameters:
#
#       file - The name of the file that defines the class.
#       class - The class name.
#
sub DeleteClass #(file, class)
    {
    my ($self, $file, $class) = @_;

    my @parents = $files{$file}->ParentsOf($class);
    foreach my $parent (@parents)
        {
        $self->DeleteParent($file, $class, $parent);
        };

    $files{$file}->DeleteClass($class);

    # If we're deleting the last definition of this class.
    if ($classes{$class}->DeleteDefinition($file) && !$classes{$class}->HasChildren())
        {
        delete $classes{$class};
        };
    };


#
#   Function: DeleteParent
#
#   Deletes a class' parent definiton.
#
#   Parameters:
#
#       file - The name of the file that defines the class.
#       class - The name of the class.
#       parent - The name of the parent.
#
sub DeleteParent #(file, class, parent)
    {
    my ($self, $file, $class, $parent) = @_;

    $files{$file}->DeleteParent($class, $parent);

    # If we're deleting the last definition of this parent for the class.
    if ($classes{$class}->DeleteParent($file, $parent))
        {
        $classes{$parent}->DeleteChild($class);

        # Rebuild all files that define the class.
        my @classFiles = $classes{$class}->Definitions();

        foreach my $classFile (@classFiles)
            {  NaturalDocs::Project->RebuildFile($classFile);  };

        # Rebuild all files that define the parent.
        my @parentFiles = $classes{$parent}->Definitions();

        foreach my $parentFile (@parentFiles)
            {  NaturalDocs::Project->RebuildFile($parentFile);  };

        # Clean up any unnecessary objects.
        if (!$classes{$parent}->HasChildren() && !$classes{$parent}->IsDefined())
            {  delete $classes{$parent};  };
        };
    };


1;
