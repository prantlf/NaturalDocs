###############################################################################
#
#   Package: NaturalDocs::BinaryFile
#
###############################################################################
#
#   A package to manage Natural Docs' binary data files.
#
#   Usage:
#
#       - Only one data file can be managed with this package at a time.  You must close the file before opening another
#         one.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright (C) 2003-2006 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;

package NaturalDocs::ConfigFile;



###############################################################################
# Group: Variables

#
#   handle: FH_BINARYDATAFILE
#
#   The file handle used for the data file.
#


#
#   string: currentFile
#
#   The <FileName> for the current configuration file being parsed.
#
my $currentFile;



###############################################################################
# Group: File Functions


#
#   Function: OpenForReading
#
#   Opens a binary file for reading and returns the format <VersionInt>.  Returns undef if the file doesn't exist, couldn't be
#   opened, or is not binary.
#
sub OpenForReading #(FileName file) => bool
    {
    my ($self, $file) = @_;

    if (defined $currentFile)
        {  die "Tried to open binary file " . $file . " for reading when " . $currentFile . " was already open.";  };

    $currentFile = $file;

    if (open(FH_BINARYDATAFILE, '<' . $currentFile))
        {
        # See if it's binary.
        binmode(FH_BINARYDATAFILE);

        my $firstChar;
        read(FH_BINARYDATAFILE, $firstChar, 1);

        if ($firstChar == ::BINARY_FORMAT())
            {
            return NaturalDocs::Version->FromBinaryFile(\*FH_BINARYDATAFILE);
            }

        else # it's not in binary
            {
            close(FH_BINARYDATAFILE);
            };
        };

    $currentFile = undef;
    return undef;
    };


#
#   Function: OpenForWriting
#
#   Opens a binary file for writing and writes the standard header.  Dies if the file cannot be opened.
#
sub OpenForWriting #(FileName file)
    {
    my ($self, $file) = @_;

    if (defined $currentFile)
        {  die "Tried to open binary file " . $file . " for writing when " . $currentFile . " was already open.";  };

    $currentFile = $file;

    open (FH_BINARYDATAFILE, '>' . $currentFile)
        or die "Couldn't save " . $file . ".\n";

    binmode(FH_BINARYDATAFILE);

    print FH_BINARYDATAFILE '' . ::BINARY_FORMAT();
    NaturalDocs::Version->ToBinaryFile(\*FH_BINARYDATAFILE, NaturalDocs::Settings->AppVersion());
    };


#
#   Function: Close
#
#   Closes the current configuration file.
#
sub Close
    {
    my $self = shift;

    if (!$currentFile)
        {  die "Tried to close a binary file when one wasn't open.";  };

    close(FH_BINARYDATAFILE);
    $currentFile = undef;
    };



###############################################################################
# Group: Reading Functions


#
#   Function: GetUInt8
#   Reads and returns a UInt8 from the open file.
#
sub GetUInt8 # => UInt8
    {
    my $raw;
    read(FH_BINARYDATAFILE, $raw, 1);

    return unpack('C', $raw);
    };

#
#   Function: GetUInt16
#   Reads and returns a UInt16 from the open file.
#
sub GetUInt16 # => UInt16
    {
    my $raw;
    read(FH_BINARYDATAFILE, $raw, 2);

    return unpack('n', $raw);
    };

#
#   Function: GetUInt32
#   Reads and returns a UInt32 from the open file.
#
sub GetUInt32 # => UInt32
    {
    my $raw;
    read(FH_BINARYDATAFILE, $raw, 4);

    return unpack('N', $raw);
    };

#
#   Function: GetAString16
#   Reads and returns an AString16 from the open file.  Supports undef strings.
#
sub GetAString16 # => string
    {
    my $rawLength;
    read(FH_BINARYDATAFILE, $rawLength, 2);
    my $length = unpack('n', $rawLength);

    if (!$length)
        {  return undef;  };

    my $string;
    read(FH_BINARYDATAFILE, $string, $length);

    return $string;
    };



###############################################################################
# Group: Writing Functions


#
#   Function: WriteUInt8
#   Writes a UInt8 to the open file.
#
sub WriteUInt8 #(UInt8 value)
    {
    my ($self, $value) = @_;
    print FH_BINARYDATAFILE pack('C', $value);
    };

#
#   Function: WriteUInt16
#   Writes a UInt32 to the open file.
#
sub WriteUInt16 #(UInt16 value)
    {
    my ($self, $value) = @_;
    print FH_BINARYDATAFILE pack('n', $value);
    };

#
#   Function: WriteUInt32
#   Writes a UInt32 to the open file.
#
sub WriteUInt32 #(UInt32 value)
    {
    my ($self, $value) = @_;
    print FH_BINARYDATAFILE pack('N', $value);
    };

#
#   Function: WriteAString16
#   Writes an AString16 to the open file.  Supports undef strings.
#
sub WriteAString16 #(string value)
    {
    my ($self, $string) = @_;

    if (length($string))
        {  print FH_BINARYDATAFILE pack('nA*', length($string), $string);  }
    else
        {  print FH_BINARYDATAFILE pack('n', 0);  };
    };


1;
