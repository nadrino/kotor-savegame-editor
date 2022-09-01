package Logger;

use strict;
use warnings;

use Exporter;
use Cwd;
use Win32::Console::ANSI;
use Term::ANSIColor;

our @ISA= qw( Exporter );

# these CAN be exported.
our @EXPORT_OK = qw(
  LogMessage
  LogFatal
  LogError
  LogAlert
  LogWarning
  LogInfo
  LogDebug
  LogTrace
);

# these are exported by default.
our @EXPORT = qw(
  LogMessage
  LogFatal
  LogError
  LogAlert
  LogWarning
  LogInfo
  LogDebug
  LogTrace
);

our $workingdir;
$workingdir = getcwd;
$workingdir =~ s#/#\\#g;

our $Logfile = "\\KSE_log.txt";
our $Errlog = "\\KSE_Errors.txt";


sub LogMessage{
  my $logLevel = shift;
  my $logMessage = shift;

  my ($sec,$min,$hour,$mday,$mon,$year)=localtime();
  my $logTime = sprintf("%04s/%02s/%02s %02s:%02s:%02s", $year+1900, $mon+1, $mday, $hour, $min, $sec);

  my $logLevelStr;
  my $logLevelFmt;
  if   ($logLevel == 0){ $logLevelStr = "[Fatal]"; $logLevelFmt = color("ON_BRIGHT_RED"); }
  elsif($logLevel == 1){ $logLevelStr = "[Error]"; $logLevelFmt = color("BRIGHT_RED"); }
  elsif($logLevel == 2){ $logLevelStr = "[Alert]"; $logLevelFmt = color("BRIGHT_MAGENTA"); }
  elsif($logLevel == 3){ $logLevelStr = "[Warn ]"; $logLevelFmt = color("BRIGHT_YELLOW"); }
  elsif($logLevel == 4){ $logLevelStr = "[Info ]"; $logLevelFmt = color("BRIGHT_GREEN");  }
  elsif($logLevel == 5){ $logLevelStr = "[Debug]"; $logLevelFmt = color("BRIGHT_BLUE"); }
  elsif($logLevel == 6){ $logLevelStr = "[Trace]"; $logLevelFmt = color("BRIGHT_CYAN"); }

  my $logStr = $logTime." ".$logLevelStr.": ".$logMessage."\n";

  open (LOG, ">>", $workingdir . "\\$Logfile");
  print LOG $logTime." ".$logLevelStr.": ".$logMessage."\n";
  close LOG;

  print $logTime." ".$logLevelFmt.$logLevelStr.color("RESET").": ".$logMessage."\n";

  return;
}

sub LogFatal{
  my $logMessage = shift;
  LogMessage(0, $logMessage);
  die "`Stopping after fatal error.";
}
sub LogError{
  my $logMessage = shift;
  LogMessage(1, $logMessage);
}
sub LogAlert{
  my $logMessage = shift;
  LogMessage(2, $logMessage);
}
sub LogWarning{
  my $logMessage = shift;
  LogMessage(3, $logMessage);
}
sub LogInfo{
  my $logMessage = shift;
  LogMessage(4, $logMessage);
}
sub LogDebug{
  my $logMessage = shift;
  LogMessage(5, $logMessage);
}
sub LogTrace{
  my $logMessage = shift;
  LogMessage(6, $logMessage);
}
