###############################################################################
#
#   Package: NaturalDocs::SourceDB
#
###############################################################################
#
#   The central source repository database.
#
#   Requirements:
#
#       - All extension packages must call <RegisterExtension()> before they can be used.
#
#
#
#   Architecture: Assumptions
#
#       SourceDB is built around certain assumptions.
#
#       One item per file:
#
#           SourceDB assumes that only the first item per file with a particular item string is relevant.  For example, if two functions
#           have the exact same name, there's no way to link to the second one either in HTML or internally so it doesn't matter for
#           our purposes.  Likewise, if two references are exactly the same they go to the same target, so it doesn't matter whether
#           there's one or two or a thousand.  All that matters is that at least one reference exists in this file because you only need
#           to determine whether the entire file gets rebuilt.  If two items are different in some meaningful way, they should generate
#           different item strings.
#
#       Watched file parsing:
#
#           SourceDB assumes the parse method is that the information that was stored from Natural Docs' previous run is loaded, a
#           file is watched, that file is reparsed, and then <AnalyzeWatchedFileChanges()> is called.  When the file is reparsed all
#           items within it are added the same as if the file was never parsed before.
#
#           If there's a new item this time around, that's fine no matter what.  However, a changed item wouldn't normally be
#           recorded because the previous run's definition is seen as the first one and subsequent ones are ignored.  Also, deleted
#           items would normally not be recorded either because we're only adding.
#
#           The watched file method fixes this because everything is also added to a second, clean database specifically for the
#           watched file.  Because it starts clean, it always gets the first definition from the current parse which can then be
#           compared to the original by <AnalyzeWatchedFileChanges()>.  Because it starts clean you can also compare it to the
#           main database to see if anything was deleted, because it would appear in the main database but not the watched one.
#
#           This means that functions like <ChangeDefinition()> and <DeleteDefinition()> should only be called by
#           <AnalyzeWatchedFileChanges()>.  Externally only <AddDefinition()> should be called.  <DeleteItem()> is okay to be
#           called externally because entire items aren't managed by the watched file database, only definitions.
#
#
###############################################################################

# This file is part of Natural Docs, which is Copyright (C) 2003-2006 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;


use NaturalDocs::SourceDB::Extension;
use NaturalDocs::SourceDB::Item;
use NaturalDocs::SourceDB::ItemDefinition;
use NaturalDocs::SourceDB::File;
use NaturalDocs::SourceDB::WatchedFileDefinitions;


package NaturalDocs::SourceDB;


###############################################################################
# Group: Types


#
#   Type: ExtensionID
#
#   A unique identifier for each <NaturalDocs::SourceDB> extension as given out by <RegisterExtension()>.
#



###############################################################################
# Group: Variables


#
#   array: extensions
#
#   An array of <NaturalDocs::SourceDB::Extension>-derived extensions, as added with <RegisterExtension()>.  The indexes
#   are the <ExtensionIDs> and the values are package references.
#
my @extensions;


#
#   array: items
#
#   The array of source items.  The <ExtensionIDs> are the indexes, and the values are hashrefs mapping the item
#   string to <NaturalDocs::SourceDB::Item>-derived objects.  Hashrefs may be undef.
#
my @items;


#
#   hash: files
#
#   A hashref mapping source <FileNames> to <NaturalDocs::SourceDB::Files>.
#
my %files;


#
#   object: watchedFile
#
#   When a file is being watched for changes, will be a <NaturalDocs::SourceDB::File> for that file.  Is undef otherwise.
#
#   When the file is parsed, items are added to both this and the version in <files>.  Thus afterwards we can compare the two to
#   see if any were deleted since the last time Natural Docs was run, because they would be in the <files> version but not this
#   one.
#
my $watchedFile;


#
#   string: watchedFileName
#
#   When a file is being watched for changes, will be the <FileName> of the file being watched.  Is undef otherwise.
#
my $watchedFileName;


