package KseInitializer;

use warnings;
use strict;

use Logger;
use Cwd;



sub new {
  my $class = shift;
  my $mainWindowRef = shift;
  my $self = {
    k1_installed     => 0
    , k2_installed   => 0
    , tjm_installed  => 0
    , use_tsl_cloud  => 0
    , mainWindowRef  => $mainWindowRef
  };

  $self->{path}->{kotor} = "";
  $self->{path}->{kotor_save} = "";

  $self->{path}->{tsl} = "";
  $self->{path}->{tsl_save} = "";
  $self->{path}->{tsl_cloud} = "";

  $self->{path}->{tjm} = "";

  bless( $self, $class );
  return $self;
}

sub readConfigFile;
sub initKotor;
sub initKotor2;
sub writeConfigFile;

sub initialize(){
  my $self = shift;

  $self->readConfigFile();

  $self->{k1_installed} = $self->initKotor();
  $self->{k2_installed} = $self->initKotor2();

  if (-e $self->{path}->{tjm}."/saves") {
    #saves directory not found
    if(!(opendir SAVDIR3, $self->{path}->{tjm}."/saves")) {
      $self->{mainWindowRef}->messageBox(-title=>'Directory not found',
        -message=>'Could not find saves directory for TJM',-type=>'Ok');
      LogError ('KSE could not find saves directory for TJM.');
      $self->{tjm_installed}=0;
    }
    close SAVDIR3;
  }

  $self->writeConfigFile();

}

sub readConfigFile(){
  my $self=shift;

  my $workDir;
  $workDir = getcwd();
  $workDir =~ s#/#\\#g;

  if(-e "$workDir/KSE.ini") {
    LogInfo("Reading KSE.ini...");
    open INI, "<", "$workDir/KSE.ini";

    my $line = undef;
    while(<INI>){
      $line = $_;
      if($line =~ /K1_Path=(.*)/)          { $self->{path}->{kotor}     = $1; }
      if($line =~ /K1_SavePath=(.*)/)      { $self->{path}->{kotor_save}= $1; }

      if($line =~ /K2_Path=(.*)/)          { $self->{path}->{tsl}       = $1; }
      if($line =~ /K2_SavePath=(.*)/)      { $self->{path}->{tsl_save}  = $1; }
      if($line =~ /K2_SavePathCloud=(.*)/) { $self->{path}->{tsl_cloud} = $1; }

      if($line =~ /TJM_Path=(.*)/)         { $self->{path}->{tjm}       = $1; }
    }
    close INI;
  }
  else{
    LogAlert("Could not find/open config file: $workDir/KSE.ini");
  }
}

sub initKotor{
  my $self = shift;

  LogWarning "Looking for KotOR game and saves folder...";

  unless( -e "$self->{path}->{kotor}/chitin.key" ){
    LogError "Could not find KotOR game files: $self->{path}->{kotor}/chitin.key";
    return 0;
  }
  LogInfo "Found KotOR game files at $self->{path}->{kotor}";

  # by default
  if ( $self->{path}->{kotor_save} eq "" ){ $self->{path}->{kotor_save} = $self->{path}->{kotor}."\\saves"; }

  unless (opendir SAVDIR, $self->{path}->{kotor_save}) {
    #saves directory not found
    $self->{mainWindowRef}->messageBox(-title=>'Directory not found',
      -message=>'Could not find saves directory for KotOR1',-type=>'Ok');
    LogError ('KSE could not find saves directory for KotOR1.' . "\n");
    close SAVDIR;
    return 0;
  }
  close SAVDIR;

  # at this point, everything should be fine.
  LogInfo "Found KotOR game saves at $self->{path}->{kotor_save}";
  return 1;
}

sub initKotor2{
  my $self = shift;

  LogWarning "Looking for KotOR2 game and saves folder...";

  # Game folder
  unless( -e $self->{path}->{tsl}."/chitin.key" ){

    LogWarning "TSL not found. Attempt using AppData info...";
    my $appdata_obj = MyAppData->new();
    my $appdata = $appdata_obj->getappdata();

    if( -e $appdata . "/SWKotOR2/chitin.key" ){
      $self->{path}->{tsl} = $appdata . "/SWKotOR2";
      LogInfo "Found with appdata: $self->{path}->{tsl}";
    }
    else{
      my $browsed_path = "";

      # LogInfo "Could not find TSL game folder. Asking user...";
      # unless ($browsed_path=BrowseForFolder('Locate TSL installation directory')) {
      #     LogError "Path not specified.";
      #     return 0;
      # }

      if( -e $browsed_path."/chitin.key" ){ $self->{path}->{tsl} = $browsed_path; }
      else{
        LogError "Kotor2 path not found.";
        return 0;
      }
    }

  }
  LogInfo "Found KotOR2 game files at $self->{path}->{tsl}";

  # Save folder
  my $tslSavesFound = 0;
  if( $self->{path}->{tsl_save} eq "" ){
    $self->{path}->{tsl_save} = $self->{path}->{tsl}."\\Saves";
  }
  unless( opendir SAVDIR, $self->{path}->{tsl_save} ){ LogError "KotOR2 game saves not found at: $self->{path}->{tsl_save}"; }
  else{ LogInfo "Found KotOR2 game saves at $self->{path}->{tsl_save}"; $tslSavesFound = 1; }
  close SAVDIR;

  $self->{use_tsl_cloud} = 0;
  if( $self->{path}->{'tsl_cloud'} eq "" ){
    $self->{path}->{'tsl_cloud'} = $self->{path}->{tsl}."\\cloudsaves";
  }

  if( -e $self->{path}->{'tsl_cloud'}."\\steam_autocloud.vdf" ){
    my $cloudSaveBaseDir = $self->{path}->{'tsl_cloud'};
    if( opendir(CLOUDSAVEDIR, $cloudSaveBaseDir)){
      $self->{path}->{'tsl_cloud'} = (grep { !(/\.+$/) && -d } map {"$cloudSaveBaseDir\\$_"} readdir(CLOUDSAVEDIR))[0];
    }
    closedir(CLOUDSAVEDIR); # Release handle
  }

  if( opendir CLOUDSAVEDIR, $self->{path}->{'tsl_cloud'} ){
    LogInfo "Found KotOR2 game cloud saves at $self->{path}->{'tsl_cloud'}";
    $self->{use_tsl_cloud} = 1;
  }
  else{ $self->{use_tsl_cloud} = 0; }
  closedir(CLOUDSAVEDIR);

  # # Failed to locate either saves directory, alert the user
  if($tslSavesFound == 0 && $self->{use_tsl_cloud} == 0) {
    $self->{mainWindowRef}->messageBox(-title=>'Directory not found',
      -message=>'Could not find saves or Cloud saves for KotOR2',
      -type=>'Ok');

    LogError('KSE failed to find the saves or Cloud saves for KotOR2');
    return 0;
  }

  return 1;
}

sub writeConfigFile(){
  my $self = shift;

  my $workDir;
  $workDir = getcwd();
  $workDir =~ s#/#\\#g;

  open INI, ">", "$workDir/KSE.ini";

  print INI "[Path Definition]\n";
  print INI "K1_Path=$self->{path}->{kotor}\n";
  print INI "K1_SavePath=$self->{path}->{kotor_save}\n";
  print INI "K2_Path=$self->{path}->{tsl}\n";
  print INI "K2_SavePath=$self->{path}->{tsl_save}\n";
  print INI "K2_SavePathCloud=$self->{path}->{tsl_cloud}\n";
  print INI "TJM_Path=undef\n";

  close INI;
}

1;
