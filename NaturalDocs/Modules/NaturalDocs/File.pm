###############################################################################
#
#   Package: NaturalDocs::File
#
###############################################################################
#
#   A package to manage file access across platforms.  Incorporates functions from various standard File:: packages, but more
#   importantly, works around the glorious suckage present in File::Spec.  Read the "Why oh why?" sections for why this package
#   was necessary.
#
#   Usage and Dependencies:
#
#       - The package doesn't depend on any other Natural Docs packages and is ready to use immediately.
#
#       - All functions except <CanonizePath()> assume that all parameters are canonized.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright © 2003 Greg Valure
# Natural Docs is licensed under the GPL

use File::Spec ();
use File::Path ();
use File::Copy ();

use strict;
use integer;

package NaturalDocs::File;


###############################################################################
# Group: Functions


#
#   Function: CanonizePath
#
#   Takes a path and returns a logically simplified version of it.
#
#   Why oh why?:
#
#       Because File::Spec->canonpath doesn't strip quotes on Windows.  So if you pass in "a b\c" or "a b"\c, they still end up as
#       different strings even though they're logically the same.
#
sub CanonizePath #(path)
    {
    my $path = shift;

    if ($^O eq 'MSWin32')
        {
        # We don't have to use a smarter algorithm for dropping quotes because they're invalid characters for actual file and
        # directory names.
        $path =~ s/\"//g;
        };

    return File::Spec->canonpath($path);
    };


#
#   Function: JoinPath
#
#   Joins two paths.
#
#   Parameters:
#
#       basePath       - May be a relative path, an absolute path, or undef.
#       extraPath      - May be a relative path, a file, a relative path and file together, or undef.
#       noFileInExtra - Set this to true if extraPath is a relative path only, and doesn't have a file.
#
#   Returns:
#
#       The joined path.
#
#   Why oh why?:
#
#       Because nothing in File::Spec will simply slap two paths together.  They have to be split up for catpath/file, and rel2abs
#       requires the base to be absolute.
#
sub JoinPath #(basePath, extraPath, noFileInExtra)
    {
    my ($basePath, $extraPath, $noFileInExtra) = @_;

    # If both are undef, it will return undef, which is what we want.
    if (!defined $basePath)
        {  return $extraPath;  }
    elsif (!defined $extraPath)
        {  return $basePath;  };

    my ($baseVolume, $baseDirString, $baseFile) = File::Spec->splitpath($basePath, 1);
    my ($extraVolume, $extraDirString, $extraFile) = File::Spec->splitpath($extraPath, $noFileInExtra);

    my @baseDirectories = SplitDirectories($baseDirString);
    my @extraDirectories = SplitDirectories($extraDirString);

    my $fullDirString = File::Spec->catdir(@baseDirectories, @extraDirectories);

    my $fullPath = File::Spec->catpath($baseVolume, $fullDirString, $extraFile);

    return CanonizePath($fullPath);
    };


