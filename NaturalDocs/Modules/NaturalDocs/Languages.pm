###############################################################################
#
#   Package: NaturalDocs::Languages
#
###############################################################################
#
#   A package to manage all the programming languages Natural Docs supports.
#
#   Usage and Dependencies:
#
#       - Prior to use, <NaturalDocs::Settings> must be initialized and <Load()> must be called.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright � 2003-2004 Greg Valure
# Natural Docs is licensed under the GPL

use NaturalDocs::Languages::Base;
use NaturalDocs::Languages::Simple;
use NaturalDocs::Languages::Advanced;

use NaturalDocs::Languages::Perl;
use NaturalDocs::Languages::CSharp;

use NaturalDocs::Languages::PLSQL;
use NaturalDocs::Languages::Pascal;
use NaturalDocs::Languages::Ada;
use NaturalDocs::Languages::Tcl;

use strict;
use integer;

package NaturalDocs::Languages;


###############################################################################
# Group: Variables


#
#   handle: FH_LANGUAGES
#
#   The file handle used for writing to <Languages.txt>.
#


#
#   hash: languages
#
#   A hash of all the defined languages.  The keys are the all-lowercase language names, and the values are
#   <NaturalDocs::Languages::Base>-derived objects.
#
my %languages;

#
#   hash: extensions
#
#   A hash of all the defined languages' extensions.  The keys are the all-lowercase extensions, and the values are the
#   all-lowercase names of the languages that defined them.
#
my %extensions;

#
#   hash: shebangStrings
#
#   A hash of all the defined languages' strings to search for in the shebang (#!) line.  The keys are the all-lowercase strings, and
#   the values are the all-lowercase names of the languages that defined them.
#
my %shebangStrings;

#
#   hash: shebangFiles
#
#   A hash of all the defined languages for files where it needs to be found via shebang strings.  The keys are the file names,
#   and the values are language names, or undef if the file isn't supported.  These values should be filled in the first time
#   each file is parsed for a shebang string so that it doesn't have to be done multiple times.
#
my %shebangFiles;



###############################################################################
# Group: Files


#
#   File: Languages.txt
#
#   The configuration file that defines or overrides the language definitions for Natural Docs.  One version sits in Natural Docs'
#   configuration directory, and another can be in a project directory to add to or override them.
#
#   > # [comments]
#
#   Everything after a # symbol is ignored.  However, for this particular file, comments can only appear on their own lines.
#   They cannot appear after content on the same line.
#
#   > Format: [version]
#
#   Specifies the file format version of the file.
#
#
#   Sections:
#
#       > Ignore[d] Extension[s]: [extension] [extension] ...
#
#       Causes the listed file extensions to be ignored, even if they were previously defined to be part of a language.  The list is
#       space-separated.  ex. "Ignore Extensions: cvs txt"
#
#
#       > Language: [name]
#
#       Creates a new language.  Everything underneath applies to this language until the next one.  Names can use any
#       characters.
#
#       The languages "Text File" and "Shebang Script" have special meanings.  Text files are considered all comment and don't
#       have comment symbols.  Shebang scripts have their language determined by the shebang string and automatically
#       include files with no extension in addition to the extensions defined.
#
#
#       > Alter Language: [name]
#
#       Alters an existing language.  Everything underneath it overrides the previous settings until the next one.  Note that if a
#       property has an [Add/Replace] form and that property has already been defined, you have to specify whether you're adding
#       to or replacing the defined list.
#
#
#   Language Properties:
#
#       > Extension[s]: [extension] [extension] ...
#       > [Add/Replace] Extension[s]: ...
#
#       Defines file extensions for the language's source files.  The list is space-separated.  ex. "Extensions: c cpp".  You can use
#       extensions that were previously used by another language to redefine them.
#
#
#       > Shebang String[s]: [string] [string] ...
#       > [Add/Replace] Shebang String[s]: ...
#
#       Defines a list of strings that can appear in the shebang (#!) line to designate that it's part of this language.  They can
#       appear anywhere in the line, so "php" will work for "#!/user/bin/php4".  You can use strings that were previously used by
#       another language to redefine them.
#
#
#       > Package Separator: [symbol]
#
#       Defines the default package separator symbol, such as . or ::.  This is for presentation only and will not affect how
#       Natural Docs links are parsed.  The default is a dot.
#
#
#       > Ignore[d] Prefix[es] in Index: [prefix] [prefix] ...
#       > Ignore[d] [Topic Type] Prefix[es] in Index: [prefix] [prefix] ...
#       > [Add/Replace] Ignore[d] Prefix[es] in Index: ...
#       > [Add/Replace] Ignore[d] [Topic Type] Prefix[es] in Index: ...
#
#       Specifies prefixes that should be ignored when sorting symbols for an index.  Can be specified in general or for a specific
#       <TopicType>.  The prefixes will still appear, the symbols will just be sorted as if they're not there.  For example, specifying
#       "ADO_" for functions will mean that "ADO_DoSomething" will appear under D instead of A.
#
#
#   Basic Language Support Properties:
#
#       These attributes are only available for languages with basic language support.
#
#
#       > Line Comment[s]: [symbol] [symbol] ...
#
#       Defines a space-separated list of symbols that are used for line comments, if any.  ex. "Line Comment: //".
#
#
#       > Block Comment[s]: [opening symbol] [closing symbol] [opening symbol] [closing symbol] ...
#
#       Defines a space-separated list of symbol pairs that are used for block comments, if any.  ex. "Block Comment: /* */".
#
#
#       > [Topic Type] Prototype Ender[s]: [symbol] [symbol] ...
#
#       When defined, Natural Docs will attempt to collect prototypes from the code following the specified <TopicType>.  It grabs
#       code until the first ender symbol or the next Natural Docs comment, and if it contains the topic name, it serves as its
#       prototype.  Use \n to specify a line break.  ex. "Function Prototype Enders: { ;", "Variable Prototype Enders: = ;".
#
#
#       > Line Extender: [symbol]
#
#       Defines the symbol that allows a prototype to span multiple lines if normally a line break would end it.
#
#
#       > Perl Package: [perl package]
#
#       Specifies the Perl package used to fine-tune the language behavior in ways too complex to do in this file.
#
#
#   Full Language Support Properties:
#
#       These attributes are only available for languages with full language support.
#
#
#       > Full Language Support: [perl package]
#
#       Specifies the Perl package that has the parsing routines necessary for full language support.
#