#
#   object: watchedFileDefinitions
#
#   When a file is being watched for changes, will be a <NaturalDocs::SourceDB::WatchedFileDefinitions> object.  Is undef
#   otherwise.
#
#   When the file is parsed, items are added to both this and the version in <items>.  Since only the first definition is kept, this
#   will always have the definition info from the file whereas the version in <items> will have the first definition as of the last time
#   Natural Docs was run.  Thus they can be compared to see if the definitions of items that existed the last time around have
#   changed.
#
my $watchedFileDefinitions;



###############################################################################
# Group: Extension Functions


#
#   Function: RegisterExtension
#
#   Registers a <NaturalDocs::SourceDB::Extension>-derived package and returns a unique <ExtensionID> for it.  All extensions
#   must call this before they can be used.
#
#   Registration Order:
#
#       The order in which extensions register is important.  Whenever possible, items are added in the order their extensions
#       registered.  However, items are changed and deleted in the reverse order.  Take advantage of this to minimize
#       churn between extensions that are dependent on each other.
#
#       For example, when symbols are added or deleted they may cause references to be retargeted and thus their files need to
#       be rebuilt.  However, adding or deleting references never causes the symbols' files to be rebuilt.  So it makes sense that
#       symbols should be created before references, and that references should be deleted before symbols.
#
#   Parameters:
#
#       extension - The package or object of the extension.  Must be derived from <NaturalDocs::SourceDB::Extension>.
#
#   Returns:
#
#       An <ExtensionID> unique to the extension.  This should be saved because it's required in functions such as <AddItem()>.
#
sub RegisterExtension #(package extension) => ExtensionID
    {
    my ($self, $extension);

    push @extensions, $extension;

    return scalar @extensions - 1;
    };


#
#   Function: ExtensionOnlyTracksExistence
#
#   Returns whether the passed <ExtensionID> only tracks the fact that a definition exists or whether they use
#   <NaturalDocs::SourceDB::ItemDefinition>-derived objects to track additional information about them.
#
sub ExtensionOnlyTracksExistence #(ExtensionID extension) => bool
    {
    my ($self, $extension) = @_;
    return $extensions[$extension]->OnlyTracksExistence();
    };




###############################################################################
# Group: Item Functions


#
#   Function: AddItem
#
#   Adds the passed item to the database.  Will not work if the item string already exists.  The item added should *not* already
#   have definitions attached.  Only use this to add blank items and then call <AddDefinition()> instead.
#
#   Parameters:
#
#       extension - An <ExtensionID>.
#       itemString - The string serving as the item identifier.
#       item - An object derived from <NaturalDocs::SourceDB::Item>.
#
#   Returns:
#
#       Whether the item was added, that is, whether it was the first time this item was added.
#
sub AddItem #(ExtensionID extension, string itemString, NaturalDocs::SourceDB::Item item) => bool
    {
    my ($self, $extension, $itemString, $item) = @_;

    if (!defined $items[$extension])
        {  $items[$extension] = { };  };

    if (!exists $items[$extension]->{$itemString})
        {
        if ($item->HasDefinitions())
            {  die "Tried to add an item to SourceDB that already had definitions.";  };

        $items[$extension]->{$itemString} = $item;
        return 1;
        };

    return 0;
    };


#
#   Function: GetItem
#
#   Returns the <NaturalDocs::SourceDB::Item>-derived object for the passed <ExtensionID> and item string, or undef if there
#   is none.
#
sub GetItem #(ExtensionID extension, string itemString) => bool
    {
    my ($self, $extensionID, $itemString) = @_;

    if (defined $items[$extensionID])
        {  return $items[$extensionID]->{$itemString};  }
    else
        {  return undef;  };
    };


#
#   Function: DeleteItem
#
#   Deletes the record of the passed <ExtensionID> and item string.  Returns whether it was successful, meaning whether an
#   entry existed for it.  Do *not* delete items that still have definitions this way.  Use <DeleteDefinition()> first.
#
sub DeleteItem #(ExtensionID extension, string itemString) => bool
    {
    my ($self, $extension, $itemString) = @_;

    if (defined $items[$extension] && exists $items[$extension]->{$itemString})
        {
        if ($items[$extension]->{$itemString}->HasDefinitions())
            {  die "Tried to delete an item from SourceDB that still has definitions.";  };

        delete $items[$extension]->{$itemString};
        return 1;
        }
    else
        {  return 0;  };
    };


