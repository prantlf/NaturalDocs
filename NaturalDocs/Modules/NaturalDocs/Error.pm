###############################################################################
#
#   Package: NaturalDocs::Error
#
###############################################################################
#
#   Manages all aspects of error handling in Natural Docs.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright � 2003-2010 Greg Valure
# Natural Docs is licensed under version 3 of the GNU Affero General Public License (AGPL)
# Refer to License.txt for the complete details

use strict;
use integer;

$SIG{'__DIE__'} = \&NaturalDocs::Error::CatchDeath;


package NaturalDocs::Error;


###############################################################################
# Group: Variables


#
#   handle: FH_CRASHREPORT
#   The filehandle used for generating crash reports.
#


#
#   var: stackTrace
#   The stack trace generated by <CatchDeath()>.
#
my $stackTrace;


#
#   var: softDeath
#   Whether the program exited using <SoftDeath()>.
#
my $softDeath;


#
#   var: currentAction
#   What Natural Docs was doing when it crashed.  This stores strings generated by functions like <OnStartParsing()>.
#
my $currentAction;


###############################################################################
# Group: Functions


#
#   Function: SoftDeath
#
#   Generates a "soft" death, which means the program exits like with Perl's die(), but no crash report will be generated.
#
#   Parameter:
#
#       message - The error message to die with.
#
sub SoftDeath #(message)
    {
    my ($self, $message) = @_;

    $softDeath = 1;
    if ($message !~ /\n$/)
        {  $message .= "\n";  };

    die $message;
    };


#
#   Function: OnStartParsing
#
#   Called whenever <NaturalDocs::Parser> starts parsing a source file.
#
sub OnStartParsing #(FileName file)
    {
    my ($self, $file) = @_;
    $currentAction = 'Parsing ' . $file;
    };


#
#   Function: OnEndParsing
#
#   Called whenever <NaturalDocs::Parser> is done parsing a source file.
#
sub OnEndParsing #(FileName file)
    {
    my ($self, $file) = @_;
    $currentAction = undef;
    };


#
#   Function: OnStartBuilding
#
#   Called whenever <NaturalDocs::Builder> starts building a source file.
#
sub OnStartBuilding #(FileName file)
    {
    my ($self, $file) = @_;
    $currentAction = 'Building ' . $file;
    };


#
#   Function: OnEndBuilding
#
#   Called whenever <NaturalDocs::Builder> is done building a source file.
#
sub OnEndBuilding #(FileName file)
    {
    my ($self, $file) = @_;
    $currentAction = undef;
    };


#
#   Function: HandleDeath
#
#   Should be called whenever Natural Docs dies out of execution.
#
sub HandleDeath
    {
    my $self = shift;

    my $reason = $::EVAL_ERROR;
    $reason =~ s/[\n\r]+$//;

    my $errorMessage =
         "\n"
         . "Natural Docs encountered the following error and was stopped:\n"
         . "\n"
         . "   " . $reason . "\n"
         . "   Cause: $? - $!\n"
         . "\n"

         . "You can get help at the following web site:\n"
         . "\n"
         . "   " . NaturalDocs::Settings->AppURL() . "\n"
         . "\n";

    if (!$softDeath)
        {
        my $crashReport = $self->GenerateCrashReport();

        if ($crashReport)
            {
            $errorMessage .=
             "If sending an error report, please include the information found in the\n"
             . "following file:\n"
             . "\n"
             . "   " . $crashReport . "\n"
             . "\n";
            }
        else
            {
            $errorMessage .=
             "If sending an error report, please include the following information:\n"
             . "\n"
             . "   Natural Docs version: " . NaturalDocs::Settings->TextAppVersion() . "\n"
             . "   Perl version: " . $self->PerlVersion() . " on " . $::OSNAME . "\n"
             . "\n";
             };
        };

    die $errorMessage;
    };


###############################################################################
# Group: Support Functions


#
#   Function: PerlVersion
#   Returns the current Perl version as a string.
#
sub PerlVersion
    {
    my $self = shift;

    my $perlVersion;

    if ($^V)
        {  $perlVersion = sprintf('%vd', $^V);  }
    if (!$perlVersion || substr($perlVersion, 0, 1) eq '%')
        {  $perlVersion = $];  };

    return $perlVersion;
    };


#
#   Function: GenerateCrashReport
#
#   Generates a report and returns the <FileName> it's located at.  Returns undef if it could not generate one.
#
sub GenerateCrashReport
    {
    my $self = shift;

    my $errorMessage = $::EVAL_ERROR;
    $errorMessage =~ s/[\r\n]+$//;

    my $reportDirectory = NaturalDocs::Settings->ProjectDirectory();

    if (!$reportDirectory || !-d $reportDirectory)
        {  return undef;  };

    my $file = NaturalDocs::File->JoinPaths($reportDirectory, 'LastCrash.txt');

    open(FH_CRASHREPORT, '>' . $file) or return undef;

    print FH_CRASHREPORT
    'Crash Message:' . "\n\n"
    . '   ' . $errorMessage . "\n\n";

    if ($currentAction)
        {
        print FH_CRASHREPORT
        'Current Action:' . "\n\n"
        . '   ' . $currentAction . "\n\n";
        };

    print FH_CRASHREPORT
    'Natural Docs version ' . NaturalDocs::Settings->TextAppVersion() . "\n"
    . 'Perl version ' . $self->PerlVersion . ' on ' . $::OSNAME . "\n\n"
    . 'Command Line:' . "\n\n"
    . '   ' . join(' ', @ARGV) . "\n\n";

    if ($stackTrace)
        {
        print FH_CRASHREPORT
        'Stack Trace:' . "\n\n"
        . $stackTrace;
        }
    else
        {
        print FH_CRASHREPORT
        'Stack Trace not available.' . "\n\n";
        };

    close(FH_CRASHREPORT);
    return $file;
    };


###############################################################################
# Group: Signal Handlers


#
#   Function: CatchDeath
#
#   Catches Perl die calls.
#
#   *IMPORTANT:* This function is a signal handler and should not be called manually.  Also, because of this, it does not have
#   a $self parameter.
#
#   Parameters:
#
#       message - The error message to die with.
#
sub CatchDeath #(message)
    {
    # No $self because it's a signal handler.
    my $message = shift;

    if (!$NaturalDocs::Error::softDeath)
        {
        my $i = 0;
        my ($lastPackage, $lastFile, $lastLine, $lastFunction);

        while (my ($package, $file, $line, $function) = caller($i))
            {
            if ($i != 0)
                {  $stackTrace .= ', called from' . "\n";  };

            $stackTrace .= '   ' . $function;

            if (defined $lastLine)
                {
                $stackTrace .= ', line ' . $lastLine;

                if ($function !~ /^NaturalDocs::/)
                    {  $stackTrace .= ' of ' . $lastFile;  };
                };

            ($lastPackage, $lastFile, $lastLine, $lastFunction) = ($package, $file, $line, $function);
            $i++;
            };
        };
    };


1;