###############################################################################
# Group: File Functions


#
#   Function: Load
#
#   Loads both the master and the project version of <Languages.txt>.
#
sub Load
    {
    my $self = shift;

    # Hashrefs where the keys are all-lowercase extensions/shebang strings, and the values are arrayrefs of the languages
    # that defined them, earliest first, all lowercase.
    my %tempExtensions;
    my %tempShebangStrings;

    $self->LoadFile(1, \%tempExtensions, \%tempShebangStrings);  # Main

    if (!exists $languages{'shebang script'})
        {
        NaturalDocs::ConfigFile->AddError('You must define "Shebang Script" in the main languages file.');
        };

    if (NaturalDocs::ConfigFile->ErrorCount())
        {
        NaturalDocs::ConfigFile->PrintErrorsAndAnnotateFile();
        die 'There ' . (NaturalDocs::ConfigFile->ErrorCount() == 1 ? 'is an error' : 'are errors')
           . ' in ' . NaturalDocs::Project->MainLanguagesFile() . "\n";
        }


    $self->LoadFile(0, \%tempExtensions, \%tempShebangStrings);  # User

    if (NaturalDocs::ConfigFile->ErrorCount())
        {
        NaturalDocs::ConfigFile->PrintErrorsAndAnnotateFile();
        die 'There ' . (NaturalDocs::ConfigFile->ErrorCount() == 1 ? 'is an error' : 'are errors')
           . ' in ' . NaturalDocs::Project->UserLanguagesFile() . "\n";
        };


    # Convert the temp hashes into the real ones.

    while (my ($extension, $languages) = each %tempExtensions)
        {
        $extensions{$extension} = $languages->[-1];
        };
    while (my ($shebangString, $languages) = each %tempShebangStrings)
        {
        $shebangStrings{$shebangString} = $languages->[-1];
        };
    };


#
#   Function: LoadFile
#
#   Loads a particular version of <Languages.txt>.
#
#   Parameters:
#
#       isMain - Whether the file is the main file or not.
#       tempExtensions - A hashref where the keys are all-lowercase extensions, and the values are arrayrefs of the all-lowercase
#                                 names of the languages that defined them, earliest first.  It will be changed by this function.
#       tempShebangStrings - A hashref where the keys are all-lowercase shebang strings, and the values are arrayrefs of the
#                                        all-lowercase names of the languages that defined them, earliest first.  It will be changed by this
#                                        function.
#
sub LoadFile #(isMain, tempExtensions, tempShebangStrings)
    {
    my ($self, $isMain, $tempExtensions, $tempShebangStrings) = @_;

    my ($file, $status);

    if ($isMain)
        {
        $file = NaturalDocs::Project->MainLanguagesFile();
        $status = NaturalDocs::Project->MainLanguagesFileStatus();
        }
    else
        {
        $file = NaturalDocs::Project->UserLanguagesFile();
        $status = NaturalDocs::Project->UserLanguagesFileStatus();
        };


    my $version;

    # An array of properties for the current language.  Each entry is the three consecutive values ( lineNumber, keyword, value ).
    my @properties;

    if ($version = NaturalDocs::ConfigFile->Open($file))
        {
        # The format hasn't changed since the file was introduced.

        if ($status == ::FILE_CHANGED())
            {
            NaturalDocs::Project->ReparseEverything();
            NaturalDocs::SymbolTable->RebuildAllIndexes();  # Because the ignored prefixes could change.
            };

        my ($keyword, $value, $comment);

        while (($keyword, $value, $comment) = NaturalDocs::ConfigFile->GetLine())
            {
            $value .= $comment;
            $value =~ s/^ //;

            # Process previous properties.
            if (($keyword eq 'language' || $keyword eq 'alter language') && scalar @properties)
                {
                $self->ProcessProperties(\@properties, $tempExtensions, $tempShebangStrings);
                @properties = ( );
                };

            if ($keyword =~ /^ignored? extensions?$/)
                {
                $value =~ tr/.*//d;
                my @extensions = split(/ /, lc($value));

                foreach my $extension (@extensions)
                    {  delete $tempExtensions->{$extension};  };
                }
            else
                {
                push @properties, NaturalDocs::ConfigFile->LineNumber(), $keyword, $value;
                };
            };

        if (scalar @properties)
            {  $self->ProcessProperties(\@properties, $tempExtensions, $tempShebangStrings);  };
        }

    else # couldn't open file
        {
        if ($isMain)
            {  die "Couldn't open languages file " . $file . "\n";  };
        };
    };


