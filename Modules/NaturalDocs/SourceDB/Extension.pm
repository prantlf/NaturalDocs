###############################################################################
#
#   Package: NaturalDocs::SourceDB::Extension
#
###############################################################################
#
#   A base package for all <SourceDB> extensions.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright (C) 2003-2006 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;


package NaturalDocs::SourceDB::Extension;


###############################################################################
# Group: Interface Functions
# These functions must be overridden by the derived class.


#
#   Function: Register
#
#   Override this function to register the package with <NaturalDocs::SourceDB->RegisterExtension()>.
#
sub Register
    {
    die "Called SourceDB::Extension->Register().  This function should be overridden by every extension.";
    };

#
#   Function: OnlyTracksExistence
#
#   Override this function to return whether your extension only tracks the existence of items or whether it uses
#   <NaturalDocs::SourceDB::ItemDefinition>-derived objects to track additional information about them.
#
sub OnlyTracksExistence # => bool
    {
    die "Called SourceDB::Extension->OnlyTracksExistence().  This function should be overridden by every extension.";
    };


#
#   Function: OnDeletedDefinition
#
#   Called for each definition deleted by <NaturalDocs::SourceDB->AnalyzeWatchedFileChanges()>.  This is called *after* the
#   definition has been deleted from <NaturalDocs::SourceDB>.
#
sub OnDeletedDefinition #(string itemString, FileName file)
    {
    };


#
#   Function: OnChangedDefinition
#
#   Called for each definition changed by <NaturalDocs::SourceDB->AnalyzeWatchedFileChanges()>.  This is called *after* the
#   definition has been changed in <NaturalDocs::SourceDB>.
#
sub OnChangedDefinition #(string itemString, FileName file)
    {
    };


1;
