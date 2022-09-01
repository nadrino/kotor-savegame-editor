package Logger;

use strict;
use warnings;

use Exporter;
use Cwd;

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
  if   ($logLevel == 0){ $logLevelStr = "[Fatal]"; }
  elsif($logLevel == 1){ $logLevelStr = "[Error]"; }
  elsif($logLevel == 2){ $logLevelStr = "[Alert]"; }
  elsif($logLevel == 3){ $logLevelStr = "[Warn ]"; }
  elsif($logLevel == 4){ $logLevelStr = "[Info ]"; }
  elsif($logLevel == 5){ $logLevelStr = "[Debug]"; }
  elsif($logLevel == 6){ $logLevelStr = "[Trace]"; }

  my $logStr = $logTime." ".$logLevelStr.": ".$logMessage."\n";

  open (LOG, ">>", $workingdir . "\\$Logfile");
  print LOG $logStr;
  close LOG;

  print $logStr;

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
