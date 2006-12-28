###############################################################################
#
#   Package: NaturalDocs::ImageReferenceTable
#
###############################################################################
#
#   A package that manages all the image references appearing in source files.
#
#
#   Usage:
#
#       - <NaturalDocs::Project> and <NaturalDocs::SourceDB> must be initialized before this package can be used.
#
#       - Call <Register()> before using.
#
#
#   Programming:
#
#       When working on this code, remember that there are three things it has to juggle.
#
#       - The information in <NaturalDocs::SourceDB>.
#       - Image file references in <NaturalDocs::Project>.
#       - Source file rebuilding on changes.
#
#       Managing the actual image files will be handled between <NaturalDocs::Project> and the <NaturalDocs::Builder>
#       sub-packages.
#
#
###############################################################################

# This file is part of Natural Docs, which is Copyright (C) 2003-2006 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

use NaturalDocs::ImageReferenceTable::String;
use NaturalDocs::ImageReferenceTable::Reference;


package NaturalDocs::ImageReferenceTable;

use base 'NaturalDocs::SourceDB::Extension';


###############################################################################
# Group: Variables


#
#   var: extensionID
#   The <ExtensionID> granted by <NaturalDocs::SourceDB>.
#
my $extensionID;



###############################################################################
# Group: Files


#
#   File: ImageReferenceTable.nd
#
#   The data file which stores all the image references from the last run of Natural Docs.
#
#   Format:
#
#       > [Standard Binary Header]
#
#       It starts with the standard binary header from <NaturalDocs::BinaryFile>.
#
#       > [Image Reference String or undef]
#       > [AString16: target file]
#       > [UInt16: target width or 0]
#       > [UInt16: target height or 0]
#
#       For each <ImageReferenceString>, it's target, width, and height are stored.  The target is needed so we can tell if it
#       changed from the last run, and the dimensions are needed because if the target hasn't changed but the file's dimensions
#       have, the source files need to be rebuilt.
#
#       <ImageReferenceStrings> are encoded by <NaturalDocs::ImageReferenceTable::String>.
#
#       > [AString16: definition file or undef] ...
#
#       Then comes a series of AString16s for all the files that define the reference until it hits an undef.
#
#       This whole series is repeated for each <ImageReferenceString> until it hits an undef.
#



###############################################################################
# Group: Functions


#
#   Function: Register
#   Registers the package with <NaturalDocs::SourceDB>.
#
sub Register
    {
    my $self = shift;
    $extensionID = NaturalDocs::SourceDB->RegisterExtension($self, 0);
    };


#
#   Function: Load
#
#   Loads the data from <ImageReferenceTable.nd>.  Returns whether it was successful.
#
sub Load # => bool
    {
    my $self = shift;

    if (NaturalDocs::Settings->RebuildData())
        {  return 0;  };

    my $version = NaturalDocs::BinaryFile->OpenForReading( NaturalDocs::Project->DataFile('ImageReferenceTable.nd') );

    if (!defined $version)
        {  return 0;  }

    # The file format hasn't changed since it was introduced.
    if (!NaturalDocs::Version->CheckFileFormat($version))
        {
        NaturalDocs::BinaryFile->Close();
        return 0;
        };


    # [Image Reference String or undef]
    while (my $referenceString = NaturalDocs::ImageReferenceTable::String->FromBinaryFile())
        {
        NaturalDocs::SourceDB->AddItem($extensionID, $referenceString,
                                                           NaturalDocs::ImageReferenceTable::Reference->New());

        # [AString16: target file]
        # [UInt16: target width or 0]
        # [UInt16: target height or 0]

        my $targetFile = NaturalDocs::BinaryFile->GetAString16();
        my $width = NaturalDocs::BinaryFile->GetUInt16();
        my $height = NaturalDocs::BinaryFile->GetUInt16();

        my $newTargetFile = $self->SetReferenceTarget($referenceString);
        my $newWidth;
        my $newHeight;

        if ($newTargetFile)
            {
            NaturalDocs::Project->AddImageFileReference($newTargetFile);
            ($newWidth, $newHeight) = NaturalDocs::Project->ImageFileDimensions($newTargetFile);
            };

        my $rebuildDefinitions = ($newTargetFile ne $targetFile || $newWidth != $width || $newHeight != $height);


        # [AString16: definition file or undef] ...
        while (my $definitionFile = NaturalDocs::BinaryFile->GetAString16())
            {
            NaturalDocs::SourceDB->AddDefinition($extensionID, $referenceString, $definitionFile);

            if ($rebuildDefinitions)
                {  NaturalDocs::Project->RebuildFile($definitionFile);  };
            };
        };


    NaturalDocs::BinaryFile->Close();
    return 1;
    };