#
#   Function: HasItem
#
#   Returns whether there is an item defined for the passed <ExtensionID> and item string.
#
sub HasItem #(ExtensionID extension, string itemString) => bool
    {
    my ($self, $extension, $itemString) = @_;

    if (defined $items[$extension])
        {  return (exists $items[$extension]->{$itemString});  }
    else
        {  return 0;  };
    };



###############################################################################
# Group: Definition Functions


#
#   Function: AddDefinition
#
#   Adds a definition to the item.  Assumes the item is already defined.  If there's already a definition for this file and item, the
#   new definition will be ignored.
#
#   Parameters:
#
#       extension - The <ExtensionID>.
#       itemString - The item string.
#       file - The <FileName> the definition is in.
#       definition - The definition, which must be an object derived from <NaturalDocs::SourceDB::ItemDefinition>.  Ignored if the
#                       extension only tracks existence.
#
#   Returns:
#
#       Whether the definition was added, which is to say, whether this was the first definition for the passed <FileName>.
#
sub AddDefinition #(ExtensionID extension, string itemString, FileName file, optional NaturalDocs::SourceDB::ItemDefinition definition) => bool
    {
    my ($self, $extension, $itemString, $file, $definition) = @_;


    # Items

    my $item = $self->GetItem($extension, $itemString);

    if (!defined $item)
        {  die "Tried to add a definition to an undefined item in SourceDB.";  };

    if ($self->ExtensionOnlyTracksExistence($extension))
        {  $definition = 1;  };

    my $result = $item->AddDefinition($file, $definition);


    # Files

    if (!exists $files{$file})
        {  $files{$file} = NaturalDocs::SourceDB::File->New();  };

    $files{$file}->AddItem($extension, $itemString);


    # Watched File

    if ($self->WatchingFileForChanges())
        {
        $watchedFile->AddItem($extension, $itemString);

        if (!$self->ExtensionOnlyTracksExistence($extension))
            {  $watchedFileDefinitions->AddDefinition($extension, $itemString, $definition);  };
        };


    return $result;
    };


#
#   Function: ChangeDefinition
#
#   Changes the definition of an item.  Assumes the item is already defined.
#
#   Parameters:
#
#       extension - The <ExtensionID>.
#       itemString - The item string.
#       file - The <FileName> the definition is in.
#       definition - The definition, which must be an object derived from <NaturalDocs::SourceDB::ItemDefinition>.
#
sub ChangeDefinition #(ExtensionID extension, string itemString, FileName file, NaturalDocs::SourceDB::ItemDefinition definition)
    {
    my ($self, $extension, $itemString, $file, $definition) = @_;

    my $item = $self->GetItem($extension, $itemString);

    if (!defined $item)
        {  die "Tried to change the definition of an undefined item in SourceDB.";  };

    if ($self->ExtensionOnlyTracksExistence($extension))
        {  die "Tried to change the definition of an item in an extension that only tracks existence in SourceDB.";  };

    $item->ChangeDefinition($file, $definition);
    };


#
#   Function: GetDefinition
#
#   Returns the <NaturalDocs::SourceDB::ItemDefinition>-derived object for the passed item, non-zero if it only tracks existence,
#   or undef if there is none.
#
sub GetDefinition #(ExtensionID extension, string itemString, FileName file) => NaturalDocs::SourceDB::ItemDefinition or bool
    {
    my ($self, $extension, $itemString, $file) = @_;

    my $item = $self->GetItem($extension, $itemString);

    if (!defined $item)
        {  return undef;  };

    return $item->GetDefinition($file);
    };