#
#   Function: ProcessProperties
#
#   Processes an array of language properties from <Languages.txt>.
#
#   Parameters:
#
#       properties - An arrayref of properties where each entry is the three consecutive values ( lineNumber, keyword, value ).
#                         It must start with the Language or Alter Language property.
#       tempExtensions - A hashref where the keys are all-lowercase extensions, and the values are arrayrefs of the all-lowercase
#                                 names of the languages that defined them, earliest first.  It will be changed by this function.
#       tempShebangStrings - A hashref where the keys are all-lowercase shebang strings, and the values are arrayrefs of the
#                                        all-lowercase names of the languages that defined them, earliest first.  It will be changed by this
#                                        function.
#
sub ProcessProperties #(properties, tempExtensions, tempShebangStrings)
    {
    my ($self, $properties, $tempExtensions, $tempShebangStrings) = @_;


    # First validate the name and check whether the language has full support.

    my $language;
    my $fullLanguageSupport;
    my ($lineNumber, $languageKeyword, $languageName) = @$properties[0..2];
    my $lcLanguageName = lc($languageName);
    my ($keyword, $value);

    if ($languageKeyword eq 'alter language')
        {
        $language = $languages{$lcLanguageName};

        if (!defined $language)
            {
            NaturalDocs::ConfigFile->AddError('The language ' . $languageName . ' is not defined.', $lineNumber);
            return;
            }
        else
            {
            $fullLanguageSupport = (!$language->isa('NaturalDocs::Languages::Simple'));
            };
        }

    else # ($languageKeyword eq 'language')
        {
        if (exists $languages{$lcLanguageName})
            {
            NaturalDocs::ConfigFile->AddError('The language ' . $value . ' is already defined.  Use "Alter Language" if you want '
                                                             . 'to override its settings.', $lineNumber);
            return;
            };

        for (my $i = 3; $i < scalar @$properties; $i += 3)
            {
            ($lineNumber, $keyword, $value) = @$properties[$i..$i+2];

            if ($keyword eq 'full language support')
                {
                $fullLanguageSupport = 1;

                eval
                    {
                    $language = $value->New($languageName);
                    };
                if ($::EVAL_ERROR)
                    {
                    NaturalDocs::ConfigFile->AddError('Could not create ' . $value . ' object.', $lineNumber);
                    return;
                    };

                last;
                }

            elsif ($keyword eq 'perl package')
                {
                eval
                    {
                    $language = $value->New($languageName);
                    };
                if ($::EVAL_ERROR)
                    {
                    NaturalDocs::ConfigFile->AddError('Could not create ' . $value . ' object.', $lineNumber);
                    return;
                    };
                };
            };

        # If $language was not created by now, it's a generic basic support language.
        if (!defined $language)
            {  $language = NaturalDocs::Languages::Simple->New($languageName);  };

        $languages{$lcLanguageName} = $language;
        };


    # Decode the properties.

    for (my $i = 3; $i < scalar @$properties; $i += 3)
        {
        ($lineNumber, $keyword, $value) = @$properties[$i..$i+2];

        if ($keyword =~ /^(?:(add|replace) )?extensions?$/)
            {
            my $command = $1;


            # Remove old extensions.

            if (defined $language->Extensions() && $command eq 'replace')
                {
                foreach my $extension (@{$language->Extensions()})
                    {
                    if (exists $tempExtensions->{$extension})
                        {
                        my $languages = $tempExtensions->{$extension};
                        my $i = 0;

                        while ($i < scalar @$languages)
                            {
                            if ($languages->[$i] eq $lcLanguageName)
                                {  splice(@$languages, $i, 1);  }
                            else
                                {  $i++;  };
                            };

                        if (!scalar @$languages)
                            {  delete $tempExtensions->{$extension};  };
                        };
                    };
                };


            # Add new extensions.

            # Ignore stars and dots so people could use .ext or *.ext.
            $value =~ tr/*.//d;

            my @extensions = split(/ /, lc($value));

            foreach my $extension (@extensions)
                {
                if (!exists $tempExtensions->{$extension})
                    {  $tempExtensions->{$extension} = [ ];  };

                push @{$tempExtensions->{$extension}}, $lcLanguageName;
                };


            # Set the extensions for the language object.

            if (defined $language->Extensions())
                {
                if ($command eq 'add')
                    {  push @extensions, @{$language->Extensions()};  }
                elsif (!$command)
                    {
                    NaturalDocs::ConfigFile->AddError('You need to specify whether you are adding to or replacing the list of extensions.',
                                                                       $lineNumber);
                    };
                };

            $language->SetExtensions(\@extensions);
            }

        elsif ($keyword =~ /^(?:(add|replace) )?shebang strings?$/)
            {
            my $command = $1;


            # Remove old strings.

            if (defined $language->ShebangStrings() && $command eq 'replace')
                {
                foreach my $shebangString (@{$language->ShebangStrings()})
                    {
                    if (exists $tempShebangStrings->{$shebangString})
                        {
                        my $languages = $tempShebangStrings->{$shebangString};
                        my $i = 0;

                        while ($i < scalar @$languages)
                            {
                            if ($languages->[$i] eq $lcLanguageName)
                                {  splice(@$languages, $i, 1);  }
                            else
                                {  $i++;  };
                            };

                        if (!scalar @$languages)
                            {  delete $tempShebangStrings->{$shebangString};  };
                        };
                    };
                };


            # Add new strings.

            my @shebangStrings = split(/ /, lc($value));

            foreach my $shebangString (@shebangStrings)
                {
                if (!exists $tempShebangStrings->{$shebangString})
                    {  $tempShebangStrings->{$shebangString} = [ ];  };

                push @{$tempShebangStrings->{$shebangString}}, $lcLanguageName;
                };


            # Set the strings for the language object.

            if (defined $language->ShebangStrings())
                {
                if ($command eq 'add')
                    {  push @shebangStrings, @{$language->ShebangStrings()};  }
                elsif (!$command)
                    {
                    NaturalDocs::ConfigFile->AddError('You need to specify whether you are adding to or replacing the list of shebang '
                                                                     . 'strings.', $lineNumber);
                    };
                };

            $language->SetShebangStrings(\@shebangStrings);
            }

        elsif ($keyword eq 'package separator')
            {
            $language->SetPackageSeparator($value);
            }

        elsif ($keyword =~ /^(?:(add|replace) )?ignored? (?:(.+) )?prefix(?:es)? in index$/)
            {
            my ($command, $topicName) = ($1, $2);
            my $topicType;

            if ($topicName)
                {
                if (!( ($topicType, undef) = NaturalDocs::Topics->NameInfo($topicName) ))
                    {
                    NaturalDocs::ConfigFile->AddError($topicName . ' is not a defined topic type.', $lineNumber);
                    };
                }
            else
                {  $topicType = ::TOPIC_GENERAL();  };

            if ($topicType)
                {
                my @prefixes;

                if (defined $language->IgnoredPrefixesFor($topicType))
                    {
                    if ($command eq 'add')
                        {  @prefixes = @{$language->IgnoredPrefixesFor($topicType)};  }
                    elsif (!$command)
                        {
                        NaturalDocs::ConfigFile->AddError('You need to specify whether you are adding to or replacing the list of '
                                                                         . 'ignored prefixes.', $lineNumber);
                        };
                    };

                push @prefixes, split(/ /, $value);
                $language->SetIgnoredPrefixesFor($topicType, \@prefixes);
                };
            }

        elsif ($keyword eq 'full language support' || $keyword eq 'perl package')
            {
            if ($languageKeyword eq 'alter language')
                {
                NaturalDocs::ConfigFile->AddError('You cannot use ' . $keyword . ' with Alter Language.', $lineNumber);
                };
            # else ignore it.
            }

        elsif ($keyword =~ /^line comments?$/)
            {
            if ($fullLanguageSupport)
                {
                NaturalDocs::ConfigFile->AddError('You cannot define this property when using full language support.', $lineNumber);
                }
            else
                {
                my @symbols = split(/ /, $value);
                $language->SetLineCommentSymbols(\@symbols);
                };
            }

        elsif ($keyword =~ /^block comments?$/)
            {
            if ($fullLanguageSupport)
                {
                NaturalDocs::ConfigFile->AddError('You cannot define this property when using full language support.', $lineNumber);
                }
            else
                {
                my @symbols = split(/ /, $value);

                if ((scalar @symbols) % 2 == 0)
                    {  $language->SetBlockCommentSymbols(\@symbols);  }
                else
                    {  NaturalDocs::ConfigFile->AddError('Block comment symbols must appear in pairs.', $lineNumber);  };
                };
            }

        elsif ($keyword =~ /^(?:(.+) )?prototype enders?$/)
            {
            if ($fullLanguageSupport)
                {
                NaturalDocs::ConfigFile->AddError('You cannot define this property when using full language support.', $lineNumber);
                }
            else
                {
                my $topicName = $1;
                my $topicType;

                if ($topicName)
                    {
                    if (!( ($topicType, undef) = NaturalDocs::Topics->NameInfo($topicName) ))
                        {
                        NaturalDocs::ConfigFile->AddError($topicName . ' is not a defined topic type.', $lineNumber);
                        };
                    }
                else
                    {  $topicType = ::TOPIC_GENERAL();  };

                if ($topicType)
                    {
                    $value =~ s/\\n/\n/g;
                    my @symbols = split(/ /, $value);
                    $language->SetPrototypeEndersFor($topicType, \@symbols);
                    };
                };
            }

        elsif ($keyword eq 'line extender')
            {
            if ($fullLanguageSupport)
                {
                NaturalDocs::ConfigFile->AddError('You cannot define this property when using full language support.', $lineNumber);
                }
            else
                {
                $language->SetLineExtender($value);
                };
            }

        else
            {
            NaturalDocs::ConfigFile->AddError($keyword . ' is not a valid keyword.', $lineNumber);
            };
        };
    };


#
#   Function: Save
#
#   Saves the main and user versions of <Languages.txt>.
#
sub Save
    {
    my $self = shift;

    $self->SaveFile(1); # Main
    $self->SaveFile(0); # User
    };


#
#   Function: SaveFile
#
#   Saves a particular version of <Topics.txt>.
#
#   Parameters:
#
#       isMain - Whether the file is the main file or not.
#
sub SaveFile #(isMain)
    {
    my ($self, $isMain) = @_;

    my $file;

    if ($isMain)
        {
        if (NaturalDocs::Project->MainLanguagesFileStatus() == ::FILE_SAME())
            {  return;  };
        $file = NaturalDocs::Project->MainLanguagesFile();
        }
    else
        {
        if (NaturalDocs::Project->UserLanguagesFileStatus() == ::FILE_SAME())
            {  return;  };
        $file = NaturalDocs::Project->UserLanguagesFile();
        };


    # Array of segments, with each being groups of three consecutive entries.  The first is the keyword ('language', 'alter language',
    # or 'ignore extensions'), the second is the value, and the third is a hashref of all the properties.
    # - For properties that can accept a topic type, the property values are hashrefs mapping topic types to the values.
    # - For properties that can accept 'add' or 'replace', there is an additional property ending in 'command' that stores it.
    # - For properties that can accept both, the 'command' thing is applied to the topic types rather than the properties.
    my @segments;

    my $currentProperties;

    if (NaturalDocs::ConfigFile->Open($file))
        {
        # We can assume the file is valid.

        while (my ($keyword, $value, $comment) = NaturalDocs::ConfigFile->GetLine())
            {
            $value .= $comment;
            $value =~ s/^ //;

            if ($keyword eq 'language')
                {
                $currentProperties = { };
                push @segments, 'language', $value, $currentProperties;
                }

            elsif ($keyword eq 'alter language')
                {
                $currentProperties = { };
                push @segments, 'alter language', $languages{lc($value)}->Name(), $currentProperties;
                }

            elsif ($keyword =~ /^ignored? extensions?$/)
                {
                push @segments, 'ignore extensions', $value, undef;
                }

            elsif ($keyword eq 'package separator' || $keyword eq 'full language support' || $keyword eq 'perl package' ||
                    $keyword eq 'line extender')
                {
                $currentProperties->{$keyword} = $value;
                }

            elsif ($keyword =~ /^line comments?$/)
                {
                $currentProperties->{'line comments'} = $value;
                }
            elsif ($keyword =~ /^block comments?$/)
                {
                $currentProperties->{'block comments'} = $value;
                }

            elsif ($keyword =~ /^(?:(add|replace) )?extensions?$/)
                {
                my $command = $1;

                if ($command eq 'add' && exists $currentProperties->{'extensions'})
                    {  $currentProperties->{'extensions'} .= ' ' . $value;  }
                else
                    {
                    $currentProperties->{'extensions'} = $value;
                    $currentProperties->{'extensions command'} = $command;
                    };
                }

            elsif ($keyword =~ /^(?:(add|replace) )?shebang strings?$/)
                {
                my $command = $1;

                if ($command eq 'add' && exists $currentProperties->{'shebang strings'})
                    {  $currentProperties->{'shebang strings'} .= ' ' . $value;  }
                else
                    {
                    $currentProperties->{'shebang strings'} = $value;
                    $currentProperties->{'shebang strings command'} = $command;
                    };
                }

            elsif ($keyword =~ /^(?:(.+) )?prototype enders?$/)
                {
                my $topicName = $1;
                my $topicType;

                if ($topicName)
                    {  ($topicType, undef) = NaturalDocs::Topics->NameInfo($topicName);  }
                else
                    {  $topicType = ::TOPIC_GENERAL();  };

                my $currentTypeProperties = $currentProperties->{'prototype enders'};

                if (!defined $currentTypeProperties)
                    {
                    $currentTypeProperties = { };
                    $currentProperties->{'prototype enders'} = $currentTypeProperties;
                    };

                $currentTypeProperties->{$topicType} = $value;
                }

            elsif ($keyword =~ /^(?:(add|replace) )?ignored? (?:(.+) )?prefix(?:es)? in index$/)
                {
                my ($command, $topicName) = ($1, $2);
                my $topicType;

                if ($topicName)
                    {  ($topicType, undef) = NaturalDocs::Topics->NameInfo($topicName);  }
                else
                    {  $topicType = ::TOPIC_GENERAL();  };

                my $currentTypeProperties = $currentProperties->{'ignored prefixes in index'};

                if (!defined $currentTypeProperties)
                    {
                    $currentTypeProperties = { };
                    $currentProperties->{'ignored prefixes in index'} = $currentTypeProperties;
                    };

                if ($command eq 'add' && exists $currentTypeProperties->{$topicType})
                    {  $currentTypeProperties->{$topicType} .= ' ' . $value;  }
                else
                    {
                    $currentTypeProperties->{$topicType} = $value;
                    $currentTypeProperties->{$topicType . ' command'} = $command;
                    };
                };
            };

        NaturalDocs::ConfigFile->Close();
        };


    open(FH_LANGUAGES, '>' . $file) or die "Couldn't save " . $file;

    print FH_LANGUAGES 'Format: ' . NaturalDocs::Settings->TextAppVersion() . "\n\n";

    # Remember the 80 character limit.

    if ($isMain)
        {
        print FH_LANGUAGES
"# This is the main Natural Docs languages file.  If you change anything here,
# it will apply to EVERY PROJECT you use Natural Docs on.  If you'd like to
# change something for just one project, edit the Languages.txt in its project
# directory instead.\n";
        }
    else
        {
        print FH_LANGUAGES
"# This is the Natural Docs languages file for this project.  If you change
# anything here, it will apply to THIS PROJECT ONLY.  If you'd like to change
# something for all your projects, edit the Languages.txt in Natural Docs'
# Config directory instead.\n";
        };

    print FH_LANGUAGES
    "\n" .
"# Also, if you add something that you think would be useful to other developers
# and should be included in Natural Docs by default, please e-mail it to
# languages [at] naturaldocs [dot] org.


###############################################################################
#
#   Syntax
#
#   Unlike other Natural Docs configuration files, in this file all comments
#   MUST be alone on a line.  Some languages deal with the # character, so you
#   cannot put comments on the same line as content.
#
###############################################################################
#
#   Ignore Extensions: [extension] [extension] ...
#
#   Causes the listed file extensions to be ignored, even if they were
#   previously defined to be part of a language.  The list is
#   space-separated.  ex. \"Ignore Extensions: cvs txt\"
#
#
#   Language: [name]
#
#   Defines a new language.  Its name can use any characters.
#
#   The languages \"Text File\" and \"Shebang Script\" have special meanings.
#   Text files are treated like one big comment and don't have comment symbols.
#   Shebang scripts have their language determined by the shebang string
#   instead of the extension and include files with no extension.
#
#
#   Alter Language: [name]
#
#   Alters an existing language so you can override its settings.  Note that if
#   a property has an Add/Replace form and that property has already been
#   defined, you have to specify whether you're adding to the list or replacing
#   it.  Otherwise assume you're replacing the value.
#
#
###############################################################################
#
#   Language Properties
#
###############################################################################
#
#   Extensions: [extension] [extension] ...
#   [Add/Replace] Extensions: [extension] [extension] ...
#
#   Defines the file extensions for the language's source files.  The list is
#   space-separated.  ex. \"Extensions: c cpp\".  You can use extensions that
#   were previously used by another language to redefine them.
#
#
#   Shebang Strings: [string] [string] ...
#   [Add/Replace] Shebang Strings: [string] [string] ...
#
#   Defines a list of strings that can appear in the shebang (#!) line to
#   designate that it's part of the language.  They can appear anywhere in the
#   line, so \"php\" will work for \"#!/user/bin/php4\".  You can use strings
#   that were previously used by another language to redefine them.
#
#
#   Package Separator: [symbol]
#
#   Defines the default package separator symbol, such as . or ::.  This is
#   for presentation only and will not affect how Natural Docs links are
#   parsed.  The default is a dot.
#
#
#   Ignore Prefixes in Index: [prefix] [prefix] ...
#   [Add/Replace] Ignored Prefixes in Index: [prefix] [prefix] ...
#
#   Ignore [Topic Type] Prefixes in Index: [prefix] [prefix] ...
#   [Add/Replace] Ignored [Topic Type] Prefixes in Index: [prefix] [prefix] ...
#
#   Specifies prefixes that should be ignored when sorting symbols in an
#   index.  Can be specified in general or for a specific topic type.  The
#   prefixes will still appear, the symbols will just be sorted as if they're
#   not there.  For example, specifying \"ADO_\" for functions will mean that
#   \"ADO_DoSomething\" will appear under D instead of A.
#
#
###############################################################################
#
#   Basic Language Support Properties
#
#   These properties are only available for languages with basic language
#   support.
#
###############################################################################
#
#   Line Comments: [symbol] [symbol] ...
#
#   Defines a space-separated list of symbols that are used for line comments,
#   if any.  ex. \"Line Comments: //\".
#
#
#   Block Comments: [opening sym] [closing sym] [opening sym] [closing sym] ...
#
#   Defines a space-separated list of symbol pairs that are used for block
#   comments, if any.  ex. \"Block Comments: /* */\".
#
#
#   [Topic Type] Prototype Enders: [symbol] [symbol] ...
#
#   When defined, Natural Docs will attempt to get a prototype from the code
#   immediately following the specified topic type.  It grabs code until the
#   first ender symbol or the next Natural Docs comment, and if it contains the
#   topic name, it serves as its prototype.  Use \\n to specify a line break.
#   ex. \"Function Prototype Enders: { ;\", \"Variable Prototype Enders: = ;\".
#
#
#   Line Extender: [symbol]
#
#   Defines the symbol that allows a prototype to span multiple lines if
#   normally a line break would end it.
#
#
#   Perl Package: [perl package]
#
#   Specifies the Perl package used to fine-tune the language behavior in ways
#   too complex to do in this file.
#
#
###############################################################################
#
#   Full Language Support Properties:
#
#   These properties are only available for languages with full language
#   support.
#
###############################################################################
#
#   Full Language Support: [perl package]
#
#   Specifies the Perl package that has the parsing routines necessary for full
#   language support.
#
#
###############################################################################\n";

    if ($isMain)
        {
        print FH_LANGUAGES "\n"
        . "# The language \"Shebang Script\" MUST be defined in this file.\n";
        };

    my @topicTypeOrder = ( ::TOPIC_GENERAL(), ::TOPIC_CLASS(), ::TOPIC_FUNCTION(), ::TOPIC_VARIABLE(),
                                         ::TOPIC_PROPERTY(), ::TOPIC_TYPE(), ::TOPIC_CONSTANT() );

    for (my $i = 0; $i < scalar @segments; $i += 3)
        {
        my ($keyword, $name, $properties) = @segments[$i..$i+2];

        print FH_LANGUAGES "\n\n";

        if ($keyword eq 'ignore extensions')
            {
            my @extensions = split(/ /, $name, 2);

            if (scalar @extensions == 1)
                {  print FH_LANGUAGES 'Ignore Extension: ';  }
            else
                {  print FH_LANGUAGES 'Ignore Extensions: ';  };

            print FH_LANGUAGES $name . "\n";
            }
        else # 'language' or 'alter language'
            {
            if ($keyword eq 'language')
                {  print FH_LANGUAGES 'Language: ' . $name . "\n\n";  }
            else
                {  print FH_LANGUAGES 'Alter Language: ' . $name . "\n\n";  };

            if (exists $properties->{'extensions'})
                {
                print FH_LANGUAGES '   ';

                if ($properties->{'extensions command'})
                    {  print FH_LANGUAGES ucfirst($properties->{'extensions command'}) . ' ';  };

                my @extensions = split(/ /, $properties->{'extensions'}, 2);

                if (scalar @extensions == 1)
                    {  print FH_LANGUAGES 'Extension: ';  }
                else
                    {  print FH_LANGUAGES 'Extensions: ';  };

                print FH_LANGUAGES lc($properties->{'extensions'}) . "\n";
                };

            if (exists $properties->{'shebang strings'})
                {
                print FH_LANGUAGES '   ';

                if ($properties->{'shebang strings command'})
                    {  print FH_LANGUAGES ucfirst($properties->{'shebang strings command'}) . ' ';  };

                my @shebangStrings = split(/ /, $properties->{'shebang strings'}, 2);

                if (scalar @shebangStrings == 1)
                    {  print FH_LANGUAGES 'Shebang String: ';  }
                else
                    {  print FH_LANGUAGES 'Shebang Strings: ';  };

                print FH_LANGUAGES lc($properties->{'shebang strings'}) . "\n";
                };

            if (exists $properties->{'ignored prefixes in index'})
                {
                my $topicTypePrefixes = $properties->{'ignored prefixes in index'};

                my %usedTopicTypes;
                my @topicTypes = ( @topicTypeOrder, keys %$topicTypePrefixes );

                foreach my $topicType (@topicTypes)
                    {
                    if ($topicType !~ / command$/ &&
                        exists $topicTypePrefixes->{$topicType} &&
                        !exists $usedTopicTypes{$topicType})
                        {
                        print FH_LANGUAGES '   ';

                        if ($topicTypePrefixes->{$topicType . ' command'})
                            {  print FH_LANGUAGES ucfirst($topicTypePrefixes->{$topicType . ' command'}) . ' Ignored ';  }
                        else
                            {  print FH_LANGUAGES 'Ignore ';  };

                        if ($topicType ne ::TOPIC_GENERAL())
                            {  print FH_LANGUAGES NaturalDocs::Topics->TypeInfo($topicType)->Name() . ' ';  };

                        my @prefixes = split(/ /, $topicTypePrefixes->{$topicType}, 2);

                        if (scalar @prefixes == 1)
                            {  print FH_LANGUAGES 'Prefix in Index: ';  }
                        else
                            {  print FH_LANGUAGES 'Prefixes in Index: ';  };

                        print FH_LANGUAGES $topicTypePrefixes->{$topicType} . "\n";

                        $usedTopicTypes{$topicType} = 1;
                        };
                    };
                };

            if (exists $properties->{'line comments'})
                {
                my @comments = split(/ /, $properties->{'line comments'}, 2);

                if (scalar @comments == 1)
                    {  print FH_LANGUAGES '   Line Comment: ';  }
                else
                    {  print FH_LANGUAGES '   Line Comments: ';  };

                print FH_LANGUAGES $properties->{'line comments'} . "\n";
                };

            if (exists $properties->{'block comments'})
                {
                my @comments = split(/ /, $properties->{'block comments'}, 3);

                if (scalar @comments == 2)
                    {  print FH_LANGUAGES '   Block Comment: ';  }
                else
                    {  print FH_LANGUAGES '   Block Comments: ';  };

                print FH_LANGUAGES $properties->{'block comments'} . "\n";
                };

            if (exists $properties->{'package separator'})
                {
                print FH_LANGUAGES '   Package Separator: ' . $properties->{'package separator'} . "\n";
                };

            if (exists $properties->{'prototype enders'})
                {
                my $topicTypeEnders = $properties->{'prototype enders'};

                my %usedTopicTypes;
                my @topicTypes = ( @topicTypeOrder, keys %$topicTypeEnders );

                foreach my $topicType (@topicTypes)
                    {
                    if ($topicType !~ / command$/ &&
                        exists $topicTypeEnders->{$topicType} &&
                        !exists $usedTopicTypes{$topicType})
                        {
                        print FH_LANGUAGES '   ';

                        if ($topicType ne ::TOPIC_GENERAL())
                            {  print FH_LANGUAGES NaturalDocs::Topics->TypeInfo($topicType)->Name() . ' ';  };

                        my @enders = split(/ /, $topicTypeEnders->{$topicType}, 2);

                        if (scalar @enders == 1)
                            {  print FH_LANGUAGES 'Prototype Ender: ';  }
                        else
                            {  print FH_LANGUAGES 'Prototype Enders: ';  };

                        print FH_LANGUAGES $topicTypeEnders->{$topicType} . "\n";

                        $usedTopicTypes{$topicType} = 1;
                        };
                    };
                };

            if (exists $properties->{'line extender'})
                {
                print FH_LANGUAGES '   Line Extender: ' . $properties->{'line extender'} . "\n";
                };

            if (exists $properties->{'perl package'})
                {
                print FH_LANGUAGES '   Perl Package: ' . $properties->{'perl package'} . "\n";
                };

            if (exists $properties->{'full language support'})
                {
                print FH_LANGUAGES '   Full Language Support: ' . $properties->{'full language support'} . "\n";
                };
            };
        };

    close(FH_LANGUAGES);
    };



###############################################################################
# Group: Functions


#
#   Function: LanguageOf
#
#   Returns the language of the passed source file.
#
#   Parameters:
#
#       sourceFile - The source <FileName> to get the language of.
#
#   Returns:
#
#       A <NaturalDocs::Languages::Base>-derived object for the passed file, or undef if the file is not a recognized language.
#
sub LanguageOf #(sourceFile)
    {
    my ($self, $sourceFile) = @_;

    my $extension = NaturalDocs::File->ExtensionOf($sourceFile);
    if (defined $extension)
        {  $extension = lc($extension);  };

    my $languageName;

    if (!defined $extension)
        {  $languageName = 'Shebang Script';  }
    else
        {  $languageName = $extensions{$extension};  };

    if (defined $languageName)
        {
        if ($languageName eq 'Shebang Script')
            {
            if (exists $shebangFiles{$sourceFile})
                {
                if (defined $shebangFiles{$sourceFile})
                    {  return $languages{$shebangFiles{$sourceFile}};  }
                else
                    {  return undef;  };
                }

            else # (!exists $shebangFiles{$sourceFile})
                {
                my $shebangLine;

                open(SOURCEFILEHANDLE, '<' . $sourceFile) or die 'Could not open ' . $sourceFile;

                read(SOURCEFILEHANDLE, $shebangLine, 2);
                if ($shebangLine eq '#!')
                    {  $shebangLine = <SOURCEFILEHANDLE>;  }
                else
                    {  $shebangLine = undef;  };

                close (SOURCEFILEHANDLE);

                if (!defined $shebangLine)
                    {
                    $shebangFiles{$sourceFile} = undef;
                    return undef;
                    }
                else
                    {
                    $shebangLine = lc($shebangLine);

                    foreach my $shebangString (keys %shebangStrings)
                        {
                        if (index($shebangLine, $shebangString) != -1)
                            {
                            $shebangFiles{$sourceFile} = $shebangStrings{$shebangString};
                            return $languages{$shebangStrings{$shebangString}};
                            };
                        };

                    $shebangFiles{$sourceFile} = undef;
                    return undef;
                    };
                };
            }

        else # language name ne 'Shebang Script'
            {  return $languages{$languageName};  };
        }
    else # !defined $language
        {
        return undef;
        };
    };


#
#   Function: IsSupported
#
#   Returns whether the language of the passed file is supported.
#
#   Parameters:
#
#       file - The <FileName> to test.
#
#   Returns:
#
#       Whether the file's language is supported.
#
sub IsSupported #(file)
    {
    my ($self, $file) = @_;

    # This function used to be slightly more efficient than just testing if LanguageOf returns undef, but now that we support
    # shebangs, it's really not worth it.

    return (defined $self->LanguageOf($file));
    };


1;