#
#   Function: Save
#
#   Saves the data to <ImageReferenceTable.nd>.
#
sub Save
    {
    my $self = shift;

    my $references = NaturalDocs::SourceDB->GetAllItemsHashRef($extensionID);

    NaturalDocs::BinaryFile->OpenForWriting( NaturalDocs::Project->DataFile('ImageReferenceTable.nd') );

    while (my ($referenceString, $referenceObject) = each %$references)
        {
        # [Image Reference String or undef]
        # [AString16: target file]
        # [UInt16: target width or 0]
        # [UInt16: target height or 0]

        NaturalDocs::ImageReferenceTable::String->ToBinaryFile($referenceString);

        my $target = $referenceObject->Target();
        my ($width, $height);

        if ($target)
            {  ($width, $height) = NaturalDocs::Project->ImageFileDimensions($target);  };

        NaturalDocs::BinaryFile->WriteAString16( $referenceObject->Target() );
        NaturalDocs::BinaryFile->WriteUInt16( ($width || 0) );
        NaturalDocs::BinaryFile->WriteUInt16( ($height || 0) );

        # [AString16: definition file or undef] ...

        my $definitions = $referenceObject->GetAllDefinitionsHashRef();

        foreach my $definition (keys %$definitions)
            {  NaturalDocs::BinaryFile->WriteAString16($definition);  };

        NaturalDocs::BinaryFile->WriteAString16(undef);
        };

    NaturalDocs::ImageReferenceTable::String->ToBinaryFile(undef);

    NaturalDocs::BinaryFile->Close();
    };


#
#   Function: AddReference
#
#   Adds a new image reference.
#
sub AddReference #(FileName file, string referenceText)
    {
    my ($self, $file, $referenceText) = @_;

    my $referenceString = NaturalDocs::ImageReferenceTable::String->Make($file, $referenceText);

    if (!NaturalDocs::SourceDB->HasItem($extensionID, $referenceString))
        {
        my $referenceObject = NaturalDocs::ImageReferenceTable::Reference->New();
        NaturalDocs::SourceDB->AddItem($extensionID, $referenceString, $referenceObject);

        my $target = $self->SetReferenceTarget($referenceString);
        if ($target)
            {  NaturalDocs::Project->AddImageFileReference($target);  };
        };

    NaturalDocs::SourceDB->AddDefinition($extensionID, $referenceString, $file);
    };


#
#   Function: OnDeletedDefinition
#
#   Called for each definition deleted by <NaturalDocs::SourceDB>.  This is called *after* the definition has been deleted from
#   the database, so don't expect to be able to read it.
#
sub OnDeletedDefinition #(ImageReferenceString referenceString, FileName file, bool wasLastDefinition)
    {
    my ($self, $referenceString, $file, $wasLastDefinition) = @_;

    if ($wasLastDefinition)
        {
        my $referenceObject = NaturalDocs::SourceDB->GetItem($extensionID, $referenceString);
        my $target = $referenceObject->Target();

        if ($target)
            {  NaturalDocs::Project->DeleteImageFileReference($target);  };

        NaturalDocs::SourceDB->DeleteItem($extensionID, $referenceString);
        };
    };


#
#   Function: GetReferenceTarget
#
#   Returns the image file the reference resolves to, or undef if none.
#
#   Parameters:
#
#       sourceFile - The source <FileName> the reference appears in.
#       text - The reference text.
#
sub GetReferenceTarget #(FileName sourceFile, string text) => FileName
    {
    my ($self, $sourceFile, $text) = @_;

    my $referenceString = NaturalDocs::ImageReferenceTable::String->Make($sourceFile, $text);
    my $reference = NaturalDocs::SourceDB->GetItem($extensionID, $referenceString);

    if (!defined $reference)
        {  return undef;  }
    else
        {  return $reference->Target();  };
    };


#
#   Function: SetReferenceTarget
#
#   Determines the best target for the passed <ImageReferenceString> and sets it on the
#   <NaturalDocs::ImageReferenceTable::Reference> object.  Returns the new target <FileName>.  Does *not* add any source
#   files to the bulid list.
#
sub SetReferenceTarget #(ImageReferenceString referenceString) => FileName
    {
    my ($self, $referenceString) = @_;

    my $referenceObject = NaturalDocs::SourceDB->GetItem($extensionID, $referenceString);
    my ($path, $text) = NaturalDocs::ImageReferenceTable::String->InformationOf($referenceString);

    my $imageFile = NaturalDocs::File->JoinPaths($path, $text);
    my $target;

    if (NaturalDocs::Project->ImageFileExists($imageFile))
        {  $target = NaturalDocs::Project->ImageFileCapitalization($imageFile);  };

    $referenceObject->SetTarget($target);
    return $target;
    };


1;