#
#   Function: DeleteDefinition
#
#   Removes the definition for the passed item.  Returns whether it was successful, meaning whether a definition existed
#   for that file.
#
sub DeleteDefinition #(ExtensionID extension, string itemString, FileName file) => bool
    {
    my ($self, $extension, $itemString, $file) = @_;

    my $item = $self->GetItem($extension, $itemString);

    if (!defined $item)
        {  return 0;  };

    my $result = $item->DeleteDefinition($file);

    $files{$file}->DeleteItem($extension, $itemString);

    return $result;
    };


#
#   Function: HasDefinitions
#
#   Returns whether there are any definitions for this item.
#
sub HasDefinitions #(ExtensionID extension, string itemString) => bool
    {
    my ($self, $extension, $itemString) = @_;

    my $item = $self->GetItem($extension, $itemString);

    if (!defined $item)
        {  return 0;  };

    return $item->HasDefinitions();
    };


#
#   Function: HasDefinition
#
#   Returns whether there is a definition for the passed <FileName>.
#
sub HasDefinition #(ExtensionID extension, string itemString, FileName file) => bool
    {
    my ($self, $extension, $itemString, $file) = @_;

    my $item = $self->GetItem($extension, $itemString);

    if (!defined $item)
        {  return 0;  };

    return $item->HasDefinition($file);
    };



###############################################################################
# Group: Watched File Functions


#
#   Function: WatchFileForChanges
#
#   Begins watching a file for changes.  Only one file at a time can be watched.
#
#   This should be called before a file is parsed so the file info goes both into the main database and the watched file info.
#   Afterwards you call <AnalyzeWatchedFileChanges()> so item deletions and definition changes can be detected.
#
#   Parameters:
#
#       filename - The <FileName> to watch.
#
sub WatchFileForChanges #(FileName filename)
    {
    my ($self, $filename) = @_;

    $watchedFileName = $filename;
    $watchedFile = NaturalDocs::File->New();
    $watchedFileDefinitions = NaturalDocs::WatchedFileDefinitions->New();
    };


#
#   Function: WatchingFileForChanges
#
#   Returns whether we're currently watching a file for changes or not.
#
sub WatchingFileForChanges # => bool
    {
    my $self = shift;
    return defined $watchedFileName;
    };


#
#   Function: AnalyzeWatchedFileChanges
#
#   Analyzes the watched file for changes.  For each item that was removed from the file,
#   <NaturalDocs::SourceDB::Extension->OnDeletedDefinition()> will be called for the extension class.  For each item that was
#   changed (as determined by <NaturalDocs::SourceDB::ItemDefinition->Compare()>)
#   <NaturalDocs::SourceDB::Extension->OnChangedDefinition()> will be called for the extension class.  This assumes that the
#   extension is using <NaturalDocs::SourceDB::ItemDefinition>-derived classes and not merely tracking each item's existence.
#
sub AnalyzeWatchedFileChanges
    {
    my $self = shift;

    if (!$self->WatchingFileForChanges())
        {  die "Tried to analyze watched file for changes in SourceDB when no file was being watched.";  };


    # Process extensions last registered to first.

    for (my $i = scalar @extensions - 1; $i >= 0; $i--)
        {
        my @items = $files{$watchedFileName}->ListItems($i);

        foreach my $item (@items)
            {
            if ($watchedFile->HasItem($item))
                {
                if (!$self->ExtensionOnlyTracksExistence($i))
                    {
                    my $originalDefinition = $items[$i]->GetDefinition($watchedFileName);
                    my $watchedDefinition = $watchedFileDefinitions->GetDefinition($i, $item);

                    if (!$originalDefinition->Compare($watchedDefinition))
                        {
                        $self->ChangeDefinition($i, $item, $watchedFileName, $watchedDefinition);
                        $extensions[$i]->OnChangedDefinition($item, $watchedFileName);
                        };
                    }
                }
            else # !$watchedFile->HasItem($item)
                {
                if ($self->DeleteDefinition($i, $item, $watchedFileName))
                    {  $extensions[$i]->OnDeletedDefinition($item, $watchedFileName);  };
                };
            };
        };


    $watchedFile = undef;
    $watchedFileName = undef;
    $watchedFileDefinitions = undef;
    };


1;