#
#   Function: MakeRelativePath
#
#   Takes two paths and returns a relative path between them.
#
#   Parameters:
#
#       basePath    - The starting path.  May be relative or absolute, so long as the target path is as well.
#       targetPath  - The target path.  May be relative or absolute, so long as the base path is as well.
#
#       If both paths are relative, they are assumed to be relative to the same base.
#
#   Returns:
#
#       The target path relative to base.
#
#   Why oh why?:
#
#       Wow, where to begin?  First of all, there's nothing that gives a relative path between two relative paths.
#
#       Second of all, if target and base are absolute but on different volumes, File::Spec->abs2rel creates a totally non-functional
#       relative path.  It should return the target as is, since there is no relative path.
#
#       Third of all, File::Spec->abs2rel between absolute paths on the same volume, at least on Windows, leaves the drive letter
#       on.  So abs2rel('a:\b\c\d', 'a:\b') returns 'a:c\d' instead of the expected 'c\d'.  That makes no fucking sense whatsoever.  It's
#       not like it was designed to handle only directory names, either; the documentation says 'path' and the code seems to
#       explicitly handle it.  There's just an 'unless' in there that tacks on the volume, defeating the purpose of a *relative* path and
#       making the function worthless.  Morons.
#
#       Update: This last one appears to be fixed in File::Spec 0.83, but that version isn't even listed on CPAN.  Lovely.  Apparently
#       it just comes with ActivePerl.  Somehow I don't think most Linux users are using that.
#
sub MakeRelativePath #(basePath, targetPath)
    {
    my ($basePath, $targetPath) = @_;

    my ($baseVolume, $baseDirString, $baseFile) = File::Spec->splitpath($basePath, 1);
    my ($targetVolume, $targetDirString, $targetFile) = File::Spec->splitpath($targetPath);

    # If the volumes are different, there is no possible relative path.
    if ($targetVolume ne $baseVolume)
        {  return $targetPath;  };

    my @baseDirectories = SplitDirectories($baseDirString);
    my @targetDirectories = SplitDirectories($targetDirString);

    # Skip the parts of the path that are the same.
    while (scalar @baseDirectories && @targetDirectories && $baseDirectories[0] eq $targetDirectories[0])
        {
        shift @baseDirectories;
        shift @targetDirectories;
        };

    # Back out of the base path until it reaches where they were similar.
    for (my $i = 0; $i < scalar @baseDirectories; $i++)
        {
        unshift @targetDirectories, File::Spec->updir();
        };

    $targetDirString = File::Spec->catdir(@targetDirectories);

    return File::Spec->catpath(undef, $targetDirString, $targetFile);
    };


#
#   Function: ConvertToURL
#
#   Takes a relative path and converts it from the native format to a relative URL.  Note that it _doesn't_ convert special characters
#   to amp chars.
#
sub ConvertToURL #(path)
    {
    my $path = shift;

    my ($pathVolume, $pathDirString, $pathFile) = File::Spec->splitpath($path);
    my @pathDirectories = SplitDirectories($pathDirString);

    my $i = 0;
    while ($i < scalar @pathDirectories && $pathDirectories[$i] eq File::Spec->updir())
        {
        $pathDirectories[$i] = '..';
        $i++;
        };

    return join('/', @pathDirectories, $pathFile);
    };


#
#   Function: NoUpwards
#
#   Takes an array of directory entries and returns one without all the entries that refer to the parent directory, such as '.' and '..'.
#
sub NoUpwards #(array)
    {
    return File::Spec->no_upwards(@_);
    };


#
#   Function: NoFileName
#
#   Takes a path and returns a version without the file name.  Useful for sending paths to <CreatePath()>.
#
sub NoFileName #(path)
    {
    my $path = shift;

    my ($pathVolume, $pathDirString, $pathFile) = File::Spec->splitpath($path);

    return File::Spec->catpath($pathVolume, $pathDirString, undef);
    };


#
#   Function: CreatePath
#
#   Creates a directory tree corresponding to the passed path, regardless of how many directories do or do not already exist.
#   Do _not_ include a file name in the path.  Use <NoFileName()> first if you need to.
#
sub CreatePath #(path)
    {
    File::Path::mkpath($_[0]);
    };


#
#   Function: Copy
#
#   Copies a file from one path to another.  If the destination file exists, it is overwritten.
#
#   Parameters:
#
#       source       - The file to copy.
#       destination - The destination to copy to.
#
sub Copy #(source, destination)
    {
    File::Copy::copy(@_);
    };


###############################################################################
# Group: Support Functions

#
#   Function: SplitDirectories
#
#   Takes a string of directories and returns an array of its elements.
#
#   Why oh why?:
#
#       Because File::Spec->splitdir might leave an empty element at the end of the array, which screws up both joining in
#       <ConvertToURL> and navigation in <MakeRelativePath>.  Morons.
#
sub SplitDirectories #(directoryString)
    {
    my $directoryString = shift;

    my @directories = File::Spec->splitdir($directoryString);

    if (!length $directories[-1])
        {  pop @directories;  };

    return @directories;
    };


1;