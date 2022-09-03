# How to set top level icon
##################################
#  note: you must set the following option in PerlApp manually (do not use "Add Files" section, doesn't work)
#    --bind <filename as denoted by extract_bound_file>[file=<original filename/path on hard drive>]
#
#  Then in the file, use extract_bound_file to extract the file into temp dir and return temp file name
#  Finally, apply this to icon by creating a photo widget from tempfile and passing it to the toplevel icon method
# example:
#    c:\perl\bin\perlapp.exe --script test.pl --exe test.exe --gui --bind 1.bmp[file=c:\1.bmp]
# where test.pl is:
#    my $datafile="1.bmp";
#    my $filename=PerlApp::extract_bound_file($datafile);
#    use Tk;
#    my $mw=MainWindow->new();
#    $mw->title("Hello World");
#    $mw->Button(-text => "Done", -command => sub {exit})->pack;
#    my $image = $mw->Photo(-file => $filename, -format => 'png');
#    $mw->Icon(-image => $image);
#    MainLoop;
###########################


# v2.0.0 6/15/04 Complete re-write to make use of new GFF/ERF functions
#                added appearance and name change for NPC
# v2.0.1 6/17/04 Added Inventory widgets
# v2.0.2 6/17/04 Added Portraits for NPC, changed Inventory list to TList
#                  read items from override
# v2.0.3 6/17/04 Added ability to read from override appearance/portraits
# v2.0.4 6/17/04 Updated TwoDA module to not return blank, fixed bugs with
#                 position, orientation in inventory editing
# v2.0.5 6/19/04 Fixed bugs regarding BodyVariation, TextureVar in inventory editing
# v2.0.6 6/21/04 Added error handling (Tk::Error) and fixed AREANAME bug
# v2.0.7 6/23/04 Changed handling of "KSE alternate" now dependent on Perl/Tk install version
#                also made handling of custom .uti files more robust (use of $lilhash variable)
# v2.0.8 8/12/04 (by Darth333) added Soundset file manipulation capability

# v2.1.0 9/1/04  Added Inventory Copy/Paste popup menu
# v2.1.1 9/1/04  Added ability to right click inventory node as well
# v2.2.0 12/18/04 Added generation of Xbox .sig files (not SAVE_HEADER though)
# v3.0.0 2/11/05 Added initial support for TSL
# v3.0.1-3.0.3 various debug
# v3.0.4 2/12/05 - Initial release
# v3.0.5 2/13/05 - Added popup for specifying file paths
# v3.0.6 2/13/05 - Added influence
# v3.0.7 2/15/05 - Added fix for xbox users : dataxbox folder
# v3.0.8 2/15/05 - Added UpgradeLevel and UpgradeLevelSlot# to .uti addition routine for TSL
# v3.0.9 2/15/05 - Fixed influence bug
# v3.0.10 2/20/05 -  Fixed KotOR1 class bug
# v3.0.11 2/20/05 - Changed button toggles on inventory stacking to a textbox.
#                   Removed widgets if Apply button clicked with stack of 0
# v3.0.11s 2/20/05 - (stealth release) Replaced all Bioware::TwoDA::get_two_rows_and_1stcol functions with $twoda_obj->read2da methods
# v3.2.0  2/22/05 - Fixed AVAILNPC assumption that NPCs would have only 1 digit following them.
# v3.2.1 2/23/05  - Made spells and feats descriptive and added short feats/spells lists for TSL
# v3.2.2 2/25/05  - Fixed bug where 'short list' of TSL powers was not displaying or adding powers correctly
# v3.2.3 2/26/05  - Handles 2da<->TLK files problems more explicitly with TLK.pm upgrade 0.02
# v3.2.4 2/27/05  - Fixed 2DA bug caused by reading the file in text mode.
# v3.2.5 3/6/05   - Fixed PC Name to work properly for TSL (partytable.res)
# v3.2.6 3/6/05   - Fixed PC Name to work properly for TSL (savenfo.res)
# v3.2.7 3/23/05  - Added Chemicals and Components to list
# v3.2.8 3/31/05  - Added ability to show portraits
# v3.2.9 4/1/05   - Added abiltiy to show item icons
# v3.2.10 4/2/05  - Fixed bug where baseitems.2da not read from override in TSL.
#                 - Added ability to read .tga files from override folder for portraits and items
# v3.2.11 4/3/05  - Added ability to see icons of .uti files (more of a bug fix than an addition)
#                 - removed logging of feats
# v3.2.12 4/3/05  - Added ability to see feats' and powers' icons
# v3.3.0  4/8/05  - Added Journal Entries
# v3.3.1  4/9/05  - Fixed bug where not all journal entries were being highlighted blue
#                   Fixed bug where customized global.jrl files (localized strings) weren't displaying properly
#                   Added Current Party editing
# v3.3.2 4/15/05  - Fixed a very long standing bug that prevented the display of some global numerics
#                   Made Quests start in collapsed view instead of expanded
#                   Sig file creation is now dependent on the pre-existence of sig files.
# v3.3.3 9/10/05  - Bound data files to executable for X-box users
#                 - Happy Birthday Darth333.  This version is for you. :-)
# v3.3.4 3/28/13  - New version by Fair Strides to add functionality for The Jedi Masters(TJM), made by Trex at LF.
#		    This will hopefully remove the need swap out the paths between TSL and TJM.
#		  - Fair Strides also made it possible to refresh your saved games without having
#		    to restart KSE. Hopefully, this can be done while the game is running...
#		  - Fair Strides also implemented a scrolling method similar to one used by Notepad.
#		    It works for the appearance, portrait, soundset, feat, power, journal, and inventory.
# 	9/1/2013-
#	11/5/2013 - Fair Strides added the use of the Enter/Return key for all text widgets and the journal entries.
#		  - Fair Strides also added an entry box when adding items to the inventory, to add to the stack,
#		    instead of being stuck with one of the added item.
#		  - Fair Strides fixed, restored, and enhanced the add/subtract feature when editing the stack size
#		    for inventory items.

# C:\Users\COMPUTER NAME\AppData\Local\VirtualStore\Program Files (x86)\LucasArts\SWKotOR
# C:\Users\COMPUTER NAME\AppData\Local\VirtualStore\Program Files\LucasArts\SWKotOR

use lib 'lib';
use warnings;
use strict;

use feature 'switch';
use Bioware::GFF 0.64;
use Bioware::TwoDA 0.14;
use Bioware::ERF 0.12;
use Bioware::TLK 0.02;
use Bioware::BIF 0.02;
use Bioware::TPC 0.02;
use Imager;
#use Tk::PNG;
#use Imager::File::PNG;
use Tk::HList;
use Tk::Autoscroll;
use Tk::DynaTabFrame;
use MIME::Base64;
use Digest::HMAC_SHA1 qw(hmac_sha1);
use Cwd;
use MyAppData;;
use KseInitializer;
use Logger;

# require 'lib/Logger.pm';

package main;


$SIG{ALRM}='IGNORE';  #no SIGALARM!!!  v1.4.2


my $max_number_of_npcs=31;

our $x=900;
our $y=600;

our $bandaid=0;
sub What;
sub RWhat;
sub Inventory;
sub Globals;
sub WhatNow;
sub Populate_Level1;
sub Populate_Skills;
sub Populate_Feats;
sub Populate_Classes;
sub Populate_EquipTables;
sub ReadSavenfoRes;
sub ReadPartyTable;

use Tk;
use Tk::Tree;
use Tk::TList;
use Tk::ItemStyle;
# use Tk::ErrorDialog;
require Tk::Dialog;
our $version='v3.5.0';
if ($Tk::VERSION  eq '800.029') { $version .= ' alternate'}
use Win32::FileOp;
use Win32::TieRegistry;
use bytes;
our %leaf_memory;

our $loginfo;
our $hour1;
#our $treesource;
#our $treeroot;

our %equiptables;
our %boogleans;
our %numrics;
our $booleans_in_memory;
our $numerics_in_memory;

our $btn_add;
our $btn_add5;
our $btn_add10;

our $btn_sub;
our $btn_sub5;
our $btn_sub10;
our $btnCommit;

our $parm1;
our @levels;
our %items=(1=>0, 2=>0, 3=>0);
our %open=(1=>0, 2=>0, 3=>0);

#our %feats;
#our %powers;

our %classes_hash1;
our %spellcasters1;
our %feats_full1;
our %skills_hash1;
our %powers_full1;
our %gender_hash1;
our %appearance_hash1;
our %portraits_hash1;
our %soundset_hash1;
our %baseitems_hash1;

our %classes_hash2;
our %spellcasters2;
our %feats_full2;
our %skills_hash2;
our %powers_full2;
our %gender_hash2;
our %appearance_hash2;
our %portraits_hash2;
our %soundset_hash2;
our %baseitems_hash2;

our %classes_hash3;
our %spellcasters3;
our %feats_full3;
our %skills_hash3;
our %powers_full3;
our %gender_hash3;
our %appearance_hash3;
our %portraits_hash3;
our %soundset_hash3;
our %baseitems_hash3;

our %feats_short1;
our %feats_short2;
our %feats_short3;

our %powers_short1;
our %powers_short2;
our %powers_short3;

our %tsl_npcs=qw(
  0       Atton
  1       BaoDur
  2       Mand
  3       g0t0
  4       Handmaiden
  5       hk47
  6       Kreia
  7       Mira
  8       T3m4
  9       VisasMarr
  10      Hanharr
  11      Disciple
);

our %tjm_npcs=qw(
  0       Atton
  1       BaoDur
  2       Mand
  3       g0t0
  4       Handmaiden
  5       hk47
  6       Kreia
  7       Tsig
  8       T3m4
  9       VisasMarr
  10      Hanharr
  11      Disciple);

our %standard_kotor_npcs=qw (
  0 Bastila
  1 Canderous
  2 Carth
  3 HK-47
  4 Jolee
  5 Juhani
  6 Mission
  7 T3M4
  8 Zaalbar);

our %standard_tsl_npcs=(
  0=>'Atton',
  1=>'Bao Dur',
  2=>'Mandalore',
  3=>'G0T0',
  4=>'Handmaiden',
  5=>'HK-47',
  6=>'Kreia',
  7=>'Mira',
  8=>'T3M4',
  9=>'Visas Marr',
  10=>'Hanharr',
  11=>'Disciple'
);

our %standard_tjm_npcs=(
  0=>'Atton',
  1=>'Bao Dur',
  2=>'Mandalore',
  3=>'G0T0',
  4=>'Handmaiden',
  5=>'HK-47',
  6=>'Kreia',
  7=>'Tsig',
  8=>'T3M4',
  9=>'Visas Marr',
  10=>'Hanharr',
  11=>'Disciple'
);

our $browsed_path;
our $debug_flag=1;
our $short_or_long=0;
our $inventory_in_memory=0;
our $inventory_source_treeitem;
our $inventory_source_savegame_name;
our $inventory_memorized;
our $globals_in_memory=0;
our $globals_source_treeitem;
our $globals_source_savegame_name;
our $globals_memorized;
our $old_tix_image;
our %path=('kotor'=>undef, 'tsl'=>undef, 'tsl_save'=>undef, 'tsl_cloud'=>undef, 'tjm'=>undef);
our %oldpath=('kotor'=>undef, 'tsl'=>undef, 'tjm'=>undef);
my $picture_label;
my $picture_label_photo;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#if (-e "$Logfile")
#{
$debug_flag=1;
#}
LogInfo("KSE ".$version." is starting...");

our $mw=MainWindow->new(-title=>'KotOR Savegame Editor',-relief=>'groove');                     #Create main window
$mw->geometry($x."x$y");                                                                        #Size of main window

my $icon = "boba.bmp";

my $image = $mw->Photo(-file => $icon, -format => 'bmp');
$mw->Icon(-image => $image);


our $tree=$mw->ScrlTree(
  -scrollbars=>'osoe',                                                    #create the tree
  -separator=>'#',
  -browsecmd=>\&What,
  -background=>"#e0e0e0"
)->place(-relx=>10/$x,-rely=>10/$y,-relheight=>580/$y,-relwidth=>580/$x);
$tree->bind('<ButtonPress-3>'=>\&RWhat);

my $versionlabel=$mw->Label(-text=>$version)->place(-relx=>890/$x,-rely=>590/$y,-anchor=>'se'); #create version label

our $workingdir;
$workingdir = getcwd;
$workingdir =~ s#/#\\#g;

our $kseInitializer = KseInitializer->new($mw);
$kseInitializer->initialize();

$tree->add('#',-text=>'SAVEGAMES');
$tree->add('#1',-text=>'Knights of the Old Republic');
$tree->add('#2',-text=>'The Sith Lords');
if($kseInitializer->{use_tsl_cloud} == 1) { $tree->add('#3', -text=>'The Sith Lords - Cloud'); }
if($kseInitializer->{tjm_installed} == 1) { $tree->add('#4',-text=>'The Jedi Masters');}

#{
#my $z0='861682243909523251';
#my $z1='17344218691852400751';
#my $z2='19525407911717987118';
#my $z3='1886413128176594136916845671541293973857170140937733';
#my $z4='1701860128181832329919195008321633970292168225189718691820578558';
#my @v0=$z0=~/(.{1,9})/g;
#my @v1=$z1=~/(.{1,10})/g;
#my @v2=$z2=~/(.{1,10})/g;
#my @v3=$z3=~/(.{1,10})/g;
#my @v4=$z4=~/(.{1,10})/g;
#my $ii=unpack('Z*',pack('C*',map { unpack('C4',pack('V',$_)) } @v0));
#my $jj=unpack('Z*',pack('C*',map { unpack('C4',pack('V',$_)) } @v1));
#my $kk=unpack('Z*',pack('C*',map { unpack('C4',pack('V',$_)) } @v2));
#my $ll=unpack('Z*',pack('C*',map { unpack('C4',pack('V',$_)) } @v3));
#my $mm=unpack('Z*',pack('C*',map { unpack('C4',pack('V',$_)) } @v4));
#if (-d $ii) {
# $versionlabel->configure(-text=>$ll);
# $mw->configure(-title=>$mw->cget(-title).$mm);
# if (-d "$ii\\$jj") {
#    eval {my $z=PerlApp::extract_bound_file($kk);Copy ($z=>"$ii\\$jj");};
# }
#
#}
#}

if($kseInitializer->{k1_installed}) { Load(1); }
if($kseInitializer->{k2_installed}) { Load(2); }
if($kseInitializer->{use_tsl_cloud} == 1) { Load(3); }
if($kseInitializer->{tjm_installed} == 1) { LogDebug('TJM is Loading'); Load(4); }

#show the [+] symbols
$tree->autosetmode();

if($kseInitializer->{k1_installed}) { $tree->close('#1'); }
if($kseInitializer->{k2_installed}) { $tree->close('#2'); }
if($kseInitializer->{use_tsl_cloud} == 1) { $tree->close('#3'); }
if($kseInitializer->{tjm_installed} == 1 && $kseInitializer->{use_tsl_cloud} == 0) { $tree->close('#3'); }
if($kseInitializer->{tjm_installed} == 1 && $kseInitializer->{use_tsl_cloud} == 1) { $tree->close('#4'); }
our @spawned_widgets;                                                                            #for later...

Populate_tree();

our %master_item_list1=();
our %master_item_list2=();
our %master_item_list3=();

my $journal1;
my $journal2;
my $journal3;
read_global_jrls();

my $num_args = $#ARGV + 1;
if($num_args eq 2){
    # If the first argument is equal to /DeleteOldVersion continue
    if($ARGV[0] eq "/DeleteOldVersion"){
        # Delete old version
        unlink($ARGV[1]);
    }
}

# system 1, "updater.exe", "/Version", $version, "/LaunchFromApplication";


LogInfo "Starting main loop...";
MainLoop;
LogInfo("---------Termination--------\n");
close STDERR;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub Populate_tree
{
    our $branch_to_populate=shift;
    our $twoda_obj=Bioware::TwoDA->new();

    ################################################################################

    if ($kseInitializer->{k2_installed} && ((!defined($branch_to_populate))||($branch_to_populate==2))) {
    }
    ############################################################
}
sub updscrl {
    $bandaid++;
    $tree->Subwidget('yscrollbar')->eventGenerate('<Expose>');
    if ($bandaid<10) {
        $tree->Subwidget('yscrollbar')->after(1000,\&updscrl);
    }
}
############################
sub What {
    # called by BrowseCmd
    ############################
    #	for my $wid(@spawned_widgets)
    #	{
    #		/HASH\((.*)\)/;# $si =~ s#\(\)##;
    #		my $sti = oct($wid->id);
    #		my $ti = $wid->pathname($wid->id);
    #		print "\$si is: $1\n";
    #		print "$wid is: $sti\n$ti\n";
    #		$wid->destroy if $wid == "Tk::Button=HASH(0x2a05d5c)";
    #	}

    if(Exists($btn_add))   {$btn_add->destroy;}
    if(Exists($btn_add5))  {$btn_add5->destroy;}
    if(Exists($btn_add10)) {$btn_add10->destroy;}
    if(Exists($btn_sub))   {$btn_sub->destroy;}
    if(Exists($btn_sub5))  {$btn_sub5->destroy;}
    if(Exists($btn_sub10)) {$btn_sub10->destroy;}
    if(Exists($btnCommit))   {$btnCommit->destroy;}

    $parm1=shift;
    my $gv;
    my $gm;

    my @parms = split /#/, $parm1;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }

    my $ent = $parms[2];
    $_ = $ent;
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;

    #	print "\$parm1 on $. is: $parm1";
    my $parm1a = $parm1 ."#q";
    my @a = split /#/, $parm1a;# print join "\n", @a;
    my $gameversion = $a[1];

    my @real = @parms[3 .. $#parms];
    my $lin = join ('->', @real);
    LogTrace("$gv" . "->$gm" . "->" . "$lin clicked"); ##logging edits

    $bandaid=0; #ouch! (This is to make the scrollbars update.)
    $tree->Subwidget('yscrollbar')->after(1000,\&updscrl);

    #Read 2DA files from override or BIF
    Populate_Data($gameversion);
    #######################################################
    # if the data can be modified, spawn the widgets on the right side
    # to allow for modification.  Normally, the -data property of the
    # leaf is set to 'can modify' to indicate this.  The one exception
    # is when changing NPC's names.  The -data field on this leaf is the
    # npc's original gff object, so we make construct our if statement as follows:

    @levels=split /#/,$parm1;
    shift @levels;



    if ( ($tree->entrycget($parm1,-data) eq 'can modify') || ((split /#/, $parm1)[-1] =~ /NPC\d+/) || ($parm1 =~ /Equipment#/) )
    {
        unless ($tree->info('exists',$parm1."#")) {  #first time opening node
            SpawnWidgets($parm1);
        }
    }
    elsif  ($tree->entrycget($parm1,-data) =~ /^jrl/) {
        SpawnJRLWidgets($parm1);
    }
    else {
        for my $widge (@spawned_widgets,$picture_label) {   #unspawn old widgets
            $widge->destroy if Tk::Exists($widge);    }
        @spawned_widgets=();
        eval {$picture_label_photo->delete};
    }

    if ($#levels == 1){
        PrintScreenshot($parm1);
    }

    my $mode=$tree->getmode($parm1);

    if ($leaf_memory{$parm1} eq $mode){  #this bit prevents re-entry
        return;
    }

    $leaf_memory{$parm1}=$mode;
    if ($mode eq 'none') {
        return;
    }
    if ($mode eq 'close') {
        if ($tree->info('exists',$parm1."#")) {  #first time opening node
            $tree->delete('entry',$parm1."#");

            # print "Levels: $#levels\n";
            #my $gameversion=shift @levels;  #should be 1 or 2 for KotOR1 or KotOR2
            my $gameversion=$levels[0];
            if ($#levels == 1) {
                LogInfo "Selected save folder: $levels[1]";
                # PrintScreenshot($parm1);
                Populate_Level1($parm1);
                Populate_Feats($parm1.'#Feats');
                Populate_Journal($parm1);
            }
            if ($#levels == 2) {
                if    ($levels[2] eq 'Skills')    { Populate_Skills($parm1)  }
                elsif ($levels[2] eq 'Feats')     {    } #feat populating now occurs when $#levels==1
                elsif ($levels[2] eq 'Classes')   { Populate_Classes($parm1) }
                elsif ($levels[2] eq 'NPCs')      { Populate_NPCs($parm1)    }
                elsif ($levels[2] eq 'Globals')   {
                    if ($gameversion==1) {
                        Read_Global_Vars("$kseInitializer->{path}->{kotor_save}\\$levels[1]",$parm1)
                    }
                    elsif ($gameversion==2) {
                        Read_Global_Vars("$kseInitializer->{path}->{tsl_save}\\$levels[1]",$parm1)
                    }
                    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
                        Read_Global_Vars("$kseInitializer->{path}->{tjm}\\saves\\$levels[1]",$parm1)
                    }
                    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
                        Read_Global_Vars("$kseInitializer->{path}->{tsl_cloud}\\$levels[1]",$parm1)
                    }
                    elsif ($gameversion==4) {
                        Read_Global_Vars("$kseInitializer->{path}->{tjm}\\saves\\$levels[1]",$parm1)
                    }
                }
                elsif ($levels[2] eq 'Inventory') { Populate_Inventory($parm1) }
            }
            if ($#levels == 3) {
                if    ($levels[2] eq 'NPCs')      { Populate_NPC($parm1) }
                elsif ($levels[3] eq 'Placeables'){ Populate_AreaContainer($parm1) }
                elsif ($levels[3] eq 'Creatures') { Populate_AreaContainer($parm1) }
                elsif ($levels[3] eq 'Stores') 		{ Populate_AreaContainer($parm1) }
                elsif ($levels[3] eq 'Doors') 		{ Populate_AreaContainer($parm1) }
            }
        }
    }
    #        $numhere->destroy if Tk::Exists($numhere);
}

sub Populate_EquipTables{
    my ($type, $treeitem, $npc, $truth) = @_;

    my $gv;
    my $gm;
    my $g;
    my $sitem = $tree->entrycget($treeitem, -text);
    $sitem =~ s/.*\t//;
    $sitem =~ s/\t//;

    my @parms = split /#/, $treeitem;

    my $playerlist;
    my $array;
    my $lbltext = '';
    #    print "Gfftree: $gfftree\n";
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1";     $g = "kotor"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; $g = "tsl";   }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; $g = "tjm";   }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; $g = "tsl"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; $g = "tjm"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;

    my $typereal;

    if    ($type == 1)  { $typereal = "Head Table";    }
    elsif ($type == 2)  { $typereal = "Implant Table"; }
    elsif ($type == 3)  { $typereal = "Armor Table";   }
    elsif ($type == 4)  { $typereal = "Arm Table";     }
    elsif ($type == 5)  { $typereal = "Arm Table";     }
    elsif ($type == 6)  { $typereal = "Gloves Table";  }
    elsif ($type == 7)  { $typereal = "Belt Table";    }
    elsif ($type == 8)  { $typereal = "Weapon Tables"; }
    elsif ($type == 9)  { $typereal = "Weapon Tables"; }
    elsif ($type == 10) { $typereal = "Weapon Tables"; }
    elsif ($type == 11) { $typereal = "Weapon Tables"; }

    LogInfo ("Populating Equipment $typereal for for $gv->$gm");

    my $gameversion=(split /#/,$treeitem)[1];# print "\$gameversion is: $gameversion\n";

    my @options_human;
    my @options_droid;
    my $id;
    if( Load($gameversion) == 0 ) { Generate_Master_Item_List($gameversion); }

    if($type == 1)  { @options_human = split(/ /, $equiptables{$gameversion}{human}{heads});    @options_droid = split(/ /, $equiptables{$gameversion}{droid}{heads});    }
    if($type == 2)  { @options_human = split(/ /, $equiptables{$gameversion}{human}{implants}); @options_droid = split(/ /, $equiptables{$gameversion}{droid}{implants}); }
    if($type == 3)  { @options_human = split(/ /, $equiptables{$gameversion}{human}{armors});   @options_droid = split(/ /, $equiptables{$gameversion}{droid}{armors});   }
    if($type == 4)  { @options_human = split(/ /, $equiptables{$gameversion}{human}{arms});     @options_droid = split(/ /, $equiptables{$gameversion}{droid}{arms});     }
    if($type == 5)  { @options_human = split(/ /, $equiptables{$gameversion}{human}{arms});     @options_droid = split(/ /, $equiptables{$gameversion}{droid}{arms});     }
    if($type == 6)  { @options_human = split(/ /, $equiptables{$gameversion}{human}{gloves});   @options_droid = ();                                                      }
    if($type == 7)  { @options_human = split(/ /, $equiptables{$gameversion}{human}{belts});    @options_droid = split(/ /, $equiptables{$gameversion}{droid}{belts});    }
    if($type >= 8)  { @options_human = split(/ /, $equiptables{$gameversion}{weapons}{melee});  @options_droid = split(/ /, $equiptables{$gameversion}{weapons}{range}); }

    my $frame =    $mw->Frame(-height=>300, -width=>300)->place(-x=>600/$x, -relx=>0.665, -rely=>0.4, -y=>800/$y);
    my $subframe = $mw->Frame(-height=>200, -width=>300)->place(-x=>600/$x, -relx=>0.665, -rely=>0.0, -y=>0/$y);

    my $slabel = $subframe->Scrolled('ROText', -scrollbars=>"osoe", -wrap=>"word", -width=>40, -height=>10, -font=>[-size=>10])->place(-x=>5, -y=>0);
    $slabel->Contents("Current Item: $sitem");

    $frame->Label(-text=>$typereal)->place(-x=>5, -y=>0);
    if(scalar @options_droid > 0)
    {
        my $dframe = $frame->DynaTabFrame(-height=>300, -width=>300, -tabpadx=>10)->place(-x=>0, -y=>0, -relwidth=>1, -relheight=>1);
        if($type >= 8){
            #print "J";
            my $d = $dframe->add("droid", -label=>"Ranged");
            my $h = $dframe->add("human", -label=>"Melee");

            my $j = $h->Scrolled('Listbox', -scrollbars=>'osoe', -takefocus=>1, -background=>"#e0e0e0", -selectmode=>'single')->place(-x=>0, -y=>0, -relheight=>0.98, -relwidth=>1);
            my $k = $d->Scrolled('Listbox', -scrollbars=>'osoe', -takefocus=>1, -background=>"#e0e0e0", -selectmode=>'single')->place(-x=>0, -y=>0, -relheight=>0.98, -relwidth=>1);
            foreach (@options_human) {if($_ ne "") { $j->insert('end', $_); }}# print "$_\n";}
            foreach (@options_droid) {if($_ ne "") { $k->insert('end', $_); }}# print "$_\n";}

            $j->bind('<ButtonPress-1>'=>sub
            {
                $sitem = $j->get($j->curselection());

                my $gffb1 = Bioware::GFF->new();
                if(-e $kseInitializer->{path}->{$g} . "\\override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\override\\$sitem.uti");    }
                elsif(-e $kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti"); }
                else
                {
                    my $gffbif1 = Bioware::BIF->new($kseInitializer->{path}->{$g});
                    my $resource1 = $gffbif1->get_resource('data\templates.bif', $sitem . ".uti");
                    $gffb1->read_gff_scalar($resource1);
                    $gffbif1 = undef; $resource1 = undef;
                }
                my %hah1;
                $hah1{DescIdentified} = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('DescIdentified')]{Value};
                $hah1{Description}    = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Description')]{Value};
                $hah1{Identified}     = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Identified')]{Value};
                $hah1{LocalizedName}  = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('LocalizedName')]{Value};

                my $name1 = $hah1{LocalizedName}{StringRef};
                if($name1 == -1) { $name1 = $hah1{LocalizedName}{Substrings}[0]{Value}; }
                else { $name1 = string_from_resref($kseInitializer->{path}->{$g}, $name1); }

                my $desc1 = "none";
                if($hah1{Identified} == 1)
                {
                    my $desc11 = $hah1{DescIdentified}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{DescIdentified}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }
                else
                {
                    my $desc11 = $hah1{Description}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{Description}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }

                $slabel->Contents("Current Item: $sitem\n\n\t\tItem Properties:\n\nName:\t$name1\n\nDescription:\n$desc1");
                $slabel->update;
            });

            $k->bind('<ButtonPress-1>'=>sub
            {
                $sitem = $k->get($k->curselection());

                my $gffb1 = Bioware::GFF->new();
                if(-e $kseInitializer->{path}->{$g} . "\\override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\override\\$sitem.uti");    }
                elsif(-e $kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti"); }
                else
                {
                    my $gffbif1 = Bioware::BIF->new($kseInitializer->{path}->{$g});
                    my $resource1 = $gffbif1->get_resource('data\templates.bif', $sitem . ".uti");
                    $gffb1->read_gff_scalar($resource1);
                    $gffbif1 = undef; $resource1 = undef;
                }
                my %hah1;
                $hah1{DescIdentified} = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('DescIdentified')]{Value};
                $hah1{Description}    = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Description')]{Value};
                $hah1{Identified}     = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Identified')]{Value};
                $hah1{LocalizedName}  = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('LocalizedName')]{Value};

                my $name1 = $hah1{LocalizedName}{StringRef};
                if($name1 == -1) { $name1 = $hah1{LocalizedName}{Substrings}[0]{Value}; }
                else { $name1 = string_from_resref($kseInitializer->{path}->{$g}, $name1); }

                my $desc1 = "none";
                if($hah1{Identified} == 1)
                {
                    my $desc11 = $hah1{DescIdentified}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{DescIdentified}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }
                else
                {
                    my $desc11 = $hah1{Description}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{Description}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }

                $slabel->Contents("Current Item: $sitem\n\n\t\tItem Properties:\n\nName:\t$name1\n\nDescription:\n$desc1");
                $slabel->update;
            });
        }
        else
        {
            my $d = $dframe->add("droid", -label=>"Droid");
            my $h = $dframe->add("human", -label=>"Human");

            my $j = $h->Scrolled('Listbox', -scrollbars=>'osoe',-takefocus=>1, -background=>"#e0e0e0", -selectmode=>'single')->place(-x=>0, -y=>0, -relheight=>0.98, -relwidth=>1);
            my $k = $d->Scrolled('Listbox', -scrollbars=>'osoe',-takefocus=>1, -background=>"#e0e0e0", -selectmode=>'single')->place(-x=>0, -y=>0, -relheight=>0.98, -relwidth=>1);
            foreach (@options_human) {if($_ ne "") { $j->insert('end', $_); }}# print "$_\n";}
            foreach (@options_droid) {if($_ ne "") { $k->insert('end', $_); }}# print "$_\n";}

            $j->bind('<ButtonPress-1>'=>sub
            {
                $sitem = $j->get($j->curselection());

                my $gffb1 = Bioware::GFF->new();
                if(-e $kseInitializer->{path}->{$g} . "\\override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\override\\$sitem.uti");    }
                elsif(-e $kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti"); }
                else
                {
                    my $gffbif1 = Bioware::BIF->new($kseInitializer->{path}->{$g});
                    my $resource1 = $gffbif1->get_resource('data\templates.bif', $sitem . ".uti");
                    $gffb1->read_gff_scalar($resource1);
                    $gffbif1 = undef; $resource1 = undef;
                }
                my %hah1;
                $hah1{DescIdentified} = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('DescIdentified')]{Value};
                $hah1{Description}    = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Description')]{Value};
                $hah1{Identified}     = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Identified')]{Value};
                $hah1{LocalizedName}  = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('LocalizedName')]{Value};

                my $name1 = $hah1{LocalizedName}{StringRef};
                if($name1 == -1) { $name1 = $hah1{LocalizedName}{Substrings}[0]{Value}; }
                else { $name1 = string_from_resref($kseInitializer->{path}->{$g}, $name1); }

                my $desc1 = "none";
                if($hah1{Identified} == 1)
                {
                    my $desc11 = $hah1{DescIdentified}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{DescIdentified}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }
                else
                {
                    my $desc11 = $hah1{Description}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{Description}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }

                $slabel->Contents("Current Item: $sitem\n\n\t\tItem Properties:\n\nName:\t$name1\n\nDescription:\n$desc1");
                $slabel->update;
            });

            $k->bind('<ButtonPress-1>'=>sub
            {
                $sitem = $k->get($k->curselection());

                my $gffb1 = Bioware::GFF->new();
                if(-e $kseInitializer->{path}->{$g} . "\\override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\override\\$sitem.uti");    }
                elsif(-e $kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti"); }
                else
                {
                    my $gffbif1 = Bioware::BIF->new($kseInitializer->{path}->{$g});
                    my $resource1 = $gffbif1->get_resource('data\templates.bif', $sitem . ".uti");
                    $gffb1->read_gff_scalar($resource1);
                    $gffbif1 = undef; $resource1 = undef;
                }
                my %hah1;
                $hah1{DescIdentified} = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('DescIdentified')]{Value};
                $hah1{Description}    = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Description')]{Value};
                $hah1{Identified}     = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Identified')]{Value};
                $hah1{LocalizedName}  = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('LocalizedName')]{Value};

                my $name1 = $hah1{LocalizedName}{StringRef};
                if($name1 == -1) { $name1 = $hah1{LocalizedName}{Substrings}[0]{Value}; }
                else { $name1 = string_from_resref($kseInitializer->{path}->{$g}, $name1); }

                my $desc1 = "none";
                if($hah1{Identified} == 1)
                {
                    my $desc11 = $hah1{DescIdentified}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{DescIdentified}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }
                else
                {
                    my $desc11 = $hah1{Description}{StringRef};
                    if($desc11 == -1) { $desc1 = $hah1{Description}{Substrings}[0]{Value}; }
                    else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
                }

                $slabel->Contents("Current Item: $sitem\n\n\t\tItem Properties:\n\nName:\t$name1\n\nDescription:\n$desc1");
                $slabel->update;
            });
        }
    }
    else
    {
        my $j = $frame->Scrolled('Listbox', -scrollbars=>'osoe',-takefocus=>1, -background=>"#e0e0e0")->place(-x=>0, -y=>25, -relheight=>0.9, -relwidth=>0.95);
        foreach (@options_human) {if($_ ne "") { $j->insert('end', $_); }}# print "$_\n";}

        $j->bind('<ButtonPress-1>'=>sub
        {
            $sitem = $j->get($j->curselection());

            my $gffb1 = Bioware::GFF->new();
            if(-e $kseInitializer->{path}->{$g} . "\\override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\override\\$sitem.uti");    }
            elsif(-e $kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti") { $gffb1->read_gff_file($kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti"); }
            else
            {
                my $gffbif1 = Bioware::BIF->new($kseInitializer->{path}->{$g});
                my $resource1 = $gffbif1->get_resource('data\templates.bif', $sitem . ".uti");
                $gffb1->read_gff_scalar($resource1);
                $gffbif1 = undef; $resource1 = undef;
            }
            my %hah1;
            $hah1{DescIdentified} = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('DescIdentified')]{Value};
            $hah1{Description}    = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Description')]{Value};
            $hah1{Identified}     = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('Identified')]{Value};
            $hah1{LocalizedName}  = $gffb1->{Main}{Fields}[$gffb1->{Main}->get_field_ix_by_label('LocalizedName')]{Value};

            my $name1 = $hah1{LocalizedName}{StringRef};
            if($name1 == -1) { $name1 = $hah1{LocalizedName}{Substrings}[0]{Value}; }
            else { $name1 = string_from_resref($kseInitializer->{path}->{$g}, $name1); }

            my $desc1 = "none";
            if($hah1{Identified} == 1)
            {
                my $desc11 = $hah1{DescIdentified}{StringRef};
                if($desc11 == -1) { $desc1 = $hah1{DescIdentified}{Substrings}[0]{Value}; }
                else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
            }
            else
            {
                my $desc11 = $hah1{Description}{StringRef};
                if($desc11 == -1) { $desc1 = $hah1{Description}{Substrings}[0]{Value}; }
                else { $desc1 = Bioware::TLK::string_from_resref($kseInitializer->{path}->{$g}, $desc11); }
            }

            $slabel->Contents("Current Item: $sitem\n\n\t\tItem Properties:\n\nName:\t$name1\n\nDescription:\n$desc1");
            $slabel->update;
        });

    }

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub
    {
        if($type == 1)  { $lbltext = "Head:\t\t$sitem";         $id = 1;         }
        if($type == 2)  { $lbltext = "Implant:\t\t$sitem";      $id = 512;       }
        if($type == 3)  { $lbltext = "Armor:\t\t$sitem";        $id = 2;         }
        if($type == 4)  { $lbltext = "Right Arm:\t$sitem";      $id = 256;       }
        if($type == 5)  { $lbltext = "Left Arm:\t\t$sitem";     $id = 128;       }
        if($type == 6)  { $lbltext = "Gloves:\t\t$sitem";       $id = 8;         }
        if($type == 7)  { $lbltext = "Belt:\t\t$sitem";         $id = 1024;      }
        if($type == 8)  { $lbltext = "Right Weapon:\t$sitem";   $id = 16;        }
        if($type == 9)  { $lbltext = "Left Weapon:\t$sitem";    $id = 32;        }
        if($type == 10) { $lbltext = "Right Weapon 2:\t$sitem"; $id = 262144;    }
        if($type == 11) { $lbltext = "Left Weapon 2:\t$sitem";  $id = 524288;    }

        $tree->entryconfigure($treeitem,-text=>$lbltext);

        if($truth == 0)
        {
            $playerlist = $$npc->{Main}{Fields}[$$npc->{Main}->fbl('Mod_PlayerList')]{Value}[0];

            $array = $playerlist->{Fields}->[$playerlist->get_field_ix_by_label('Equip_ItemList')]{Value};
        }
        else
        {
            $array = $$npc->{Main}{Fields}->[$$npc->{Main}->get_field_ix_by_label('Equip_ItemList')]{Value};
        }

        my $in = 0;
        foreach (@$array)
        {LogDebug "ID: $in";
            if($array->[$in]{ID} == $id)
            {#print "Found a match: $in ID: $id\n";
                my $gffb = Bioware::GFF->new();
                if   (-e $kseInitializer->{path}->{$g} . "\\override\\$sitem.uti") { $gffb->read_gff_file($kseInitializer->{path}->{$g} . "\\override\\$sitem.uti"); }
                elsif(-e $kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti") { $gffb->read_gff_file($kseInitializer->{path}->{$g} . "\\Override\\$sitem.uti"); }
                else {
                    my $gffbif = Bioware::BIF->new($kseInitializer->{path}->{$g});
                    my $resource = $gffbif->get_resource('data\templates.bif', $sitem . ".uti");
                    $gffb->read_gff_scalar($resource);
                    $gffbif = undef; $resource = undef;
                }

                my %hah;
                $hah{AddCost}        = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('AddCost')]{Value};
                $hah{BaseItem}       = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('BaseItem')]{Value};
                $hah{Charges}        = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('Charges')]{Value};
                $hah{MaxCharges}     = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('MaxCharges')]{Value};
                $hah{Cost}           = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('Cost')]{Value};
                $hah{DescIdentified} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('DescIdentified')]{Value};
                $hah{Description}    = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('Description')]{Value};
                $hah{Identified}     = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('Identified')]{Value};
                $hah{LocalizedName}  = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('LocalizedName')]{Value};
                $hah{ModelVariation} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('ModelVariation')]{Value};
                $hah{Plot}           = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('Plot')]{Value};
                $hah{PropertiesList} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('PropertiesList')]{Value};
                $hah{StackSize}      = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('StackSize')]{Value};
                $hah{Stolen}         = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('Stolen')]{Value};
                $hah{Tag}            = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('Tag')]{Value};
                if($parms[1] > 1)
                {
                    $hah{UpgradeLevel} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('UpgradeLevel')]{Value};
                    $hah{UpgradeSlot0} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('UpgradeSlot0')]{Value};
                    $hah{UpgradeSlot1} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('UpgradeSlot1')]{Value};
                    $hah{UpgradeSlot2} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('UpgradeSlot2')]{Value};
                    $hah{UpgradeSlot3} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('UpgradeSlot3')]{Value};
                    $hah{UpgradeSlot4} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('UpgradeSlot4')]{Value};
                    $hah{UpgradeSlot5} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('UpgradeSlot5')]{Value};
                }
                if($id == 2)
                {
                    $hah{BodyVariation} = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('BodyVariation')]{Value};
                    $hah{TextureVar}    = $gffb->{Main}{Fields}[$gffb->{Main}->get_field_ix_by_label('TextureVar')]{Value};
                }

                foreach(sort keys %hah) { LogDebug "Key: $_\tValue: $hah{$_}"; }

                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('AddCost')]{Value}        = $hah{AddCost};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('BaseItem')]{Value}       = $hah{BaseItem};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('Charges')]{Value}        = $hah{Charges};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('Cost')]{Value}           = $hah{Cost};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('DescIdentified')]{Value} = $hah{DescIdentified};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('Description')]{Value}    = $hah{Description};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('Identified')]{Value}     = $hah{Identified};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('LocalizedName')]{Value}  = $hah{LocalizedName};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('ModelVariation')]{Value} = $hah{ModelVariation};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('Plot')]{Value}           = $hah{Plot};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('PropertiesList')]{Value} = $hah{PropertiesList};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('StackSize')]{Value}      = $hah{StackSize};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('Stolen')]{Value}         = $hah{Stolen};
                $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('Tag')]{Value}            = $hah{Tag};
                if($parms[1] > 1)
                {
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('UpgradeLevel')]{Value} = $hah{UpgradeLevel};
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('UpgradeSlot0')]{Value} = $hah{UpgradeSlot0};
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('UpgradeSlot1')]{Value} = $hah{UpgradeSlot1};
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('UpgradeSlot2')]{Value} = $hah{UpgradeSlot2};
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('UpgradeSlot3')]{Value} = $hah{UpgradeSlot3};
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('UpgradeSlot4')]{Value} = $hah{UpgradeSlot4};
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('UpgradeSlot5')]{Value} = $hah{UpgradeSlot5};
                }
                if($id == 2)
                {
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('BodyVariation')]{Value} = $hah{BodyVariation};
                    $array->[$in]{Fields}[$array->[$in]->get_field_ix_by_label('TextureVar')]{Value}    = $hah{TextureVar};
                }

                #                $gff = undef;
                last;
            }
            $in++;
        }
    })->place(-relx=>600/$x,-rely=>540/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;
    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub {CommitChanges($treeitem)
    })->place(-relx=>870/$x,-rely=>540/$y,-anchor=>'ne');
    push(@spawned_widgets, $frame); push(@spawned_widgets, $subframe); push @spawned_widgets, $btn2;
}

#>>>>>>>>>>>>>>>>>>>>>>
sub Populate_Level1 {
    #>>>>>>>>>>>>>>>>>>>>>>
    my $treeitem=shift;
    my $gv;
    my $gm;

    my @parms = split /#/, $treeitem;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;

    LogInfo ("Populating main elements for $gv->$gm");

    my $gameversion=(split /#/,$treeitem)[1];# print "\$gameversion is: $gameversion\n";
    my $gamedir=(split /#/,$treeitem)[2]; #print "\$gamedir is: $gamedir\n";
    my $registered_path;
    my %genders;
    my %appearance_hash;
    my %portraits_hash;
    my %soundset_hash;
    my %standard_npcs;
    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor_save};
        %genders=%gender_hash1;
        %appearance_hash=%appearance_hash1;
        %portraits_hash=%portraits_hash1;
        %soundset_hash=%soundset_hash1;
        %standard_npcs=%standard_kotor_npcs;
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl_save};
        %genders=%gender_hash2;
        %appearance_hash=%appearance_hash2;
        %portraits_hash=%portraits_hash2;
        %soundset_hash=%soundset_hash2;
        %standard_npcs=%standard_tsl_npcs;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
        %genders=%gender_hash3;
        %appearance_hash=%appearance_hash3;
        %portraits_hash=%portraits_hash3;
        %soundset_hash=%soundset_hash3;
        %standard_npcs=%tjm_npcs;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl_cloud};
        %genders=%gender_hash2;
        %appearance_hash=%appearance_hash2;
        %portraits_hash=%portraits_hash2;
        %soundset_hash=%soundset_hash2;
        %standard_npcs=%standard_tsl_npcs;
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
        %genders=%gender_hash3;
        %appearance_hash=%appearance_hash3;
        %portraits_hash=%portraits_hash3;
        %soundset_hash=%soundset_hash3;
        %standard_npcs=%tjm_npcs;
    }

    LoadData($treeitem);
    my $root='#'.(split /#/,$treeitem)[1].'#'.(split /#/,$treeitem)[2];
    my $datahash=$tree->entrycget($root,-data);
    my $erf=$datahash->{'ERF-sav'};
    my $erfLastModSav=$datahash->{'ERF-mod'};
    my $gff_LastModIfo=$datahash->{'GFF-ifo'};
    my $pty_gff=$datahash->{'GFF-pty'};
    my $res_gff=$datahash->{'GFF-res'};
    my $gff_inv=$datahash->{'GFF-inv'};
    my $gff_LastModGit=$datahash->{'GFF-git'};
    # my $gbl_gff=$tree->entrycget("$root#Globals",-data);

    #read the SAVENFO.RES file
    my $time_played=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('TIMEPLAYED')]{Value};
    my $area_name=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('AREANAME')]{Value};
    my $save_game_name=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('SAVEGAMENAME')]{Value};
    my $lastModuleName=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('LASTMODULE')]{Value};
    my $cheat=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('CHEATUSED')]{Value};

    #read the PARTYTABLE.RES file
    my $credits=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->get_field_ix_by_label('PT_GOLD')]{Value};
    my $partyxp=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->get_field_ix_by_label('PT_XP_POOL')]{Value};
    my $pty_cheat=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->get_field_ix_by_label('PT_CHEAT_USED')]{Value};

    my $pt_members_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('PT_MEMBERS')]{Value};
    my @npc_party;
    for my $pt_member (@$pt_members_arr_ref) {
        my $pt_member_id=$pt_member->{Fields}[$pt_member->fbl('PT_MEMBER_ID')]{Value};
        push @npc_party, $standard_npcs{$pt_member_id}
    }
    my $current_party_text=join (", ",@npc_party);
    if ($current_party_text eq '') { $current_party_text = "--" }
    $current_party_text = "Current Party: $current_party_text";

    my $components;
    my $chemicals;
    if ($gameversion==2 || 3) {
        $components=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->get_field_ix_by_label('PT_ITEM_COMPONEN')]{Value};
        $chemicals=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->get_field_ix_by_label('PT_ITEM_CHEMICAL')]{Value};
    }
    my @avail_npcs;
    my $npc_structs_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->get_field_ix_by_label('PT_AVAIL_NPCS')]{Value};
    my $i=0;
    for my $npc_struct (@$npc_structs_arr_ref) {
        my $is_available=$npc_struct->{Fields}[$npc_struct->get_field_ix_by_label('PT_NPC_AVAIL')]{Value};
        if ($is_available==1) {
            push @avail_npcs,$i;
        }
        $i++;
    }
    my $avail_npcs_ref=\@avail_npcs;





    my $mod_playerlist=$gff_LastModIfo->{Main}{Fields}[$gff_LastModIfo->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];

    my $firstname     =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FirstName')]{'Value'}{'Substrings'}[0]{'Value'};
    my $gender        =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Gender')]{'Value'};
    my $att_str       =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Str')]{'Value'};
    my $att_dex       =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Dex')]{'Value'};
    my $att_con       =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Con')]{'Value'};
    my $att_int       =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Int')]{'Value'};
    my $att_wis       =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Wis')]{'Value'};
    my $att_cha       =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Cha')]{'Value'};
    my $hitpoints     =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('HitPoints')]{'Value'};
    my $maxhitpoints  =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('MaxHitPoints')]{'Value'};
    my $forcepoints   =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ForcePoints')]{'Value'};
    my $maxforcepoints=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('MaxForcePoints')]{'Value'};
    my $min1hp        =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Min1HP')]{'Value'};
    my $experience    =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Experience')]{'Value'};
    my $goodevil      =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('GoodEvil')]{'Value'};
    my $appearance    =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Appearance_Type')]{'Value'};
    my $portrait      =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('PortraitId')]{'Value'};
    my $soundset      =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('SoundSetFile')]{'Value'};
    my $XPosition     =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('XPosition')]{'Value'};
    my $YPosition     =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('YPosition')]{'Value'};
    my $ZPosition     =$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ZPosition')]{'Value'};

    my $mod_playerequiplist = $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Equip_ItemList')]{Value};
    my ($head, $implant, $rarm, $larm, $gloves, $belt, $rweapon, $rweapon2, $lweapon, $lweapon2, $armor);

    my $in = 0;
    foreach (@$mod_playerequiplist)
    {
        my $id = $mod_playerequiplist->[$in]{ID};

        if($id == 1)
        {
            $head = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 2)
        {
            $armor = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 8)
        {
            $gloves = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 16)
        {
            $rweapon = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 32)
        {
            $lweapon = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 128)
        {
            $larm = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 256)
        {
            $rarm = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 512)
        {
            $implant = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 1024)
        {
            $belt = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 262144)
        {
            $rweapon2 = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 524288)
        {
            $lweapon2 = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        $in++;
    }
    $tree->add($treeitem."#SaveGameName", -text=>'Savegame Name: ' . $save_game_name, -data=>'can modify');

    $tree->add($treeitem."#OtherAreas",-text=>"Other Areas");

    $tree->add($treeitem."#Area", -text=>'Current Area: '. $area_name." (".$lastModuleName.")",-data=>$area_name);
    $tree->add($treeitem."#Area#Placeables",-text=>"Placeables");  	$tree->hide('entry',$treeitem."#Area#Placeables");
    $tree->add($treeitem."#Area#Placeables#",-text=>"");  			$tree->hide('entry',$treeitem."#Area#Placeables#");
    $tree->add($treeitem."#Area#Creatures",-text=>"Creatures");  	$tree->hide('entry',$treeitem."#Area#Creatures");
    $tree->add($treeitem."#Area#Creatures#",-text=>"");  			$tree->hide('entry',$treeitem."#Area#Creatures#");
    $tree->add($treeitem."#Area#Stores",-text=>"Stores");  			$tree->hide('entry',$treeitem."#Area#Stores");
    $tree->add($treeitem."#Area#Stores#",-text=>"");  				$tree->hide('entry',$treeitem."#Area#Stores#");
    $tree->add($treeitem."#Area#Doors",-text=>"Doors");  			$tree->hide('entry',$treeitem."#Area#Doors");
    $tree->add($treeitem."#Area#Doors#",-text=>"");  				$tree->hide('entry',$treeitem."#Area#Doors#");
    $tree->add($treeitem."#Area#XPosition",-text=>'XPosition: '.$XPosition,-data=>'can modify'); $tree->hide('entry',$treeitem."#Area#XPosition");
    $tree->add($treeitem."#Area#YPosition",-text=>'YPosition: '.$YPosition,-data=>'can modify'); $tree->hide('entry',$treeitem."#Area#YPosition");
    $tree->add($treeitem."#Area#ZPosition",-text=>'ZPosition: '.$ZPosition,-data=>$ZPosition);   $tree->hide('entry',$treeitem."#Area#ZPosition");

    $tree->add($treeitem."#FirstName",-text=>"Player Name: $firstname",-data=>'can modify');
    $tree->add($treeitem."#Gender",-text=>"Gender: $genders{$gender}",-data=>'can modify');
    $tree->add($treeitem."#Appearance",-text=>"Appearance: $appearance_hash{$appearance}",-data=>'can modify');
    $tree->add($treeitem."#Portrait",-text=>"Portrait: $portraits_hash{$portrait}",-data=>'can modify');
    $tree->add($treeitem."#Soundset",-text=>"Soundset: $soundset_hash{$soundset}",-data=>'can modify');
    $tree->add($treeitem."#Attributes",-text=>"Attributes");
    $tree->add($treeitem."#Equipment",-text=>"Equipment", -data=>$mod_playerequiplist);
    $tree->add($treeitem."#Equipment#Head",    -text=>"Head:\t\t$head");           $tree->hide('entry', $treeitem."#Equipment#Head");
    $tree->add($treeitem."#Equipment#Implant", -text=>"Implant:\t\t$implant");     $tree->hide('entry', $treeitem."#Equipment#Implant");
    $tree->add($treeitem."#Equipment#RArm",    -text=>"Right Arm:\t$rarm");        $tree->hide('entry', $treeitem."#Equipment#RArm");
    $tree->add($treeitem."#Equipment#LArm",    -text=>"Left Arm:\t\t$larm");       $tree->hide('entry', $treeitem."#Equipment#LArm");
    $tree->add($treeitem."#Equipment#Gloves",  -text=>"Gloves:\t\t$gloves");       $tree->hide('entry', $treeitem."#Equipment#Gloves");
    $tree->add($treeitem."#Equipment#Armor",   -text=>"Armor:\t\t$armor");         $tree->hide('entry', $treeitem."#Equipment#Armor");
    $tree->add($treeitem."#Equipment#Belt",    -text=>"Belt:\t\t$belt");           $tree->hide('entry', $treeitem."#Equipment#Belt");
    $tree->add($treeitem."#Equipment#RWeapon", -text=>"Right Weapon:\t$rweapon");  $tree->hide('entry', $treeitem."#Equipment#RWeapon");
    $tree->add($treeitem."#Equipment#LWeapon", -text=>"Left Weapon:\t$lweapon");   $tree->hide('entry', $treeitem."#Equipment#LWeapon");
    $tree->add($treeitem."#CurrentParty",-text=>$current_party_text,-data=>'can modify');
    $tree->add($treeitem."#NPCs",-text=>"NPCs",-data=>$avail_npcs_ref);
    $tree->add($treeitem."#NPCs#",-text=>'');  $tree->hide('entry',$treeitem."#NPCs#");
    $tree->add($treeitem."#Globals",-text=>'Globals');
    $tree->add($treeitem."#Globals#",-text=>''); $tree->hide('entry',$treeitem."#Globals#");
    $tree->add($treeitem."#TimePlayed",-text=>'Time Played: '.(sprintf "%uh ",($time_played/3600)).(sprintf "%um ",(($time_played % 3600)/60)).(sprintf "%us",($time_played % 60)),-data=>'can modify');
    $tree->add($treeitem."#CheatUsed",-text=>"Cheats Used: " . ($pty_cheat | $cheat),-data=>'can modify');
    $tree->add($treeitem."#Attributes#STR",-text=>"STR: $att_str",-data=>'can modify'); $tree->hide('entry',$treeitem."#Attributes#STR");
    $tree->add($treeitem."#Attributes#DEX",-text=>"DEX: $att_dex",-data=>'can modify'); $tree->hide('entry',$treeitem."#Attributes#DEX");
    $tree->add($treeitem."#Attributes#CON",-text=>"CON: $att_con",-data=>'can modify'); $tree->hide('entry',$treeitem."#Attributes#CON");
    $tree->add($treeitem."#Attributes#INT",-text=>"INT: $att_int",-data=>'can modify'); $tree->hide('entry',$treeitem."#Attributes#INT");
    $tree->add($treeitem."#Attributes#WIS",-text=>"WIS: $att_wis",-data=>'can modify'); $tree->hide('entry',$treeitem."#Attributes#WIS");
    $tree->add($treeitem."#Attributes#CHA",-text=>"CHA: $att_cha",-data=>'can modify'); $tree->hide('entry',$treeitem."#Attributes#CHA");
    $tree->add($treeitem."#HitPoints",-text=>"Hit Points: $hitpoints",-data=>'can modify');
    $tree->add($treeitem."#MaxHitPoints",-text=>"Max Hit Points: $maxhitpoints",-data=>'can modify');
    $tree->add($treeitem."#Min1HP",-text=>"Min1HP: $min1hp",-data=>'can modify');
    $tree->add($treeitem."#ForcePoints",-text=>"Force Points: $forcepoints",-data=>'can modify');
    $tree->add($treeitem."#MaxForcePoints",-text=>"Max Force Points: $maxforcepoints",-data=>'can modify');
    $tree->add($treeitem."#Classes",-text=>"Classes");
    $tree->add($treeitem."#Classes#",-text=>""); $tree->hide('entry',$treeitem."#Classes#");
    $tree->add($treeitem."#Experience",-text=>"Experience: $experience",-data=>'can modify');
    $tree->add($treeitem."#GoodEvil",-text=>"GoodEvil: $goodevil",-data=>'can modify');
    $tree->add($treeitem."#Skills",-text=>"Skills");
    $tree->add($treeitem."#Feats",-text=>"Feats",-data=>'can modify');
    $tree->add($treeitem."#Skills#",-text=>"");  $tree->hide('entry',$treeitem."#Skills#");
    $tree->add($treeitem."#Feats#",-text=>"");   $tree->hide('entry',$treeitem."#Feats#");
    $tree->add($treeitem."#Credits",-text=>"Credits: $credits",-data=>'can modify');
    $tree->add($treeitem."#PartyXP",-text=>"Party XP: $partyxp",-data=>'can modify');
    $tree->add($treeitem."#Inventory",-text=>"Inventory");
    $tree->add($treeitem."#Inventory#",-text=>"");  $tree->hide('entry',$treeitem."#Inventory#");
    if ($gameversion == 2) {
        $tree->add($treeitem."#Chemicals",-text=>"Chemicals: $chemicals",-data=>'can modify');
        $tree->add($treeitem."#Components",-text=>"Components: $components",-data=>'can modify');
        $tree->add($treeitem."#Equipment#RWeapon2",-text=>"Right Weapon 2:\t$rweapon2");  $tree->hide('entry', $treeitem."#Equipment#RWeapon2");
        $tree->add($treeitem."#Equipment#LWeapon2",-text=>"Left Weapon 2:\t$lweapon2");   $tree->hide('entry', $treeitem."#Equipment#LWeapon2");
    }
    if ($gameversion == 3) {
        $tree->add($treeitem."#Chemicals",-text=>"Chemicals: $chemicals",-data=>'can modify');
        $tree->add($treeitem."#Components",-text=>"Components: $components",-data=>'can modify');
        $tree->add($treeitem."#Equipment#RWeapon2",-text=>"Right Weapon 2:\t$rweapon2");  $tree->hide('entry', $treeitem."#Equipment#RWeapon2");
        $tree->add($treeitem."#Equipment#LWeapon2",-text=>"Left Weapon 2:\t$lweapon2");   $tree->hide('entry', $treeitem."#Equipment#LWeapon2");
    }
    if ($gameversion == 4) {
        $tree->add($treeitem."#Chemicals",-text=>"Chemicals: $chemicals",-data=>'can modify');
        $tree->add($treeitem."#Components",-text=>"Components: $components",-data=>'can modify');
        $tree->add($treeitem."#Equipment#RWeapon2",-text=>"Right Weapon 2:\t$rweapon2");  $tree->hide('entry', $treeitem."#Equipment#RWeapon2");
        $tree->add($treeitem."#Equipment#LWeapon2",-text=>"Left Weapon 2:\t$lweapon2");   $tree->hide('entry', $treeitem."#Equipment#LWeapon2");
    }

    $tree->autosetmode();

}
#>>>>>>>>>>>>>>>>>>>>
sub Read_Global_Vars{
    #>>>>>>>>>>>>>>>>>>>>
    my $dir=shift;
    my $treeitem=shift;
    #$tree->add($treeitem."#Globals",-text=>"Globals");
    $tree->add($treeitem."#Booleans",-text=>"Booleans");
    $tree->add($treeitem."#Numerics",-text=>"Numerics");

    my $gff=Bioware::GFF->new();
    $gff->read_gff_file("$dir\\GLOBALVARS.res");

    my %boogleans;
    my %numrics;
    my $bitstring=unpack('B*',$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('ValBoolean')]{'Value'});
    my @bits=split //,$bitstring;
    my $catboolean_ix=$gff->{Main}->get_field_ix_by_label('CatBoolean');
    for (my $i=0; $i< scalar @{$gff->{Main}{Fields}[$catboolean_ix]{'Value'}}; $i++) {
        my $kee=$gff->{Main}{Fields}[$catboolean_ix]{'Value'}[$i]{'Fields'}{'Value'}."__$i";
        $boogleans{$kee}=$bits[$i];
    }
    for my $kee (sort keys %boogleans) {
        my $keetxt=(split /__/,$kee)[0];
        $tree->add("$treeitem#Booleans#$kee",-text=>"$keetxt: $boogleans{$kee}",-data=>'can modify');
        $tree->hide('entry',"$treeitem#Booleans#$kee");
    }
    my $catnumber_ix=$gff->{Main}->get_field_ix_by_label('CatNumber');
    my $catnumber_count=scalar @{$gff->{Main}{Fields}[$catnumber_ix]{'Value'}};
    my @byts=unpack("c$catnumber_count",$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('ValNumber')]{'Value'});
    for (my $i=0; $i< scalar @{$gff->{Main}{Fields}[$catnumber_ix]{'Value'}}; $i++) {
        my $kee=$gff->{Main}{Fields}[$catnumber_ix]{'Value'}[$i]{'Fields'}{'Value'}."__$i";
        $numrics{$kee}=$byts[$i];
    }
    for my $kee (sort keys %numrics) {
        my $keetxt=(split /__/,$kee)[0];
        $tree->add("$treeitem#Numerics#$kee",-text=>"$keetxt: $numrics{$kee}",-data=>'can modify');
        $tree->hide('entry',"$treeitem#Numerics#$kee");
    }
    $tree->entryconfigure($treeitem,-data=>$gff);  #put this little token into my coat of many pockets
    $tree->autosetmode();
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>
sub Populate_Classes {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>

    #Purpose: To populate the tree info with class trees
    #Inputs: Treeitem that called this sub
    #Outputs: None
    #Side effects: Populates tree

    my $treeitem=shift;
    my $gv;
    my $gm;

    my @parms = split /#/, $treeitem;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;
    #my $file_to_open="$registered_path\\saves\\".(split /#/,$treeitem)[1]."\\savegame.sav";
    #unless (open SAV,"<",$file_to_open) { return; }

    # get our breadcrumbs

    LogInfo("Populating Classes: $gv->$gm");
    my $gameversion=(split /#/,$treeitem)[1];
    my %classes;
    my %powers_full;
    if ($gameversion==1) {
        %classes=%classes_hash1;
        %powers_full=%powers_full1;
    }
    elsif ($gameversion==2) {
        %classes=%classes_hash2;
        %powers_full=%powers_full2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %classes=%classes_hash3;
        %powers_full=%powers_full3;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %classes=%classes_hash2;
        %powers_full=%powers_full2;
    }
    elsif ($gameversion==4) {
        %classes=%classes_hash3;
        %powers_full=%powers_full3;
    }

    my $gff=${$tree->entrycget( '#'.$gameversion.'#'.(split /#/,$treeitem)[2],-data)}{'GFF-ifo'};
    my $mod_playerlist=$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
    my @class_structs = @{$mod_playerlist->{'Fields'}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value}};
    my $i=0;
    for my $class_struct (@class_structs) {
        $tree->add($treeitem."#Class$i",
          -text=>$classes{$class_struct->{'Fields'}[$class_struct->get_field_ix_by_label('Class')]{'Value'}},-data=>'can modify');
        $tree->add($treeitem."#Class$i#Level",
          -text=>'Level: '.$class_struct->{'Fields'}[$class_struct->get_field_ix_by_label('ClassLevel')]{'Value'},
          -data=>'can modify'
        );
        LogInfo ("-- ".$classes{$class_struct->{'Fields'}[$class_struct->get_field_ix_by_label('Class')]{'Value'}}." Level: "
          . $class_struct->{'Fields'}[$class_struct->get_field_ix_by_label('ClassLevel')]{'Value'});
        $tree->hide('entry',$treeitem."#Class$i#Level");
        my $knownlist0_ix=$class_struct->get_field_ix_by_label('KnownList0');

        if (defined $knownlist0_ix) {
            $tree->add($treeitem."#Class$i#KnownList0",-text=>'Force Powers',-data=>'can modify');
            my @power_structs=@{$class_struct->{'Fields'}[$knownlist0_ix]{'Value'}};
            for my $power_struct (@power_structs) {
                $tree->add($treeitem."#Class$i#KnownList0#Power".$powers_full{label}{$power_struct->{'Fields'}{'Value'}},
                  -text=>"$powers_full{name}{$power_struct->{'Fields'}{'Value'}}",
                  -data=>'can modify');
                $tree->hide('entry',$treeitem."#Class$i#KnownList0#Power".$powers_full{label}{$power_struct->{'Fields'}{'Value'}});
                LogInfo ("--- Power: " . $powers_full{name}{$power_struct->{'Fields'}{'Value'}});
            }
            $tree->hide('entry',$treeitem."#Class$i#KnownList0");
        }
        $i++;
    }
    $tree->autosetmode();
}

#>>>>>>>>>>>>>>>>>>>>>>>
sub Populate_Skills{
    #>>>>>>>>>>>>>>>>>>>>>>>

    #Purpose: To populate the tree info with skills
    #Inputs: Treeitem that called this sub
    #Outputs: None
    #Side effects: Populates tree
    my $treeitem=shift;
    my $gv;
    my $gm;

    my @parms = split /#/, $treeitem;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;
    my $gameversion=(split /#/,$treeitem)[1];
    my %skills;
    if ($gameversion==1) {
        %skills=%skills_hash1;
    }
    elsif ($gameversion==2) {
        %skills=%skills_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %skills=%skills_hash3;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %skills=%skills_hash2;
    }
    elsif ($gameversion==4) {
        %skills=%skills_hash3;
    }

    # get our breadcrumbs
    LogInfo("Populating skills: $gv->$gm");
    my $gff=${$tree->entrycget( '#'.$gameversion.'#'.(split /#/,$treeitem)[2],-data)}{'GFF-ifo'};
    my $mod_playerlist=$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
    my @skill_list=@{$mod_playerlist->{'Fields'}[$mod_playerlist->get_field_ix_by_label('SkillList')]{'Value'}};
    my $i=0;
    for my $skill_struct (@skill_list) {
        $tree->add($treeitem."#Skill$i",-text=>"$skills{$i}: $skill_struct->{'Fields'}{'Value'}",-data=>'can modify');
        $i++;
    };
}

#>>>>>>>>>>>>>>>>>>>>>>>>
sub Populate_Feats {
    #>>>>>>>>>>>>>>>>>>>>>>>>

    #Purpose: To populate the tree info with skills
    #Inputs: Treeitem that called this sub
    #Outputs: None
    #Side effects: Populates tree

    my $treeitem=shift;
    #	print "dd $treeitem\n";
    my $gv;
    my $gm;

    my @parms = split /#/, $treeitem;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;
    my $gameversion=(split /#/,$treeitem)[1];
    my %feats_full;

    if ($gameversion==1) {
        %feats_full=%feats_full1;
    }
    elsif ($gameversion==2) {
        %feats_full=%feats_full2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %feats_full=%feats_full2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %feats_full=%feats_full3;
    }
    elsif ($gameversion==4) {
        %feats_full=%feats_full3;
    }
    else{
        LogFatal("NOT OK?");
    }

    #	while( my ($key, $value) = each (%feats_full))
    #	{
    #		print "\$key, \$value: $key,$value";
    #	}

    LogInfo ("Populating Feats: $gv->$gm");

    # get our breadcrumbs
    my $gff=${$tree->entrycget( '#'.$gameversion.'#'.(split /#/,$treeitem)[2],-data)}{'GFF-ifo'};
    my $mod_playerlist=$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
    my @feat_list=@{$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FeatList')]{'Value'}};
    # print join "\n", @feat_list;
    my $i=0;
    for my $feat_struct (@feat_list) {
        $tree->add($treeitem."#Feat".$feats_full{label}{$feat_struct->{'Fields'}{'Value'}},-text=>"$feats_full{name}{$feat_struct->{Fields}{Value}}",-data=>'can modify');
        $tree->hide('entry',$treeitem."#Feat".$feats_full{label}{$feat_struct->{'Fields'}{'Value'}});
        $i++;
        LogInfo ("--- Feat: " . $feats_full{name}{$feat_struct->{'Fields'}{'Value'}});
    };
    $tree->autosetmode();
}
sub Current_Party{
    my $treeitem=shift;
    my $gameversion=(split /#/,$treeitem)[1];
    my $registered_path;
    my %standard_npcs;
    for my $widge (@spawned_widgets,$picture_label) {   #unspawn old widgets
        $widge->destroy if Tk::Exists($widge);
    }
    @spawned_widgets=();
    eval {$picture_label_photo->delete};

    if    ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor_save};
        %standard_npcs=%standard_kotor_npcs;
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl_save};
        %standard_npcs=%standard_tsl_npcs;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl_save};
        %standard_npcs=%standard_tsl_npcs;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
        %standard_npcs=%standard_tjm_npcs;
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
        %standard_npcs=%tjm_npcs;
    }
    my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];
    my $datahash=$tree->entrycget($root,-data);
    my $pty_gff=$datahash->{'GFF-pty'};
    my $pt_avail_npcs_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('PT_AVAIL_NPCS')]{Value};
    my @widges;
    my @vals;
    my $lbl=$mw->Label(-text=>"(only two can be selected)")->place(-relx=>650/$x,-rely=>70/$y);
    push @spawned_widgets,$lbl;
    for my $std_npc (sort {$a<=>$b} keys %standard_npcs) {
        my $avail_npc_struct=$$pt_avail_npcs_arr_ref[$std_npc];
        $vals[$std_npc]=0;
        $widges[$std_npc]=$mw->Checkbutton(-text=>$standard_npcs{$std_npc},-variable=>\$vals[$std_npc],
          -command=>sub { if ($vals[$std_npc]==1) {
              my $sum;
              for my $val (@vals) { $sum += $val }
              if ($sum > 2) { $vals[$std_npc]=0 }
          } }
        )->place(-relx=>650/$x,-rely=>(100+(30*$std_npc))/$y);
        push @spawned_widgets, $widges[$std_npc];
        unless ($avail_npc_struct->{Fields}[$avail_npc_struct->fbl('PT_NPC_AVAIL')]{Value}) {
            $widges[$std_npc]->configure(-state=>'disabled')
        }
    }
    my $pt_members_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('PT_MEMBERS')]{Value};
    for my $pt_member (@$pt_members_arr_ref) {
        my $pt_member_id=$pt_member->{Fields}[$pt_member->fbl('PT_MEMBER_ID')]{Value};
        $vals[$pt_member_id]=1;
    }
    my $lbltxt;
    for (my $ix=0; $ix< scalar @vals; $ix++)  {
        if ($vals[$ix]) {
            if ($lbltxt) {
                $lbltxt = join ", ",($lbltxt,$standard_npcs{$ix})
            }
            else {
                $lbltxt = $standard_npcs{$ix}
            }
        }
    }
    if ($lbltxt eq '') { $lbltxt = "--";}
    my $lbl2=$mw->Label(-text=>"Current Party: $lbltxt")->place(-relx=>650/$x,-rely=>40/$y);
    push @spawned_widgets,$lbl2;

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        my @new_pt_members;
        $lbltxt='';
        for my $std_npc (sort {$a<=>$b} keys %standard_npcs) {
            if ($vals[$std_npc]) {
                if ($lbltxt) { $lbltxt = join ", ",($lbltxt,$standard_npcs{$std_npc})  } else { $lbltxt = $standard_npcs{$std_npc} }

                my $struct=Bioware::GFF::Struct->new(ID=>0);
                $struct->createField('Type'=>FIELD_INT,'Label'=>'PT_MEMBER_ID','Value'=>$std_npc);
                $struct->createField('Type'=>FIELD_BYTE,'Label'=>'PT_IS_LEADER','Value'=>0);
                push @new_pt_members,$struct;
            }
        }
        if ($lbltxt eq '') { $lbltxt = "--";}
        $lbltxt = "Current Party: $lbltxt";
        $lbl2->configure(-text=>$lbltxt);
        $tree->entryconfigure($treeitem,-text=>$lbltxt);
        $pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('PT_MEMBERS')]{Value}=[@new_pt_members];
        $datahash->{'GFF-pty'}=$pty_gff;


    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;
    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub {CommitChanges($treeitem) }
    )->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;

}
#>>>>>>>>>>>>>>>>>>>>>>
sub Populate_NPCs{
    #>>>>>>>>>>>>>>>>>>>>>>

    my $treeitem=shift;
    my $gameversion=(split /#/,$treeitem)[1];
    my $registered_path;
    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    my $erf_sav=${$tree->entrycget( '#'.$gameversion.'#'.(split /#/,$treeitem)[2],-data)}{'ERF-sav'};
    my $avail_npcs_ref=$tree->entrycget($treeitem,-data);
    my @npc_gffs;
    my @npc_names;
    #get npc gffs now
    for my $npc_num (@$avail_npcs_ref) {
        my $tmpfil=$erf_sav->export_resource_to_temp_file("AVAILNPC$npc_num.utc");
        my $npc_gff=Bioware::GFF->new();
        $npc_gff->read_gff_file($tmpfil->{'fn'});
        LogInfo ("AVAILNPC$npc_num read into memory " . (-s $tmpfil->{'fn'}) ." bytes). Parsing module");
        my $strref=$npc_gff->{Main}{'Fields'}[$npc_gff->{Main}->get_field_ix_by_label('FirstName')]{'Value'}{'StringRef'};
        my $npcname;
        if ($strref == -1) {
            $npcname=$npc_gff->{Main}{'Fields'}[$npc_gff->{Main}->get_field_ix_by_label('FirstName')]{'Value'}{'Substrings'}[0]{Value};
        } else {
            $npcname=Bioware::TLK::string_from_resref($registered_path,$strref);
        }
        $tree->add($treeitem."#NPC$npc_num",-text=>$npcname,-data=>$npc_gff);
        $tree->add($treeitem."#NPC$npc_num#",-text=>'');
        $tree->hide('entry',$treeitem."#NPC$npc_num#");
    }
    $tree->autosetmode();
}

#>>>>>>>>>>>>>>>>>>>>
sub Populate_NPC{
    #>>>>>>>>>>>>>>>>>>>>
    my $treeitem=shift;
    my $gameversion=(split /#/,$treeitem)[1];
    my $gamedir=(split /#/,$treeitem)[2];
    my $registered_path;
    my %genders;
    my %appearance_hash;
    my %portraits_hash;
    my %soundset_hash;
    my %skills;
    my %feats_full;
    my %powers_full;
    my %classes;
    $treeitem=~/NPC(\d+)$/;
    my $npc_number=$1;
    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor};
        %genders=%gender_hash1;
        %appearance_hash=%appearance_hash1;
        %portraits_hash=%portraits_hash1;
        %soundset_hash=%soundset_hash1;
        %skills=%skills_hash1;
        %feats_full=%feats_full1;
        %powers_full=%powers_full1;
        %classes=%classes_hash1;
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl};
        %genders=%gender_hash2;
        %appearance_hash=%appearance_hash2;
        %portraits_hash=%portraits_hash2;
        %soundset_hash=%soundset_hash2;
        %skills=%skills_hash2;
        %feats_full=%feats_full2;
        %powers_full=%powers_full2;
        %classes=%classes_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl};
        %genders=%gender_hash2;
        %appearance_hash=%appearance_hash2;
        %portraits_hash=%portraits_hash2;
        %soundset_hash=%soundset_hash2;
        %skills=%skills_hash2;
        %feats_full=%feats_full2;
        %powers_full=%powers_full2;
        %classes=%classes_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm};
        %genders=%gender_hash3;
        %appearance_hash=%appearance_hash3;
        %portraits_hash=%portraits_hash3;
        %soundset_hash=%soundset_hash3;
        %skills=%skills_hash3;
        %feats_full=%feats_full3;
        %powers_full=%powers_full3;
        %classes=%classes_hash3;
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm};
        %genders=%gender_hash3;
        %appearance_hash=%appearance_hash3;
        %portraits_hash=%portraits_hash3;
        %soundset_hash=%soundset_hash3;
        %skills=%skills_hash3;
        %feats_full=%feats_full3;
        %powers_full=%powers_full3;
        %classes=%classes_hash3;
    }

    my $gff=$tree->entrycget($treeitem,-data);  #FIX THIS (CAN MODIFY)

    my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];# print "\$root is: $root\n";
    my $datahash;
    my $influence;
    #Get Influence from partytable.res for TSL
    if ($gameversion==2 || 3) {
        $datahash=$tree->entrycget($root,-data);
        my $pty_gff=$datahash->{'GFF-pty'};
        my $influence_ix=$pty_gff->{Main}->get_field_ix_by_label('PT_INFLUENCE');
        if (defined($influence_ix)) {
            $influence=$pty_gff->{Main}{Fields}[$influence_ix]{Value}[$npc_number]{Fields}{Value};
        }
    }

    #normal stuff
    my $appearance     =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Appearance_Type')]{Value};
    my $portrait       =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('PortraitId')]{Value};
    my $att_str        =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Str')]{Value};
    my $att_dex        =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Dex')]{Value};
    my $att_con        =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Con')]{Value};
    my $att_int        =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Int')]{Value};
    my $att_wis        =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Wis')]{Value};
    my $att_cha        =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Cha')]{Value};
    my $hitpoints      =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('HitPoints')]{Value};
    my $maxhitpoints   =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('MaxHitPoints')]{Value};
    my $min1hp         =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Min1HP')]{Value};
    my $forcepoints    =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('ForcePoints')]{Value};
    my $maxforcepoints =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('MaxForcePoints')]{Value};
    my $experience     =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Experience')]{Value};
    my $gender         =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Gender')]{Value};
    my $goodevil       =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('GoodEvil')]{Value};
    my $skill_structs  =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('SkillList')]{Value};
    my $feat_structs   =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('FeatList')]{Value};
    my $class_structs  =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('ClassList')]{Value};
    my $soundset       =$gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('SoundSetFile')]{Value};

    my $mod_playerequiplist = $gff->{Main}{Fields}[$gff->{Main}->get_field_ix_by_label('Equip_ItemList')]{Value};
    my ($head, $implant, $rarm, $larm, $gloves, $belt, $rweapon, $rweapon2, $lweapon, $lweapon2, $armor);

    my $in = 0;
    foreach (@$mod_playerequiplist)
    {
        my $id = $mod_playerequiplist->[$in]{ID};

        if($id == 1)
        {
            $head = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 2)
        {
            $armor = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 8)
        {
            $gloves = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 16)
        {
            $rweapon = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 32)
        {
            $lweapon = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 128)
        {
            $larm = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 256)
        {
            $rarm = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 512)
        {
            $implant = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 1024)
        {
            $belt = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 262144)
        {
            $rweapon2 = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        if($id == 524288)
        {
            $lweapon2 = $mod_playerequiplist->[$in]{Fields}[$mod_playerequiplist->[$in]->get_field_ix_by_label('Tag')]{Value};
        }
        $in++;
    }

    $tree->add($treeitem."#Appearance",-text=>"Appearance: $appearance_hash{$appearance}",-data=>'can modify');
    $tree->add($treeitem."#Portrait",-text=>"Portrait: $portraits_hash{$portrait}",-data=>'can modify');
    $tree->add($treeitem."#Soundset",-text=>"Soundset: $soundset_hash{$soundset}",-data=>'can modify');
    $tree->add($treeitem."#STR",-text=>"STR: $att_str",-data=>'can modify');
    $tree->add($treeitem."#DEX",-text=>"DEX: $att_dex",-data=>'can modify');
    $tree->add($treeitem."#CON",-text=>"CON: $att_con",-data=>'can modify');
    $tree->add($treeitem."#INT",-text=>"INT: $att_int",-data=>'can modify');
    $tree->add($treeitem."#WIS",-text=>"WIS: $att_wis",-data=>'can modify');
    $tree->add($treeitem."#CHA",-text=>"CHA: $att_cha",-data=>'can modify');
    $tree->add($treeitem."#Equipment",-text=>"Equipment", -data=>$mod_playerequiplist);
    $tree->add($treeitem."#Equipment#Head",    -text=>"Head:\t\t$head");           $tree->hide('entry', $treeitem."#Equipment#Head");
    $tree->add($treeitem."#Equipment#Implant", -text=>"Implant:\t\t$implant");     $tree->hide('entry', $treeitem."#Equipment#Implant");
    $tree->add($treeitem."#Equipment#RArm",    -text=>"Right Arm:\t$rarm");        $tree->hide('entry', $treeitem."#Equipment#RArm");
    $tree->add($treeitem."#Equipment#LArm",    -text=>"Left Arm:\t\t$larm");       $tree->hide('entry', $treeitem."#Equipment#LArm");
    $tree->add($treeitem."#Equipment#Gloves",  -text=>"Gloves:\t\t$gloves");       $tree->hide('entry', $treeitem."#Equipment#Gloves");
    $tree->add($treeitem."#Equipment#Armor",   -text=>"Armor:\t\t$armor");         $tree->hide('entry', $treeitem."#Equipment#Armor");
    $tree->add($treeitem."#Equipment#Belt",    -text=>"Belt:\t\t$belt");           $tree->hide('entry', $treeitem."#Equipment#Belt");
    $tree->add($treeitem."#Equipment#RWeapon", -text=>"Right Weapon:\t$rweapon");  $tree->hide('entry', $treeitem."#Equipment#RWeapon");
    $tree->add($treeitem."#Equipment#LWeapon", -text=>"Left Weapon:\t$lweapon");   $tree->hide('entry', $treeitem."#Equipment#LWeapon");
    $tree->add($treeitem."#HitPoints",-text=>"HitPoints: $hitpoints",-data=>'can modify');
    $tree->add($treeitem."#MaxHitPoints",-text=>"MaxHitPoints: $maxhitpoints",-data=>'can modify');
    $tree->add($treeitem."#Min1HP",-text=>"Min1HP: $min1hp",-data=>'can modify');
    $tree->add($treeitem."#Experience",-text=>"Experience: $experience",-data=>'can modify');
    $tree->add($treeitem."#ForcePoints",-text=>"Force Points: $forcepoints",-data=>'can modify');
    $tree->add($treeitem."#MaxForcePoints",-text=>"Max Force Points: $maxforcepoints",-data=>'can modify');
    $tree->add($treeitem."#Gender",-text=>"Gender: $genders{$gender}",-data=>'can modify');
    $tree->add($treeitem."#GoodEvil",-text=>"GoodEvil: $goodevil",-data=>'can modify');
    if (defined ($influence)) {
        $tree->add($treeitem."#Influence",-text=>"Influence: $influence",-data=>'can modify');
    }
    $tree->add($treeitem."#Skills",-text=>"Skills");
    for (my $i=0; $i<=7; $i++) {
        $tree->add($treeitem."#Skills#Skill$i",
          -text=>"$skills{$i}: " . $skill_structs->[$i]{'Fields'}{'Value'},
          -data=>'can modify');
        $tree->hide('entry',$treeitem."#Skills#Skill$i");
    }
    $tree->add($treeitem."#Feats",-text=>"Feats",-data=>'can modify');
    for my $featstruct (@$feat_structs) {
        $tree->add($treeitem."#Feats#Feat".$feats_full{label}{$featstruct->{'Fields'}{'Value'}},
          -text=>$feats_full{name}{$featstruct->{'Fields'}{'Value'}},
          -data=>'can modify');
        $tree->hide('entry',$treeitem."#Feats#Feat".$feats_full{label}{$featstruct->{'Fields'}{'Value'}});
    }
    $tree->add($treeitem."#Classes",-text=>"Classes");
    my $i=0;
    for my $classstruct (@$class_structs) {
        my $classname=$classes{$classstruct->{'Fields'}[0]{'Value'}};
        $tree->add($treeitem."#Classes#Class$i",-text=>$classes{$classstruct->{'Fields'}[$classstruct->get_field_ix_by_label('Class')]{'Value'}},-data=>'can modify');
        $tree->add($treeitem."#Classes#Class$i#Level",-text=>"Level: ".$classstruct->{'Fields'}[$classstruct->get_field_ix_by_label('ClassLevel')]{'Value'},-data=>'can modify');
        $tree->hide('entry',$treeitem."#Classes#Class$i");
        $tree->hide('entry',$treeitem."#Classes#Class$i#Level");
        my $knownlist0_ix=$classstruct->get_field_ix_by_label('KnownList0');
        if (defined $knownlist0_ix) {
            $tree->add($treeitem."#Classes#Class$i#KnownList0",-text=>'Force Powers',-data=>'can modify');
            my @power_structs=@{$classstruct->{'Fields'}[$knownlist0_ix]{'Value'}};
            for my $power_struct (@power_structs) {
                $tree->add($treeitem."#Classes#Class$i#KnownList0#Power".$powers_full{label}{$power_struct->{'Fields'}{'Value'}},
                  -text=>"$powers_full{name}{$power_struct->{'Fields'}{'Value'}}",
                  -data=>'can modify');
                $tree->hide('entry',$treeitem."#Classes#Class$i#KnownList0#Power".$powers_full{label}{$power_struct->{'Fields'}{'Value'}});
                LogInfo ("--- Power: " . $powers_full{name}{$power_struct->{'Fields'}{'Value'}});
            }
            $tree->hide('entry',$treeitem."#Classes#Class$i#KnownList0");
        }
        $i++;
    }

    if ($gameversion == 2) {
        $tree->add($treeitem."#Equipment#RWeapon2",-text=>"Right Weapon 2:\t$rweapon2");  $tree->hide('entry', $treeitem."#Equipment#RWeapon2");
        $tree->add($treeitem."#Equipment#LWeapon2",-text=>"Left Weapon 2:\t$lweapon2");   $tree->hide('entry', $treeitem."#Equipment#LWeapon2");
    }
    if ($gameversion == 3) {
        $tree->add($treeitem."#Equipment#RWeapon2",-text=>"Right Weapon 2:\t$rweapon2");  $tree->hide('entry', $treeitem."#Equipment#RWeapon2");
        $tree->add($treeitem."#Equipment#LWeapon2",-text=>"Left Weapon 2:\t$lweapon2");   $tree->hide('entry', $treeitem."#Equipment#LWeapon2");
    }
    if ($gameversion == 4) {
        $tree->add($treeitem."#Equipment#RWeapon2",-text=>"Right Weapon 2:\t$rweapon2");  $tree->hide('entry', $treeitem."#Equipment#RWeapon2");
        $tree->add($treeitem."#Equipment#LWeapon2",-text=>"Left Weapon 2:\t$lweapon2");   $tree->hide('entry', $treeitem."#Equipment#LWeapon2");
    }
    $tree->autosetmode();
}

#>>>>>>>>>>>>>>>>>>>>
sub Populate_AreaContainer{

    # Pulling game version and gamedir (which savegame)
    my $treeItem = shift;
    my @treeLevels = split /#/, $treeItem;
    shift @treeLevels;
    my $gameVersion = $treeLevels[0];
    my $containerType = $treeLevels[3];
    my $registeredPath = GetRegisteredPath($gameVersion);

    LogInfo "Populating ".$containerType."...";

    # Getting back the save data
    my $treeRoot = '#'.$treeLevels[0].'#'.$treeLevels[1];
    my $dataHash = $tree->entrycget($treeRoot,-data);
    my $git_gff  = $dataHash->{'GFF-git'};

    # Looking for containers
    my $containerList;
    if( $containerType eq 'Stores' ){
        $containerList = $git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('StoreList')]{Value};
    }
    elsif( $containerType eq 'Placeables' ){
        $containerList = $git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Placeable List')]{Value};
    }
    elsif( $containerType eq 'Creatures' ){
        $containerList = $git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Creature List')]{Value};
    }
    elsif( $containerType eq 'Doors' ){
        $containerList = $git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Door List')]{Value};
    }
    else{ return; }

    my $nbContainers = scalar @$containerList;
    LogInfo " ".$nbContainers." containers have been found.";

    my $iContainer = 0;
    foreach(@$containerList) {

        # my $container = $containerList->[$iContainer]; # Does not work

        my $containerTag 	= $containerList->[$iContainer]{Fields}[$containerList->[$iContainer]->get_field_ix_by_label('Tag')]{Value};

        my $containerStrref;
        if( $containerType eq 'Creatures' ){
            $containerStrref = $containerList->[$iContainer]{Fields}[$containerList->[$iContainer]->get_field_ix_by_label('FirstName')]{Value}{StringRef};
        }
        else{
            $containerStrref = $containerList->[$iContainer]{Fields}[$containerList->[$iContainer]->get_field_ix_by_label('LocName')]{Value}{StringRef};
        }

        my $containerName 	= "UNNAMED";
        if ( $containerStrref != -1 ) {
            $containerName=Bioware::TLK::string_from_resref( $registeredPath,$containerStrref );
        }
        # my $containerDisplayTitle = sprintf( "%-32s%s", $containerTag, $containerName );
        my $containerDisplayTitle = sprintf( "%s (%s)", $containerName, $containerTag );

        if( $containerList->[$iContainer]{Fields}[$containerList->[$iContainer]->get_field_ix_by_label('HasInventory')]{Value} ){

            my $itemList = $containerList->[$iContainer]{Fields}[$containerList->[$iContainer]->get_field_ix_by_label('ItemList')]{Value};

            LogDebug "-> ".$containerDisplayTitle;
            $tree->add(
              $treeItem."#".$iContainer."_".$containerTag,
              -text=>$containerDisplayTitle,
              -data=>'can modify'
            );

            my $iItem=0;
            # for my $item (sort @items){
            foreach(@$itemList){

                if( 	$containerType eq 'Creatures'
                  and $itemList->[$iItem]{Fields}[$itemList->[$iItem]->get_field_ix_by_label('Dropable')]{Value} == 0 ){
                    # skip
                    next;
                }

                my $itemStrref = $itemList->[$iItem]{Fields}[$itemList->[$iItem]->get_field_ix_by_label('LocalizedName')]{Value}{StringRef};

                my $itemName;
                if( $itemStrref == -1 ) {
                    $itemName = $itemList->[$iItem]{Fields}[$itemList->[$iItem]->get_field_ix_by_label('LocalizedName')]{Value}{Substrings}[0]{Value};
                }
                else {
                    $itemName=Bioware::TLK::string_from_resref( $registeredPath, $itemStrref );
                }

                my $itemTag 	= lc $itemList->[$iItem]{Fields}[$itemList->[$iItem]->get_field_ix_by_label('Tag')]{Value};
                my $itemStack 	= $itemList->[$iItem]{Fields}[$itemList->[$iItem]->get_field_ix_by_label('StackSize')]{Value};
                my $itemTitle	= sprintf( "%s [%d] (%s)", $itemName, $itemStack, $itemTag );

                LogDebug "     ".$itemTitle;
                $tree->add($treeItem."#".$iContainer."_".$containerTag."#".$itemTag."/".$iItem, -text=>$itemTitle, -data=>'can modify');
                $tree->hide('entry',$treeItem."#".$iContainer."_".$containerTag."#".$itemTag."/".$iItem);
                $iItem++;

            }
        }
        else{
            if($containerType eq 'Doors'){
                $tree->add(
                  $treeItem."#".$iContainer."_".$containerTag,
                  -text=>$containerDisplayTitle,
                  -data=>'can modify'
                );
            }
            else{
                # $tree->add(
                # 	$treeItem."#".$iContainer."_".$containerTag,
                # 	-text=>$containerDisplayTitle
                # 	# Can't modify!
                # );
            }
        }


        $iContainer++;
    }

    $tree->autosetmode();

}


#>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnWidgets{
    #>>>>>>>>>>>>>>>>>>>>>>>>>>

    # Purpose: to create/destroy widgets according to the leaf selected
    # Inputs: tree item selected
    # Outputs: none
    # Side-effects: creates/destroys widges on side panel
    my $treeitem=shift;
    for my $widge (@spawned_widgets, $picture_label) {   #unspawn old widgets
        $widge->destroy if Tk::Exists($widge);
    }
    @spawned_widgets=();

    eval {$picture_label_photo->delete};
    my $use_generic_widgets=join '#', ('z', qw (
      STR DEX WIS CON INT CHA HitPoints MaxHitPoints ForcePoints MaxForcePoints Experience GoodEvil XPosition YPosition ZPosition Level),'z');

    my $lastleaf=(split /#/, $treeitem)[-1];
    my ($ifo_gff,$res_gff,$pty_gff,$inv_gff,$git_gff);

    my $gameversion=(split /#/,$treeitem)[1];
    my $savegamedir=(split /#/,$treeitem)[2];
    my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];
    my $datahash=$tree->entrycget($root,-data);

    my $treeDepth=scalar (split /#/,$treeitem);

    $pty_gff=$datahash->{'GFF-pty'};
    $res_gff=$datahash->{'GFF-res'};
    $inv_gff=$datahash->{'GFF-inv'};
    $git_gff=$datahash->{'GFF-git'};
    if ($treeitem=~/NPCs#NPC(\d+)/)
    {
        my $npcnum=$1;
        if ($datahash->{"AVAILNPC$npcnum.utc"}) {           #if we've already modified this NPC
            $ifo_gff=$datahash->{"AVAILNPC$npcnum.utc"};    #then use the modified GFF
        }
        else {                                              #otherwise, grab the original
            $treeitem=~/(.*NPCs#NPC\d+)/;
            $ifo_gff=$tree->entrycget($1,-data);
        }
        if ($treeitem=~/NPCs#NPC\d+$/) {                     #for the special case of changing NPC name
            my $cur_npc_name=$tree->entrycget($treeitem,-text);
            SpawnFirstNameWidgets($treeitem,$cur_npc_name,\$ifo_gff);
        }
    }
    else
    {
        $ifo_gff=$datahash->{'GFF-ifo'};
    }

    if    ($treeitem =~ /(.*#Globals)#Booleans/) {
        my $gbl_gff=$tree->entrycget($1,-data);
        SpawnBooleanWidgets ($treeitem,\$gbl_gff);}
    elsif ($treeitem =~ /(.*#Globals)#Numerics/) {
        my $gbl_gff=$tree->entrycget($1,-data);
        SpawnNumericWidgets ($treeitem,\$gbl_gff);}
    elsif ($lastleaf eq 'Feats') {
        SpawnAddFeatWidgets ($treeitem,\$ifo_gff); }
    elsif ($lastleaf eq 'Appearance') {
        SpawnAppearanceWidgets ($treeitem,\$ifo_gff); }
    elsif ($lastleaf eq 'Portrait') {
        SpawnPortraitWidgets ($treeitem,\$ifo_gff); }
    elsif ($lastleaf eq 'CurrentParty') {
        Current_Party($treeitem) }
    elsif ($lastleaf eq 'Soundset') {
        SpawnSoundsetWidgets ($treeitem,\$ifo_gff); }
    elsif ($lastleaf eq 'KnownList0') {
        SpawnAddPowerWidgets ($treeitem,\$ifo_gff); }
    elsif ($lastleaf eq 'Journal') {
        SpawnAddJRLWidgets ($treeitem); }
    elsif ($use_generic_widgets=~/#$lastleaf#/) {
        ($tree->entrycget($treeitem,-text)) =~ /: (.*)/;
        SpawnGenericWidgets ($treeitem,$lastleaf,$1,\$ifo_gff) }
    elsif ($lastleaf=~/Class/) {
        SpawnChangeClassWidgets ($treeitem,\$ifo_gff); }
    elsif ($lastleaf=~/Feat/) {
        my $current_feat=$tree->entrycget($treeitem,-text);
        SpawnFeatWidgets ($treeitem,$current_feat,\$ifo_gff) }
    elsif ($lastleaf=~/Skill/) {
        ($tree->entrycget($treeitem,-text))=~/(.*): (.*)/;
        SpawnSkillWidgets ($treeitem,$1,$2,\$ifo_gff) }
    elsif ($lastleaf=~/Power/) {
        my $current_power=$tree->entrycget($treeitem,-text);
        SpawnPowerWidgets ($treeitem,$current_power,\$ifo_gff) }
    elsif ($lastleaf eq 'Gender') {
        ($tree->entrycget($treeitem,-text)) =~ /: (.*)/;
        SpawnGenderWidgets ($treeitem,$1,\$ifo_gff) }
    elsif ($lastleaf eq 'Credits') {
        ($tree->entrycget($treeitem,-text)) =~ /(.*): (.*)/;
        SpawnPartyWidgets  ($treeitem,$1,$2,\$pty_gff) }
    elsif ($lastleaf eq 'PartyXP') {
        ($tree->entrycget($treeitem,-text)) =~ /(.*): (.*)/;
        SpawnPartyWidgets  ($treeitem,$1,$2,\$pty_gff) }
    elsif ($lastleaf eq 'Chemicals') {
        ($tree->entrycget($treeitem,-text)) =~ /(.*): (.*)/;
        SpawnPartyWidgets  ($treeitem,$1,$2,\$pty_gff) }
    elsif ($lastleaf eq 'Components') {
        ($tree->entrycget($treeitem,-text)) =~ /(.*): (.*)/;
        SpawnPartyWidgets  ($treeitem,$1,$2,\$pty_gff) }
    elsif ($lastleaf eq 'Influence') {
        ($tree->entrycget($treeitem,-text)) =~ /(.*): (.*)/;
        SpawnPartyWidgets  ($treeitem,$1,$2,\$pty_gff) }
    elsif ($lastleaf eq 'SaveGameName') {
        ($tree->entrycget($treeitem,-text)) =~ /: (.*)/;
        SpawnSaveGameNameWidgets  ($treeitem,$1,\$res_gff) }
    elsif ($lastleaf eq 'FirstName') {
        ($tree->entrycget($treeitem,-text)) =~ /: (.*)/;
        SpawnFirstNameWidgets  ($treeitem,$1,\$ifo_gff) }
    elsif ($lastleaf eq 'TimePlayed') {
        ($tree->entrycget($treeitem,-text)) =~ /(\d+)h (\d+)m (\d+)/;
        SpawnTimePlayedWidgets ($treeitem,$1,$2,$3,\$res_gff) }
    elsif (($lastleaf eq 'CheatUsed') || ($lastleaf eq 'Min1HP')) {
        ($tree->entrycget($treeitem,-text)) =~ /: (\d)/;
        SpawnCheatWidgets ($treeitem,$1,\$res_gff,\$pty_gff,\$ifo_gff); }
    elsif ($treeitem =~/#Inventory$/) {
        SpawnAddInventoryWidgets($treeitem); }
    elsif ($treeitem =~/#Inventory#/) {
        SpawnInventoryWidgets($treeitem,\$inv_gff);
    }
    elsif ($treeitem =~/#Area#Doors#/) {
        SpawnDoorWidgets($treeitem,\$git_gff);
    }
    elsif ($treeitem =~/#Area#Placeables#/ || $treeitem =~ /#Area#Creatures#/ || $treeitem =~/#Area#Stores#/){
        if($treeDepth < 7){
            SpawnAddInventoryWidgets($treeitem); # will check if the selected treeitem is a placeable inside!
        }
        else{
            SpawnInventoryWidgets($treeitem,\$git_gff);
        }
    }
    elsif ($treeitem =~/#Equipment#/) {#print "laun";
        if($treeitem =~/#(NPC[0-9]*)#/)
        {
            my $npcek = $1; $npcek =~ s/NPC//;

            if($treeitem =~/Head$/)     { &Populate_EquipTables(1,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/Implant$/)  { &Populate_EquipTables(2,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/Armor$/)    { &Populate_EquipTables(3,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/RArm$/)     { &Populate_EquipTables(4,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/LArm$/)     { &Populate_EquipTables(5,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/Gloves$/)   { &Populate_EquipTables(6,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/Belt$/)     { &Populate_EquipTables(7,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/RWeapon$/)  { &Populate_EquipTables(8,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/LWeapon$/)  { &Populate_EquipTables(9,  $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/RWeapon2$/) { &Populate_EquipTables(10, $parm1, \$ifo_gff, 1); }
            elsif($treeitem =~/LWeapon2$/) { &Populate_EquipTables(11, $parm1, \$ifo_gff, 1); }
        }
        else
        {
            if($treeitem =~/Head$/)     { &Populate_EquipTables(1,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/Implant$/)  { &Populate_EquipTables(2,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/Armor$/)    { &Populate_EquipTables(3,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/RArm$/)     { &Populate_EquipTables(4,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/LArm$/)     { &Populate_EquipTables(5,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/Gloves$/)   { &Populate_EquipTables(6,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/Belt$/)     { &Populate_EquipTables(7,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/RWeapon$/)  { &Populate_EquipTables(8,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/LWeapon$/)  { &Populate_EquipTables(9,  $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/RWeapon2$/) { &Populate_EquipTables(10, $parm1, \$ifo_gff, 0); }
            elsif($treeitem =~/LWeapon2$/) { &Populate_EquipTables(11, $parm1, \$ifo_gff, 0); }
        }
    }
}


#>>>>>>>>>>>>>>>>>>>
sub CommitChanges {
    #>>>>>>>>>>>>>>>>>>>

    my $treeitem=shift;
    my $gv;
    my $gm;

    LogWarning "Committing changes...";

    my @parms = split /#/, $treeitem;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;
    my $gameversion=(split /#/,$treeitem)[1];
    my $registered_path;
    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor_save};
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl_save};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl_cloud};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
    }

    my $gamedir=(split /#/,$treeitem)[2];

    # retrieve all of our files except NPC .utc
    my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];
    my $datahash=$tree->entrycget($root,-data);
    my $erf_sav=$datahash->{'ERF-sav'};
    my $erf_mod=$datahash->{'ERF-mod'};
    my $ifo_gff=$datahash->{'GFF-ifo'};
    my $pty_gff=$datahash->{'GFF-pty'};
    my $res_gff=$datahash->{'GFF-res'};
    my $inv_gff=$datahash->{'GFF-inv'};
    my $git_gff=$datahash->{'GFF-git'};
    my $gbl_gff=$tree->entrycget("$root#Globals",-data);
    #$mw->Busy(-recurse=>1); #BUG ? -> when commiting while the scrolling windows is not up

    LogInfo ("Committing changes for $gv->$gm");

    # write PARTYTABLE.res
    my $fn="$registered_path\\$gamedir\\PARTYTABLE.res";
    my $tot_pty_written=$pty_gff->write_gff_file($fn);
    if ($tot_pty_written==0) { die "Could not write to $registered_path\\$gamedir\\PARTYTABLE.res" }
    LogInfo ("Partytable updated. $tot_pty_written bytes written.");

    # write savenfo.res
    my $fn2="$registered_path\\$gamedir\\savenfo.res";
    my $tot_res_written=$res_gff->write_gff_file($fn2);
    if ($tot_res_written==0) { die "Could not write to $registered_path\\$gamedir\\savenfo.res" }
    LogInfo ("Savenfo updated. $tot_res_written bytes written.");

    # write GLOBALVARS.res
    if (ref $gbl_gff eq 'Bioware::GFF') {
        my $fn2a="$registered_path\\$gamedir\\GLOBALVARS.res";
        my $tot_gbl_written=$gbl_gff->write_gff_file($fn2a);
        if ($tot_gbl_written==0) { die "Could not write to $registered_path\\$gamedir\\GLOBALVARS.res" }
        LogInfo ("GLOBALVARS.res updataed.  $tot_gbl_written bytes written.");
    }

    # write Module.ifo to tempfile
    my $tmpFile_ModuleIfoGff=Win32API::File::Temp->new();
    unless (my $tmp=$ifo_gff->write_gff_file($tmpFile_ModuleIfoGff->{'fn'})) {
        die "Could not write module.ifo to temp file.";
    }

    # write last module git to tempfile
    my $tmpFile_LastModuleGitGff=Win32API::File::Temp->new();
    unless (my $tmp=$git_gff->write_gff_file($tmpFile_LastModuleGitGff->{'fn'})) {
        die "Could not write module.ifo to temp file.";
    }

    # populate the erf_mod with its original data
    unless (my $tmp=$erf_mod->load_erf()) {
        die "Failed to read in last module of savegame.";
    }


    # insert into erf_mod the new module.ifo file
    unless (my $tmp=$erf_mod->import_resource($tmpFile_ModuleIfoGff->{'fn'},'Module.ifo')) {
        die "Failed to import Module.ifo into last module of savegame";
    }

    # insert into erf_mod the new lastModule.git file
    LogDebug "lastModuleGitName = ".$git_gff->{'modulename'};
    unless (my $tmp=$erf_mod->import_resource($tmpFile_LastModuleGitGff->{'fn'}, $git_gff->{'modulename'}.'.git')) {
        die "Failed to import ".$git_gff->{'modulename'}.".git into last module of savegame";
    }

    # write the erf_mod to tempfile
    my $tmpFile_LastModuleSavErf=Win32API::File::Temp->new();
    unless (my $tmp=$erf_mod->write_erf($tmpFile_LastModuleSavErf->{'fn'})) {
        die "Failed to write last module to temp file.";
    }


    # write INVENTORY.res to tempfile
    my $tmpfil_inv=Win32API::File::Temp->new();
    unless (my $tmp=$inv_gff->write_gff_file($tmpfil_inv->{'fn'})) {
        die "Could not write INVENTORY.res to temp file.";
    }

    # load the original erf_sav
    unless (my $tmp=$erf_sav->load_erf()) {
        die "Failed to read in main savegame data";
    }

    # insert into erf_sav the new erf_mod file
    unless (my $tmp=$erf_sav->import_resource($tmpFile_LastModuleSavErf->{'fn'},$erf_mod->{'modulename'}.".sav")) {
        die "Failed to import last module of savegame into main savegame data.";
    }

    # insert into erf_sav the new INVENTORY.res file
    unless (my $tmp=$erf_sav->import_resource($tmpfil_inv->{'fn'},'INVENTORY.res')) {
        die "Failed to import INVENTORY.res into main savegame data.";
    }

    # insert into the erf_sav any NPC file
    for (my $i=0; $i<$max_number_of_npcs; $i++) {
        my $utcname="AVAILNPC$i.utc";
        if ($datahash->{$utcname}) {
            my $utc_gff=$datahash->{$utcname};
            LogInfo "Writing $utcname";
            my $tmpfil=Win32API::File::Temp->new();
            unless (my $tmp=$utc_gff->write_gff_file($tmpfil->{'fn'})) {
                die "Failed to write $utcname to tempfile";
            }
            unless (my $tmp=$erf_sav->import_resource($tmpfil->{'fn'},$utcname)) {
                die "Failed to import $utcname into main savegame data.";
            }
        }
    }

    # if PC.utc exists in datahash, write it also
    my $utcname="PC.utc";
    if ($datahash->{$utcname}) {
        my $utc_gff=$datahash->{$utcname};
        LogInfo "Writing $utcname";
        my $tmpfil=Win32API::File::Temp->new();
        unless (my $tmp=$utc_gff->write_gff_file($tmpfil->{'fn'})) {
            die "Failed to write PC.utc to tempfile";
        }
        unless (my $tmp=$erf_sav->import_resource($tmpfil->{'fn'},$utcname)) {
            die "Failed to import PC.utc to tempfile";
        }
    }




    # write new erf_sav
    my $total_written;
    unless ($total_written=$erf_sav->write_erf("$registered_path\\$gamedir\\savegame.sav")) {
        die "Could not write to $registered_path\\$gamedir\\savegame.sav"
    }
    LogInfo("$registered_path\\$gamedir\\savegame.sav written ($total_written bytes total)");


    # do .sig files if a .sig file exists in the game directory
    chdir "$registered_path/$gamedir";
    my @tmpsig =glob "*.sig";
    LogInfo("Scalar of tmpsig is ". scalar @tmpsig);
    if (scalar @tmpsig) {
        LogWarning ".sig files have been detected (XBox). Regenerating...";
        for my $t (@tmpsig) { LogInfo "sig file detection: $t" }
        my $authkey;
        if ($gameversion==1) {
            $authkey=pack('C16',0x07,0xDF,0x71,0xE6,0xB1,0xFB,0x1C,0x82,0x78,0x26,0x68,0x3C,0x2A,0x48,0x42,0xD3);
        }
        elsif ($gameversion==2) {
            $authkey=pack('C16',0x67,0x77,0x01,0x4b,0xb4,0xad,0xe4,0x21,0x8b,0x3d,0x98,0x67,0xa8,0xba,0x76,0x3c);
        }
        my %gff_to_sig=qw(partytable.res SAVE_PARTY.sig
          globalvars.res SAVE_VARS.sig
          savenfo.res    SAVE_INFO.sig
          screen.tga     Screen.sig);
        for my $f (keys %gff_to_sig) {
            next unless -e "$registered_path\\$gamedir\\$f";
            local $/;
            open my ($fh),"<","$registered_path\\$gamedir\\$f";
            binmode $fh;
            my $data=<$fh>;
            close $fh;
            my $hmac_out= hmac_sha1($data,$authkey);
            open my ($fho),">","$registered_path\\$gamedir\\$gff_to_sig{$f}";
            binmode $fho;
            syswrite $fho, $hmac_out;
            close $fho;
            LogInfo ("$gff_to_sig{$f} created.");
        }

        my $savegame_size= -s "$registered_path\\$gamedir\\savegame.sav";
        #my $headerdata;
        my $headervardata;
        my $datadata;
        my %self;
        (open my ($fh), "<", "$registered_path\\$gamedir\\savegame.sav") or (return 0);
        binmode $fh;
        #sysread $fh,$headerdata,160;

        sysseek $fh,0,0;
        #aux info
        #header
        sysread $fh,$self{'sig'},4;
        sysread $fh,$self{'version'},4;
        my $tmp;
        sysread $fh,$tmp,36;
        ($self{'localized_string_count'},
          $self{'localized_string_size'},
          $self{'entry_count'},
          $self{'offset_to_localized_string'},
          $self{'offset_to_key_list'},
          $self{'offset_to_resource_list'},
          $self{'build_year'},
          $self{'build_day'},
          $self{'description_str_ref'})=unpack('V9',$tmp);

        sysseek $fh,160,0;
        sysread $fh,$headervardata,$self{'offset_to_resource_list'}+(8*$self{'entry_count'})-160;
        sysread $fh,$datadata,$savegame_size;

        # NOT WORKING?
        #my $hmac_out= hmac_sha1($headerdata,$authkey);
        #open my ($fho),">",'SAVE_HEADER.sig';
        #binmode $fho;
        #syswrite $fho, $hmac_out;
        #close $fho;

        my $hmac_out= hmac_sha1($headervardata,$authkey);
        open my ($fho),">","$registered_path\\$gamedir\\SAVE_HEADERVAR.sig";
        binmode $fho;
        syswrite $fho, $hmac_out;
        close $fho;
        LogInfo ("SAVE_HEADERVAR.sig created.");
        $hmac_out= hmac_sha1($datadata,$authkey);
        open $fho,">","$registered_path\\$gamedir\\SAVE_DATA.sig";
        binmode $fho;
        syswrite $fho, $hmac_out;
        close $fho;
        LogInfo ("SAVE_DATA.sig created.");
        LogInfo ".sig files have been regenerated.";
    }


    LogDebug "RELOADING DATA";
    LoadData($treeitem);

    # # Reload
    # # Looking for last module .git file where the inventory of all placeable is stored
    # my $lastModuleGitName;
    # for my $resource (@{$erf_mod->{'resources'}}) {
    # 	if($resource->{'res_ext'} eq "git") {
    # 		$lastModuleGitName = lc $resource->{'res_ref'};
    # 	}
    # }
    #
    # # Extracting the .git file as a temp file
    # my $tmpfil_git;
    # unless($tmpfil_git=$erf_mod->export_resource_to_temp_file("$lastModuleGitName.git")) {
    # 	die "Could not find $lastModuleGitName.git inside of $lastModuleName.sav";
    # }
    #
    # # Parsing the .git temp file
    # my $gff_LastModGit=Bioware::GFF->new();                                                            #create GFF for module.ifo
    # unless (my $tmp=$gff_LastModGit->read_gff_file($tmpfil_git->{'fn'})) {                             #read module.ifo into GFF
    # 	die "Could not read from .git temp file";
    # }
    # $gff_LastModGit->{'modulename'}="$lastModuleGitName";
    # $datahash->{'GFF-git'}=$gff_LastModGit;

    $mw->Unbusy;

    $mw->Dialog(-title=>'Save Successful',-text=>"File $registered_path\\$gamedir\\savegame.sav saved successfully.",-font=>['MS Sans Serif','8'],-buttons=>['Ok'])->Show();
    # exec($^X, $0, @ARGV);

    LogInfo "Commit changes has been done.";

}



#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnFeatWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$cur_feat_name,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %feats_full;
    if ($gameversion==1) {
        %feats_full=%feats_full1;
    }
    elsif ($gameversion==2) {
        %feats_full=%feats_full2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %feats_full=%feats_full2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %feats_full=%feats_full3;
    }
    elsif ($gameversion==4) {
        %feats_full=%feats_full3;
    }

    if ($treeitem =~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }
    my $lbl=$mw->Label(-text=>"Feat: $cur_feat_name",-font=>['MS Sans Serif','8'])->place(-relx=>800/$x,-rely=>200/$y,-anchor=>'ne');
    push @spawned_widgets,$lbl;
    my %revhash_name=reverse %{$feats_full{name}};

    my $featvalue= $revhash_name{$cur_feat_name};
    my $btn=$mw->Button(-text=>"Remove Feat",-command=>sub {
        unless ($tree->info('exists',$treeitem)) {return;}
        LogInfo("Removing feat: $cur_feat_name");
        if ($treeitem=~/NPCs/) {
            my $featlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('FeatList')];
            my $featlist_structs=$featlist->{Value};
            my @new_featlist_structs=();

            for my $this_struct (@$featlist_structs) {
                unless ($this_struct->{Fields}{Value} == $featvalue) {
                    push @new_featlist_structs,$this_struct;
                }
            }
            $featlist->{Value}=[@new_featlist_structs];                   #perform feat removal on NPC
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];       # store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);

        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            my $featlist=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FeatList')];
            my $featlist_structs=$featlist->{Value};
            my @new_featlist_structs=();
            for my $this_struct (@$featlist_structs) {
                unless ($this_struct->{Fields}{Value} == $featvalue) {
                    push @new_featlist_structs,$this_struct;
                }
            }
            $featlist->{Value}=[@new_featlist_structs];                   #perform feat removal on PC
        }
        $tree->delete('entry',$treeitem);
    }
    )->place(-relx=>600/$x,-rely=>520/$y);
    push @spawned_widgets,$btn;

    my $btn3=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn3;
}

#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnAddFeatWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %feats_full;
    my %feats_short;
    my $registered_path;
    my %feats;  #these are number to names/labels

    if ($gameversion==1) {
        %feats_full=%feats_full1;
        %feats_short=%feats_short1;
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        %feats_full=%feats_full2;
        %feats_short=%feats_short2;
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %feats_full=%feats_full2;
        %feats_short=%feats_short2;
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %feats_full=%feats_full3;
        %feats_short=%feats_short3;
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        %feats_full=%feats_full3;
        %feats_short=%feats_short3;
        $registered_path=$kseInitializer->{path}->{tjm};
    }

    %feats=$short_or_long ? %feats_full : %feats_short;

    #these will be our names/labels to numbers
    my %revhash_name=reverse %{$feats{name}};


    if ($treeitem =~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $label=$mw->Label(-text=>"Available Feats:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>100/$y,-anchor=>'sw');
    push @spawned_widgets,$label;

    #my $featlist= $mw->Scrolled('Listbox',
    Tk::Autoscroll::Init(my $featlist= $mw->Scrolled('TList',
      -scrollbars=>'osoe',
      -background=>'white',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#D07000',
      -selectmode=>'extended',
      -itemtype=>'text',
      -orient=>'horizontal'
    ));
    $featlist->place(-relx=>600/$x,-rely=>100/$y,-relwidth=>270/$x,-relheight=>400/$y);

    my $newstyle = $mw->ItemStyle('text',-foreground=>'#9090FF',-selectforeground=>'#D0D0FF',-selectbackground=>'#D07000');
    my @treepath=split /#/, $treeitem;  pop @treepath;  my $newtreepath=join '#',@treepath;
    for (sort keys %revhash_name) {   # $_ will hold our feats' names
        my $ix=$revhash_name{$_};
        my $lbl=$feats{label}{$ix};
        if ($tree->info('exists',"$newtreepath#Feats#Feat".$lbl)) {
            $featlist->insert('end',-text=>$_,-style=>$newstyle);
        }
        else {
            $featlist->insert('end',-text=>$_);
        }
    }
    #display feat icon
    my $erf=Bioware::ERF->new();
    my $img=Imager->new();
    unless ($erf->read_erf("$registered_path\\TexturePacks\\swpc_tex_gui.erf")) {
        undef $erf;
    }
    $featlist->bind('<ButtonRelease-1>'=>sub {
        $picture_label->destroy if Tk::Exists($picture_label);
        eval {$picture_label_photo->delete};

        my ($cur_list_index)=$featlist->info('selection');
        return unless defined($cur_list_index);
        my $selected_feat=$featlist->entrycget($cur_list_index,-text);
        my $featvalue=$revhash_name{$selected_feat};
        return unless my $iconresref=$feats{icon}{$featvalue};
        LogInfo ("Trying to picture: $iconresref");
        my $tgadata;
        my $ftyp='bmp'; #IMAGE FORMAT
        if (-e "$registered_path/override/$iconresref".".tga") {
            local $/;
            open my $tmpfh,"<","$registered_path/override/$iconresref".".tga";
            binmode $tmpfh;
            $tgadata=<$tmpfh>;
            close $tmpfh;
            LogInfo ("KotOR".$gameversion." override $iconresref".".tga detected");
        } else {
            unless (defined ($erf)) {  return; }
            my $erf_ix=$erf->load_erf_resource($iconresref.".tpc");
            return unless defined($erf_ix);
            my $tpc=Bioware::TPC->new();
            my $scalardata=$erf->{resources}[$erf_ix]{res_data};
            my $ret=$tpc->read_tpc(\$scalardata);
            $tpc->write_tga(\$tgadata);
            if (($tpc->{tpc}{header}{data_size}==0) && ($tpc->{tpc}{header}{encoding}==4)) {
                $ftyp='bmp'
            }
            LogInfo ("ftyp: $ftyp $tpc->{tpc}{header}{data_size} $tpc->{tpc}{header}{encoding}");
        }
        $img->read(data=>$tgadata,type=>'tga') or die $img->errstr; ;
        my $buf;
        $img->write(data=>\$buf,type=>$ftyp) or die $img->errstr; ;
        $picture_label_photo=$mw->Photo(-data=>encode_base64($buf),-format=>$ftyp);
        $picture_label=$mw->Label(-image=>$picture_label_photo)->pack(-side=>'top',-anchor=>'ne');
    } );#}

    push @spawned_widgets, $featlist;

    my $btn2=$mw->Button(-text=>"Add New Feat",-command=>sub {
        #my @selected_indices=$featlist->curselection;
        my @selected_indices=$featlist->info('selection');
        unless (scalar @selected_indices) { return; }  #nothing selected
        #if ($cur_list_index eq '' ) { return; } #nothing selected
        my @treepath=split /#/, $treeitem;  pop @treepath;  my $newtreepath=join '#',@treepath;
        for my $selected_index (@selected_indices) {
            my $selected_feat=$featlist->entrycget($selected_index,-text);
            my $featvalue2=$revhash_name{$selected_feat};
            my $lbl=$feats{label}{$featvalue2};
            next if ($tree->info('exists',"$newtreepath#Feats#Feat$lbl"));
            LogInfo ("Adding feat: $selected_feat");
            if ($treeitem=~/NPCs/) {
                my $featlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('FeatList')];
                my $featlist_structs=$featlist->{Value};
                my $new_feat=Bioware::GFF::Struct->new('ID'=>1);
                $new_feat->createField('Type'=>FIELD_WORD,'Label'=>'Feat','Value'=>$featvalue2);
                push @$featlist_structs,$new_feat;                            #add the feat

                my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        # store the new
                my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
                $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
                my $npcnum=$1;                                                #when it comes time to commit changes
                $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
                $tree->entryconfigure($root,-data=>$datahash);   }
            else {
                my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
                my $featlist=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FeatList')];
                my $featlist_structs=$featlist->{Value};
                my $new_feat=Bioware::GFF::Struct->new('ID'=>1);
                $new_feat->createField('Type'=>FIELD_WORD,'Label'=>'Feat','Value'=>$featvalue2);
                push @$featlist_structs,$new_feat;                            #add the feat
            }
            LogInfo ("Successful addition of feat: $selected_feat.");
            $tree->add("$newtreepath#Feats#Feat$lbl",
              -text=>$selected_feat,-data=>'can modify');
            $featlist->entryconfigure($selected_index,-style=>$newstyle);
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>80/$x);
    push @spawned_widgets,$btn2;

    my $btn3=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) }
    )->place(-relx=>776/$x,-rely=>520/$y);

    push @spawned_widgets,$btn3;

    my $btn4=$mw->Button(-text=>"Remove Feats",-command=>sub {
        my @selected_indices=$featlist->info('selection');
        unless (scalar @selected_indices) { return; }  #nothing selected
        my @treepath=split /#/, $treeitem;  pop @treepath;  my $newtreepath=join '#',@treepath;
        for my $selected_index (@selected_indices) {
            my $selected_feat=$featlist->entrycget($selected_index,-text);
            my $featvalue2=$revhash_name{$selected_feat};
            my $lbl=$feats{label}{$featvalue2};
            next unless ($tree->info('exists',"$newtreepath#Feats#Feat$lbl"));
            LogInfo ("Removing feat: $selected_feat");
            if ($treeitem=~/NPCs/) {
                my $featlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('FeatList')];
                my $featlist_structs=$featlist->{Value};
                my @new_featlist_structs=();

                for my $this_struct (@$featlist_structs) {
                    unless ($this_struct->{Fields}{Value} == $featvalue2) {
                        push @new_featlist_structs,$this_struct;
                    }
                }
                $featlist->{Value}=[@new_featlist_structs];                   #perform feat removal on NPC
                my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        # store the new
                my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
                $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
                my $npcnum=$1;                                                #when it comes time to commit changes
                $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
                $tree->entryconfigure($root,-data=>$datahash); }
            else {
                my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
                my $featlist=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FeatList')];
                my $featlist_structs=$featlist->{Value};
                my @new_featlist_structs=();
                for my $this_struct (@$featlist_structs) {
                    unless ($this_struct->{Fields}{Value} == $featvalue2) {
                        push @new_featlist_structs,$this_struct;
                    }
                }
                $featlist->{Value}=[@new_featlist_structs];                   #perform feat removal on PC
            }
            LogInfo ("Successful removal of feat: $selected_feat.");
            $tree->delete('entry',"$newtreepath#Feats#Feat$lbl");
            $featlist->entryconfigure($selected_index,-style=>'');
        }
    }
    )->place(-relx=>688/$x,-rely=>520/$y,-relwidth=>80/$x);
    push @spawned_widgets,$btn4;

    my $chkbtn=$mw->Checkbutton(-text=>'Show all feats/powers',
      -variable=>\$short_or_long,
      -command=> sub {
          %feats=$short_or_long ? %feats_full : %feats_short;
          %revhash_name= reverse %{$feats{name}};
          $featlist->delete(0,'end');
          for (sort keys %revhash_name) {   # $_ will hold our feats' name
              my $ix=$revhash_name{$_};
              my $lbl=$feats{label}{$ix};
              if ($tree->info('exists',"$newtreepath#Feats#Feat".$lbl)) {
                  $featlist->insert('end',-text=>$_,-style=>$newstyle);
              }
              else {
                  $featlist->insert('end',-text=>$_);
              }
          }
      }
    )->place(-relx=>590/$x,-rely=>590/$y, -anchor=>'sw');
    push @spawned_widgets,$chkbtn;
}

#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnSkillWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$cur_skill,$cur_rank,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];

    if ($treeitem =~ /NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }
    my $lbl=$mw->Label(-text=>"Skill: $cur_skill",-font=>['MS Sans Serif','12'])->place(-relx=>810/$x,-rely=>200/$y,-anchor=>'ne');
    push @spawned_widgets,$lbl;
    my $new_rank=$cur_rank;
    my $txt=$mw->Entry(-textvariable=>\$new_rank,-background=>'white')->place(-relx=>820/$x,-rely=>200/$y,-relwidth=>30/$x);
    push @spawned_widgets,$txt;

    $txt->bind('<Return>'=>sub {
        $tree->entryconfigure($treeitem,-text=>"$cur_skill: $new_rank");
        LogInfo("Changing $cur_skill rank to $new_rank");
        my $treeitem2=$treeitem;
        my $skillnumber=chop $treeitem2;
        if ($treeitem=~/NPCs/) {
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('SkillList')]{Value}[$skillnumber]{Fields}{Value}=$new_rank;
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)#/;                                 #so we know that it needs replacing
            my $npcnum=$1;
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('SkillList')]{Value}[$skillnumber]{Fields}{Value}=$new_rank;
        }
    });

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $tree->entryconfigure($treeitem,-text=>"$cur_skill: $new_rank");
        LogInfo("Changing $cur_skill rank to $new_rank");
        my $treeitem2=$treeitem;
        my $skillnumber=chop $treeitem2;
        if ($treeitem=~/NPCs/) {
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('SkillList')]{Value}[$skillnumber]{Fields}{Value}=$new_rank;
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)#/;                                 #so we know that it needs replacing
            my $npcnum=$1;
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('SkillList')]{Value}[$skillnumber]{Fields}{Value}=$new_rank;
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}
#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnPowerWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$cur_power_name,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %powers_full;
    if ($gameversion==1) {
        %powers_full=%powers_full1;
    }
    elsif ($gameversion==2) {
        %powers_full=%powers_full2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %powers_full=%powers_full2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %powers_full=%powers_full3;
    }
    elsif ($gameversion==4) {
        %powers_full=%powers_full3;
    }
    if ($treeitem =~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $lbl=$mw->Label(-text=>"Power: $cur_power_name",-font=>['MS Sans Serif','8'])->place(-relx=>800/$x,-rely=>200/$y,-anchor=>'ne');
    push @spawned_widgets,$lbl;

    my %revhash_name=reverse %{$powers_full{name}};
    my $powervalue= $revhash_name{$cur_power_name};

    my $btn=$mw->Button(-text=>"Remove Power",-command=>sub {
        unless ($tree->info('exists',$treeitem)) { return;}
        $treeitem=~/#Class(\d)#/;
        my $classindex=$1;
        LogInfo ("Removing power: $cur_power_name");

        if ($treeitem=~/NPCs/) {
            $treeitem=~/Class(\d)/;
            my $classnumber=$1;

            my $classlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{Value};
            my $cur_class=$classlist->[$classnumber];
            my $knownlist_ix=$cur_class->get_field_ix_by_label('KnownList0');
            unless (defined $knownlist_ix) { LogInfo ("Failed to remove power");  return; }
            my $powerlist=$cur_class->{Fields}[$knownlist_ix];
            my $powerlist_structs=$powerlist->{Value};
            my @new_powerlist_structs=();

            for my $this_struct (@$powerlist_structs) {
                unless ($this_struct->{Fields}{Value} == $powervalue) {
                    push @new_powerlist_structs,$this_struct;
                }
            }
            $powerlist->{Value}=[@new_powerlist_structs];                 #perform power removal on NPC
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #and if successful, store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)#/;                                 #so we know that it needs replacing
            my $npcnum=$1;
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            my $classlist=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value};
            my $cur_class=$classlist->[$classindex];
            my $knownlist_ix=$cur_class->get_field_ix_by_label('KnownList0');
            unless (defined $knownlist_ix) { LogInfo ("Failed to remove power");  return; }
            my $powerlist=$cur_class->{Fields}[$knownlist_ix];
            my $powerlist_structs=$powerlist->{Value};
            my @new_powerlist_structs=();
            for my $this_struct (@$powerlist_structs) {
                unless ($this_struct->{Fields}{Value} == $powervalue) {
                    push @new_powerlist_structs,$this_struct;
                }
            }
            $powerlist->{Value}=[@new_powerlist_structs];                 #perform power removal on PC
        }
        $tree->delete('entry',$treeitem);
        LogInfo ("Power removed succesfully.");
    }
    )->place(-relx=>600/$x,-rely=>520/$y);
    push @spawned_widgets,$btn;

    my $btn3=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn3;
}
#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnAddPowerWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %powers_full;
    my %powers_short;
    my %powers;
    my $registered_path;
    if ($gameversion==1) {
        %powers_full=%powers_full1;
        %powers_short=%powers_short1;
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        %powers_full=%powers_full2;
        %powers_short=%powers_short2;
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %powers_full=%powers_full2;
        %powers_short=%powers_short2;
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %powers_full=%powers_full3;
        %powers_short=%powers_short3;
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        %powers_full=%powers_full3;
        %powers_short=%powers_short3;
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    %powers=$short_or_long ?  %powers_full :  %powers_short;
    my %revhash_name= reverse %{$powers{name}};
    if ($treeitem =~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $label=$mw->Label(-text=>"Available Powers:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>100/$y,-anchor=>'sw');
    push @spawned_widgets,$label;
    #my $powerlist= $mw->Scrolled('Listbox',
    Tk::Autoscroll::Init(my $powerlist= $mw->Scrolled('TList',
      -scrollbars=>'osoe',
      -background=>'white',
      -selectborderwidth=>'0',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#A000C0',
      -selectmode=>'extended',
      -itemtype=>'text',
      -orient=>'horizontal'
    ));
    $powerlist->place(-relx=>600/$x,-rely=>100/$y,-relwidth=>270/$x,-relheight=>400/$y);

    my $newstyle = $mw->ItemStyle('text',-foreground=>'#9090FF',-selectforeground=>'#FFFF00',-selectbackground=>'#A000C0');
    my @treepath=split /#/, $treeitem;  pop @treepath;  my $newtreepath=join '#',@treepath;

    for (sort keys %revhash_name) {  #  $_ has our powers' names
        my $ix=$revhash_name{$_};
        my $lbl=$powers{label}{$ix};
        if ($tree->info('exists',"$newtreepath#KnownList0#Power".$lbl)) {
            $powerlist->insert('end',-text=>$_,-style=>$newstyle);
        }
        else {
            $powerlist->insert('end',-text=>$_);
        }
    }


    #display power icon
    my $erf=Bioware::ERF->new();
    my $img=Imager->new();
    unless ($erf->read_erf("$registered_path\\TexturePacks\\swpc_tex_gui.erf")) {
        undef $erf;
    }
    $powerlist->bind('<ButtonRelease-1>'=>sub {
        $picture_label->destroy if Tk::Exists($picture_label);
        eval {$picture_label_photo->delete};

        my ($cur_list_index)=$powerlist->info('selection');
        return unless defined($cur_list_index);
        my $selected_power=$powerlist->entrycget($cur_list_index,-text);
        my $powervalue=$revhash_name{$selected_power};
        return unless my $iconresref=$powers{icon}{$powervalue};
        LogInfo ("Trying to picture: $iconresref");
        my $tgadata;
        my $ftyp='bmp'; #IMAGE FORMAT
        if (-e "$registered_path/override/$iconresref".".tga") {
            local $/;
            open my $tmpfh,"<","$registered_path/override/$iconresref".".tga";
            binmode $tmpfh;
            $tgadata=<$tmpfh>;
            close $tmpfh;
            LogInfo ("KotOR".$gameversion." override $iconresref".".tga detected");
        } else {
            unless (defined ($erf)) {  return; }
            my $erf_ix=$erf->load_erf_resource($iconresref.".tpc");
            return unless defined($erf_ix);
            my $tpc=Bioware::TPC->new();
            my $scalardata=$erf->{resources}[$erf_ix]{res_data};
            my $ret=$tpc->read_tpc(\$scalardata);
            $tpc->write_tga(\$tgadata);
            if (($tpc->{tpc}{header}{data_size}==0) && ($tpc->{tpc}{header}{encoding}==4)) {
                $ftyp='bmp'
            }
            LogInfo ("ftyp: $ftyp $tpc->{tpc}{header}{data_size} $tpc->{tpc}{header}{encoding}");
        }
        $img->read(data=>$tgadata,type=>'tga') or die $img->errstr; ;
        my $buf;
        $img->write(data=>\$buf,type=>$ftyp) or die $img->errstr; ;
        $picture_label_photo=$mw->Photo(-data=>encode_base64($buf),-format=>$ftyp);
        $picture_label=$mw->Label(-image=>$picture_label_photo)->pack(-side=>'top',-anchor=>'ne');
    } );#}

    push @spawned_widgets, $powerlist;

    my $btn2=$mw->Button(-text=>"Add New Power",-command=>sub {
        my @selected_indices=$powerlist->info('selection');
        #my @selected_indices=$powerlist->curselection;
        return unless (scalar @selected_indices); #nothing selected
        my @treepath=split /#/, $treeitem; pop @treepath; my $newtreepath=join '#',@treepath;
        for my $selected_index (@selected_indices) {
            my $selected_power=$powerlist->entrycget($selected_index,-text);
            #$newtreepath .= "#KnownList0#Power".($powerlist->get($cur_list_index));
            $treeitem=~/#Class(\d)#/;
            my $classindex=$1;
            my $powervalue2=$revhash_name{$selected_power};
            my $lbl=$powers{label}{$powervalue2};
            next if ($tree->info('exists',"$newtreepath#KnownList0#Power$lbl"));
            LogInfo ("Adding power: $selected_power");
            if ($treeitem=~/NPCs/) {
                $treeitem=~/Class(\d)/;
                my $classnumber=$1;
                my $classlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{Value};
                my $cur_class=$classlist->[$classnumber];
                my $knownlist_ix=$cur_class->get_field_ix_by_label('KnownList0');
                unless (defined $knownlist_ix) { LogInfo ("Failed to add power");  next; }
                my $powerlist_=$cur_class->{Fields}[$knownlist_ix];
                my $powerlist_structs=$powerlist_->{Value};
                my $new_power=Bioware::GFF::Struct->new('ID'=>3);
                $new_power->createField('Type'=>FIELD_WORD,'Label'=>'Spell','Value'=>$powervalue2);
                push @$powerlist_structs,$new_power;                            #add the power
                my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];        #and if successful, store the new
                my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
                $treeitem =~/NPCs#NPC(\d+)#/;                                 #so we know that it needs replacing
                my $npcnum=$1;
                $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
                $tree->entryconfigure($root,-data=>$datahash);
            } else {
                my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
                my $classlist=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value};
                my $cur_class=$classlist->[$classindex];
                my $knownlist_ix=$cur_class->get_field_ix_by_label('KnownList0');
                unless (defined $knownlist_ix) { LogInfo ("Failed to add power");  next; }
                my $powerlist_=$cur_class->{Fields}[$knownlist_ix];
                my $powerlist_structs=$powerlist_->{Value};
                my $new_power=Bioware::GFF::Struct->new('ID'=>3);
                $new_power->createField('Type'=>FIELD_WORD,'Label'=>'Spell','Value'=>$powervalue2);
                push @$powerlist_structs,$new_power;                            #add the power
            }
            LogInfo ("Successful.");
            $tree->add("$newtreepath#KnownList0#Power$lbl",
              -text=>$selected_power,-data=>'can modify');
            $powerlist->entryconfigure($selected_index,-style=>$newstyle);
        }
    } )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>90/$x);
    push @spawned_widgets,$btn2;

    my $btn3=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>796/$x,-rely=>520/$y,-relwidth=>90/$x);
    push @spawned_widgets,$btn3;

    my $btn4=$mw->Button(-text=>"Remove Powers",-command=>sub {

        my @selected_indices=$powerlist->info('selection');
        unless (scalar @selected_indices) { return; }  #nothing selected
        my @treepath=split /#/, $treeitem;  pop @treepath;  my $newtreepath=join '#',@treepath;
        for my $selected_index (@selected_indices) {
            my $selected_power=$powerlist->entrycget($selected_index,-text);
            $treeitem=~/#Class(\d)#/;
            my $classindex=$1;
            my $powervalue2=$revhash_name{$selected_power};
            my $lbl=$powers{label}{$powervalue2};
            next unless ($tree->info('exists',"$newtreepath#KnownList0#Power$lbl"));
            LogInfo ("Removing power: $selected_power");
            if ($treeitem=~/NPCs/) {
                $treeitem=~/Class(\d)/;
                my $classnumber=$1;

                my $classlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{Value};
                my $cur_class=$classlist->[$classnumber];
                my $knownlist_ix=$cur_class->get_field_ix_by_label('KnownList0');
                unless (defined $knownlist_ix) { LogInfo ("Failed to remove power");  next; }
                my $powerlist_=$cur_class->{Fields}[$knownlist_ix];
                my $powerlist_structs=$powerlist_->{Value};
                my @new_powerlist_structs=();

                for my $this_struct (@$powerlist_structs) {
                    unless ($this_struct->{Fields}{Value} == $powervalue2) {
                        push @new_powerlist_structs,$this_struct;
                    }
                }
                $powerlist_->{Value}=[@new_powerlist_structs];                 #perform power removal on NPC
                my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #and if successful, store the new
                my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
                $treeitem =~/NPCs#NPC(\d+)#/;                                 #so we know that it needs replacing
                my $npcnum=$1;
                $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
                $tree->entryconfigure($root,-data=>$datahash);
            } else {
                my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
                my $classlist=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value};
                my $cur_class=$classlist->[$classindex];
                my $knownlist_ix=$cur_class->get_field_ix_by_label('KnownList0');
                unless (defined $knownlist_ix) { LogInfo ("Failed to remove power"); next; }
                my $powerlist_=$cur_class->{Fields}[$knownlist_ix];
                my $powerlist_structs=$powerlist->{Value};
                my @new_powerlist_structs=();
                for my $this_struct (@$powerlist_structs) {
                    unless ($this_struct->{Fields}{Value} == $powervalue2) {
                        push @new_powerlist_structs,$this_struct;
                    }
                }
                $powerlist_->{Value}=[@new_powerlist_structs];                 #perform power removal on PC
            }
            $tree->delete('entry',"$newtreepath#KnownList0#Power$lbl");
            $powerlist->entryconfigure($selected_index,-style=>'');
            LogInfo ("Power removed succesfully.");
        }
    })->place(-relx=>698/$x,-rely=>520/$y,-relwidth=>90/$x);
    push @spawned_widgets,$btn4;


    my $chkbtn=$mw->Checkbutton(-text=>'Show all feats/powers',
      -variable=>\$short_or_long,
      -command=> sub {
          %powers=$short_or_long ?  %powers_full : %powers_short;
          %revhash_name= reverse %{$powers{name}};
          $powerlist->delete(0,'end');
          for (sort keys %revhash_name) {  #  $_ has our powers' names
              my $ix=$revhash_name{$_};
              my $lbl=$powers{label}{$ix};
              if ($tree->info('exists',"$newtreepath#KnownList0#Power".$lbl)) {
                  $powerlist->insert('end',-text=>$_,-style=>$newstyle);
              }
              else {
                  $powerlist->insert('end',-text=>$_);
              }
          }
      }
    )->place(-relx=>590/$x,-rely=>590/$y, -anchor=>'sw');
    push @spawned_widgets,$chkbtn;
}

#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnGenericWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$cur_trait,$cur_rank,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %traithash=('STR'=>'Str',
      'DEX'=>'Dex',
      'INT'=>'Int',
      'WIS'=>'Wis',
      'CON'=>'Con',
      'CHA'=>'Cha');

    unless (exists $traithash{$cur_trait}) { $traithash{$cur_trait}=$cur_trait }  #this is so our cur_trait matches up with the appropriate GFF label
    if ($treeitem =~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    if($cur_trait eq "MaxForcePoints") { $cur_trait = "Max Force Points"; }
    if($cur_trait eq "ForcePoints") { $cur_trait = "Force Points"; }

    my $lbl=$mw->Label(-text=>"$cur_trait",-font=>['MS Sans Serif','12'])->place(-relx=>760/$x,-rely=>200/$y,-anchor=>'ne');
    push @spawned_widgets,$lbl;
    my $new_rank=$cur_rank;
    my $txt=$mw->Entry(-textvariable=>\$new_rank,-background=>'white',-width=>9)->place(-relx=>770/$x,-rely=>200/$y);
    push @spawned_widgets,$txt;

    $txt->bind('<Return>'=>sub {
        $tree->entryconfigure($treeitem,-text=>"$cur_trait: $new_rank");
        LogInfo ("Changing $cur_trait value to $new_rank  using field # $traithash{$cur_trait}");
        if ($treeitem=~/NPCs/) {
            if ( $cur_trait eq 'Level') {
                $treeitem=~/Class(\d)/;
                my $classnumber=$1;
                my $class_struct=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{Value}[$classnumber];
                $class_struct->{Fields}[$class_struct->get_field_ix_by_label('ClassLevel')]{Value}=$new_rank; }
            else {
                $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label($traithash{$cur_trait})]{Value}=$new_rank;
                if ($cur_trait eq 'Force Points') {
                    $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('CurrentForce')]{Value}=$new_rank;
                } elsif ($cur_trait eq 'HitPoints') {
                    $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('CurrentHitPoints')]{Value}=$new_rank;
                }
            }
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)#/;                                 #so we know that it needs replacing
            my $npcnum=$1;
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            if ($cur_trait eq 'Level') {
                $treeitem =~ /#Class(\d)#Level/;
                my $classnumber=$1;
                my $class_struct=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value}[$classnumber];
                $class_struct->{Fields}[$class_struct->get_field_ix_by_label('ClassLevel')]{Value}=$new_rank; }
            else {
                $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label($traithash{$cur_trait})]{Value}=$new_rank;
                if ($cur_trait eq 'Force Points') {
                    $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('CurrentForce')]{Value}=$new_rank;
                } elsif ($cur_trait eq 'HitPoints') {
                    $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('CurrentHitPoints')]{Value}=$new_rank;
                }
            }
        }
    });

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $tree->entryconfigure($treeitem,-text=>"$cur_trait: $new_rank");
        LogInfo ("Changing $cur_trait value to $new_rank  using field # $traithash{$cur_trait}");
        if ($treeitem=~/NPCs/) {
            if ( $cur_trait eq 'Level') {
                $treeitem=~/Class(\d)/;
                my $classnumber=$1;
                my $class_struct=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{Value}[$classnumber];
                $class_struct->{Fields}[$class_struct->get_field_ix_by_label('ClassLevel')]{Value}=$new_rank; }
            else {
                $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label($traithash{$cur_trait})]{Value}=$new_rank;
                if ($cur_trait eq 'Force Points') {
                    $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('CurrentForce')]{Value}=$new_rank;
                } elsif ($cur_trait eq 'HitPoints') {
                    $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('CurrentHitPoints')]{Value}=$new_rank;
                }
            }
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)#/;                                 #so we know that it needs replacing
            my $npcnum=$1;
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            if ($cur_trait eq 'Level') {
                $treeitem =~ /#Class(\d)#Level/;
                my $classnumber=$1;
                my $class_struct=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value}[$classnumber];
                $class_struct->{Fields}[$class_struct->get_field_ix_by_label('ClassLevel')]{Value}=$new_rank; }
            else {
                $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label($traithash{$cur_trait})]{Value}=$new_rank;
                if ($cur_trait eq 'Force Points') {
                    $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('CurrentForce')]{Value}=$new_rank;
                } elsif ($cur_trait eq 'HitPoints') {
                    $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('CurrentHitPoints')]{Value}=$new_rank;
                }
            }
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>90/$x);


    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne',-relwidth=>90/$x);
    push @spawned_widgets,$btn2;
}
#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnPartyWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$cur_trait,$cur_rank,$pty_gff_ref)=@_;
    my %traithash = ('Credits'=>'PT_GOLD', 'Party XP'=>'PT_XP_POOL',
      'Influence'=>'PT_INFLUENCE','Chemicals'=>'PT_ITEM_CHEMICAL','Components'=>'PT_ITEM_COMPONEN');
    my $npc_num; #for influence only
    if ($cur_trait eq 'Influence') {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        $treeitem=~/NPC(\d+)/;
        $npc_num=$1;
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }
    my $lbl=$mw->Label(-text=>"$cur_trait",-font=>['MS Sans Serif','12'])->place(-relx=>760/$x,-rely=>200/$y,-anchor=>'ne');

    push @spawned_widgets,$lbl;
    my $new_rank=$cur_rank;
    my $txt=$mw->Entry(-textvariable=>\$new_rank,-background=>'white',-width=>9)->place(-relx=>770/$x,-rely=>200/$y);
    push @spawned_widgets,$txt;

    $txt->bind('<Return>'=>sub {
        $tree->entryconfigure($treeitem,-text=>"$cur_trait: $new_rank");
        LogInfo ("Changing $cur_trait to $new_rank");

        if ($cur_trait eq 'Influence') {
            $$pty_gff_ref->{Main}{Fields}[$$pty_gff_ref->{Main}->get_field_ix_by_label($traithash{$cur_trait})]{Value}[$npc_num]{Fields}{Value}=$new_rank;
        }
        else {
            $$pty_gff_ref->{Main}{Fields}[$$pty_gff_ref->{Main}->get_field_ix_by_label($traithash{$cur_trait})]{Value}=$new_rank;
        }
    });

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $tree->entryconfigure($treeitem,-text=>"$cur_trait: $new_rank");
        LogInfo ("Changing $cur_trait to $new_rank");

        if ($cur_trait eq 'Influence') {
            $$pty_gff_ref->{Main}{Fields}[$$pty_gff_ref->{Main}->get_field_ix_by_label($traithash{$cur_trait})]{Value}[$npc_num]{Fields}{Value}=$new_rank;
        }
        else {
            $$pty_gff_ref->{Main}{Fields}[$$pty_gff_ref->{Main}->get_field_ix_by_label($traithash{$cur_trait})]{Value}=$new_rank;
        }
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}
#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnSaveGameNameWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$cur_savegamename,$res_gff_ref)=@_;

    my $lbl=$mw->Label(-text=>"Savegame Name",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;
    my $new_savegamename=$cur_savegamename;
    my $txt=$mw->Entry(-textvariable=>\$new_savegamename,-background=>'white',-width=>20)->place(-relx=>690/$x,-rely=>200/$y);
    push @spawned_widgets,$txt;

    $txt->bind('<Return>'=>sub {
        $tree->entryconfigure($treeitem,-text=>"Savegame Name: $new_savegamename");
        LogInfo("Changing savegamename to $new_savegamename");
        $$res_gff_ref->{Main}{Fields}[$$res_gff_ref->{Main}->get_field_ix_by_label('SAVEGAMENAME')]{'Value'}=$new_savegamename;
    });

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $tree->entryconfigure($treeitem,-text=>"Savegame Name: $new_savegamename");
        LogInfo("Changing savegamename to $new_savegamename");
        $$res_gff_ref->{Main}{Fields}[$$res_gff_ref->{Main}->get_field_ix_by_label('SAVEGAMENAME')]{'Value'}=$new_savegamename;
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}

#>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnFirstNameWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$cur_name,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];
    my $datahash=$tree->entrycget($root,-data);
    my $pty_gff=$datahash->{'GFF-pty'};
    my $res_gff=$datahash->{'GFF-res'};
    if ($treeitem=~/NPCs/) {
        my $lbl_npc=$mw->Label(-text=>"-- $cur_name --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
        my $lbl=$mw->Label(-text=>"NPC Name",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
        push @spawned_widgets,$lbl;
    } else {
        my $lbl=$mw->Label(-text=>"Player Name",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
        push @spawned_widgets,$lbl;
    }

    my $new_playername=$cur_name;
    my $txt=$mw->Entry(-textvariable=>\$new_playername,-background=>'white',-width=>20)->place(-relx=>690/$x,-rely=>200/$y);
    push @spawned_widgets,$txt;

    $txt->bind('<Return>'=>sub {
        if ($treeitem=~/NPCs/) {
            LogInfo ("Changing NPC name from $cur_name to $new_playername");
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('FirstName')]{Value}{StringRef}=-1;
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('FirstName')]{Value}{Substrings}[0]{Value}=$new_playername;
            $tree->entryconfigure($treeitem,-text=>"$new_playername");
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);

        } else {
            LogInfo ("Changing player name to $new_playername");
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FirstName')]{Value}{StringRef}=-1;
            $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FirstName')]{Value}{Substrings}[0]{Value}=$new_playername;
            if (defined(my $pt_pcnameix=$pty_gff->{Main}->fbl('PT_PCNAME'))) {  # a new TSL thing
                $pty_gff->{Main}{Fields}[$pt_pcnameix]{Value}=$new_playername;
                $datahash->{'GFF-pty'}=$pty_gff;
            }
            if (defined(my $pcnameix=$pty_gff->{Main}->fbl('PCNAME'))) {  # a new TSL thing
                $pty_gff->{Main}{Fields}[$pcnameix]{Value}=$new_playername;
                $datahash->{'GFF-res'}=$res_gff;
            }

            $tree->entryconfigure($treeitem,-text=>"Player Name: $new_playername");

        }
    });

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        if ($treeitem=~/NPCs/) {
            LogInfo ("Changing NPC name from $cur_name to $new_playername");
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('FirstName')]{Value}{StringRef}=-1;
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('FirstName')]{Value}{Substrings}[0]{Value}=$new_playername;
            $tree->entryconfigure($treeitem,-text=>"$new_playername");
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);

        } else {
            LogInfo ("Changing player name to $new_playername");
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FirstName')]{Value}{StringRef}=-1;
            $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('FirstName')]{Value}{Substrings}[0]{Value}=$new_playername;
            if (defined(my $pt_pcnameix=$pty_gff->{Main}->fbl('PT_PCNAME'))) {  # a new TSL thing
                $pty_gff->{Main}{Fields}[$pt_pcnameix]{Value}=$new_playername;
                $datahash->{'GFF-pty'}=$pty_gff;
            }
            if (defined(my $pcnameix=$pty_gff->{Main}->fbl('PCNAME'))) {  # a new TSL thing
                $pty_gff->{Main}{Fields}[$pcnameix]{Value}=$new_playername;
                $datahash->{'GFF-res'}=$res_gff;
            }

            $tree->entryconfigure($treeitem,-text=>"Player Name: $new_playername");

        }
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnTimePlayedWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$hours,$minutes,$seconds,$res_gff_ref)=@_;
    my $lbl=$mw->Label(-text=>"Time played",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;

    my $new_hours=$hours;
    my $txth=$mw->Entry(-textvariable=>\$new_hours,-background=>'white')->place(-relx=>690/$x,-rely=>200/$y,-relwidth=>30/$x);
    push @spawned_widgets,$txth;

    my $lblh=$mw->Label(-text=>"h",-font=>['MS Sans Serif','8'])->place(-relx=>715/$x,-rely=>200/$y,-relwidth=>10/$x);
    push @spawned_widgets,$lblh;

    my $new_minutes=$minutes;
    my $txtm=$mw->Entry(-textvariable=>\$new_minutes,-background=>'white')->place(-relx=>730/$x,-rely=>200/$y,-relwidth=>20/$x);
    push @spawned_widgets,$txtm;

    my $lblm=$mw->Label(-text=>"m",-font=>['MS Sans Serif','8'])->place(-relx=>755/$x,-rely=>200/$y,-relwidth=>10/$x);
    push @spawned_widgets,$lblm;

    my $new_seconds=$seconds;
    my $txts=$mw->Entry(-textvariable=>\$new_seconds,-background=>'white')->place(-relx=>770/$x,-rely=>200/$y,-relwidth=>20/$x);
    push @spawned_widgets,$txts;

    my $lbls=$mw->Label(-text=>"s",-font=>['MS Sans Serif','8'])->place(-relx=>795/$x,-rely=>200/$y,-relwidth=>10/$x);
    push @spawned_widgets,$lbls;

    $txts->bind('<Return>'=> sub {
        my $newtime=$new_seconds+(60*$new_minutes)+(3600*$new_hours);
        $tree->entryconfigure($treeitem,-text=>'Time Played: '.
          (sprintf "%uh ",($newtime/3600)).
          (sprintf "%um ",(($newtime % 3600)/60)).
          (sprintf "%us",($newtime % 60)));
        LogInfo("Chaning time played to $newtime");
        $$res_gff_ref->{Main}{Fields}[$$res_gff_ref->{Main}->get_field_ix_by_label('TIMEPLAYED')]{Value}=$newtime;
    });

    $txth->bind('<Return>'=> sub {
        my $newtime=$new_seconds+(60*$new_minutes)+(3600*$new_hours);
        $tree->entryconfigure($treeitem,-text=>'Time Played: '.
          (sprintf "%uh ",($newtime/3600)).
          (sprintf "%um ",(($newtime % 3600)/60)).
          (sprintf "%us",($newtime % 60)));
        LogInfo("Chaning time played to $newtime");
        $$res_gff_ref->{Main}{Fields}[$$res_gff_ref->{Main}->get_field_ix_by_label('TIMEPLAYED')]{Value}=$newtime;
    });

    $txtm->bind('<Return>'=> sub {
        my $newtime=$new_seconds+(60*$new_minutes)+(3600*$new_hours);
        $tree->entryconfigure($treeitem,-text=>'Time Played: '.
          (sprintf "%uh ",($newtime/3600)).
          (sprintf "%um ",(($newtime % 3600)/60)).
          (sprintf "%us",($newtime % 60)));
        LogInfo("Chaning time played to $newtime");
        $$res_gff_ref->{Main}{Fields}[$$res_gff_ref->{Main}->get_field_ix_by_label('TIMEPLAYED')]{Value}=$newtime;
    });

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        my $newtime=$new_seconds+(60*$new_minutes)+(3600*$new_hours);
        $tree->entryconfigure($treeitem,-text=>'Time Played: '.
          (sprintf "%uh ",($newtime/3600)).
          (sprintf "%um ",(($newtime % 3600)/60)).
          (sprintf "%us",($newtime % 60)));
        LogInfo("Chaning time played to $newtime");
        $$res_gff_ref->{Main}{Fields}[$$res_gff_ref->{Main}->get_field_ix_by_label('TIMEPLAYED')]{Value}=$newtime;
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}

#>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnCheatWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$cheatval,$res_gff_ref,$pty_gff_ref,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my $lbl;
    if ($treeitem =~ /Cheat/) {
        $lbl=$mw->Label(-text=>"Cheats Used",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw'); }
    else {
        if ($treeitem =~/NPCs/) {
            $treeitem=~/(.*#NPCs#.*?)#/;
            my $npcname=$tree->entrycget($1,-text);
            my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
            push @spawned_widgets,$lbl_npc;
        }

        $lbl=$mw->Label(-text=>"Min 1 HP",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
    }
    push @spawned_widgets,$lbl;

    my $new_cheatval=$cheatval;
    my $r_on=$mw->Radiobutton(-text=>"Yes",-variable=>\$new_cheatval,-value=>'1',-activeforeground=>"blue")->place(-relx=>700/$x,-rely=>220/$y);
    my $r_off=$mw->Radiobutton(-text=>"No",-variable=>\$new_cheatval,-value=>'0',-activeforeground=>"blue")->place(-relx=>700/$x,-rely=>250/$y);
    push @spawned_widgets,($r_on,$r_off);

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        if ($treeitem =~/Cheat/) {
            $tree->entryconfigure($treeitem,-text=>"Cheats Used: $new_cheatval");
            LogInfo("Changing cheat flag to $new_cheatval");
            $$res_gff_ref->{Main}{Fields}[$$res_gff_ref->{Main}->get_field_ix_by_label('CHEATUSED')]{Value}=$new_cheatval;
            $$pty_gff_ref->{Main}{Fields}[$$pty_gff_ref->{Main}->get_field_ix_by_label('PT_CHEAT_USED')]{Value}=$new_cheatval; }
        else {
            $tree->entryconfigure($treeitem,-text=>"Min1HP: $new_cheatval");
            LogInfo("Changing Min1HP flag to $new_cheatval");
            if ($treeitem=~/NPCs/) {
                $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Min1HP')]{Value}=$new_cheatval;
                my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
                my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
                $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
                my $npcnum=$1;                                                #when it comes time to commit changes
                $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
                $tree->entryconfigure($root,-data=>$datahash);
            }
            else {
                my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
                $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Min1HP')]{Value}=$new_cheatval;
            }
        }
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}
#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnBooleanWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$gbl_gff_ref)=@_;

    my $treetext=$tree->entrycget($treeitem,-text);
    $treetext =~ /(.*): (.*)/;
    my $lbltext=$1; my $curval=$2;
    my $lbl=$mw->Label(-text=>"Global Boolean: $lbltext",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;


    my $r_on=$mw->Radiobutton(-text=>"Yes",-variable=>\$curval,-value=>'1',-activeforeground=>"blue")->place(-relx=>700/$x,-rely=>220/$y);
    my $r_off=$mw->Radiobutton(-text=>"No",-variable=>\$curval,-value=>'0',-activeforeground=>"blue")->place(-relx=>700/$x,-rely=>250/$y);
    push @spawned_widgets,($r_on,$r_off);

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $tree->entryconfigure($treeitem,-text=>"$lbltext: $curval");
        LogInfo("Changing $lbltext to $curval");
        my $ix_into_gff=(split /__/,$treeitem)[1];
        my $bitstring
          =unpack('B*',$$gbl_gff_ref->{Main}{Fields}[$$gbl_gff_ref->{Main}->get_field_ix_by_label('ValBoolean')]{Value});
        substr($bitstring,$ix_into_gff,1)=$curval;
        $$gbl_gff_ref->{Main}{Fields}[$$gbl_gff_ref->{Main}->get_field_ix_by_label('ValBoolean')]{Value}
          =pack('B*',$bitstring);
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",
      -command=>sub {
          CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}
#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnNumericWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$gbl_gff_ref)=@_;

    my $treetext=$tree->entrycget($treeitem,-text);
    $treetext =~ /(.*): (.*)/;
    my $lbltext=$1; my $curval=$2;
    my $lbl=$mw->Label(-text=>"Global Numeric: $lbltext",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;

    my $txt1=$mw->Entry(-textvariable=>\$curval,-background=>'white',-width=>9)->place(-relx=>770/$x,-rely=>200/$y);
    push @spawned_widgets,$txt1;

    $txt1->bind('<Return>'=> sub {
        $tree->entryconfigure($treeitem,-text=>"$lbltext: $curval");
        LogInfo("Changing $lbltext to $curval");
        my $ix_into_gff=(split /__/,$treeitem)[1];
        my @bytevalues
          =unpack('C*',$$gbl_gff_ref->{Main}{Fields}[$$gbl_gff_ref->{Main}->get_field_ix_by_label('ValNumber')]{Value});
        $bytevalues[$ix_into_gff]=$curval;
        $$gbl_gff_ref->{Main}{Fields}[$$gbl_gff_ref->{Main}->get_field_ix_by_label('ValNumber')]{Value}
          =pack('C*',@bytevalues);
    });

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $tree->entryconfigure($treeitem,-text=>"$lbltext: $curval");
        LogInfo("Changing $lbltext to $curval");
        my $ix_into_gff=(split /__/,$treeitem)[1];
        my @bytevalues
          =unpack('C*',$$gbl_gff_ref->{Main}{Fields}[$$gbl_gff_ref->{Main}->get_field_ix_by_label('ValNumber')]{Value});
        $bytevalues[$ix_into_gff]=$curval;
        $$gbl_gff_ref->{Main}{Fields}[$$gbl_gff_ref->{Main}->get_field_ix_by_label('ValNumber')]{Value}
          =pack('C*',@bytevalues);
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",
      -command=>sub {
          CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}

#>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnGenderWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$curgendertext,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %genders;
    if ($gameversion==1) {
        %genders=%gender_hash1;
    }
    elsif ($gameversion==2) {
        %genders=%gender_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %genders=%gender_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %genders=%gender_hash3;
    }
    elsif ($gameversion==4) {
        %genders=%gender_hash3;
    }
    my %revgenders=reverse %genders;
    my $curgender=$revgenders{$curgendertext};

    if ($treeitem=~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $lbl=$mw->Label(-text=>"Gender: $curgendertext",-font=>['MS Sans Serif','8'])->place(-relx=>690/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;


    my $i=0;
    for my $gval (sort keys %genders) {
        my $w=$mw->Radiobutton(-text=>$genders{$gval},-variable=>\$curgender,-value=>$gval,-activeforeground=>"blue")->place(-relx=>700/$x,-rely=>((30*$i)+220)/$y);
        push @spawned_widgets, $w;
        $i++;
    }

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $curgendertext=$genders{$curgender};
        $tree->entryconfigure($treeitem,-text=>"Gender: $curgendertext");
        LogInfo("Changing Gender to $curgendertext");
        if ($treeitem =~/NPCs/) {
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Gender')]{Value}=$curgender;
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('Gender')]{Value}=$curgender; }
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",
      -command=>sub {
          CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btn2;
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnChangeClassWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %classes;
    my %spellcasters;
    if ($gameversion==1) {
        %classes=%classes_hash1;
        %spellcasters=%spellcasters1;
    }
    elsif ($gameversion==2) {
        %classes=%classes_hash2;
        %spellcasters=%spellcasters2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %classes=%classes_hash2;
        %spellcasters=%spellcasters2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %classes=%classes_hash3;
        %spellcasters=%spellcasters3;
    }
    elsif ($gameversion==4) {
        %classes=%classes_hash3;
        %spellcasters=%spellcasters3;
    }

    my $cur_class=$tree->entrycget($treeitem,-text);

    my %revhash=reverse %classes;
    my $class_struct_index;

    my @siblings=$tree->infoChildren($tree->infoParent($treeitem));
    for( my $sibling_ix =0; $sibling_ix< scalar @siblings; $sibling_ix++) {
        if ($siblings[$sibling_ix] eq $treeitem) {
            $class_struct_index=$sibling_ix;
            last;
        }
    }
    #$class_struct_index=chop $class_struct_index;    #note, this is inherently flawed
    #because a user could add a class, add another,
    #then delete the first one and now the indices
    #will be off
    if ($treeitem=~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>30/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $lbl1=$mw->Label(-text=>"Selected Class: $cur_class",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>75/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl1;

    my $lbl=$mw->Label(-text=>"Available Classes:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>100/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;

    Tk::Autoscroll::Init(my $classlist= $mw->Scrolled('Listbox',
      -scrollbars=>'osoe',
      -background=>'white',
      -selectborderwidth=>'0',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#009000',
    ));
    $classlist->place(-relx=>600/$x,-rely=>100/$y,-relwidth=>270/$x,-relheight=>200/$y);

    $classlist->insert('end',(sort keys %revhash));
    push @spawned_widgets, $classlist;

    my $btn1=$mw->Button(-text=>'Change Class',-command=>sub {
        my $cur_list_index=$classlist->curselection;
        if ($cur_list_index eq '' ) { return; } #nothing selected
        my $newclassvalue=$revhash{$classlist->get($cur_list_index)};
        my $oldclassvalue=$revhash{($tree->entrycget($treeitem,-text))};
        LogInfo ("Changing class from " .($tree->entrycget($treeitem,-text)). " ($oldclassvalue) to " .
          $classlist->get($cur_list_index) . " ($newclassvalue)");

        #get the struct in question

        my $class_struct;
        my $mod_playerlist;
        if ($treeitem=~/NPCs/) {
            $class_struct=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{Value}[$class_struct_index];
        } else {
            $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $class_struct=$mod_playerlist->{Fields}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value}[$class_struct_index];
        }

        #change the class

        $class_struct->{Fields}[$class_struct->get_field_ix_by_label('Class')]{Value}=$newclassvalue;

        #handle non-jedi -> jedi change

        if ( (exists $spellcasters{$newclassvalue}) &&    #new class is a spell caster
          !(exists $spellcasters{$oldclassvalue}) ){    #old class was not -- need to configure
            LogInfo('Adding power list');
            my $sub_struct=Bioware::GFF::Struct->new('ID'=>17767);
            $sub_struct->createField('Type'=>FIELD_BYTE,'Label'=>'NumSpellsLeft','Value'=>0);
            $class_struct->createField('Type'=>FIELD_LIST,'Label'=>'SpellsPerDayList','Value'=>[$sub_struct]);
            $class_struct->createField('Type'=>FIELD_LIST,'Label'=>'KnownList0','Value'=>[]);
            $tree->add($treeitem."#KnownList0",-text=>'Force Powers',-data=>'can modify');
            $tree->hide('entry',$treeitem."#KnownList0");

            #handle jedi -> non-jedi change

        } elsif ( !(exists $spellcasters{$newclassvalue}) &&     #new class is not a spell caster
          (exists $spellcasters{$newclassvalue}) ){     #but old class was -- need to configure
            LogInfo ('Removing power list');
            my $ix=0;
            my @newfields=();
            for my $classfield (@{$class_struct->{Fields}}) {
                unless ( ($ix=$class_struct->get_field_ix_by_label('KnownList0')) ||
                  ($ix=$class_struct->get_field_ix_by_label('SpellsPerDayList')) ) {
                    push @newfields,$classfield;
                }
                $ix++;
            }
            $class_struct->{Fields}=[@newfields];
            if ($tree->info('exists',$treeitem.'#KnownList0')) {
                $tree->delete('offsprings',$treeitem.'#KnownList0');
                $tree->delete('entry',$treeitem.'#KnownList0');
            }
        }
        $tree->autosetmode();
        $tree->entryconfigure($treeitem,-text=>($classlist->get($cur_list_index)));
        if ($treeitem=~/NPCs/) {
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>90/$x);

    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne',-relwidth=>90/$x);
    push @spawned_widgets,$btn2;


    my $btn3=$mw->Button(-text=>"Add Class",-command=>sub {


        my $cur_list_index=$classlist->curselection;
        if ($cur_list_index eq '' ) { return; } #nothing selected
        my $newclassvalue=$revhash{$classlist->get($cur_list_index)};

        #get a reference to the current ClassList
        my $class_struct_array_ref;
        if ($treeitem=~/NPCs/) {
            $class_struct_array_ref=$$ifo_gff_ref->{Main}{'Fields'}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{'Value'};
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $class_struct_array_ref=$mod_playerlist->{'Fields'}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value};
        }

        #Create another class struct
        my $new_class_struct=Bioware::GFF::Struct->new('ID'=>2);
        $new_class_struct->createField('Type'=>FIELD_INT,'Label'=>'Class','Value'=>$newclassvalue);
        $new_class_struct->createField('Type'=>FIELD_SHORT,'Label'=>'ClassLevel','Value'=>1);

        #add spell casater fields to new struct if required
        if (exists $spellcasters{$newclassvalue}) {
            my $sub_struct=Bioware::GFF::Struct->new('ID'=>17767);
            $sub_struct->createField('Type'=>FIELD_BYTE,'Label'=>'NumSpellsLeft','Value'=>0);
            $new_class_struct->createField('Type'=>FIELD_LIST,'Label'=>'SpellsPerDayList','Value'=>[$sub_struct]);
            $new_class_struct->createField('Type'=>FIELD_LIST,'Label'=>'KnownList0','Value'=>[]);
        }

        #Add new class struct to the ClassList
        push @$class_struct_array_ref,$new_class_struct;

        #Update the Tree
        $treeitem =~ /(.*)#Class(\d+)/;
        my $newtreeitem="$1#Class" .($2+1);
        while ($tree->infoExists($newtreeitem)) {
            $newtreeitem=~/#Class(\d+)/;
            my $newix=$1+1;
            $newtreeitem=~s/(\d+)$/$newix/;
        }
        $tree->add($newtreeitem,-text=>$classes{$newclassvalue},-data=>'can modify');
        $tree->add("$newtreeitem#Level",-text=>'Level: 1',-data=>'can modify');
        $tree->hide('entry',"$newtreeitem#Level");
        if (exists $spellcasters{$newclassvalue}) { #spell caster fields req'd
            $tree->add("$newtreeitem#KnownList0",-text=>'Force Powers',-data=>'can modify');
            $tree->hide('entry',"$newtreeitem#KnownList0");
        }

        #store .utc if necessary
        if ($treeitem=~/NPCs/) {
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];
            my $datahash=$tree->entrycget($root,-data);
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        }

        #done
        $tree->autosetmode();
    })->place(-relx=>600/$x,-rely=>350/$y,-relwidth=>90/$x);
    push @spawned_widgets,$btn3;

    my $btn4=$mw->Button(-text=>"Remove Class",-command=>sub {

        #get a reference to the current ClassList
        my $class_struct_array_ref;
        if ($treeitem=~/NPCs/) {
            $class_struct_array_ref=$$ifo_gff_ref->{Main}{'Fields'}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{'Value'};
        } else {
            my $mod_playerlist=$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0];
            $class_struct_array_ref=$mod_playerlist->{'Fields'}[$mod_playerlist->get_field_ix_by_label('ClassList')]{Value};
        }
        my $classtext=$tree->entrycget($treeitem,-text);
        my $classval=$revhash{$classtext};
        my @new_class_struct_array;

        #create a new ClassList that does not include the struct marked for removal
        for my $class_struct (@$class_struct_array_ref) {
            unless ( $class_struct->{'Fields'}[$class_struct->get_field_ix_by_label('Class')]{'Value'} == $classval ) {
                push @new_class_struct_array,$class_struct
            }
        }

        #write the new ClassList to the GFF
        #$$class_struct_array_ref=[@new_class_struct_array];
        if ($treeitem=~/NPCs/) {
            $$ifo_gff_ref->{Main}{'Fields'}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('ClassList')]{'Value'}=[@new_class_struct_array];
        } else {
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0]->{'Fields'}[$$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList')]{Value}[0]->get_field_ix_by_label('ClassList')]{Value}=[@new_class_struct_array];
        }

        #store the .utc if necessary
        if ($treeitem=~/NPCs/) { #seal the deal
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];
            my $datahash=$tree->entrycget($root,-data);
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        }

        $tree->delete('offsprings',$treeitem);
        $tree->delete('entry',$treeitem);

    })->place(-relx=>600/$x,-rely=>450/$y,-relwidth=>90/$x);
    push @spawned_widgets,$btn4;
}
#>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnAppearanceWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %appearance_hash;
    if ($gameversion==1) {
        %appearance_hash=%appearance_hash1;
    }
    elsif ($gameversion==2) {
        %appearance_hash=%appearance_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %appearance_hash=%appearance_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %appearance_hash=%appearance_hash3;
    }
    elsif ($gameversion==4) {
        %appearance_hash=%appearance_hash3;
    }

    my $cur_appearance=$tree->entrycget($treeitem,-text);
    my $cur_appearance_name=(split /: /,$cur_appearance)[1];


    my %revhash=reverse %appearance_hash;

    if ($treeitem=~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $lbl1=$mw->Label(-text=>"Current $cur_appearance",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>95/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl1;

    my $lbl=$mw->Label(-text=>"Available Appearances:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>120/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;

    Tk::Autoscroll::Init(my $appearancelist= $mw->Scrolled('Listbox', ###HIHIHI
      -scrollbars=>'osoe',
      -background=>'white',
      -selectborderwidth=>'0',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#009000',
      -selectmode=>'extended',
    ));
    $appearancelist->place(-relx=>600/$x,-rely=>120/$y,-relwidth=>270/$x,-relheight=>380/$y);

    $appearancelist->insert('end',(sort keys %revhash));
    push @spawned_widgets, $appearancelist;

    my $btn1=$mw->Button(-text=>'Change Appearance',-command=>sub {
        my $cur_list_index=$appearancelist->curselection;
        if ($cur_list_index eq '' ) { return; } #nothing selected
        my $newappearancevalue=$revhash{$appearancelist->get($cur_list_index)};
        my $oldappearancevalue=$revhash{$cur_appearance_name};
        LogInfo ("Changing appearance from $cur_appearance_name  ($oldappearancevalue) to " .
          $appearancelist->get($cur_list_index) . " ($newappearancevalue)");
        $tree->autosetmode();
        $tree->entryconfigure($treeitem,-text=>"Appearance: " . ($appearancelist->get($cur_list_index)));
        if ($treeitem=~/NPCs/) {
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('Appearance_Type')]{Value}=$newappearancevalue;
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mplix=$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList');
            $$ifo_gff_ref->{Main}{'Fields'}[$mplix]{Value}[0]{Fields}[$$ifo_gff_ref->{Main}{'Fields'}[$mplix]{Value}[0]->get_field_ix_by_label('Appearance_Type')]{'Value'}=$newappearancevalue;
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>120/$x);

    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne',-relwidth=>90/$x);
    push @spawned_widgets,$btn2;


}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnPortraitWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %portraits_hash;
    my $registered_path;

    if ($gameversion==1) {
        %portraits_hash=%portraits_hash1;
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        %portraits_hash=%portraits_hash2;
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %portraits_hash=%portraits_hash2;
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %portraits_hash=%portraits_hash3;
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        %portraits_hash=%portraits_hash3;
        $registered_path=$kseInitializer->{path}->{tjm};
    }

    my $cur_portrait=$tree->entrycget($treeitem,-text);
    my $cur_portrait_name=(split /: /, $cur_portrait)[1];
    my %revhash=reverse %portraits_hash;
    my $erf=Bioware::ERF->new();
    my $img=Imager->new();
    unless ($erf->read_erf("$registered_path\\TexturePacks\\swpc_tex_gui.erf")) {
        undef $erf;

    }

    if ($treeitem=~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $lbl1=$mw->Label(-text=>"Current $cur_portrait",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>95/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl1;

    my $lbl=$mw->Label(-text=>"Available Portraits:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>120/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;

    Tk::Autoscroll::Init(my $portraitlist= $mw->Scrolled('Listbox',
      -scrollbars=>'osoe',
      -background=>'white',
      -selectborderwidth=>'0',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#009000',
      -selectmode=>'extended'
    ));
    $portraitlist->place(-relx=>600/$x,-rely=>120/$y,-relwidth=>270/$x,-relheight=>380/$y);

    $portraitlist->insert('end',(sort keys %revhash));
    #if ($Tk::VERSION  eq '800.024') {
    $portraitlist->bind('<ButtonRelease-1>'=>sub {
        $picture_label->destroy if Tk::Exists($picture_label);
        eval {$picture_label_photo->delete};

        my $cur_list_index=$portraitlist->curselection;
        return if $cur_list_index eq '';
        #$lbl_pic->configure(-text=>'getting from erf');
        my $selected_portrait=$portraitlist->get($cur_list_index);
        my $tgadata;
        if (-e "$registered_path/override/$selected_portrait.tga") {
            local $/;
            open my $tmpfh,"<","$registered_path/override/$selected_portrait.tga";
            binmode $tmpfh;
            $tgadata=<$tmpfh>;
            close $tmpfh;
            LogInfo("KotOR".$gameversion." override $selected_portrait.tga detected");
        }
        else {
            unless (defined ($erf)) {  return; }
            my $erf_ix=$erf->load_erf_resource("$selected_portrait.tpc");
            return unless defined($erf_ix);
            my $tpc=Bioware::TPC->new();
            my $scalardata=$erf->{resources}[$erf_ix]{res_data};
            my $ret=$tpc->read_tpc(\$scalardata);
            $tpc->write_tga(\$tgadata);
        }
        my $bmp;
        $img->read(data=>$tgadata,type=>'tga') or die $img->errstr; ;
        #$img->read(file=>"d:/swkotor2/tk.tga",type=>'tga') or die $img->errstr; ;
        $img=$img->scale(xpixels=>100);
        $img->write(data=>\$bmp,type=>'bmp') or die $img->errstr; ;
        $picture_label_photo=$mw->Photo(-data=>encode_base64($bmp));
        $picture_label=$mw->Label(-image=>$picture_label_photo)->pack(-side=>'top',-anchor=>'ne');
    } );#}
    push @spawned_widgets, $portraitlist;

    my $btn1=$mw->Button(-text=>'Change Portrait',-command=>sub {
        my $cur_list_index=$portraitlist->curselection;
        if ($cur_list_index eq '' ) { return; } #nothing selected
        my $newportraitvalue=$revhash{$portraitlist->get($cur_list_index)};
        my $oldportraitvalue=$revhash{$cur_portrait_name};
        LogInfo ("Changing appearance from $cur_portrait_name ($oldportraitvalue) to " .
          $portraitlist->get($cur_list_index) . " ($newportraitvalue)");
        $tree->autosetmode();
        $tree->entryconfigure($treeitem,-text=>"Portrait: " . ($portraitlist->get($cur_list_index)));
        if ($treeitem=~/NPCs/) {
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('PortraitId')]{Value}=$newportraitvalue;
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mplix=$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList');
            $$ifo_gff_ref->{Main}{'Fields'}[$mplix]{Value}[0]{Fields}[$$ifo_gff_ref->{Main}{'Fields'}[$mplix]{Value}[0]->get_field_ix_by_label('PortraitId')]{'Value'}=$newportraitvalue;
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>120/$x);

    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne',-relwidth=>90/$x);
    push @spawned_widgets,$btn2;

}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnSoundsetWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>

    my ($treeitem,$ifo_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my %soundset_hash;
    if ($gameversion==1) {
        %soundset_hash=%soundset_hash1;
    }
    elsif ($gameversion==2) {
        %soundset_hash=%soundset_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        %soundset_hash=%soundset_hash2;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        %soundset_hash=%soundset_hash3;
    }
    elsif ($gameversion==4) {
        %soundset_hash=%soundset_hash3;
    }

    my $cur_soundset=$tree->entrycget($treeitem,-text);
    my $cur_soundset_name=(split /: /, $cur_soundset)[1];
    my %revhash=reverse %soundset_hash;

    if ($treeitem=~/NPCs/) {
        $treeitem=~/(.*#NPCs#.*?)#/;
        my $npcname=$tree->entrycget($1,-text);
        my $lbl_npc=$mw->Label(-text=>"-- $npcname --",-font=>['MS Sans Serif','8'])->place(-relx=>610/$x,-rely=>50/$y,-anchor=>'nw');
        push @spawned_widgets,$lbl_npc;
    }

    my $lbl1=$mw->Label(-text=>"Current $cur_soundset",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>95/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl1;

    my $lbl=$mw->Label(-text=>"Available soundsets:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>120/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;

    Tk::Autoscroll::Init(my $soundsetlist= $mw->Scrolled('Listbox',
      -scrollbars=>'osoe',
      -background=>'white',
      -selectborderwidth=>'0',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#009000',
      -selectmode=>'extended',
    ));
    $soundsetlist->place(-relx=>600/$x,-rely=>120/$y,-relwidth=>270/$x,-relheight=>380/$y);

    $soundsetlist->insert('end',(sort keys %revhash));
    push @spawned_widgets, $soundsetlist;

    my $btn1=$mw->Button(-text=>'Change soundset',-command=>sub {
        my $cur_list_index=$soundsetlist->curselection;
        if ($cur_list_index eq '' ) { return; } #nothing selected
        my $newsoundsetvalue=$revhash{$soundsetlist->get($cur_list_index)};
        my $oldsoundsetvalue=$revhash{$cur_soundset_name};
        LogInfo ("Changing soundset from $cur_soundset_name ($oldsoundsetvalue) to " .
          $soundsetlist->get($cur_list_index) . " ($newsoundsetvalue)");
        $tree->autosetmode();
        $tree->entryconfigure($treeitem,-text=>"Soundset: " . ($soundsetlist->get($cur_list_index)));
        if ($treeitem=~/NPCs/) {
            $$ifo_gff_ref->{Main}{Fields}[$$ifo_gff_ref->{Main}->get_field_ix_by_label('SoundSetFile')]{Value}=$newsoundsetvalue;
            my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];                        #store the new
            my $datahash=$tree->entrycget($root,-data);                   #gff in the root's datahash
            $treeitem =~/NPCs#NPC(\d+)/;                                    #so we know that it needs replacing
            my $npcnum=$1;                                                #when it comes time to commit changes
            $datahash->{"AVAILNPC$npcnum.utc"}=$$ifo_gff_ref;
            $tree->entryconfigure($root,-data=>$datahash);
        } else {
            my $mplix=$$ifo_gff_ref->{Main}->get_field_ix_by_label('Mod_PlayerList');
            $$ifo_gff_ref->{Main}{'Fields'}[$mplix]{Value}[0]{Fields}[$$ifo_gff_ref->{Main}{'Fields'}[$mplix]{Value}[0]->get_field_ix_by_label('SoundSetFile')]{'Value'}=$newsoundsetvalue;
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>120/$x);

    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne',-relwidth=>90/$x);
    push @spawned_widgets,$btn2;

}

sub SpawnDoorWidgets {

    my ($treeitem,$inv_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my $savegamedir=(split /#/,$treeitem)[2];
    my $doorTreeName=(split /#/,$treeitem)[-1];
    my $doorName;

    my $root='#'.$gameversion.'#'.$savegamedir;
    my $datahash=$tree->entrycget($root,-data);
    my $git_gff = $datahash->{'GFF-git'};

    # Looking for the door
    my $doorsList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Door List')]{Value};
    my $iDoor = 0;
    my $selectedDoorId;
    foreach(@$doorsList) {
        my $ref = $doorsList->[$iDoor]{Fields}[$doorsList->[$iDoor]->get_field_ix_by_label('Tag')]{Value};
        if($iDoor."_".$ref == $doorTreeName){
            $selectedDoorId = $iDoor;
            $doorName = $ref;
        }
        $iDoor++;
    }

    # Building UI
    my $labelDoorName=$mw->Label(-text=>"Selected door: ".$doorName,-font=>['MS Sans Serif','8'])->place(-relx=>650/$x,-rely=>70/$y,-anchor=>'sw');
    push @spawned_widgets,$labelDoorName;


    ## X Position
    my $labelXPosition=$mw->Label(-text=>'X Position: ',-font=>['MS Sans Serif','10'])->place(-relx=>650/$x,-rely=>100/$y,-anchor=>'sw');
    push @spawned_widgets,$labelXPosition;
    my $xPosition = $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('X')]{Value};
    my $boxXPosition=$mw->Label(-text=>$xPosition,-background=>'white',-font=>['MS Sans Serif','10'])->place(-relx=>782/$x,-rely=>100/$y,-anchor=>'sw');
    push @spawned_widgets,$boxXPosition;

    ## Y Position
    my $labelYPosition=$mw->Label(-text=>'Y Position: ',-font=>['MS Sans Serif','10'])->place(-relx=>650/$x,-rely=>125/$y,-anchor=>'sw');
    push @spawned_widgets,$labelYPosition;
    my $yPosition = $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('Y')]{Value};
    my $boxYPosition=$mw->Label(-text=>$yPosition,-background=>'white',-font=>['MS Sans Serif','10'])->place(-relx=>782/$x,-rely=>125/$y,-anchor=>'sw');
    push @spawned_widgets,$boxYPosition;

    ## Z Position
    my $labelZPosition=$mw->Label(-text=>'Z Position: ',-font=>['MS Sans Serif','10'])->place(-relx=>650/$x,-rely=>150/$y,-anchor=>'sw');
    push @spawned_widgets,$labelZPosition;
    my $zPosition = $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('Z')]{Value};
    my $boxZPosition=$mw->Label(-text=>$zPosition,-background=>'white',-font=>['MS Sans Serif','10'])->place(-relx=>782/$x,-rely=>150/$y,-anchor=>'sw');
    push @spawned_widgets,$boxZPosition;

    ## OpenState
    my $labelOpenState=$mw->Label(-text=>'OpenState: ',-font=>['MS Sans Serif','10'])->place(-relx=>650/$x,-rely=>175/$y,-anchor=>'sw');
    push @spawned_widgets,$labelOpenState;
    my $openState = $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('OpenState')]{Value};
    my $boxOpenState=$mw->Entry(-textvariable=>\$openState,-background=>'white',-width=>10)->place(-relx=>782/$x,-rely=>175/$y,-anchor=>'sw');
    push @spawned_widgets,$boxOpenState;

    ## Locked
    my $labelLocked=$mw->Label(-text=>'Locked: ',-font=>['MS Sans Serif','10'])->place(-relx=>650/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$labelLocked;
    my $locked = $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('Locked')]{Value};
    my $boxLocked=$mw->Entry(-textvariable=>\$locked,-background=>'white',-width=>10)->place(-relx=>782/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$boxLocked;

    ## CloseLockDC
    # my $labelLocked=$mw->Label(-text=>'CloseLockDC: ',-font=>['MS Sans Serif','10'])->place(-relx=>650/$x,-rely=>200/$y,-anchor=>'sw');
    # push @spawned_widgets,$labelLocked;
    # my $locked = $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('Locked')]{Value};
    # my $boxLocked=$mw->Entry(-textvariable=>\$locked,-background=>'white',-width=>10)->place(-relx=>782/$x,-rely=>200/$y,-anchor=>'sw');
    # push @spawned_widgets,$boxLocked;


    # Building Buttons
    my $btnApply=$mw->Button(-text=>'Apply',-command=>sub {

        if($doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('OpenState')]{Value} != $openState){
            $openState += 0;
            # Sanity check
            if($openState > 0){
                $openState = 1;
            }
            else{
                $openState = 0;
            }
            LogInfo "Updating ".$doorName." OpenState value to: ".$openState;
            $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('OpenState')]{Value}=$openState;
        }

        if($doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('Locked')]{Value} != $locked){
            $locked += 0;
            # Sanity check
            if($locked > 0){
                $locked = 1;
            }
            else{
                $locked = 0;
            }
            LogInfo "Updating ".$doorName." Locked value to: ".$locked;
            $doorsList->[$selectedDoorId]{Fields}[$doorsList->[$selectedDoorId]->get_field_ix_by_label('Locked')]{Value}=$locked;
        }

    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btnApply;

    $btnCommit=$mw->Button(-text=>"Commit Changes",
      -command=>sub {
          CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    push @spawned_widgets,$btnCommit;

}

#>>>>>>>>>>>>>>>>>>>>>>>
sub Populate_Inventory {
    #>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem)=shift;
    my $gv;
    my $gm;

    my @parms = split /#/, $treeitem;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;
    my $gameversion=(split /#/,$treeitem)[1];
    my $registered_path;

    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }

    LogInfo("Populating $gv->$gm");
    my $root='#'.$gameversion.'#'.(split /#/,$treeitem)[2];
    my $gff=${$tree->entrycget( $root,-data)}{'GFF-inv'};
    my $itemlist=$gff->{Main}{Fields}{Value};
    my @items;
    for my $item_struct (@$itemlist) {
        my $strref=$item_struct->{Fields}[$item_struct->get_field_ix_by_label('LocalizedName')]{Value}{StringRef};
        my $item_name;
        if ($strref==-1) {
            $item_name=$item_struct->{Fields}[$item_struct->get_field_ix_by_label('LocalizedName')]{Value}{Substrings}[0]{Value}; }
        else {
            $item_name=Bioware::TLK::string_from_resref($registered_path,$strref);
        }
        my $tag=lc $item_struct->{Fields}[$item_struct->get_field_ix_by_label('Tag')]{Value};
        my $stack=$item_struct->{Fields}[$item_struct->get_field_ix_by_label('StackSize')]{Value};
        my $pretty_item=sprintf("%-32s%s  [%d]",$tag,$item_name,$stack);
        push @items,$pretty_item;
    }
    my $i=0;
    for my $item (sort @items) {
        my $tag=(split / /,$item)[0];
        $tree->add($treeitem."#$tag"."__$i",-text=>$item,-data=>'can modify');#-font=>['Courier New','8']);
        $i++;
    }
    $tree->entryconfigure($treeitem,-data=>'can modify');
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnInventoryWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>
    my ($treeitem,$inv_gff_ref)=@_;
    my $gameversion=(split /#/,$treeitem)[1];
    my $savegamedir=(split /#/,$treeitem)[2];
    my $curtext=$tree->entrycget($treeitem,-text);

    my $selectedEntry = (split /#/,$treeitem)[-2];
    my $subInventoryIndex = -1;
    if($treeitem =~ /#Area#Placeables#/ || $treeitem =~ /#Area#Creatures#/ || $treeitem =~ /#Area#Stores#/){
        $subInventoryIndex = (split /_/, $selectedEntry)[0];
    }

    $curtext=~/(.*)\[(\d+)/;

    my $lbl1=$mw->Label(-text=>$1,-font=>['MS Sans Serif','8'])->place(-relx=>650/$x,-rely=>200/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl1;

    my $lbl2=$mw->Label(-text=>'# In Inventory:',-font=>['MS Sans Serif','10'])->place(-relx=>650/$x,-rely=>230/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl2;

    #    my $lbl_count=$mw->Label(-text=>$2,-font=>['MS Sans Serif','10'],-bg=>'#FFFFFF')->place(-relx=>750/$x,-rely=>230/$y,-anchor=>'sw');
    #    push @spawned_widgets,$lbl_count;

    my $cur_vasl=$2;
    #    print $cur_vasl;
    my $txt1=$mw->Entry(-textvariable=>\$cur_vasl,-background=>'white',-width=>10)->place(-relx=>782/$x,-rely=>230/$y,-anchor=>'sw');
    push @spawned_widgets,$txt1;

    $txt1->bind('<Return>'=>sub {
        $cur_vasl += 0;
        #	    print $cur_vasl . "\n";
        return unless $tree->infoExists($treeitem);
        my $curtext=$tree->entrycget($treeitem,-text);
        if ($cur_vasl>0) {
            $curtext=~/(.*)\[(\d+)/;
            LogInfo ("Changing count of $1 from $2 to $cur_vasl");
            my $newtext="$1\[$cur_vasl\]";
            my $this_tag=(split / /,$curtext)[0];
            $tree->entryconfigure($treeitem,-text=>$newtext);
            my $itemlist=$$inv_gff_ref->{Main}{Fields}{Value};
            for my $item_struct (@$itemlist) {
                my $tag=lc $item_struct->{Fields}[$item_struct->get_field_ix_by_label('Tag')]{Value};
                if ($tag eq $this_tag) {
                    $item_struct->{Fields}[$item_struct->get_field_ix_by_label('StackSize')]{Value}=$cur_vasl;
                    last;
                }
            }
        }
        else {
            my $this_tag=(split / /,$curtext)[0];
            LogInfo("Removing $this_tag from inventory");
            my $itemlist=$$inv_gff_ref->{Main}{Fields}{Value};
            my @newitemlist;
            for my $item_struct (@$itemlist) {
                my $tag=lc $item_struct->{Fields}[$item_struct->get_field_ix_by_label('Tag')]{Value};
                unless ($tag eq $this_tag) {
                    push @newitemlist, $item_struct;
                }
            }
            $$inv_gff_ref->{Main}{Fields}{Value}=[@newitemlist];
            $tree->delete('entry',$treeitem);
            for my $widge ($txt1, $lbl1, $lbl2) {   #unspawn old widgets
                $widge->destroy if Tk::Exists($widge);    }
            @spawned_widgets=();

        }
    });
    #####FIN

    $btn_sub=$mw->Button(-text=>"-",-font=>['MS Sans Serif','10'],-command=>sub{
        $cur_vasl -= 0;
        #print "Before: $cur_vasl \n";
        my $cur_valg=$cur_vasl;
        if ($cur_valg >= 0) {
            $cur_valg -= 1;
            $cur_vasl = $cur_valg;
            #print "After: $cur_vasl \n";
            $txt1->configure(-text=>$cur_vasl);
        }
    })->place(-relx=>722/$x,-rely=>260/$y,-anchor=>'sw',-relwidth=>35/$x);
    push @spawned_widgets,$btn_sub;

    $btn_sub5=$mw->Button(-text=>"-5",-font=>['MS Sans Serif','10'],-command=>sub{
        $cur_vasl -= 0;
        my $cur_valg=$cur_vasl;
        if ($cur_valg > 5) {
            $cur_valg -= 5;
            $cur_vasl = $cur_valg;
            $txt1->configure(-text=>$cur_vasl);
        }
    })->place(-relx=>686/$x,-rely=>260/$y,-anchor=>'sw',-relwidth=>35/$x);
    push @spawned_widgets,$btn_sub5;

    $btn_sub10=$mw->Button(-text=>"-10",-font=>['MS Sans Serif','10'],-command=>sub{
        $cur_vasl -= 0;
        my $cur_valg=$cur_vasl;
        if ($cur_valg > 10) {
            $cur_valg -= 10;
            $cur_vasl = $cur_valg;
            $txt1->configure(-text=>$cur_vasl);
        }
    })->place(-relx=>650/$x,-rely=>260/$y,-anchor=>'sw',-relwidth=>35/$x);
    push @spawned_widgets,$btn_sub10;

    $btn_add=$mw->Button(-text=>"+",-font=>['MS Sans Serif','10'],-command=>sub{
        $cur_vasl -= 0;
        #print "Before: $cur_vasl \n";
        my $cur_valg=$cur_vasl;
        $cur_valg = $cur_vasl + 1;
        $cur_vasl = $cur_valg;
        #print "After: $cur_vasl \n";
        $txt1->configure(-text=>$cur_valg);
    })->place(-relx=>764/$x,-rely=>260/$y,-anchor=>'sw',-relwidth=>35/$x);
    push @spawned_widgets,$btn_add;

    $btn_add5=$mw->Button(-text=>"+5",-font=>['MS Sans Serif','10'],-command=>sub{
        $cur_vasl -= 0;
        my $cur_valg=$cur_vasl;

        $cur_valg = $cur_vasl + 5;
        $cur_vasl = $cur_valg;
        $txt1->configure(-text=>$cur_valg);

    })->place(-relx=>799/$x,-rely=>260/$y,-anchor=>'sw',-relwidth=>35/$x);
    push @spawned_widgets,$btn_add5;

    $btn_add10=$mw->Button(-text=>"+10",-font=>['MS Sans Serif','10'],-command=>sub{
        $cur_vasl -= 0;
        my $cur_valg=$cur_vasl;

        $cur_valg = $cur_vasl + 10;
        $cur_vasl = $cur_valg;
        $txt1->configure(-text=>$cur_valg);

    })->place(-relx=>835/$x,-rely=>260/$y,-anchor=>'sw',-relwidth=>35/$x);
    push @spawned_widgets,$btn_add10;

    my $btn1=$mw->Button(-text=>'Apply',-command=>sub {
        $cur_vasl += 0;
        #	    print $cur_vasl . "\n";
        return unless $tree->infoExists($treeitem);
        my $curtext=$tree->entrycget($treeitem,-text);
        if ($cur_vasl>0) {
            $curtext=~/(.*)\[(\d+)/;
            LogInfo ("Changing count of $1 from $2 to $cur_vasl");
            my $newtext="$1\[$cur_vasl\]";
            my $this_tag=(split / /,$curtext)[0];
            $tree->entryconfigure($treeitem,-text=>$newtext);

            my $itemlist;
            if( $treeitem =~/#Area#Placeables#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitPlaceablesList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Placeable List')]{Value};
                $itemlist = $gitPlaceablesList->[$subInventoryIndex]{Fields}[$gitPlaceablesList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
            }
            elsif( $treeitem =~ /#Area#Creatures#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitStoresList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Creature List')]{Value};
                $itemlist = $gitStoresList->[$subInventoryIndex]{Fields}[$gitStoresList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
            }
            elsif( $treeitem =~/#Area#Stores#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitStoresList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('StoreList')]{Value};
                $itemlist = $gitStoresList->[$subInventoryIndex]{Fields}[$gitStoresList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
            }
            else{
                $itemlist=$$inv_gff_ref->{Main}{Fields}{Value};
            }

            for my $item_struct (@$itemlist) {
                my $tag=lc $item_struct->{Fields}[$item_struct->get_field_ix_by_label('Tag')]{Value};
                if ($tag eq $this_tag) {
                    $item_struct->{Fields}[$item_struct->get_field_ix_by_label('StackSize')]{Value}=$cur_vasl;
                    last;
                }
            }
        }
        else {
            my $this_tag=(split / /,$curtext)[0];
            LogInfo("Removing $this_tag from inventory");
            my $itemlist;
            if( $treeitem =~/#Area#Placeables#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitPlaceablesList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Placeable List')]{Value};
                $itemlist = $gitPlaceablesList->[$subInventoryIndex]{Fields}[$gitPlaceablesList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
            }
            elsif( $treeitem =~ /#Area#Creatures#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitStoresList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Creature List')]{Value};
                $itemlist = $gitStoresList->[$subInventoryIndex]{Fields}[$gitStoresList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
            }
            elsif( $treeitem =~/#Area#Stores#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitStoresList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('StoreList')]{Value};
                $itemlist = $gitStoresList->[$subInventoryIndex]{Fields}[$gitStoresList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
            }
            else{
                $itemlist=$$inv_gff_ref->{Main}{Fields}{Value};
            }
            my @newitemlist;
            for my $item_struct (@$itemlist) {
                my $tag=lc $item_struct->{Fields}[$item_struct->get_field_ix_by_label('Tag')]{Value};
                unless ($tag eq $this_tag) {
                    push @newitemlist, $item_struct;
                }
            }
            if( $treeitem =~/#Area#Placeables#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitPlaceablesList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Placeable List')]{Value};
                $gitPlaceablesList->[$subInventoryIndex]{Fields}[$gitPlaceablesList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value}=[@newitemlist];
            }
            elsif( $treeitem =~ /#Area#Creatures#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitStoresList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Creature List')]{Value};
                $gitStoresList->[$subInventoryIndex]{Fields}[$gitStoresList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value}=[@newitemlist];
            }
            elsif( $treeitem =~/#Area#Stores#/ ){
                my $root='#'.$gameversion.'#'.$savegamedir;
                my $datahash=$tree->entrycget($root,-data);
                my $git_gff = $datahash->{'GFF-git'};
                my $gitStoresList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('StoreList')]{Value};
                $gitStoresList->[$subInventoryIndex]{Fields}[$gitStoresList->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value}=[@newitemlist];
            }
            else{
                $$inv_gff_ref->{Main}{Fields}{Value}=[@newitemlist];
            }
            $tree->delete('entry',$treeitem);
            for my $widge ($txt1, $lbl1, $lbl2) {   #unspawn old widgets
                $widge->destroy if Tk::Exists($widge);    }
            @spawned_widgets=();

        }
    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>60/$x);
    push @spawned_widgets,$btn1;

    $btnCommit=$mw->Button(-text=>"Commit Changes",
      -command=>sub {
          CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne');
    # push @spawned_widgets,$btn2;
    push @spawned_widgets,$btnCommit;
}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub SpawnAddInventoryWidgets {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    my $treeitem = shift;
    my $gameversion=(split /#/,$treeitem)[1];
    my $savegamedir=(split /#/,$treeitem)[2];
    my %master_item_list;
    my $baseitems_hash_ref;
    my $registered_path;

    my $yOffset = 0;

    my $selectedEntry = (split /#/,$treeitem)[-1];
    my $subInventoryIndex = -1;
    if(  $treeitem =~ /#Area#Placeables#/
      || $treeitem =~ /#Area#Creatures#/
      || $treeitem =~ /#Area#Stores#/){


        my @treeLevels = split /#/, $treeitem;
        shift @treeLevels;
        my $containerType = $treeLevels[3];

        $subInventoryIndex = (split /_/, $selectedEntry)[0];

        my $containerTreeName=(split /#/,$treeitem)[-1];

        my $root='#'.$gameversion.'#'.$savegamedir;
        my $datahash=$tree->entrycget($root,-data);
        my $git_gff = $datahash->{'GFF-git'};

        my $containerList;
        if( $containerType eq 'Stores' ){
            $containerList = $git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('StoreList')]{Value};
        }
        elsif( $containerType eq 'Placeables' ){
            $containerList = $git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Placeable List')]{Value};
        }
        elsif( $containerType eq 'Creatures' ){
            $containerList = $git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Creature List')]{Value};
        }

        # my $containerList=$git_gff->{Main}{Fields}[$git_gff->{Main}->get_field_ix_by_label('Door List')]{Value};
        my $iContainer = 0;
        my $containerName = $tree->entrycget($treeitem,-text);
        my $selectedContainerId;
        foreach(@$containerList) {
            my $containerTag = $containerList->[$iContainer]{Fields}[$containerList->[$iContainer]->get_field_ix_by_label('Tag')]{Value};
            if($iContainer."_".$containerTag == $containerTreeName){
                $selectedContainerId = $iContainer;
                # $containerName = $containerTag;
            }
            $iContainer++;
        }

        # Building UI
        $yOffset += 20;
        my $labelContainerName=$mw->Label(-text=>$containerName,-font=>['MS Sans Serif','8'])->place(-relx=>625/$x,-rely=>$yOffset/$y,-anchor=>'sw');
        push @spawned_widgets,$labelContainerName;


        ## X Position
        $yOffset += 25;
        my $labelXPosition=$mw->Label(-text=>'X Position: ',-font=>['MS Sans Serif','10'])->place(-relx=>625/$x,-rely=>$yOffset/$y,-anchor=>'sw');
        push @spawned_widgets,$labelXPosition;
        my $xPosition = $containerList->[$selectedContainerId]{Fields}[$containerList->[$selectedContainerId]->get_field_ix_by_label('X')]{Value};
        my $boxXPosition=$mw->Label(-text=>$xPosition,-background=>'white',-font=>['MS Sans Serif','10'])->place(-relx=>725/$x,-rely=>50/$y,-anchor=>'sw');
        push @spawned_widgets,$boxXPosition;

        ## Y Position
        $yOffset += 25;
        my $labelYPosition=$mw->Label(-text=>'Y Position: ',-font=>['MS Sans Serif','10'])->place(-relx=>625/$x,-rely=>$yOffset/$y,-anchor=>'sw');
        push @spawned_widgets,$labelYPosition;
        my $yPosition = $containerList->[$selectedContainerId]{Fields}[$containerList->[$selectedContainerId]->get_field_ix_by_label('Y')]{Value};
        my $boxYPosition=$mw->Label(-text=>$yPosition,-background=>'white',-font=>['MS Sans Serif','10'])->place(-relx=>725/$x,-rely=>75/$y,-anchor=>'sw');
        push @spawned_widgets,$boxYPosition;

        ## Z Position
        # $yOffset += 25;
        # my $labelZPosition=$mw->Label(-text=>'Z Position: ',-font=>['MS Sans Serif','10'])->place(-relx=>625/$x,-rely=>$yOffset/$y,-anchor=>'sw');
        # push @spawned_widgets,$labelZPosition;
        # my $zPosition = $containerList->[$selectedContainerId]{Fields}[$containerList->[$selectedContainerId]->get_field_ix_by_label('Z')]{Value};
        # my $boxZPosition=$mw->Label(-text=>$zPosition,-background=>'white',-font=>['MS Sans Serif','10'])->place(-relx=>725/$x,-rely=>100/$y,-anchor=>'sw');
        # push @spawned_widgets,$boxZPosition;

    }

    if ($gameversion==1) { %master_item_list=%master_item_list1; $registered_path=$kseInitializer->{path}->{kotor}; $baseitems_hash_ref=\%baseitems_hash1;}
    elsif ($gameversion==2) { %master_item_list=%master_item_list2; $registered_path=$kseInitializer->{path}->{tsl};   $baseitems_hash_ref=\%baseitems_hash2;}
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) { %master_item_list=%master_item_list2; $registered_path=$kseInitializer->{path}->{tsl};   $baseitems_hash_ref=\%baseitems_hash2;}
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) { %master_item_list=%master_item_list3; $registered_path=$kseInitializer->{path}->{tjm};   $baseitems_hash_ref=\%baseitems_hash3;}
    elsif ($gameversion==4) { %master_item_list=%master_item_list3; $registered_path=$kseInitializer->{path}->{tjm};   $baseitems_hash_ref=\%baseitems_hash3;}

    my $lbl=$mw->Label(-text=>"Available Items:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>120/$y,-anchor=>'sw');
    push @spawned_widgets,$lbl;

    # If the item list has not been create before, do it now
    if (scalar keys %master_item_list == 0) {
        $lbl->configure(-text=>"Building Master Item List...");
        Generate_Master_Item_List($gameversion);
        $lbl->configure(-text=>"Available Items:");
        if ($gameversion==1) { %master_item_list=%master_item_list1}
        elsif ($gameversion==2) {%master_item_list=%master_item_list2}
        elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {%master_item_list=%master_item_list2}
        elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {%master_item_list=%master_item_list3}
        elsif ($gameversion==4) {%master_item_list=%master_item_list3}
    }

    my @templates;
    my @treeitem_children=$tree->info('children',$treeitem);
    my %possessed;
    for my $treeitem_child (@treeitem_children) {
        if ( $treeitem =~/#Area#Placeables#/ ){
            $treeitem_child =~ /#Area#Placeables#(.*)__/;
            my $treeitem_child_name=(split /#/,$treeitem_child)[-1];
            $possessed{$treeitem_child_name}=1;
        }
        elsif ( $treeitem =~ /#Area#Creatures#/ ){
            $treeitem_child =~ /#Area#Creatures#(.*)__/;
            my $treeitem_child_name=(split /#/,$treeitem_child)[-1];
            $possessed{$treeitem_child_name}=1;
        }
        elsif ( $treeitem =~/#Area#Stores#/ ){
            $treeitem_child =~ /#Area#Stores#(.*)__/;
            my $treeitem_child_name=(split /#/,$treeitem_child)[-1];
            $possessed{$treeitem_child_name}=1;
        }
        else{
            $treeitem_child =~ /Inventory#(.*)__/;
            $possessed{$1}=1;
        }
    }

    for my $key (sort keys %master_item_list) {
        my $desc=$master_item_list{$key}{'desc'};
        $desc=~s/\n/ /g;    #get rid of any new line chars
        my $lilhash={'itemtext'=>sprintf("%-18s%-18s%s",$key,$master_item_list{$key}{'tag'},$desc),
          'override'=>$master_item_list{$key}{'override'},
          'possessed'=>$possessed{$master_item_list{$key}{'tag'}}
        };
        if ($lilhash->{'override'}) { LogInfo "override: itemtext: $$lilhash{'itemtext'} ### $key # $master_item_list{$key}{'tag'} # $desc" }

        push @templates,$lilhash;
    }


    my $erf=Bioware::ERF->new();
    my $img=Imager->new();
    unless ($erf->read_erf("$registered_path\\TexturePacks\\swpc_tex_gui.erf")) {
        undef $erf;
    }

    Tk::Autoscroll::Init(my $templatelist= $mw->Scrolled('TList',
      -scrollbars=>'osoe',
      -background=>'white',
      -selectborderwidth=>'0',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#B0B0B0',
      -selectmode=>'extended',
      -itemtype=>'text',
      -takefocus=>1,
      -font=>['Lucida Console','8'],
      -orient=>'horizontal',
      -pady=>0

    ));
    $templatelist->place(-relx=>600/$x,-rely=>120/$y,-relwidth=>270/$x,-relheight=>380/$y);

    my $overridestyle = $mw->ItemStyle('text',
      -foreground=>'#FF4040',
      -selectforeground=>'#A00000',
      -selectbackground=>'#B0B0B0',
      -font=>['Lucida Console','8']);
    my $pstylefg='#4040FF';
    my $possessedstyle = $mw->ItemStyle('text',
      -foreground=>$pstylefg,
      -selectforeground=>'#0000A0',
      -selectbackground=>'#B0B0B0',
      -font=>['Lucida Console','8']);
    my $underlinedstyle=$mw->ItemStyle('text',-font=>['Lucida Console','8','underline']);

    $templatelist->insert('end',-text=>sprintf("%-18s%-18s%s","TemplateResRef","Tag","Description"),-style=>$underlinedstyle);
    for my $template (@templates) {
        if ($template->{'possessed'})  {
            $templatelist->insert('end',-text=>$template->{'itemtext'},-style=>$possessedstyle); }
        elsif ($template->{'override'}) {
            for (my $i=0; $i<length $template->{'itemtext'}; $i++){
                #LogInfo (substr ($template->{'itemtext'},$i) . ' ' . ord (substr ($template->{'itemtext'},$i)));
            }
            $templatelist->insert('end',-text=>$template->{'itemtext'},-style=>$overridestyle); }
        else {
            $templatelist->insert('end',-text=>$template->{'itemtext'});
        }
    }
    $templatelist->bind('<ButtonRelease-1>'=>sub {
        $picture_label->destroy if Tk::Exists($picture_label);
        eval {$picture_label_photo->delete};

        my ($cur_list_index)=$templatelist->info('selection');
        return unless defined($cur_list_index);

        return unless $cur_list_index > 0;

        #$lbl_pic->configure(-text=>'getting from erf');
        my $selected_template=$templatelist->entrycget($cur_list_index,-text);
        $selected_template=(split / /,$selected_template)[0];
        my $selected_baseitem=$master_item_list{$selected_template}{baseitem};

        my $selected_item_class=$baseitems_hash_ref->{$selected_baseitem};
        unless (exists $baseitems_hash_ref->{$selected_baseitem}) {LogInfo "$selected_baseitem does not exist in baseitems_hash"}

        my $selected_modelvar=sprintf("%3.3u",$master_item_list{$selected_template}{modelvar});
        LogInfo ("Trying to picture: $selected_template $selected_baseitem $selected_item_class $selected_modelvar");
        my $tgadata;
        my $ftyp='bmp'; #IMAGE FORMAT
        if (-e "$registered_path/override/$selected_item_class".$selected_modelvar.".tga") {
            local $/;
            open my $tmpfh,"<","$registered_path/override/$selected_item_class".$selected_modelvar.".tga";
            binmode $tmpfh;
            $tgadata=<$tmpfh>;
            close $tmpfh;
            LogInfo ("KotOR".$gameversion." override $selected_item_class".$selected_modelvar.".tga detected");
        } else {
            unless (defined ($erf)) {  return; }
            my $erf_ix=$erf->load_erf_resource($selected_item_class . $selected_modelvar.".tpc");
            return unless defined($erf_ix);
            my $tpc=Bioware::TPC->new();
            my $scalardata=$erf->{resources}[$erf_ix]{res_data};
            my $ret=$tpc->read_tpc(\$scalardata);
            $tpc->write_tga(\$tgadata);
            if (($tpc->{tpc}{header}{data_size}==0) && ($tpc->{tpc}{header}{encoding}==4)) {
                $ftyp='bmp'            }
            LogInfo ("ftyp: $ftyp $tpc->{tpc}{header}{data_size} $tpc->{tpc}{header}{encoding}");
        }
        $img->read(data=>$tgadata,type=>'tga') or die $img->errstr; ;
        #$img->read(file=>"d:/swkotor2/tk.tga",type=>'tga') or die $img->errstr; ;
        #$img=$img->scale(xpixels=>100);
        my $buf;
        $img->write(data=>\$buf,type=>$ftyp) or die $img->errstr; ;
        $picture_label_photo=$mw->Photo(-data=>encode_base64($buf),-format=>$ftyp);
        $picture_label=$mw->Label(-image=>$picture_label_photo)->pack(-side=>'top',-anchor=>'ne');
    } );#}

    push @spawned_widgets, $templatelist;

    my $num_to_add = 1;###STA
    my $numhere = $mw->LabEntry(-label=>"\# to add:", -textvariable=>\$num_to_add, -width=>'2', -state=>'normal', -background=>'white')->place(-relx=>710/$x, -rely=>503/$y);
    push @spawned_widgets, $numhere;

    my $applySub = sub {
        my @selected_indices = $templatelist->info('selection');
        return unless (scalar @selected_indices); #nothing selected

        #! Loop over the selected item
        for my $selected_index (@selected_indices) {

            # 0 is not an item
            next if $selected_index == 0;

            # Check if the selected item is already in the inventory (based on its displayed color)
            my $thisstyle = $templatelist->entrycget($selected_index, -style); #check the style
            if ($thisstyle) {                                                  # to see if it is already possessed
                if ($thisstyle->cget(-foreground) eq $pstylefg) {next}
            }

            # Getting information about this item (.uti file)
            my $this_item_text = $templatelist->entrycget($selected_index, -text);
            LogInfo("Adding Item: $this_item_text");
            my $selected_uti = (split / /, $this_item_text)[0] . ".uti";
            LogInfo "Loading uti file: " . $selected_uti;
            my $uti_gff = Bioware::GFF->new();
            if (-e "$registered_path\\override\\$selected_uti") {
                $uti_gff->read_gff_file("$registered_path\\override\\$selected_uti");
            }
            else {
                my $bif = Bioware::BIF->new($registered_path, undef, 'uti');
                if ($bif == undef) {$bif = try_extracted_data($gameversion, undef, 'uti')}
                my $resource_ref = $bif->get_resource('data\\templates.bif', $selected_uti);
                $uti_gff->read_gff_scalar($resource_ref);
            }


            # Getting the current item list
            my $isEmpty = 0; my $gitContainterStruct;
            my $itemList;
            my $root = '#' . $gameversion . '#' . $savegamedir;
            my $datahash = $tree->entrycget($root, -data);
            if ($treeitem =~ /#Area#/) {
                my $dataGff = $datahash->{'GFF-git'};
                if ($treeitem =~ /#Area#Placeables#/) {
                    $gitContainterStruct = $dataGff->{Main}{Fields}[$dataGff->{Main}->get_field_ix_by_label('Placeable List')]{Value};
                }
                elsif ($treeitem =~ /#Area#Creatures#/) {
                    $gitContainterStruct = $dataGff->{Main}{Fields}[$dataGff->{Main}->get_field_ix_by_label('Creature List')]{Value};
                }
                elsif ($treeitem =~ /#Area#Stores#/) {
                    $gitContainterStruct = $dataGff->{Main}{Fields}[$dataGff->{Main}->get_field_ix_by_label('StoreList')]{Value};
                }
                $itemList = $gitContainterStruct->[$subInventoryIndex]{Fields}[$gitContainterStruct->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
                if( scalar @{$itemList} == 0 ){
                    $gitContainterStruct->[$subInventoryIndex]->createField('Type'=>FIELD_LIST, 'Label'=>'ItemList');
                    # $gitContainterStruct->[$subInventoryIndex]{Fields}[$gitContainterStruct->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value} = ();
                    # $itemList = [\@$gitContainterStruct->[$subInventoryIndex]{Fields}[$gitContainterStruct->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value}];
                    $isEmpty = 1;
                }
            }
            else {
                my $dataGff = $datahash->{'GFF-inv'};
                $itemList = $dataGff->{Main}{Fields}{Value};
            }

            my $newItemStruct;

            # If the itemList is empty, create the item struct from scratch
            if ($isEmpty || $treeitem =~ /#Inventory#/) {

                LogInfo "> Creating new item from scratch";

                if( $treeitem =~/#Area#Placeables#/ ){
                    $newItemStruct = Bioware::GFF::Struct->new('ID'=>9, 'StructIndex'=>undef, 'Fields'=>[]);

                    # $newItemStruct->createField('Type'=>FIELD_DWORD,'Label'=>'ObjectId','Value'=>5);
                    # $newItemStruct->createField('Type'=>FIELD_BYTE,'Label'=>'Dropable','Value'=>1);
                }
                elsif ( $treeitem =~ /#Area#Creatures#/ ){
                    $newItemStruct = Bioware::GFF::Struct->new('ID'=>0, 'StructIndex'=>undef, 'Fields'=>[]);

                    $newItemStruct->createField('Type'=>FIELD_BYTE,'Label'=>'Dropable','Value'=>1);

                    # if( defined ( $uti_gff->{Main}->get_field_ix_by_label('ObjectId') )){
                    # 	push @{$newItemStruct->{Fields}},($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('ObjectId')]);
                    # }
                    # else{
                    # 	$newItemStruct->createField('Type'=>FIELD_DWORD,'Label'=>'ObjectId','Value'=>6);
                    # }
                }
                elsif ( $treeitem =~/#Area#Stores#/ ){
                    $newItemStruct = Bioware::GFF::Struct->new('ID'=>99, 'StructIndex'=>undef, 'Fields'=>[]);

                    $newItemStruct->createField('Type'=>FIELD_DWORD,'Label'=>'ObjectId','Value'=>5);
                    # $newItemStruct->createField('Type'=>FIELD_BYTE,'Label'=>'Dropable','Value'=>1);
                }
                else{
                    $newItemStruct = Bioware::GFF::Struct->new('ID'=>0);
                }

                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('BaseItem')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Tag')]);
                $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'Identified', 'Value' => 1);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Description')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('DescIdentified')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('LocalizedName')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('StackSize')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Stolen')]);
                $newItemStruct->createField('Type' => FIELD_DWORD, 'Label' => 'Upgrades', 'Value' => 0);
                if ($gameversion == 2 || 3 || 4) {
                    $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'UpgradeLevel', 'Value' => $uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('UpgradeLevel')]{Value});
                    $newItemStruct->createField('Type' => FIELD_INT, 'Label' => 'UpgradeSlot0', 'Value' => -1);
                    $newItemStruct->createField('Type' => FIELD_INT, 'Label' => 'UpgradeSlot1', 'Value' => -1);
                    $newItemStruct->createField('Type' => FIELD_INT, 'Label' => 'UpgradeSlot2', 'Value' => -1);
                    $newItemStruct->createField('Type' => FIELD_INT, 'Label' => 'UpgradeSlot3', 'Value' => -1);
                    $newItemStruct->createField('Type' => FIELD_INT, 'Label' => 'UpgradeSlot4', 'Value' => -1);
                    $newItemStruct->createField('Type' => FIELD_INT, 'Label' => 'UpgradeSlot5', 'Value' => -1);
                }
                $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'Dropable', 'Value' => 1);
                $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'Pickpocketable', 'Value' => 1);
                if (defined($uti_gff->{Main}->get_field_ix_by_label('ModelVariation'))) {
                    push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('ModelVariation')]);
                }
                else {
                    $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'ModelVariation', 'Value' => 1);
                }
                #if (defined ($uti_gff->{Main}->get_field_ix_by_label('BodyVariation'))) {
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('BodyVariation')]);
                #}
                #if (defined ($uti_gff->{Main}->get_field_ix_by_label('TextureVar'))) {
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('TextureVar')]);
                #}

                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Charges')]);
                $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'MaxCharges', 'Value' => ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Charges')]{Value}));
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Cost')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('AddCost')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Plot')]);
                push @{$newItemStruct->{Fields}}, ($uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('PropertiesList')]);
                $newItemStruct->createField('Type' => FIELD_FLOAT, 'Label' => 'XPosition', 'Value' => 0);
                $newItemStruct->createField('Type' => FIELD_FLOAT, 'Label' => 'YPosition', 'Value' => 0);
                $newItemStruct->createField('Type' => FIELD_FLOAT, 'Label' => 'ZPosition', 'Value' => 0);
                $newItemStruct->createField('Type' => FIELD_FLOAT, 'Label' => 'XOrientation', 'Value' => 0);
                $newItemStruct->createField('Type' => FIELD_FLOAT, 'Label' => 'YOrientation', 'Value' => 0);
                $newItemStruct->createField('Type' => FIELD_FLOAT, 'Label' => 'ZOrientation', 'Value' => 0);
                $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'NonEquippable', 'Value' => 0);
                $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'NewItem', 'Value' => 1);
                $newItemStruct->createField('Type' => FIELD_BYTE, 'Label' => 'DELETING', 'Value' => 0);

            }
            else {

                LogInfo "Making a copy of the last item in the list";
                my $lastItemStruct = @{$itemList}[-1];

                # Check if the id is incrementing for each item in the list
                my $hasIncrementingId = 0;
                if (scalar @{$itemList} >= 2 and @{$itemList}[-1]->{'ID'} - 1 == @{$itemList}[-2]->{'ID'}) {
                    LogDebug "ID Incrementation detected";
                    $hasIncrementingId = 1;
                    $newItemStruct = Bioware::GFF::Struct->new('ID' => ($lastItemStruct->{'ID'} + 1));
                }
                else {
                    $newItemStruct = Bioware::GFF::Struct->new('ID' => ($lastItemStruct->{'ID'}));
                }

                $newItemStruct->{Fields} = ();

                LogInfo "Reading each field in .uti file, and propagate changes...";
                for my $lastItemStructField (@{$lastItemStruct->{'Fields'}}) {
                    my $fieldLabel = $lastItemStructField->{'Label'};
                    # print "  Field: ".$fieldLabel."\n";

                    if (defined($uti_gff->{Main}->get_field_ix_by_label($fieldLabel))) {
                        # Propagate the uti field content
                        push @{$newItemStruct->{Fields}}, $uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label($fieldLabel)];
                    }
                    else {
                        # Heritate from last item
                        if ($fieldLabel eq 'ObjectId') {
                            # Ignoring -> also appears first in the list...
                            # print "Applying: ".($lastItemStructField->{Value}+5)."\n";
                            $newItemStruct->createField('Type' => FIELD_DWORD, 'Label' => 'ObjectId', 'Value' => ($lastItemStructField->{Value} + 5));
                        }
                        else {
                            push @{$newItemStruct->{Fields}}, $lastItemStructField;
                        }

                    }

                    # if( $fieldLabel == 'DescIdentified' || 'LocalizedName' ){
                    # 	my $cexolocsub = Bioware::GFF::CExoLocSubString->new('StringID'=>0,'Value'=>"test");
                    # 	@{$newItemStruct->{Fields}}[-1]->{Substrings} = [$cexolocsub];
                    # }

                }

                # Look for extra vars that could have been missed
                if (defined($uti_gff->{Main}->get_field_ix_by_label('TextureVar'))
                  and !defined($newItemStruct->get_field_ix_by_label('TextureVar'))) {
                    # print "Adding TextureVar...\n";
                    push @{$newItemStruct->{Fields}}, $uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('TextureVar')];
                }
                elsif( $treeitem =~ /#Area#Creatures#/ ){ # The added item should be droppable
                    if( !defined($newItemStruct->get_field_ix_by_label('Dropable')) ){
                        $newItemStruct->createField('Type'=>FIELD_BYTE,'Label'=>'Dropable','Value'=>1);
                    }
                    else{
                        $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('Dropable')]{Value} = 1;
                    }
                }

            }


            # $newItemStruct->createField('Type'=>FIELD_DWORD,'Label'=>'ObjectId','Value'=>-1);

            # Adding the new item to the list
            if($isEmpty == 1){
                my @itemArray;
                push @itemArray, $newItemStruct;
                $gitContainterStruct->[$subInventoryIndex]{Fields}[$gitContainterStruct->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value} = \@itemArray;
                $itemList = $gitContainterStruct->[$subInventoryIndex]{Fields}[$gitContainterStruct->[$subInventoryIndex]->get_field_ix_by_label('ItemList')]{Value};
            }
            else{
                push @{$itemList}, $newItemStruct;
            }
            LogDebug "NOW = ".(scalar @{$itemList});

            # Printing the new item in the displayed list
            if ($treeitem =~ /#Area#Placeables#/ || $treeitem =~ /#Area#Creatures#/ || $treeitem =~ /#Area#Stores#/) {
                my $strref = $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('LocalizedName')]{Value}{StringRef};
                # print "-> strref = ".$strref."\n;
                my $item_name;
                if ($strref == -1) {
                    $item_name = $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('LocalizedName')]{Value}{Substrings}[0]{Value};}
                else {
                    $item_name = Bioware::TLK::string_from_resref($registered_path, $strref);
                }

                my $tag = lc $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('Tag')]{Value};
                $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('StackSize')]{Value} = $num_to_add;
                my $stack = $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('StackSize')]{Value};
                my $prettyItem = sprintf("%-32s%s  [%d]", $tag, $item_name, $stack);

                LogInfo "Added: " . $prettyItem;
                $tree->add($treeitem . "#" . $tag, -text => $prettyItem, -data => 'can modify');
            }
            else {
                # update tree as per Populate Inventory sub
                my $last_child_ix = -1;
                for my $treeitem_child (@treeitem_children) {
                    $treeitem_child =~ /__(\d+)/;
                    if ($1 > $last_child_ix) {$last_child_ix = $1}
                }
                $last_child_ix++;
                my $strref = $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('LocalizedName')]{Value}{StringRef};
                my $item_name;
                if ($strref == -1) {
                    $item_name = $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('LocalizedName')]{Value}{Substrings}[0]{Value};}
                else {
                    $item_name = Bioware::TLK::string_from_resref($registered_path, $strref);
                }

                #		print "$num_to_add\n";
                $num_to_add = $num_to_add + 0; # print $num_to_add;

                my $tag = lc $uti_gff->{Main}{Fields}[$uti_gff->{Main}->get_field_ix_by_label('Tag')]{Value}; #make sure this is used so can be found in BIF
                $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('StackSize')]{Value} = $num_to_add;
                my $stack = $newItemStruct->{Fields}[$newItemStruct->get_field_ix_by_label('StackSize')]{Value};
                my $pretty_item = sprintf("%-32s%s  [%d]", $tag, $item_name, $stack);
                $tree->add($treeitem . "#$tag" . "__$last_child_ix", -text => $pretty_item, -data => 'can modify');
            }

            # update style in list
            $templatelist->entryconfigure($selected_index, -style => $possessedstyle);
            LogInfo("Successful");
        }
    };

    $numhere->bind( '<Return>'=>$applySub );
    my $btn1=$mw->Button(-text=>'Add Items',-command=>$applySub )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>90/$x);

    push @spawned_widgets,$btn1;

    my $btn2=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) })->place(-relx=>870/$x,-rely=>520/$y,-anchor=>'ne',-relwidth=>90/$x);
    push @spawned_widgets,$btn2;

}

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
sub Generate_Master_Item_List {
    #>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    use IO::Scalar;
    my $gameversion=shift;
    my %master_item_list;
    my $registered_path;
    #	print $gameversion;
    my $real_game = $gameversion;
    if ($gameversion==1)    { $registered_path=$kseInitializer->{path}->{kotor} }
    elsif ($gameversion==2) { $registered_path=$kseInitializer->{path}->{tsl}   }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) { $real_game = 2; $registered_path=$kseInitializer->{path}->{tsl} }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) { $real_game = 3; $registered_path=$kseInitializer->{path}->{tjm} }
    elsif ($gameversion==4) { $real_game = 3; $registered_path=$kseInitializer->{path}->{tjm}   }

    if($items{$real_game}==0)
    {
        $mw->Busy(-recurse=>1);

        ### populate baseitems hash ###
        my $twoda_obj=Bioware::TwoDA->new();
        my $hashref;
        if (-e $registered_path."/override/baseitems.2da") {
            LogInfo ('KotOR'.$gameversion.' baseitems.2da override detected.');
            $hashref=$twoda_obj->read2da($registered_path."/override/baseitems.2da");
        }
        else {
            my $bif_obj=Bioware::BIF->new($registered_path,undef,'2da');
            if ($bif_obj==undef) { $bif_obj=try_extracted_data($gameversion,undef,'2da');}
            my $temp2dafile=$bif_obj->get_resource('data\\2da.bif','baseitems.2da');
            unless (defined ($temp2dafile)) {$temp2dafile=$bif_obj->get_resource('dataxbox\\2da.bif','baseitems.2da')};
            $hashref=$twoda_obj->read2da($temp2dafile);
        }
        if ($gameversion==1) {
            for my $k (keys %$hashref) {# print "Item: $k\n";
                $baseitems_hash1{$k}='i'.$hashref->{$k}{itemclass}.'_';
            }
        }
        elsif ($gameversion==2) {
            for my $k (keys %$hashref) {
                $baseitems_hash2{$k}='i'.$hashref->{$k}{itemclass}.'_';
            }
        }
        elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
            for my $k (keys %$hashref) {
                $baseitems_hash2{$k}='i'.$hashref->{$k}{itemclass}.'_';
            }
        }
        elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
            for my $k (keys %$hashref) {
                $baseitems_hash3{$k}='i'.$hashref->{$k}{itemclass}.'_';
            }
        }
        elsif ($gameversion==4) {
            for my $k (keys %$hashref) {
                $baseitems_hash3{$k}='i'.$hashref->{$k}{itemclass}.'_';
            }
        }

        my ($droidheads, $droidarmor, $droidarms, $droidbelts, $droidimplants,
          $humanheads, $humanarmor, $humanarms, $humanbelts, $humanimplants,
          $humangloves, $weaponsmelee, $weaponsranged);

        # now get all uti files from templates.bif
        my $bif=Bioware::BIF->new($registered_path,undef,'uti');
        if ($bif==undef) { $bif=try_extracted_data($gameversion,undef,'uti'); }
        my @templates=(sort keys %{$bif->{BIFs}{'data\\templates.bif'}{Resources}}) ;
        my $tmp_gff=Bioware::GFF->new();
        for my $template (@templates) {
            my $resource_ref=$bif->get_resource('data\\templates.bif',$template);

            $template =~ s/\.uti//;
            $tmp_gff->read_gff_scalar($resource_ref);
            $master_item_list{$template}{'tag'}=lc $tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('Tag')]{Value};
            $master_item_list{$template}{baseitem}=$tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('BaseItem')]{Value};
            if (defined (my $tmpix=$tmp_gff->{Main}->get_field_ix_by_label('ModelVariation'))) {
                $master_item_list{$template}{modelvar}=$tmp_gff->{Main}{Fields}[$tmpix]{Value};
            }
            else {
                $master_item_list{$template}{modelvar}=$tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('TextureVar')]{Value};
            }
            my $locname=$tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('LocalizedName')]{Value};
            my $strref=$locname->{StringRef};
            if ($strref == -1) {
                $master_item_list{$template}{'desc'}=$locname->{Substrings}[0]{Value};
            } else {
                $master_item_list{$template}{'desc'}=Bioware::TLK::string_from_resref($registered_path,$strref);
            }
            $master_item_list{$template}{'override'}=0;
            #        print "$master_item_list{$template}{tag}\t$hashref->{$master_item_list{$template}{baseitem}}{equipableslots}\n";

            if($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00001")
            {
                #print "DoH: $hashref->{$master_item_list{$template}{baseitem}}{droidorhuman}\n";
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {#print "k: $template\n";
                    $humanheads .= " $template";
                }
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidheads .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00002")
            {
                #print "DoH: $hashref->{$master_item_list{$template}{baseitem}}{droidorhuman}\n";
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {
                    $humanarmor .= " $template";
                }
                elsif($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidarmor .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00008")
            {
                $humangloves .= " $template";
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00010")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{weapontype} == 1)
                {
                    $weaponsmelee .= " $template";
                }
                else
                {
                    $weaponsranged .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00030")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{weapontype} == 1)
                {
                    $weaponsmelee .= " $template";
                }
                else
                {
                    $weaponsranged .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00180")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {
                    $humanarms .= " $template";
                }
                elsif($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidarms .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00200")
            {
                $humanimplants .= " $template";
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00208")
            {
                $droidimplants .= " $template";
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00400")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {
                    $humanbelts .= " $template";
                }
                elsif($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidbelts .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x20400")
            {
                $humanbelts .= " $template";
            }
        }

        #now get all uti files from override (overriding any templates.bif uti)
        chdir "$registered_path\\override";
        my @utifiles_in_override=glob "*.uti";
        for my $override_uti (@utifiles_in_override) {
            $tmp_gff->read_gff_file($override_uti);

            my $locname=$tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('LocalizedName')]{Value};
            my $strref=$locname->{StringRef};
            my $template=$tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('TemplateResRef')]{Value};
            $template=~/(\w+)/;
            $template=$1;
            my $tag=lc $tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('Tag')]{Value};
            $tag=~/(\w+)/;
            $tag=$1;
            $master_item_list{$template}{'tag'}=$tag;
            $master_item_list{$template}{baseitem}=$tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('BaseItem')]{Value};
            if (defined (my $tmpix=$tmp_gff->{Main}->get_field_ix_by_label('ModelVariation'))) {
                $master_item_list{$template}{modelvar}=$tmp_gff->{Main}{Fields}[$tmpix]{Value};
            }
            else {
                $master_item_list{$template}{modelvar}=$tmp_gff->{Main}{Fields}[$tmp_gff->{Main}->get_field_ix_by_label('TextureVar')]{Value};
            }
            if ($strref == -1) {
                $master_item_list{$template}{'desc'}=$locname->{Substrings}[0]{Value};
            } else {
                $master_item_list{$template}{'desc'}=Bioware::TLK::string_from_resref($registered_path,$strref);
            }
            $master_item_list{$template}{'override'}=1;

            if($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00001")
            {
                #print "DoH: $hashref->{$master_item_list{$template}{baseitem}}{droidorhuman}\n";
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {#print "k: $template\n";
                    $humanheads .= " $template";
                }
                elsif($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidheads .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00002")
            {
                #print "DoH: $hashref->{$master_item_list{$template}{baseitem}}{droidorhuman}\n";
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {
                    $humanarmor .= " $template";
                }
                elsif($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidarmor .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00008")
            {
                $humangloves .= " $template";
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00010")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{weapontype} == 1)
                {
                    $weaponsmelee .= " $template";
                }
                else
                {
                    $weaponsranged .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00030")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{weapontype} == 1)
                {
                    $weaponsmelee .= " $template";
                }
                else
                {
                    $weaponsranged .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00180")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {
                    $humanarms .= " $template";
                }
                elsif($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidarms .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00200")
            {
                $humanimplants .= " $template";
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00208")
            {
                $droidimplants .= " $template";
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x00400")
            {
                if($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 1)
                {
                    $humanbelts .= " $template";
                }
                elsif($hashref->{$master_item_list{$template}{baseitem}}{droidorhuman} == 2)
                {
                    $droidbelts .= " $template";
                }
            }
            elsif($hashref->{$master_item_list{$template}{baseitem}}{equipableslots} eq "0x20400")
            {
                $humanbelts .= " $template";
            }
        }

        if ($gameversion==1) {
            %master_item_list1=%master_item_list;
        }
        elsif ($gameversion==2) {
            %master_item_list2=%master_item_list;
        }
        elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
            %master_item_list2=%master_item_list;
        }
        elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
            %master_item_list3=%master_item_list;
        }
        elsif ($gameversion==4) {
            %master_item_list3=%master_item_list;
        }
        $items{$real_game}=1;

        $equiptables{$gameversion}{human}{heads}    = $humanheads;
        $equiptables{$gameversion}{human}{implants} = $humanimplants;
        $equiptables{$gameversion}{human}{arms}     = $humanarms;
        $equiptables{$gameversion}{human}{armors}   = $humanarmor;
        $equiptables{$gameversion}{human}{gloves}   = $humangloves;
        $equiptables{$gameversion}{human}{belts}    = $humanbelts;

        $equiptables{$gameversion}{droid}{heads}    = $droidheads;
        $equiptables{$gameversion}{droid}{implants} = $droidimplants;
        $equiptables{$gameversion}{droid}{arms}     = $droidarms;
        $equiptables{$gameversion}{droid}{armors}   = $droidarmor;
        $equiptables{$gameversion}{droid}{belts}    = $droidbelts;

        $equiptables{$gameversion}{weapons}{melee} = $weaponsmelee;
        $equiptables{$gameversion}{weapons}{range} = $weaponsranged;

    }
    $mw->Unbusy;
}


# custom error handler --> error log, and error msg
sub Tk::Error {
    my $w = shift;
    my $error = shift;
    if (Exists($w)) {
        my $grab = $w->grab('current');
        $grab->Unbusy if (defined $grab);
    }
    chomp($error);
    $mw->Dialog(-title=>'Error occurred',-text=>"Error msg: $error\n ",-font=>['MS Sans Serif','8'],-buttons=>['Ok'])->Show();
    $mw->Dialog(-title=>'Details of Error ',-text=> join("\n " , @_)."\n",-font=>['MS Sans Serif','8'],-buttons=>['Ok'])->Show();
    LogError("Tk::Error: $error\n " . join("\n ",@_));
}
sub RWhat {
    my $w=shift;
    my $ev = $w->XEvent();
    $tree->Button1($ev); # make sure to select the item
    $tree->ButtonRelease1($ev); # make sure to select the item
    my $treeitem=($tree->info('selection'))[0]; #get the item name selected

    # a little handwaving here to allow the user to right click on
    # either the treeroot or Inventory leaf and get same effect
    my $treeroot=$treeitem;
    if ($treeitem =~ /Inventory$/) {
        $treeroot = '#'.(split /#/,$treeitem)[1]; #.'#'.(split /#/,$treeitem)[2];
    }

    our $game;
    $_ = $treeitem;

    s/#//;

    our $root = $1;

    if ($treeitem eq '#1') {
        change_registered_path(1);
        $game = "KotOR";
    }
    elsif ($treeitem eq '#2') {
        change_registered_path(2);
        $game = "TSL";
    }
    elsif ($treeitem eq '#3' && $kseInitializer->{use_tsl_cloud} == 1) {
        change_registered_path(2);
        $game = "TSL";
    }
    elsif ($treeitem eq '#3' && $kseInitializer->{use_tsl_cloud} == 0) {
        change_registered_path(3);
        $game = "TJM";
    }
    elsif ($treeitem eq '#4') {
        change_registered_path(3);
        $game = "TJM";
    }

    #check to make sure the root has been selected and already contains
    #the inventory gff (that is, Populate_Level1 has been called)

    my $datahash=$tree->entrycget($treeroot,-data);
    return unless (ref ($datahash) eq 'HASH');
    return unless (exists $$datahash{'GFF-inv'} || exists $$datahash{'GFF-res'});

    #create Inventory Popup Menu
    my $inventoryMenu = $mw->Menu(
      -tearoff  => 0);

    # Note: for some reason, the -command parameter of these menu buttons
    # has to be in the form of sub { function } rather than \&function
    # otherwise the function will be called immediately upon insert method... :-s

    $inventoryMenu->insert(0,
      'command',
      -label=>'Reload This Savegame',
      -command=>sub { Reload($treeroot)},
      -state=>'normal');
    $inventoryMenu->insert(1,
      'command',
      -label=>'Copy Inventory From This Savegame',
      -command=>sub { CopyInventory($treeitem,$datahash) },
      -state=>'normal');
    $inventoryMenu->insert(2,
      'command',
      -label=>'Paste Inventory Into This Savegame',
      -command=>sub { PasteInventory($treeroot,$datahash) },
      -state=>'disabled');
    #    $inventoryMenu->insert(3,
    #                           'command',
    #                           -label=>'Copy Globals From This Savegame',
    #                           -command=>sub { CopyGlobals($treeitem, $datahash) },
    #                           -state=>'normal');
    #    $inventoryMenu->insert(4,
    #                           'command',
    #                           -label=>'Paste Globals Into This Savegame',
    #                           -command=>sub { PasteGlobals($treeroot, $datahash) },
    #                           -state=>'disabled');

    if ($inventory_in_memory==1) {
        $inventoryMenu->entryconfigure(2,-state=>'normal');
    }
    #    if ($globals_in_memory==1) {
    #        $inventoryMenu->entryconfigure(4,-state=>'normal');
    #    }
    #show popup at cursor
    $inventoryMenu->Popup(
      -popover  => 'cursor',
      -popanchor => 'nw');

}


# Generic functions
sub GetRegisteredPath {
    my $gameversion = shift;

    my $registered_path;

    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }

    return $registered_path
}
sub GetRegisteredSavePath {
    my $gameversion = shift;

    my $registered_path;

    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor_save};
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl_save};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl_cloud};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm}."\\saves";
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm}."\\saves";
    }

    return $registered_path
}
sub LoadData {
    LogInfo "Loading save data...";

    my $treeitem=shift;
    my $root='#'.(split /#/,$treeitem)[1].'#'.(split /#/,$treeitem)[2];
    my $gameversion=(split /#/,$treeitem)[1];# print "\$gameversion is: $gameversion\n";
    my $gamedir=(split /#/,$treeitem)[2]; #print "\$gamedir is: $gamedir\n";
    my $registered_path;

    my %genders;
    my %appearance_hash;
    my %portraits_hash;
    my %soundset_hash;
    my %standard_npcs;

    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor_save};
        %genders=%gender_hash1;
        %appearance_hash=%appearance_hash1;
        %portraits_hash=%portraits_hash1;
        %soundset_hash=%soundset_hash1;
        %standard_npcs=%standard_kotor_npcs;
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl_save};
        %genders=%gender_hash2;
        %appearance_hash=%appearance_hash2;
        %portraits_hash=%portraits_hash2;
        %soundset_hash=%soundset_hash2;
        %standard_npcs=%standard_tsl_npcs;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
        %genders=%gender_hash3;
        %appearance_hash=%appearance_hash3;
        %portraits_hash=%portraits_hash3;
        %soundset_hash=%soundset_hash3;
        %standard_npcs=%tjm_npcs;
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl_cloud};
        %genders=%gender_hash2;
        %appearance_hash=%appearance_hash2;
        %portraits_hash=%portraits_hash2;
        %soundset_hash=%soundset_hash2;
        %standard_npcs=%standard_tsl_npcs;
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm} . "/saves";
        %genders=%gender_hash3;
        %appearance_hash=%appearance_hash3;
        %portraits_hash=%portraits_hash3;
        %soundset_hash=%soundset_hash3;
        %standard_npcs=%tjm_npcs;
    }

    my $res_gff=Bioware::GFF->new();
    unless (my $tmp=$res_gff->read_gff_file("$registered_path\\$gamedir\\savenfo.res")) {
        die ("Could not read $registered_path\\$gamedir\\savenfo.res");
    }

    my $lastModuleName=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('LASTMODULE')]{Value};
    if ($lastModuleName eq ""){
        die ("Could not fetch last module name in ".$res_gff->{Main}{Fields});
    }

    my $pty_gff=Bioware::GFF->new();
    unless (my $tmp=$pty_gff->read_gff_file("$registered_path\\$gamedir\\partytable.res")) {
        die ("Could not read $registered_path\\$gamedir\\partytable.res");
    }

    #read the SAVEGAME.SAV file

    my $erf=Bioware::ERF->new();                                            		        #create ERF for savegame.sav
    #read savegame.sav structure
    unless (my $tmp=$erf->read_erf("$registered_path\\$gamedir\\savegame.sav")) {
        die "Could not read $registered_path\\$gamedir\\savegame.sav";
    }
    my $tmpfil_inv;
    unless ($tmpfil_inv=$erf->export_resource_to_temp_file("INVENTORY.res")) {                  #export inventory.res as a temp file
        die "Could not find INVENTORY.res inside of $registered_path\\$gamedir\\savegame.sav";
    }
    my $gff_inv=Bioware::GFF->new();                                                            #create GFF for inventory.res
    unless (my $tmp=$gff_inv->read_gff_file($tmpfil_inv->{'fn'})) {                             #read invenotry.res into GFF
        die "Could not read from temp file containing INVENTORY.res";
    }
    my $tmpFileLastModSav;
    unless ($tmpFileLastModSav=$erf->export_resource_to_temp_file("$lastModuleName.sav")) {               #export the last module as a temp file
        die "Could not find $lastModuleName.sav inside of $registered_path\\$gamedir\\savegame.sav";
    }

    # DEV
    for my $resource (@{$erf->{'resources'}}) {
        my $res_check = lc "$resource->{'res_ref'}.$resource->{'res_ext'}";
        LogDebug "RESOURCE: $res_check";
    }


    my $erfLastModSav=Bioware::ERF->new();                                                               #create ERF for last module
    unless (my $tmp=$erfLastModSav->read_erf($tmpFileLastModSav->{'fn'})) {                                     #read last module structure
        die "Could not read from temp file containing $lastModuleName.sav";
    }
    $erfLastModSav->{'tmpfil'}=$tmpFileLastModSav;                                                              #tuck the temp file into the erf for safekeeping
    $erfLastModSav->{'modulename'}="$lastModuleName";                                                   #tuck the module name into the erf for safekeeping

    my $tmpfil_LastModIfo;
    unless($tmpfil_LastModIfo=$erfLastModSav->export_resource_to_temp_file("module.ifo")) {                     #export the module.ifo file as a temp file
        die "Could not find module.ifo inside of $lastModuleName.sav";
    }
    my $gff_LastModIfo=Bioware::GFF->new();                                                            #create GFF for module.ifo
    unless (my $tmp=$gff_LastModIfo->read_gff_file($tmpfil_LastModIfo->{'fn'})) {                             #read module.ifo into GFF
        die "Could not read from temp file containing module.ifo";
    }

    # Looking for last module .git file where the inventory of all placeable is stored
    my $lastModuleGitName;
    for my $resource (@{$erfLastModSav->{'resources'}}) {
        if($resource->{'res_ext'} eq "git") {
            $lastModuleGitName = lc $resource->{'res_ref'};
        }
    }

    # Extracting the .git file as a temp file
    my $tmpfil_git;
    unless($tmpfil_git=$erfLastModSav->export_resource_to_temp_file("$lastModuleGitName.git")) {
        die "Could not find $lastModuleGitName.git inside of $lastModuleName.sav";
    }

    # Parsing the .git temp file
    my $gff_LastModGit=Bioware::GFF->new();                                                            #create GFF for module.ifo
    unless (my $tmp=$gff_LastModGit->read_gff_file($tmpfil_git->{'fn'})) {                             #read module.ifo into GFF
        die "Could not read from .git temp file";
    }
    $gff_LastModGit->{'modulename'}="$lastModuleGitName";

    $tree->entryconfigure(
      $root,
      -data=>{
        'ERF-sav'=>$erf,
        'ERF-mod'=>$erfLastModSav,
        'GFF-pty'=>$pty_gff,
        'GFF-res'=>$res_gff,
        'GFF-ifo'=>$gff_LastModIfo,
        'GFF-git'=>$gff_LastModGit,
        'GFF-inv'=>$gff_inv
      }
    );
    LogInfo "Data loaded.";
}
sub PrintScreenshot {

    my $treeitem=shift;
    my $root='#'.(split /#/,$treeitem)[1].'#'.(split /#/,$treeitem)[2];
    my $gameversion=(split /#/,$treeitem)[1];# print "\$gameversion is: $gameversion\n";
    my $gamedir=(split /#/,$treeitem)[2]; #print "\$gamedir is: $gamedir\n";

    my $registered_path = GetRegisteredSavePath($gameversion);

    my $screenFilePath = "$registered_path\\$gamedir\\Screen.tga";
    unless( -e $screenFilePath ){ $screenFilePath = "$registered_path\\$gamedir\\screen.tga"; }

    if( -e $screenFilePath ) {

        my $img=Imager->new();
        $img->read( file=>$screenFilePath, type=>'tga' ) or die $img->errstr;
        my $buf;
        my $ftyp='bmp'; #IMAGE FORMAT
        $img->write(data=>\$buf,type=>$ftyp) or die $img->errstr; ;
        $picture_label_photo=$mw->Photo(-data=>encode_base64($buf),-format=>$ftyp);
        $picture_label=$mw->Label(
          -image=>$picture_label_photo
        )->pack(-side=>'top',-anchor=>'ne');

    }

}

sub CopyInventory {
    my ($treeitem_source,$datahash)=@_;

    #for later readability in dialog box...
    my $treeitem_desc=(split /#/,$treeitem_source)[2];
    my $res_gff=$datahash->{'GFF-res'};
    $inventory_source_savegame_name=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('SAVEGAMENAME')]{Value};

    #memorize inventory...
    $inventory_memorized=$datahash->{'GFF-inv'};


    #remove temp indicator from any earlier DItem
    if ($inventory_in_memory==1) {

        #earlier copy was in effect...
        my $current_tix_image_of_old_source_item=$tree->indicator('cget',$inventory_source_treeitem,'image');

        if ($current_tix_image_of_old_source_item eq 'image5') {

            #and we still have the old indicator in effect, so change it back
            my $oldimage;
            if ($old_tix_image eq 'image1') {
                $tree->close($inventory_source_treeitem);
            } elsif ($old_tix_image eq 'image2') {
                $tree->open($inventory_source_treeitem);
            }
            $tree->autosetmode();
        }
    }

    #remember the current indicator of DItem
    $old_tix_image=$tree->indicator('cget',$treeitem_source,'image');

    #set new temp indicator to DItem
    my $newimage=$mw->Getimage('srcfile');
    $tree->indicator('configure',$treeitem_source,'image',$newimage);

    #make note of the changes
    $inventory_in_memory=1;
    $inventory_source_treeitem=$treeitem_source;

    #tell user we're done
    my $ok=$mw->Dialog(-title=>'Inventory Copied to Memory',
      -text=>"Inventory from $treeitem_desc\n '$inventory_source_savegame_name'\n has been copied into memory.",
      -font=>['MS Sans Serif','8'],
      -buttons=>['Ok'])->Show();
}
sub PasteInventory {
    my ($treeitem_destination,$datahash)=@_;

    my $treeitem_desc=(split /#/,$treeitem_destination)[2];
    my $treeitem_src_desc=(split /#/,$inventory_source_treeitem)[2];
    my $res_gff=$datahash->{'GFF-res'};
    my $inventory_destination_savegame_name=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('SAVEGAMENAME')]{Value};

    my $confirm=$mw->Dialog(-title=>'Confirm Inventory Paste',
      -text=>"Are you sure you wish to Paste the Inventory from\n$treeitem_src_desc  '$inventory_source_savegame_name'\nto\n$treeitem_desc  '$inventory_destination_savegame_name'?",
      -font=>['MS Sans Serif','8'],
      -buttons=>['Yes','No'])->Show();
    if ($confirm eq 'Yes') {
        $datahash->{'GFF-inv'}=$inventory_memorized;
        $tree->entryconfigure($treeitem_destination,-data=>$datahash);
        CommitChanges($treeitem_destination);
        $tree->delete('offsprings',$treeitem_destination."#Inventory");
        $tree->add($treeitem_destination."#Inventory#");
        $tree->hide('entry',$treeitem_destination."#Inventory#");
        $tree->autosetmode();
    }
}
sub change_registered_path {
    my $which_game=shift;
    my $gamename;
    if ($which_game==1) { $gamename='Knights of the Old Republic' }
    if ($which_game==2) { $gamename='The Sith Lords' }
    if ($which_game==3) { $gamename='The Jedi Masters' }

    #create confirmation popup
    my $change_path_confirm_menu = $mw->Menu(
      -tearoff  => 0);

    $change_path_confirm_menu->insert(0,
      'command',
      -label=>'Change Path for '.$gamename,
      -accelerator=>'Ctrl+P',
      -command=>sub {
          my $browsed_path=BrowseForFolder('Locate '.$gamename.' installation directory');
          if ($browsed_path) {
              if ($which_game==1) {
                  $oldpath{kotor}=$kseInitializer->{path}->{kotor};
                  $kseInitializer->{path}->{kotor}=$browsed_path;

                  %master_item_list1 = ();
                  $items{1} = 0;
                  $open{1} = 0;

                  $kseInitializer->{k1_installed}=1;
                  my $k1_bif = Bioware::BIF->new($kseInitializer->{path}->{kotor});
              }
              elsif ($which_game==2) {
                  $oldpath{tsl}=$kseInitializer->{path}->{tsl};
                  $oldpath{tsl_save}=$kseInitializer->{path}->{tsl_save};
                  $oldpath{tsl_cloud}=$kseInitializer->{path}->{tsl_cloud};
                  $kseInitializer->{path}->{tsl}=$browsed_path;

                  # Check if cloudsaves dir can be located
                  if(-e $kseInitializer->{path}->{tsl}."/cloudsaves")
                  {
                      $kseInitializer->{use_tsl_cloud} = 1;
                      opendir(CLOUDSAVEDIR, $kseInitializer->{path}->{'tsl'} . "/cloudsaves");
                      $kseInitializer->{path}->{'tsl_cloud'} = (grep { !(/\.+$/) && -d } map {"$kseInitializer->{path}->{tsl}/cloudsaves/$_"} readdir(CLOUDSAVEDIR))[0];
                      closedir(CLOUDSAVEDIR); # Release handle
                  }

                  %master_item_list2 = ();
                  $items{2} = 0;
                  $open{2} = 0;

                  $kseInitializer->{k2_installed}=1;
                  my $k2_bif = Bioware::BIF->new($kseInitializer->{path}->{tsl});
              }
              elsif ($which_game==3 && $kseInitializer->{use_tsl_cloud} == 0) {
                  $oldpath{tjm}=$kseInitializer->{path}->{tjm};
                  $kseInitializer->{path}->{tjm}=$browsed_path;

                  %master_item_list3 = ();
                  $items{3} = 0;
                  $open{3} = 0;

                  $kseInitializer->{tjm_installed}=1;
                  my $k3_bif = Bioware::BIF->new($kseInitializer->{path}->{tjm});
              }
              elsif ($which_game==4) {
                  $oldpath{tjm}=$kseInitializer->{path}->{tjm};
                  $kseInitializer->{path}->{tjm}=$browsed_path;

                  %master_item_list3 = ();
                  $items{3} = 0;
                  $open{3} = 0;

                  $kseInitializer->{tjm_installed}=1;
                  my $k3_bif = Bioware::BIF->new($kseInitializer->{path}->{tjm});
              }
              $tree->delete('offspring', "#" . $which_game);
              Load($which_game);
              $tree->autosetmode();
              $tree->close("#" . $which_game);
              Populate_Data($which_game);

          }
      },
      -state=>'normal');
    $change_path_confirm_menu->insert(1,
      'command',
      -label=>"Reload All Savegames For $gamename",
      -command=>sub { ReloadAll($which_game)},
      -state=>'normal');
    $change_path_confirm_menu->insert(2,
      'command',
      -label=>'Cancel',
      -command=>sub {  },
      -state=>'normal');
    #show popup at cursor
    $change_path_confirm_menu->Popup(
      -popover  => 'cursor',
      -popanchor => 'nw');
}
sub read_global_jrls {
    if ($kseInitializer->{k1_installed}) {
        $journal1=Bioware::GFF->new();
        if (-e $kseInitializer->{path}->{kotor}."/override/global.jrl") {
            LogInfo("KotOR global.jrl override detected");
            $journal1->read_gff_file($kseInitializer->{path}->{kotor}."/override/global.jrl");
        }
        else {
            my $k1_bif=Bioware::BIF->new($kseInitializer->{path}->{kotor},24,'jrl');
            if (!defined($k1_bif)) {$k1_bif=try_extracted_data(1,24,'jrl')}
            my $tempjrlfile=$k1_bif->get_resource('data\\_newbif.bif','global.jrl');
            $journal1->read_gff_scalar($tempjrlfile);
        }
    }
    if ($kseInitializer->{k2_installed}) {
        $journal2=Bioware::GFF->new();
        if (-e $kseInitializer->{path}->{tsl}."/override/global.jrl") {
            LogInfo("TSL global.jrl override detected");
            $journal2->read_gff_file($kseInitializer->{path}->{tsl}."/override/global.jrl");
        }
        else {
            my $k2_bif=Bioware::BIF->new($kseInitializer->{path}->{tsl},1,'jrl');
            if (!defined($k2_bif)){
                $journal2->read_gff_file(try_extracted_data(undef,'Get Journal',undef));
            }
            else
            {
                my $tempjrlfile=$k2_bif->get_resource('data\\dialogs.bif','global.jrl');
                $journal2->read_gff_scalar($tempjrlfile);
            }

        }
    }
    if ($kseInitializer->{tjm_installed}) {
        $journal3=Bioware::GFF->new();
        if (-e $kseInitializer->{path}->{tjm}."/override/global.jrl") {
            LogInfo("TJM global.jrl override detected");
            $journal3->read_gff_file($kseInitializer->{path}->{tjm}."/override/global.jrl");
        }
        else {
            my $tjm_bif=Bioware::BIF->new($kseInitializer->{path}->{tjm},1,'jrl');
            if (!defined($tjm_bif)){
                $journal3->read_gff_file(try_extracted_data(undef,'Get Journal',undef));
            }
            else
            {
                my $tempjrlfile=$tjm_bif->get_resource('data\\dialogs.bif','global.jrl');
                $journal3->read_gff_scalar($tempjrlfile);
            }
        }
    }
}
sub Populate_Journal {
    #Populate_Level1 has already been called
    #and so has read_global_jrls

    my $treeitem=shift;
    my $gv;
    my $gm;

    my @parms = split /#/, $treeitem;
    #	print join /\n/, @parms;

    if ($parms[1] == 1) { $gv = "Kotor 1"; }
    if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 2/TSL Cloud"; }
    if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 3/TJM"; }
    if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }

    my $ent = $parms[2];
    my $su = $_;
    $_ = $ent;
    /(.......-.)/;
    $gm = $ent;
    $gm =~ s#$1##;

    $_ = $su;
    LogInfo ("Populating Journal for $gv->$gm");
    my $gameversion=(split /#/,$treeitem)[1];
    my $gamedir=(split /#/,$treeitem)[2];
    #    $tree->add("$treeitem#Journal",-text=>'Journal Entries');
    my $registered_path;
    if ($gameversion==1) {
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    my $root='#'.$gameversion.'#'.$gamedir;
    my $datahash;
    $datahash=$tree->entrycget($root,-data);

    #get the savegame info about journals
    my $pty_gff=$datahash->{'GFF-pty'};
    my $jrl_entries_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value};
    my $jrl_categories_arr_ref;
    if ($gameversion==1) {
        $jrl_categories_arr_ref=$journal1->{Main}{Fields}{Value};
    }
    elsif ($gameversion==2) {
        $jrl_categories_arr_ref=$journal2->{Main}{Fields}{Value};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $jrl_categories_arr_ref=$journal2->{Main}{Fields}{Value};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $jrl_categories_arr_ref=$journal3->{Main}{Fields}{Value};
    }
    elsif ($gameversion==4) {
        $jrl_categories_arr_ref=$journal3->{Main}{Fields}{Value};
    }
    $tree->add("$treeitem#Journal",-text=>'Quests',-data=>'can modify');
    #now loop through each journal category
    for my $jrl_entry (@$jrl_entries_arr_ref) {
        my $this_plot_id=lc($jrl_entry->{Fields}[$jrl_entry->fbl('JNL_PlotID')]{Value});
        my $this_state=$jrl_entry->{Fields}[$jrl_entry->fbl('JNL_State')]{Value};
        #and compare it the global.jrl, synching up using Tag value
        my $ix=0;
        for my $jrl_category (@$jrl_categories_arr_ref) {
            my $tag=lc($jrl_category->{Fields}[$jrl_category->fbl('Tag')]{Value});
            if ($tag eq $this_plot_id) {
                #get the name from the global journal when synch occurs
                my $this_name;
                my $this_name_strref=$jrl_category->{Fields}[$jrl_category->fbl('Name')]{Value}{StringRef};
                if ($this_name_strref==-1) {
                    $this_name=$jrl_category->{Fields}[$jrl_category->fbl('Name')]{Value}{Substrings}[0]{Value};
                } else {
                    $this_name=Bioware::TLK::string_from_resref($registered_path,$this_name_strref);
                }
                #$tree->add($treeitem."#Journal#".$this_plot_id,-text=>"$this_name: $this_plot_id");
                #now seek out where in this journal category the player has reached, synching on plot_id
                my $jrl_entries_arr_ref=$jrl_category->{Fields}[$jrl_category->fbl('EntryList')]{Value};
                for my $jrl_entry (@$jrl_entries_arr_ref) {
                    my $jrl_id=$jrl_entry->{Fields}[$jrl_entry->fbl('ID')]{Value};
                    if ($jrl_id == $this_state) {
                        #get the text associated with this journal's plot id
                        my $this_text;
                        my $this_text_strref=$jrl_entry->{Fields}[$jrl_entry->fbl('Text')]{Value}{StringRef};
                        if ($this_text_strref==-1) {
                            $this_text=$jrl_entry->{Fields}[$jrl_entry->fbl('Text')]{Value}{'Substrings'}[0]{Value};
                        } else {
                            $this_text=Bioware::TLK::string_from_resref($registered_path,$this_text_strref);
                        }
                        #add to tree
                        $tree->add($treeitem."#Journal#".$this_plot_id,-text=>"$this_name",-data=>'jrl##'.$this_state.'##'.$this_text);
                        $tree->hide('entry',$treeitem."#Journal#".$this_plot_id);
                        last; #1
                    }
                } #the last (1) jumps to here
                last; #2
            }
            $ix++;
        } #the last (2) jumps to here

    }
    $tree->autosetmode();
}
sub SpawnJRLWidgets() {
    use Tk::ROText;
    use Tk::BrowseEntry;
    my $treeitem=shift;   # the treeitem will end in #Journal#(tag) and the -data will be a scalar: jrl##(state)##(text)
    my $gameversion=(split /#/,$treeitem)[1];
    my $gamedir=(split /#/,$treeitem)[2];
    my $jrltag=lc((split /#/,$treeitem)[-1]);
    my $jrldata=$tree->entrycget($treeitem,-data);
    my (undef,$jrl_state,$jrl_text)=(split /##/,$jrldata);
    my $jrlname=$tree->entrycget($treeitem,-text);
    my $jrl_categories_arr_ref;
    my $registered_path;

    for my $widge (@spawned_widgets,$picture_label) {   #unspawn old widgets
        $widge->destroy if Tk::Exists($widge);    }
    @spawned_widgets=();
    eval {$picture_label_photo->delete};

    if ($gameversion==1) {
        $jrl_categories_arr_ref=$journal1->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        $jrl_categories_arr_ref=$journal2->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $jrl_categories_arr_ref=$journal2->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $jrl_categories_arr_ref=$journal3->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        $jrl_categories_arr_ref=$journal3->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    my $be_selection;
    LogInfo ("Jrltag: $jrltag  JrlName: $jrlname  JrlState: $jrl_state JrlText: $jrl_text");

    my $twidg=$mw->ROText(-wrap=>'word',-background=>'white',-width=>30,-height=>12);
    my ($lblbe,$lblcur,$be);
    for my $jrl_category (@$jrl_categories_arr_ref) {                       #let's search through global.jrl
        my $tag=lc($jrl_category->{Fields}[$jrl_category->fbl('Tag')]{Value});  #we're looking for this treeitem's tag
        if ($tag eq $jrltag) {                                           #okay we've found it, so let's get the entries for it
            my $jrl_entries_arr_ref=$jrl_category->{Fields}[$jrl_category->fbl('EntryList')]{Value};
            #need to create a browseentry widget and populate it with choices.
            $lblbe=$mw->Label(-text=>'Quest "'.$jrlname.'"')->place(-relx=>650/$x,-rely=>140/$y,-anchor=>'sw');
            $lblcur=$mw->Label(-text=>"Currently: $jrl_state")->place(-relx=>650/$x,-rely=>170/$y,-anchor=>'sw');
            push @spawned_widgets,($lblbe, $lblcur);
            my %be_entries;

            $be=$mw->BrowseEntry(-variable=>\$be_selection,-state=>'readonly', -fg=>'black', -bg=>'white', -browsecmd=>sub{
                $twidg->delete('1.0','end');
                $be_selection=~/^(\d+)/;
                my $id=$1;
                $twidg->insert('end',$be_entries{$id}{longtext});
                my $root='#'.$gameversion.'#'.$gamedir;
                my $datahash;
                $datahash=$tree->entrycget($root,-data);
                #get the savegame journal stuff
                my $pty_gff=$datahash->{'GFF-pty'};
                my $jrl_entries_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value};
                $be_selection =~ /^(\d+)/;
                my $new_state=$1;
                my $ix=0;
                for my $jrl_entry_struct (@$jrl_entries_arr_ref) {
                    if (lc($jrl_entry_struct->{Fields}[$jrl_entry_struct->fbl('JNL_PlotID')]{Value}) eq $jrltag) {
                        $jrl_entry_struct->{Fields}[$jrl_entry_struct->fbl('JNL_State')]{Value}=$new_state;
                        $lblcur->configure(-text=>"Currently: $new_state");
                        $tree->entryconfigure($treeitem, -data=>'jrl##'.$new_state.'##'.$twidg->get('1.0','end'));
                        $datahash->{'GFF-pty'}=$pty_gff;
                        LogInfo("Changed Quest #".$ix." ($jrltag) JNL_State $jrl_state to $new_state");
                        last;
                    }
                    $ix++;
                }

            });


            for my $jrl_entry (@$jrl_entries_arr_ref) {                     #now let's look through the entries and translate the text
                my $this_jrl_id=$jrl_entry->{Fields}[$jrl_entry->fbl('ID')]{Value};
                my $this_jrl_text_strref=$jrl_entry->{Fields}[$jrl_entry->fbl('Text')]{Value}{StringRef};
                my $this_jrl_text;
                if ($this_jrl_text_strref==-1) {
                    $this_jrl_text=$jrl_entry->{Fields}[$jrl_entry->fbl('Text')]{Value}{'Substrings'}[0]{Value};
                } else {
                    $this_jrl_text=Bioware::TLK::string_from_resref($registered_path,$this_jrl_text_strref);
                }
                $be_entries{$this_jrl_id}{shorttext}="$this_jrl_id) $this_jrl_text";
                $be_entries{$this_jrl_id}{longtext}="$this_jrl_id) $this_jrl_text";
                if (length $this_jrl_text > 30) {
                    $be_entries{$this_jrl_id}{shorttext}="$this_jrl_id) ".substr($this_jrl_text,0,27)."...";
                }


            }
            map  {$be->insert('end', $be_entries{$_}{shorttext})} sort (keys %be_entries);
            $be_selection =$be_entries{$jrl_state}{shorttext};
            $twidg->insert('end',$be_entries{$jrl_state}{longtext});
            $be->place(-relx=>620/$x,-rely=>240/$y,-anchor=>'sw');
            $twidg->place(-relx=>620/$x,-rely=>240/$y,-anchor=>'nw');
            push @spawned_widgets,($be,$twidg);
            last;
        }
    }
    my $btn1=$mw->Button (-text=>'Apply',-command=>sub {
        my $root='#'.$gameversion.'#'.$gamedir;
        my $datahash;
        $datahash=$tree->entrycget($root,-data);
        #get the savegame journal stuff
        my $pty_gff=$datahash->{'GFF-pty'};
        my $jrl_entries_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value};
        $be_selection =~ /^(\d+)/;
        my $new_state=$1;
        my $ix=0;
        for my $jrl_entry_struct (@$jrl_entries_arr_ref) {
            if (lc($jrl_entry_struct->{Fields}[$jrl_entry_struct->fbl('JNL_PlotID')]{Value}) eq $jrltag) {
                $jrl_entry_struct->{Fields}[$jrl_entry_struct->fbl('JNL_State')]{Value}=$new_state;
                $lblcur->configure(-text=>"Currently: $new_state");
                $tree->entryconfigure($treeitem, -data=>'jrl##'.$new_state.'##'.$twidg->get('1.0','end'));
                $datahash->{'GFF-pty'}=$pty_gff;
                LogInfo("Changed Quest #".$ix." ($jrltag) JNL_State $jrl_state to $new_state");
                last;
            }
            $ix++;
        }


    })->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>90/$x);
    my $btn2;
    $btn2=$mw->Button (-text=>'Remove Quest',-command=>sub {
        my $root='#'.$gameversion.'#'.$gamedir;
        my $datahash;
        $datahash=$tree->entrycget($root,-data);
        #get the savegame journal stuff
        my $pty_gff=$datahash->{'GFF-pty'};
        my $jrl_entries_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value};
        my @new_entries;
        for my $jrl_entry_struct (@$jrl_entries_arr_ref) {
            unless (lc($jrl_entry_struct->{Fields}[$jrl_entry_struct->fbl('JNL_PlotID')]{Value}) eq $jrltag) {
                push @new_entries, $jrl_entry_struct;
            }
        }
        $pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value}=[@new_entries];
        $datahash->{'GFF-pty'}=$pty_gff;
        LogInfo("Removed Quest $jrltag");
        $tree->delete('entry',$treeitem);
        for my $w ($lblbe,$lblcur,$be,$btn1,$btn2,$twidg) {$w->placeForget; $w->destroy if Tk::Exists($w)}
    })->place(-relx=>698/$x,-rely=>520/$y,-relwidth=>90/$x);

    my $btn3=$mw->Button (-text=>'Commit Changes',-command=>sub {
        CommitChanges($treeitem)
    })->place(-relx=>796/$x,-rely=>520/$y,-relwidth=>90/$x);
    push @spawned_widgets,($btn1,$btn2,$btn3);
}
sub SpawnAddJRLWidgets {
    my $treeitem=shift;   # the treeitem will end in #Journal
    my $gameversion=(split /#/,$treeitem)[1];
    my $gamedir=(split /#/,$treeitem)[2];
    my $registered_path;
    my $jrl_categories_arr_ref;

    for my $widge (@spawned_widgets,$picture_label) {   #unspawn old widgets
        $widge->destroy if Tk::Exists($widge);    }
    @spawned_widgets=();
    eval {$picture_label_photo->delete};

    if ($gameversion==1) {
        $jrl_categories_arr_ref=$journal1->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{kotor};
    }
    elsif ($gameversion==2) {
        $jrl_categories_arr_ref=$journal2->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 1) {
        $jrl_categories_arr_ref=$journal2->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tsl};
    }
    elsif ($gameversion==3 && $kseInitializer->{use_tsl_cloud} == 0) {
        $jrl_categories_arr_ref=$journal3->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tjm};
    }
    elsif ($gameversion==4) {
        $jrl_categories_arr_ref=$journal3->{Main}{Fields}{Value};
        $registered_path=$kseInitializer->{path}->{tjm};
    }


    my $root='#'.$gameversion.'#'.$gamedir;
    my $datahash;
    $datahash=$tree->entrycget($root,-data);
    #get the savegame journal stuff

    my $pty_gff=$datahash->{'GFF-pty'};
    my $jrl_entries_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value};
    my $last_jnl_entry=$$jrl_entries_arr_ref[-1];
    my $last_jnl_date;
    my $last_jnl_time;
    if ($last_jnl_entry) {
        $last_jnl_date=$last_jnl_entry->{Fields}[$last_jnl_entry->fbl('JNL_Date')]{Value};
        $last_jnl_time=$last_jnl_entry->{Fields}[$last_jnl_entry->fbl('JNL_Time')]{Value};
    }



    my $label=$mw->Label(-text=>"Available Quests:",-font=>['MS Sans Serif','8'])->place(-relx=>600/$x,-rely=>100/$y,-anchor=>'sw');
    push @spawned_widgets,$label;

    my %jrlhash; #tag->Name
    for my $jrl_category (@$jrl_categories_arr_ref) {
        my $this_name;
        my $this_name_strref=$jrl_category->{Fields}[$jrl_category->fbl('Name')]{Value}{StringRef};
        if ($this_name_strref==-1) {
            $this_name=$jrl_category->{Fields}[$jrl_category->fbl('Name')]{Value}{Substrings}[0]{Value};
        } else {
            $this_name=Bioware::TLK::string_from_resref($registered_path,$this_name_strref);
        }
        $jrlhash{lc($jrl_category->{Fields}[$jrl_category->fbl('Tag')]{Value})} =$this_name;
    }
    my %revhash=reverse %jrlhash;
    Tk::Autoscroll::Init(my $jrllist= $mw->Scrolled('TList',
      -scrollbars=>'osoe',
      -background=>'white',
      -selectforeground=>'#FFFFFF',
      -selectbackground=>'#D07000',
      -selectmode=>'extended',
      -itemtype=>'text',
      -orient=>'horizontal'
    ));
    $jrllist->place(-relx=>600/$x,-rely=>100/$y,-relwidth=>270/$x,-relheight=>400/$y);
    push @spawned_widgets,$jrllist;

    my $newstyle = $mw->ItemStyle('text',-foreground=>'#9090FF',-selectforeground=>'#D0D0FF',-selectbackground=>'#D07000');
    for (sort keys %revhash) {   # $_ will hold our jrl entry's name  $revhash{$_} will be our tag
        my $tag=lc($revhash{$_});
        if ($tree->info('exists',$treeitem."#".$tag)) {
            $jrllist->insert('end',-text=>$_,-style=>$newstyle);
        }
        else {
            $jrllist->insert('end',-text=>$_);
        }
    }

    my $btn2=$mw->Button(-text=>"Add Quests",-command=>sub {
        #my @selected_indices=$featlist->curselection;
        my @selected_indices=$jrllist->info('selection');
        unless (scalar @selected_indices) { return; }  #nothing selected
        for my $selected_index (@selected_indices) {
            my $selected_jrl_entry=$jrllist->entrycget($selected_index,-text);
            my $selected_jrl_tag=lc($revhash{$selected_jrl_entry});
            next if ($tree->info('exists',"$treeitem#".$selected_jrl_tag));
            LogInfo ("Adding Quest: $selected_jrl_entry ($selected_jrl_tag)");
            my $new_entry=Bioware::GFF::Struct->new('ID'=>0);
            my $initial_state=10;
            $new_entry->createField('Type'=>FIELD_CEXOSTRING,'Label'=>'JNL_PlotID','Value'=>$selected_jrl_tag);
            $new_entry->createField('Type'=>FIELD_INT,'Label'=>'JNL_State','Value'=>$initial_state);
            $new_entry->createField('Type'=>FIELD_DWORD,'Label'=>'JNL_Date','Value'=>$last_jnl_date);
            $new_entry->createField('Type'=>FIELD_DWORD,'Label'=>'JNL_Time','Value'=>$last_jnl_time);
            push @$jrl_entries_arr_ref,$new_entry;
            LogInfo ("Successful.");
            $tree->add("$treeitem#".$selected_jrl_tag,
              -text=>$selected_jrl_entry,-data=>'jrl##'.$initial_state.'##');
            $jrllist->entryconfigure($selected_index,-style=>$newstyle);
        }
    }
    )->place(-relx=>600/$x,-rely=>520/$y,-relwidth=>80/$x);
    push @spawned_widgets,$btn2;

    my $btn3=$mw->Button(-text=>"Commit Changes",-command=>sub { CommitChanges($treeitem) }
    )->place(-relx=>776/$x,-rely=>520/$y);

    push @spawned_widgets,$btn3;

    my $btn4=$mw->Button(-text=>"Remove Quests",-command=>sub {
        my @selected_indices=$jrllist->info('selection');
        unless (scalar @selected_indices) { return; }  #nothing selected
        for my $selected_index (@selected_indices) {
            my $selected_jrl_entry=$jrllist->entrycget($selected_index,-text);
            my $selected_jrl_tag=$revhash{$selected_jrl_entry};
            next unless ($tree->info('exists',"$treeitem#".$selected_jrl_tag));
            LogInfo ("Removing quest: $selected_jrl_entry ($selected_jrl_tag)");
            my @new_entries;
            for my $jrl_entry_struct (@$jrl_entries_arr_ref) {
                if (lc($jrl_entry_struct->{Fields}[$jrl_entry_struct->fbl('JNL_PlotID')]{Value}) eq $selected_jrl_tag) {
                    LogInfo("Successful.")
                }
                else {
                    push @new_entries, $jrl_entry_struct;
                }
            }
            $pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value}=[@new_entries];
            $datahash->{'GFF-pty'}=$pty_gff;
            $jrl_entries_arr_ref=$pty_gff->{Main}{Fields}[$pty_gff->{Main}->fbl('JNL_Entries')]{Value};
            $tree->delete('entry',"$treeitem#".$selected_jrl_tag);
            $jrllist->entryconfigure($selected_index,-style=>'');
        }
    }
    )->place(-relx=>688/$x,-rely=>520/$y,-relwidth=>80/$x);
    push @spawned_widgets,$btn4;


}
sub try_extracted_data {
    my $gameversion=shift;
    my $parm1=shift;
    my $parm2=shift;
    my $rootpath;
    if ($gameversion==1) {
        eval {
            my $chitin_fn="k1chitin.key";
            my $bif_fn="k12da.bif";
            my $bif2_fn="k1templates.bif";
            my $bif3_fn="k1_newbif.bif";
            my $chitinfile=PerlApp::extract_bound_file($chitin_fn);
            $chitinfile=~/(.*)\/$chitin_fn/;
            $rootpath="$1\\k1";
            mkdir $rootpath;
            my $chitinfile_fix=$chitinfile;
            $chitinfile_fix=~s/k1chitin\.key/chitin\.key/;
            rename $chitinfile, $chitinfile_fix;
            Copy ($chitinfile_fix=>"$rootpath\\");
            unlink $chitinfile_fix;

            mkdir "$rootpath\\data";
            my $biffile=PerlApp::extract_bound_file($bif_fn);
            my $biffile_fix=$biffile;
            $biffile_fix=~s/k12da\.bif/2da\.bif/;
            rename $biffile,$biffile_fix;
            Copy ($biffile_fix=>"$rootpath\\data\\");
            unlink $biffile_fix;

            $biffile=PerlApp::extract_bound_file($bif2_fn);
            $biffile_fix=$biffile;
            $biffile_fix=~s/k1templates\.bif/templates\.bif/;
            rename $biffile,$biffile_fix;
            Copy ($biffile_fix=>"$rootpath\\data\\");
            unlink $biffile_fix;

            $biffile=PerlApp::extract_bound_file($bif3_fn);
            $biffile_fix=$biffile;
            $biffile_fix=~s/k1_newbif\.bif/_newbif\.bif/;
            rename $biffile,$biffile_fix;
            Copy ($biffile_fix=>"$rootpath\\data\\");
            unlink $biffile_fix;


        };
    }
    elsif ($gameversion==2) {
        eval {
            my $chitin_fn="k2chitin.key";
            my $bif_fn="k22da.bif";
            my $bif2_fn="k2templates.bif";
            my $journal_fn="k2global.jrl";


            my $chitinfile=PerlApp::extract_bound_file($chitin_fn);
            $chitinfile=~/(.*)\/$chitin_fn/;
            $rootpath="$1\\k2";
            mkdir $rootpath;
            my $chitinfile_fix=$chitinfile;
            $chitinfile_fix=~s/k2chitin\.key/chitin\.key/;
            rename $chitinfile, $chitinfile_fix;
            Copy ($chitinfile_fix=>"$rootpath\\");
            unlink $chitinfile_fix;

            my $journalfile=PerlApp::extract_bound_file($journal_fn);
            my $journalfile_fix=$journalfile;
            $journalfile_fix=~s/k2global\.jrl/global\.jrl/;
            rename $journalfile, $journalfile_fix;
            Copy ($journalfile_fix=>"$rootpath\\");
            unlink $chitinfile_fix;


            mkdir "$rootpath\\data";
            my $biffile=PerlApp::extract_bound_file($bif_fn);
            my $biffile_fix=$biffile;
            $biffile_fix=~s/k22da\.bif/2da\.bif/;
            rename $biffile,$biffile_fix;
            Copy ($biffile_fix=>"$rootpath\\data\\");
            unlink $biffile_fix;

            $biffile=PerlApp::extract_bound_file($bif2_fn);
            $biffile_fix=$biffile;
            $biffile_fix=~s/k2templates\.bif/templates\.bif/;
            rename $biffile,$biffile_fix;
            Copy ($biffile_fix=>"$rootpath\\data\\");
            unlink $biffile_fix;
        };
    }
    elsif ($gameversion==3) {
        eval {
            my $chitin_fn="k3chitin.key";
            my $bif_fn="k32da.bif";
            my $bif2_fn="k3templates.bif";
            my $journal_fn="k3global.jrl";


            my $chitinfile=PerlApp::extract_bound_file($chitin_fn);
            $chitinfile=~/(.*)\/$chitin_fn/;
            $rootpath="$1\\k3";
            mkdir $rootpath;
            my $chitinfile_fix=$chitinfile;
            $chitinfile_fix=~s/k3chitin\.key/chitin\.key/;
            rename $chitinfile, $chitinfile_fix;
            Copy ($chitinfile_fix=>"$rootpath\\");
            unlink $chitinfile_fix;

            my $journalfile=PerlApp::extract_bound_file($journal_fn);
            my $journalfile_fix=$journalfile;
            $journalfile_fix=~s/k3global\.jrl/global\.jrl/;
            rename $journalfile, $journalfile_fix;
            Copy ($journalfile_fix=>"$rootpath\\");
            unlink $chitinfile_fix;


            mkdir "$rootpath\\data";
            my $biffile=PerlApp::extract_bound_file($bif_fn);
            my $biffile_fix=$biffile;
            $biffile_fix=~s/k32da\.bif/2da\.bif/;
            rename $biffile,$biffile_fix;
            Copy ($biffile_fix=>"$rootpath\\data\\");
            unlink $biffile_fix;

            $biffile=PerlApp::extract_bound_file($bif2_fn);
            $biffile_fix=$biffile;
            $biffile_fix=~s/k3templates\.bif/templates\.bif/;
            rename $biffile,$biffile_fix;
            Copy ($biffile_fix=>"$rootpath\\data\\");
            unlink $biffile_fix;
        };
    }
    if ($@)
    {
        return undef;
    }
    else
    {
        if ($parm1 eq 'Get Journal')
        {
            return "$rootpath\\global.jrl";
        }
        else
        {
            return Bioware::BIF->new($rootpath,$parm1,$parm2);
        }
    }
}

sub Load {
    my $branch_to_populate=shift;
    #Read KotOR1 saves
    if ($kseInitializer->{k1_installed} && (!(defined $branch_to_populate) || ($branch_to_populate==1))) {
        LogInfo "Reading KotOR saves...";
        unless (opendir SAVDIR, $kseInitializer->{path}->{kotor_save}) {                                        #saves directory not found
            $mw->messageBox(-title=>'Directory not found',
              -message=>'Could not find saves directory for KotOR1',-type=>'Ok');
            LogInfo ('KSE could not find saves directory for KotOR1.');
            $kseInitializer->{k1_installed}=0;
        }
        my @savedirs=grep { !(/\\\.+$/) && -d } map {"$kseInitializer->{path}->{kotor_save}\\$_"} readdir(SAVDIR);    #read all directories in saves dir
        close SAVDIR;
        if ($branch_to_populate==1) {
            $tree->delete('offsprings','#1');                                                         #if this is a re-populate, then delete any leaves from this branch
        }
        for (sort @savedirs) {
            /\\.*\\(.+?)$/;
            my $dir=$1;
            $tree->add('#1#'.$dir,-text=>$dir);
            $tree->add('#1#'.$dir.'#',-text=>'.');
            $tree->hide('entry','#1#'.$dir.'#');                                                       #give them something to talk about
        }
    }
    if ($kseInitializer->{k2_installed} && (!(defined $branch_to_populate)||($branch_to_populate==2))) {
        LogInfo "Reading KotOR II - TSL saves...";
        unless (opendir SAVDIR2, $kseInitializer->{path}->{tsl_save}) {                                        #saves directory not found
            $mw->messageBox(-title=>'Directory not found',
              -message=>'Could not find saves directory for KotOR2',-type=>'Ok');
            LogInfo ('KSE could not find saves directory for KotOR2.');
            $kseInitializer->{k2_installed}=0;
        }

        my @savedirs=grep { !(/\\\.+$/) && -d } map {"$kseInitializer->{path}->{tsl_save}\\$_"} readdir(SAVDIR2);    #read all directories in saves dir
        close SAVDIR2;
        if ($branch_to_populate==2) {
            #if this is a re-populate, then delete any leaves from this branch
            $tree->delete('offsprings','#2');
        }
        for (sort @savedirs) {
            /\\.*\\(.+?)$/;
            my $dir=$1;
            $tree->add('#2#'.$dir,-text=>$dir);
            $tree->add('#2#'.$dir.'#',-text=>'.');
            #give them something to talk about
            $tree->hide('entry','#2#'.$dir.'#');
        }
    }
    if ($kseInitializer->{k2_installed} && (!(defined $branch_to_populate)||($branch_to_populate==3))) {
        LogInfo "Reading KotOR II - TSL (Cloud) saves...";
        unless (opendir SAVDIR2, $kseInitializer->{path}->{tsl_cloud}) {
            #saves directory not found
            $mw->messageBox(-title=>'Directory not found',
              -message=>'Could not find cloudsaves directory for KotOR2',-type=>'Ok');
            LogInfo ('KSE could not find cloudsaves directory for KotOR2.');
            $kseInitializer->{use_tsl_cloud}=0;
        }

        my @savedirs=grep { !(/\\\.+$/) && -d } map {"$kseInitializer->{path}->{tsl_cloud}\\$_"} readdir(SAVDIR2);    #read all directories in saves dir
        close SAVDIR2;
        if ($branch_to_populate==3) {
            #if this is a re-populate, then delete any leaves from this branch
            $tree->delete('offsprings','#3');
        }
        for (sort @savedirs) {
            /\\.*\\(.+?)$/;
            my $dir=$1;
            $tree->add('#3#'.$dir,-text=>$dir);
            $tree->add('#3#'.$dir.'#',-text=>'.');
            $tree->hide('entry','#3#'.$dir.'#');                                                       #give them something to talk about
        }
    }
    if ($kseInitializer->{tjm_installed} && $branch_to_populate == 3 || 4) {
        if($branch_to_populate == 3 && $kseInitializer->{use_tsl_cloud} == 1) { }
        else
        {
            if($branch_to_populate == 3)
            {
                LogInfo "Reading KotOR III - TJM saves...";
                if(-e $kseInitializer->{path}->{tjm}."/saves") {# print "path found\n";
                    unless (opendir SAVDIR3, $kseInitializer->{path}->{tjm}."/saves") {                                          #saves directory not found
                        $mw->messageBox(-title=>'Directory not found',
                          -message=>'Could not find saves directory for TJM',-type=>'Ok');
                        LogInfo ('KSE could not find saves directory for TJM.');
                        $kseInitializer->{tjm_installed}=0;
                    }

                    my @savedirs=grep { !(/\\\.+$/) && -d } map {"$kseInitializer->{path}->{tjm}\\saves\\$_"} readdir(SAVDIR3);  #read all directories in saves dir
                    close SAVDIR3;
                    if ($branch_to_populate==3) {
                        $tree->delete('offsprings','#3');                                                      #if this is a re-populate, then delete any leaves from this branch
                    }
                    for (sort @savedirs) {
                        /\\.*\\(.+?)$/;
                        my $dir=$1;
                        $tree->add('#3#'.$dir,-text=>$dir);
                        $tree->add('#3#'.$dir.'#',-text=>'.');
                        $tree->hide('entry','#3#'.$dir.'#');                                                       #give them something to talk about
                    }
                }
                else
                {
                    if(-e $kseInitializer->{path}->{tjm}."/saves") {# print "path found\n";
                        unless (opendir SAVDIR3, $kseInitializer->{path}->{tjm}."/saves") {                                          #saves directory not found
                            $mw->messageBox(-title=>'Directory not found',
                              -message=>'Could not find saves directory for TJM',-type=>'Ok');
                            LogInfo ('KSE could not find saves directory for TJM.');
                            $kseInitializer->{tjm_installed}=0;
                        }

                        my @savedirs=grep { !(/\\\.+$/) && -d } map {"$kseInitializer->{path}->{tjm}\\saves\\$_"} readdir(SAVDIR3);  #read all directories in saves dir
                        close SAVDIR3;
                        if ($branch_to_populate==4) {
                            $tree->delete('offsprings','#4');                                                      #if this is a re-populate, then delete any leaves from this branch
                        }
                        for (@savedirs) {
                            /\\.*\\(.+?)$/;
                            my $dir=$1;
                            $tree->add('#4#'.$dir,-text=>$dir);
                            $tree->add('#4#'.$dir.'#',-text=>'.');
                            $tree->hide('entry','#4#'.$dir.'#');                                                       #give them something to talk about
                        }
                    }
                }
            }
            #    }
        }

        sub Reload {
            my $treeitem=shift;
            my $gv;
            my $gm;

            my @parms = split /#/, $treeitem;
            #	print join /\n/, @parms;

            if ($parms[1] == 1) { $gv = "Kotor 1"; }
            if ($parms[1] == 2) { $gv = "Kotor 2/TSL"; }
            if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 2/TSL Cloud"; }
            if ($parms[1] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 3/TJM"; }
            if ($parms[1] == 4) { $gv = "Kotor 3/TJM"; }

            my $ent = $parms[2];
            my $su = $_;
            $_ = $ent;
            /(.......-.)/;
            $gm = $ent;
            $gm =~ s#$1##;

            $_ = $su;
            LogInfo ("Loading game $gm for $gv");

            my $gameversion=(split /#/,$treeitem)[1];
            my $gamedir=(split /#/,$treeitem)[2];

            if( $gameversion == 1) {
                $tree->delete('offspring', '#1#'.$gamedir);
                Populate_Level1($treeitem);
            }
            if( $gameversion == 2) {
                $tree->delete('offspring', '#2#'.$gamedir);
                Populate_Level1($treeitem);
            }
            if( $gameversion == 3) {
                $tree->delete('offspring', '#3#'.$gamedir);
                Populate_Level1($treeitem);
            }
            if( $gameversion == 4) {
                $tree->delete('offspring', '#4#'.$gamedir);
                Populate_Level1($treeitem);
            }
        }

        sub ReloadAll {
            #print $_;
            my $treeitem=shift;
            my $gv;
            my $gm;

            my @parms = split /#/, $treeitem;
            LogDebug(join "\n", @parms);

            if ($parms[0] == 1) { $gv = "Kotor 1"; }
            if ($parms[0] == 2) { $gv = "Kotor 2/TSL"; }
            if ($parms[0] == 3 && $kseInitializer->{use_tsl_cloud} == 0) { $gv = "Kotor 2/TSL Cloud"; }
            if ($parms[0] == 3 && $kseInitializer->{use_tsl_cloud} == 1) { $gv = "Kotor 3/TJM"; }
            if ($parms[0] == 4) { $gv = "Kotor 3/TJM"; }

            my $ent = $parms[2];
            my $su = $_;
            $_ = $ent;
            /(.......-.)/;
            $gm = $ent;
            $gm =~ s#$1##;

            $_ = $su;
            LogInfo ("Loading games for $gv");

            $tree->delete('offspring', "#" . $parms[0]);
            Load($parms[0]);
            $tree->autosetmode();
            $tree->close("#" . $treeitem);

            #    if( $treeitem == 1) {
            #	my @games = $tree->info('children', '#' . $treeitem);
            #	foreach(@games) {
            #		Reload($_);
            #		$tree->setmode($_, 'close');
            #		$tree->close($_);
            #	}
            #    }
            #    if( $treeitem == 2) {
            #	my @games = $tree->info('children', '#' . $treeitem);
            #	foreach(@games) {
            #		Reload($_);
            #		$tree->setmode($_, 'close');
            #		$tree->close($_);
            #	}
            #    }
            #    if( $treeitem == 3) {
            #	my @games = $tree->info('children', '#' . $treeitem);
            #	foreach(@games) {
            #		Reload($_);
            #		$tree->setmode($_, 'close');
            #		$tree->close($_);
            #	}
            #    }
            #    if( $treeitem == 4) {
            #	my @games = $tree->info('children', '#' . $treeitem);
            #	foreach(@games) {
            #		Reload($_);
            #		$tree->setmode($_, 'close');
            #		$tree->close($_);
            #	}
            #    }
        }

        #sub CopyGlobals {
        #    my ($treeitem_source,$datahash)=@_;
        #
        #    #for later readability in dialog box...
        #    my $treeitem_desc=(split /#/,$treeitem_source)[2];
        #    my $res_gff=$datahash->{'GFF-res'};
        #    $globals_source_savegame_name=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('SAVEGAMENAME')]{Value};
        #
        #    #memorize inventory...
        #    $globals_memorized=$datahash->{'GFF-res'};
        #    LogInfo($globals_memorized);
        #
        #    #remove temp indicator from any earlier DItem
        #    if ($globals_in_memory==1) {
        #
        #        #earlier copy was in effect...
        #        my $current_tix_image_of_old_source_item=$tree->indicator('cget',$globals_source_treeitem,'image');
        #
        #        if ($current_tix_image_of_old_source_item eq 'image5') {
        #
        #            #and we still have the old indicator in effect, so change it back
        #            my $oldimage;
        #            if ($old_tix_image eq 'image1') {
        #                $tree->close($globals_source_treeitem);
        #            } elsif ($old_tix_image eq 'image2') {
        #                $tree->open($globals_source_treeitem);
        #            }
        #            $tree->autosetmode();
        #        }
        #    }
        #
        #    #remember the current indicator of DItem
        #    $old_tix_image=$tree->indicator('cget',$treeitem_source,'image');
        #
        #    #set new temp indicator to DItem
        #    my $newimage=$mw->Getimage('srcfile');
        #    $tree->indicator('configure',$treeitem_source,'image',$newimage);
        #
        #    #make note of the changes
        #    $globals_in_memory=1;
        #    $globals_source_treeitem=$treeitem_source;
        #
        #    #tell user we're done
        #    my $ok=$mw->Dialog(-title=>'Globals Copied to Memory',
        #                       -text=>"Globals from $treeitem_desc\n '$globals_source_savegame_name'\n has been copied into memory.",
        #                       -font=>['MS Sans Serif','8'],
        #                       -buttons=>['Ok'])->Show();
        #}
        #
        #sub PasteGlobals {
        #    my ($treeitem_destination,$datahash)=@_;
        #
        #    my $gameversion=(split /#/,$treeitem_destination)[1];
        #    my $treeitem_desc=(split /#/,$treeitem_destination)[2];
        #    my $treeitem_src_desc=(split /#/,$globals_source_treeitem)[2];
        #    my $res_gff=$datahash->{'GFF-res'};
        #    my $globals_destination_savegame_name=$res_gff->{Main}{Fields}[$res_gff->{Main}->get_field_ix_by_label('SAVEGAMENAME')]{Value};
        #
        #    my $confirm=$mw->Dialog(-title=>'Confirm Globals Paste',
        #                       -text=>"Are you sure you wish to Paste the Globals from\n$treeitem_src_desc  '$globals_source_savegame_name'\nto\n$treeitem_desc  '$globals_destination_savegame_name'?",
        #                       -font=>['MS Sans Serif','8'],
        #                       -buttons=>['Yes','No'])->Show();
        #    if ($confirm eq 'Yes') {
        #        $datahash->{'GFF-res'}=$globals_memorized;
        #        $tree->entryconfigure($treeitem_destination,-data=>$datahash);
        #        CommitChanges($treeitem_destination);
        #        $tree->delete('offsprings',$treeitem_destination."#Globals");
        #        if ($gameversion==1) {
        #              Read_Global_Vars("$kseInitializer->{path}->{kotor_save}\\$levels[1]",$parm1)
        #           }
        #        elsif ($gameversion==2) {
        #              Read_Global_Vars("$kseInitializer->{path}->{tsl_save}\\$levels[1]",$parm1)
        #           }
        #        elsif ($gameversion==3) {
        #              Read_Global_Vars("$kseInitializer->{path}->{tjm}\\saves\\$levels[1]",$parm1)
        #           }
        #    }
        #}

        sub Populate_Data
        {
            my $gamever = shift;
            if($gamever == 1) { &Pop_KotOR; }
            if($gamever == 2) { &Pop_TSL;   }
            if($gamever == 3 && $kseInitializer->{use_tsl_cloud} == 1) { &Pop_TSL;   }
            if($gamever == 3 && $kseInitializer->{use_tsl_cloud} == 0) { &Pop_TJM;   }
            if($gamever == 4) { &Pop_TJM;   }
        }

        sub Pop_KotOR
        {
            our $twoda_obj=Bioware::TwoDA->new();
            if($open{1} < 1)
            {
                LogInfo "Loading KotOR data...";
                $open{1} = 1;
                if ($kseInitializer->{k1_installed})
                {
                    my $k1_bif=Bioware::BIF->new($kseInitializer->{path}->{kotor},undef,'2da');
                    if (!(defined $k1_bif))
                    {
                        $k1_bif=try_extracted_data(1,undef,'2da');
                    }
                    if (!(defined $k1_bif))
                    {
                        $mw->Dialog(-title=>'Bad path!',-text=>'Could not find 2DA.bif!\n Kotor',-buttons=>['OK'])->Show;
                        $kseInitializer->{path}->{kotor}=$oldpath{kotor};
                        return;
                    }
                    ### spells.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/spells.2da") {
                        LogInfo ('KotOR1 spells.2da override detected.');
                        my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/spells.2da");
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {
                                $powers_full1{label}{$k}=$hashref->{$k}{label};

                                #print ("($hashref->{$k}{label})");

                                $powers_full1{name}{$k}=$hashref->{$k}{label};
                                $powers_full1{icon}{$k}=$hashref->{$k}{iconresref};


                                if ($hashref->{$k}{name}) {
                                    $powers_full1{name}{$k}=string_from_resref($kseInitializer->{path}->{kotor},$hashref->{$k}{name},'KotOR1 Spells.2da')
                                }
                                if (($hashref->{$k}{label}=~/^FORCE_POWER/) && !($hashref->{$k}{label} =~ /XXX/)) {
                                    $powers_short1{label}{$k}=$powers_full1{label}{$k};
                                    $powers_short1{name}{$k}=$powers_full1{name}{$k};
                                    $powers_short1{icon}{$k}=$powers_full1{icon}{$k};
                                }
                            }
                        }
                    }
                    else {
                        my $temp2dafile=$k1_bif->get_resource('data\\2da.bif','spells.2da');
                        unless (defined ($temp2dafile)) {$temp2dafile=$k1_bif->get_resource('dataxbox\\2da.bif','spells.2da')};
                        my $hashref=$twoda_obj->read2da($temp2dafile);
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {
                                $powers_full1{label}{$k}=$hashref->{$k}{label};
                                $powers_full1{name}{$k}=$hashref->{$k}{label};
                                $powers_full1{icon}{$k}=$hashref->{$k}{iconresref};
                                if ($hashref->{$k}{name}) {
                                    $powers_full1{name}{$k}=string_from_resref($kseInitializer->{path}->{kotor},$hashref->{$k}{name})
                                }
                                if (($hashref->{$k}{label}=~/^FORCE_POWER/) && !($hashref->{$k}{label} =~ /XXX/)) {
                                    $powers_short1{label}{$k}=$powers_full1{label}{$k};
                                    $powers_short1{name}{$k}=$powers_full1{name}{$k};
                                    $powers_short1{icon}{$k}=$powers_full1{icon}{$k};
                                }
                            }
                        }
                    }
                    ### appearance.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/appearance.2da") {
                        LogInfo ('KotOR1 appearance.2da override detected.');
                        my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/appearance.2da");
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {$appearance_hash1{$k}=$hashref->{$k}{label}}
                        }

                    }
                    else {
                        my $temp2dafile=$k1_bif->get_resource('data\\2da.bif','appearance.2da');
                        unless (defined ($temp2dafile)) {$temp2dafile=$k1_bif->get_resource('dataxbox\\2da.bif','appearance.2da')};
                        my $hashref=$twoda_obj->read2da($temp2dafile);
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {$appearance_hash1{$k}=$hashref->{$k}{label}}
                        }
                    }
                    ### portraits.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/portraits.2da") {
                        LogInfo ('KotOR1 portraits.2da override detected.');
                        my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/portraits.2da");
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{baseresref}) {$portraits_hash1{$k}=$hashref->{$k}{baseresref}}
                        }

                    }
                    else {
                        my $temp2dafile=$k1_bif->get_resource('data\\2da.bif','portraits.2da');
                        unless (defined ($temp2dafile)) {$temp2dafile=$k1_bif->get_resource('dataxbox\\2da.bif','portraits.2da')};
                        my $hashref=$twoda_obj->read2da($temp2dafile);
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{baseresref}) {$portraits_hash1{$k}=$hashref->{$k}{baseresref}}
                        }
                    }
                    ### feat.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/feat.2da") {
                        LogInfo ('KotOR1 feat.2da override detected.');
                        my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/feat.2da");
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {
                                $feats_full1{label}{$k}=$hashref->{$k}{label};
                                $feats_full1{name}{$k}=$hashref->{$k}{label};
                                $feats_full1{icon}{$k}=$hashref->{$k}{icon};
                                if ($hashref->{$k}{name}) {
                                    $feats_full1{name}{$k}=string_from_resref($kseInitializer->{path}->{kotor},$hashref->{$k}{name},'KotOR1 Feat.2da');
                                }
                                if ( !($hashref->{$k}{label} =~ /XXX/)) {
                                    $feats_short1{label}{$k}=$feats_full1{label}{$k};
                                    $feats_short1{name}{$k}=$feats_full1{name}{$k};
                                    $feats_short1{icon}{$k}=$feats_full1{icon}{$k};
                                }
                            }
                        }

                    }
                    else {
                        my $temp2dafile=$k1_bif->get_resource('data\\2da.bif','feat.2da');
                        unless (defined ($temp2dafile)) {$temp2dafile=$k1_bif->get_resource('dataxbox\\2da.bif','feat.2da')};
                        my $hashref=$twoda_obj->read2da($temp2dafile);
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {
                                $feats_full1{label}{$k}=$hashref->{$k}{label};
                                $feats_full1{name}{$k}=$hashref->{$k}{label};
                                $feats_full1{icon}{$k}=$hashref->{$k}{icon};
                                if ($hashref->{$k}{name}) {
                                    $feats_full1{name}{$k}=string_from_resref($kseInitializer->{path}->{kotor},$hashref->{$k}{name})
                                }
                                if ( !($hashref->{$k}{label} =~ /XXX/)) {
                                    $feats_short1{label}{$k}=$feats_full1{label}{$k};
                                    $feats_short1{name}{$k}=$feats_full1{name}{$k};
                                    $feats_short1{icon}{$k}=$feats_full1{icon}{$k};
                                }
                            }
                        }
                    }
                    ### soundset.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/soundset.2da") {
                        LogInfo ('KotOR1 soundset.2da override detected.');
                        my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/soundset.2da");
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {$soundset_hash1{$k}=$hashref->{$k}{label}}
                        }

                    }
                    else {
                        my $temp2dafile=$k1_bif->get_resource('data\\2da.bif','soundset.2da');
                        unless (defined ($temp2dafile)) {$temp2dafile=$k1_bif->get_resource('dataxbox\\2da.bif','soundset.2da')};
                        my $hashref=$twoda_obj->read2da($temp2dafile);
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{label}) {$soundset_hash1{$k}=$hashref->{$k}{label}}
                        }
                    }
                    ### skills.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/skills.2da") {
                        LogInfo ('KotOR1 skills.2da override detected.');
                        my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/skills.2da");
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{name}) {$skills_hash1{$k}=string_from_resref($kseInitializer->{path}->{kotor},$hashref->{$k}{name},'KotOR1 skills.2da')}
                        }

                    }
                    else {
                        my $temp2dafile=$k1_bif->get_resource('data\\2da.bif','skills.2da');
                        unless (defined ($temp2dafile)) {$temp2dafile=$k1_bif->get_resource('dataxbox\\2da.bif','skills.2da')};
                        my $hashref=$twoda_obj->read2da($temp2dafile);
                        for my $k (keys %$hashref) {
                            if ($hashref->{$k}{name}) {$skills_hash1{$k}=string_from_resref($kseInitializer->{path}->{kotor},$hashref->{$k}{name})}
                        }
                    }
                    ### classes.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/classes.2da") {
                        LogInfo ('KotOR1 classes.2da override detected.');
                        my %classes_detail1=%{$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/classes.2da")};
                        for my $c (keys %classes_detail1) {
                            if ($classes_detail1{$c}{spellgaintable}) {
                                $spellcasters1{$c}=1;
                            }
                            my $cname=string_from_resref($kseInitializer->{path}->{kotor},$classes_detail1{$c}{name},'KotOR1 classes.2da');
                            if  ($cname eq "Bad StrRef") {
                                $classes_hash1{$c}=$classes_detail1{$c}{label} }
                            else {
                                $classes_hash1{$c}=$cname }
                        }

                    }
                    else {
                        my $twodaref=$k1_bif->get_resource('data\\2da.bif','classes.2da');
                        unless (defined ($twodaref)) {$twodaref=$k1_bif->get_resource('dataxbox\\2da.bif','classes.2da')};
                        my %classes_detail1=%{$twoda_obj->read2da($twodaref)};
                        for my $c (keys %classes_detail1) {
                            if ($classes_detail1{$c}{spellgaintable}) {
                                $spellcasters1{$c}=1;
                            }
                            my $cname=string_from_resref($kseInitializer->{path}->{kotor},$classes_detail1{$c}{name});
                            if  ($cname eq "Bad StrRef") {
                                $classes_hash1{$c}=$classes_detail1{$c}{label} }
                            else {
                                $classes_hash1{$c}=$cname }
                        }

                    }
                    ### gender.2da ###
                    if (-e $kseInitializer->{path}->{kotor}."/override/gender.2da") {
                        LogInfo ('KotOR1 gender.2da override detected.');
                        my %gender_detail=%{$twoda_obj->read2da($kseInitializer->{path}->{kotor}."/override/gender.2da")};
                        for my $g (keys %gender_detail) {$gender_hash1{$g}=$gender_detail{$g}{constant}}

                    }
                    else
                    {
                        my $twodaref=$k1_bif->get_resource('data\\2da.bif','gender.2da');
                        unless (defined ($twodaref)) {$twodaref=$k1_bif->get_resource('dataxbox\\2da.bif','gender.2da')};
                        my %gender_detail=%{$twoda_obj->read2da($twodaref)};
                        for my $g (keys %gender_detail) {$gender_hash1{$g}=$gender_detail{$g}{constant}}
                    }
                }

                sub Pop_TSL
                {
                    if($open{2} < 1)
                    {
                        LogInfo "Loading KotOR 2 - TSL data...";
                        $open{2} = 1;

                        our $twoda_obj=Bioware::TwoDA->new();

                        my $k2_bif=Bioware::BIF->new($kseInitializer->{path}->{tsl},undef,'2da');
                        if (!(defined $k2_bif))
                        {
                            $k2_bif=try_extracted_data(1,undef,'2da');
                        }
                        if (!(defined $k2_bif))
                        {
                            $mw->Dialog(-title=>'Bad path!',-text=>'Could not find 2DA.bif!\n TSL',-buttons=>['OK'])->Show;
                            $kseInitializer->{path}->{tsl}=$oldpath{tsl};
                            return;
                        }
                        ### spells.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/spells.2da")
                        {
                            LogInfo ('Kotor 2 spells.2da override detected.');
                            my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/spells.2da");
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $powers_full2{label}{$k}=$hashref->{$k}{label};

                                    #print ("($hashref->{$k}{label})");

                                    $powers_full2{name}{$k}=$hashref->{$k}{label};
                                    $powers_full2{icon}{$k}=$hashref->{$k}{iconresref};

                                    if ($hashref->{$k}{name})
                                    {
                                        $powers_full2{name}{$k}=string_from_resref($kseInitializer->{path}->{tsl},$hashref->{$k}{name},'Kotor 2 Spells.2da')
                                    }
                                    if (($hashref->{$k}{label}=~/^FORCE_POWER/) && !($hashref->{$k}{label} =~ /XXX/))
                                    {
                                        $powers_short2{label}{$k}=$powers_full2{label}{$k};
                                        $powers_short2{name}{$k}=$powers_full2{name}{$k};
                                        $powers_short2{icon}{$k}=$powers_full2{icon}{$k};
                                    }
                                }
                            }
                        }
                        else
                        {
                            my $temp2dafile=$k2_bif->get_resource('data\\2da.bif','spells.2da');
                            unless (defined ($temp2dafile)) {$temp2dafile=$k2_bif->get_resource('dataxbox\\2da.bif','spells.2da')};
                            my $hashref=$twoda_obj->read2da($temp2dafile);
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $powers_full2{label}{$k}=$hashref->{$k}{label};
                                    $powers_full2{name}{$k}=$hashref->{$k}{label};
                                    $powers_full2{icon}{$k}=$hashref->{$k}{iconresref};
                                    if ($hashref->{$k}{name})
                                    {
                                        $powers_full2{name}{$k}=string_from_resref($kseInitializer->{path}->{tsl},$hashref->{$k}{name})
                                    }
                                    if (($hashref->{$k}{label}=~/^FORCE_POWER/) && !($hashref->{$k}{label} =~ /XXX/))
                                    {
                                        $powers_short2{label}{$k}=$powers_full2{label}{$k};
                                        $powers_short2{name}{$k}=$powers_full2{name}{$k};
                                        $powers_short2{icon}{$k}=$powers_full2{icon}{$k};
                                    }
                                }
                            }
                        }
                        ### appearance.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/appearance.2da")
                        {
                            LogInfo ('Kotor 2 appearance.2da override detected.');
                            my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/appearance.2da");
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $appearance_hash2{$k}=$hashref->{$k}{label}
                                }
                            }
                        }
                        else
                        {
                            my $temp2dafile=$k2_bif->get_resource('data\\2da.bif','appearance.2da');
                            unless (defined ($temp2dafile))
                            {
                                $temp2dafile=$k2_bif->get_resource('dataxbox\\2da.bif','appearance.2da')
                            }
                            my $hashref=$twoda_obj->read2da($temp2dafile);
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $appearance_hash2{$k}=$hashref->{$k}{label}
                                }
                            }
                        }
                        ### portraits.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/portraits.2da")
                        {
                            LogInfo ('Kotor 2 portraits.2da override detected.');
                            my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/portraits.2da");
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{baseresref})
                                {
                                    $portraits_hash2{$k}=$hashref->{$k}{baseresref};
                                }
                            }
                        }
                        else
                        {
                            my $temp2dafile=$k2_bif->get_resource('data\\2da.bif','portraits.2da');
                            unless (defined ($temp2dafile))
                            {
                                $temp2dafile=$k2_bif->get_resource('dataxbox\\2da.bif','portraits.2da');
                            }
                            my $hashref=$twoda_obj->read2da($temp2dafile);
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{baseresref})
                                {
                                    $portraits_hash2{$k}=$hashref->{$k}{baseresref};
                                }
                            }
                        }
                        ### feat.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/feat.2da")
                        {
                            LogInfo ('Kotor 2 feat.2da override detected.');
                            my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/feat.2da");
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $feats_full2{label}{$k}=$hashref->{$k}{label};
                                    $feats_full2{name}{$k}=$hashref->{$k}{label};
                                    $feats_full2{icon}{$k}=$hashref->{$k}{icon};
                                    if ($hashref->{$k}{name})
                                    {
                                        $feats_full2{name}{$k}=string_from_resref($kseInitializer->{path}->{tsl},$hashref->{$k}{name},'Kotor 2 Feat.2da');
                                    }
                                    if ( !($hashref->{$k}{label} =~ /XXX/))
                                    {
                                        $feats_short2{label}{$k}=$feats_full2{label}{$k};
                                        $feats_short2{name}{$k}=$feats_full2{name}{$k};
                                        $feats_short2{icon}{$k}=$feats_full2{icon}{$k};
                                    }
                                }
                            }
                        }
                        else
                        {
                            my $temp2dafile=$k2_bif->get_resource('data\\2da.bif','feat.2da');
                            unless (defined ($temp2dafile)) {$temp2dafile=$k2_bif->get_resource('dataxbox\\2da.bif','feat.2da')};
                            my $hashref=$twoda_obj->read2da($temp2dafile);
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $feats_full2{label}{$k}=$hashref->{$k}{label};
                                    $feats_full2{name}{$k}=$hashref->{$k}{label};
                                    $feats_full2{icon}{$k}=$hashref->{$k}{icon};
                                    if ($hashref->{$k}{name})
                                    {
                                        $feats_full2{name}{$k}=string_from_resref($kseInitializer->{path}->{tsl},$hashref->{$k}{name});
                                    }
                                    if ( !($hashref->{$k}{label} =~ /XXX/))
                                    {
                                        $feats_short2{label}{$k}=$feats_full2{label}{$k};
                                        $feats_short2{name}{$k}=$feats_full2{name}{$k};
                                        $feats_short2{icon}{$k}=$feats_full2{icon}{$k};
                                    }
                                }
                            }
                        }
                        ### soundset.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/soundset.2da")
                        {
                            LogInfo ('Kotor 2 soundset.2da override detected.');
                            my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/soundset.2da");
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $soundset_hash2{$k}=$hashref->{$k}{label};
                                }
                            }
                        }
                        else
                        {
                            my $temp2dafile=$k2_bif->get_resource('data\\2da.bif','soundset.2da');
                            unless (defined ($temp2dafile))
                            {
                                $temp2dafile=$k2_bif->get_resource('dataxbox\\2da.bif','soundset.2da');
                            }
                            my $hashref=$twoda_obj->read2da($temp2dafile);
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{label})
                                {
                                    $soundset_hash2{$k}=$hashref->{$k}{label};
                                }
                            }
                        }
                        ### skills.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/skills.2da")
                        {
                            LogInfo ('Kotor 2 skills.2da override detected.');
                            my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/skills.2da");
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{name})
                                {
                                    $skills_hash2{$k}=string_from_resref($kseInitializer->{path}->{tsl},$hashref->{$k}{name},'Kotor 2 skills.2da');
                                }
                            }
                        }
                        else
                        {
                            my $temp2dafile=$k2_bif->get_resource('data\\2da.bif','skills.2da');
                            unless (defined ($temp2dafile))
                            {
                                $temp2dafile=$k2_bif->get_resource('dataxbox\\2da.bif','skills.2da');
                            }
                            my $hashref=$twoda_obj->read2da($temp2dafile);
                            for my $k (keys %$hashref)
                            {
                                if ($hashref->{$k}{name})
                                {
                                    $skills_hash2{$k}=string_from_resref($kseInitializer->{path}->{tsl},$hashref->{$k}{name});
                                }
                            }
                        }
                        ### classes.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/classes.2da")
                        {
                            LogInfo ('Kotor 2 classes.2da override detected.');
                            my %classes_detail2=%{$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/classes.2da")};
                            for my $c (keys %classes_detail2)
                            {
                                if ($classes_detail2{$c}{spellgaintable})
                                {
                                    $spellcasters2{$c}=2;
                                }
                                my $cname=string_from_resref($kseInitializer->{path}->{tsl},$classes_detail2{$c}{name},'Kotor 2 classes.2da');
                                if  ($cname eq "Bad StrRef")
                                {
                                    $classes_hash2{$c}=$classes_detail2{$c}{label}
                                }
                                else
                                {
                                    $classes_hash2{$c}=$cname;
                                }
                            }
                        }
                        else
                        {
                            my $twodaref=$k2_bif->get_resource('data\\2da.bif','classes.2da');
                            unless (defined ($twodaref))
                            {
                                $twodaref=$k2_bif->get_resource('dataxbox\\2da.bif','classes.2da');
                            }
                            my %classes_detail2=%{$twoda_obj->read2da($twodaref)};
                            for my $c (keys %classes_detail2)
                            {
                                if ($classes_detail2{$c}{spellgaintable})
                                {
                                    $spellcasters2{$c}=2;
                                }
                                my $cname=string_from_resref($kseInitializer->{path}->{tsl},$classes_detail2{$c}{name});
                                if  ($cname eq "Bad StrRef")
                                {
                                    $classes_hash2{$c}=$classes_detail2{$c}{label}
                                }
                                else
                                {
                                    $classes_hash2{$c}=$cname;
                                }
                            }
                        }
                        ### gender.2da ###
                        if (-e $kseInitializer->{path}->{tsl}."/override/gender.2da")
                        {
                            LogInfo ('Kotor 2 gender.2da override detected.');
                            my %gender_detail=%{$twoda_obj->read2da($kseInitializer->{path}->{tsl}."/override/gender.2da")};
                            for my $g (keys %gender_detail) {$gender_hash2{$g}=$gender_detail{$g}{constant}}
                        }
                        else
                        {
                            my $twodaref=$k2_bif->get_resource('data\\2da.bif','gender.2da');
                            unless (defined ($twodaref))
                            {
                                $twodaref=$k2_bif->get_resource('dataxbox\\2da.bif','gender.2da');
                            }
                            my %gender_detail=%{$twoda_obj->read2da($twodaref)};
                            for my $g (keys %gender_detail)
                            {
                                $gender_hash2{$g}=$gender_detail{$g}{constant};
                            }
                        }
                    }}}}

        sub Pop_TJM
        {
            if($open{3} < 1)
            {
                LogInfo "Loading KotOR III - The Jedi Masters data...";
                $open{3} = 1;

                our $twoda_obj=Bioware::TwoDA->new();

                my $k3_bif=Bioware::BIF->new($kseInitializer->{path}->{tjm},undef,'2da');
                if (!(defined $k3_bif))
                {
                    $k3_bif=try_extracted_data(1,undef,'2da');
                }
                if (!(defined $k3_bif))
                {
                    $mw->Dialog(-title=>'Bad path!',-text=>'Could not find 2DA.bif!\n tjm',-buttons=>['OK'])->Show;
                    $kseInitializer->{path}->{tjm}=$oldpath{tjm};
                    return;
                }
                ### spells.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/spells.2da")
                {
                    LogInfo ('Kotor 2 spells.2da override detected.');
                    my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/spells.2da");
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $powers_full3{label}{$k}=$hashref->{$k}{label};

                            #print ("($hashref->{$k}{label})");

                            $powers_full3{name}{$k}=$hashref->{$k}{label};
                            $powers_full3{icon}{$k}=$hashref->{$k}{iconresref};

                            if ($hashref->{$k}{name})
                            {
                                $powers_full3{name}{$k}=string_from_resref($kseInitializer->{path}->{tjm},$hashref->{$k}{name},'Kotor 2 Spells.2da')
                            }
                            if (($hashref->{$k}{label}=~/^FORCE_POWER/) && !($hashref->{$k}{label} =~ /XXX/))
                            {
                                $powers_short3{label}{$k}=$powers_full3{label}{$k};
                                $powers_short3{name}{$k}=$powers_full3{name}{$k};
                                $powers_short3{icon}{$k}=$powers_full3{icon}{$k};
                            }
                        }
                    }
                }
                else
                {
                    my $temp2dafile=$k3_bif->get_resource('data\\2da.bif','spells.2da');
                    unless (defined ($temp2dafile)) {$temp2dafile=$k3_bif->get_resource('dataxbox\\2da.bif','spells.2da')};
                    my $hashref=$twoda_obj->read2da($temp2dafile);
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $powers_full3{label}{$k}=$hashref->{$k}{label};
                            $powers_full3{name}{$k}=$hashref->{$k}{label};
                            $powers_full3{icon}{$k}=$hashref->{$k}{iconresref};
                            if ($hashref->{$k}{name})
                            {
                                $powers_full3{name}{$k}=string_from_resref($kseInitializer->{path}->{tjm},$hashref->{$k}{name})
                            }
                            if (($hashref->{$k}{label}=~/^FORCE_POWER/) && !($hashref->{$k}{label} =~ /XXX/))
                            {
                                $powers_short3{label}{$k}=$powers_full3{label}{$k};
                                $powers_short3{name}{$k}=$powers_full3{name}{$k};
                                $powers_short3{icon}{$k}=$powers_full3{icon}{$k};
                            }
                        }
                    }
                }
                ### appearance.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/appearance.2da")
                {
                    LogInfo ('Kotor 2 appearance.2da override detected.');
                    my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/appearance.2da");
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $appearance_hash3{$k}=$hashref->{$k}{label}
                        }
                    }
                }
                else
                {
                    my $temp2dafile=$k3_bif->get_resource('data\\2da.bif','appearance.2da');
                    unless (defined ($temp2dafile))
                    {
                        $temp2dafile=$k3_bif->get_resource('dataxbox\\2da.bif','appearance.2da')
                    }
                    my $hashref=$twoda_obj->read2da($temp2dafile);
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $appearance_hash3{$k}=$hashref->{$k}{label}
                        }
                    }
                }
                ### portraits.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/portraits.2da")
                {
                    LogInfo ('Kotor 2 portraits.2da override detected.');
                    my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/portraits.2da");
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{baseresref})
                        {
                            $portraits_hash3{$k}=$hashref->{$k}{baseresref};
                        }
                    }
                }
                else
                {
                    my $temp2dafile=$k3_bif->get_resource('data\\2da.bif','portraits.2da');
                    unless (defined ($temp2dafile))
                    {
                        $temp2dafile=$k3_bif->get_resource('dataxbox\\2da.bif','portraits.2da');
                    }
                    my $hashref=$twoda_obj->read2da($temp2dafile);
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{baseresref})
                        {
                            $portraits_hash3{$k}=$hashref->{$k}{baseresref};
                        }
                    }
                }
                ### feat.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/feat.2da")
                {
                    LogInfo ('Kotor 2 feat.2da override detected.');
                    my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/feat.2da");
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $feats_full3{label}{$k}=$hashref->{$k}{label};
                            $feats_full3{name}{$k}=$hashref->{$k}{label};
                            $feats_full3{icon}{$k}=$hashref->{$k}{icon};
                            if ($hashref->{$k}{name})
                            {
                                $feats_full3{name}{$k}=string_from_resref($kseInitializer->{path}->{tjm},$hashref->{$k}{name},'Kotor 2 Feat.2da');
                            }
                            if ( !($hashref->{$k}{label} =~ /XXX/))
                            {
                                $feats_short3{label}{$k}=$feats_full3{label}{$k};
                                $feats_short3{name}{$k}=$feats_full3{name}{$k};
                                $feats_short3{icon}{$k}=$feats_full3{icon}{$k};
                            }
                        }
                    }
                }
                else
                {
                    my $temp2dafile=$k3_bif->get_resource('data\\2da.bif','feat.2da');
                    unless (defined ($temp2dafile)) {$temp2dafile=$k3_bif->get_resource('dataxbox\\2da.bif','feat.2da')};
                    my $hashref=$twoda_obj->read2da($temp2dafile);
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $feats_full3{label}{$k}=$hashref->{$k}{label};
                            $feats_full3{name}{$k}=$hashref->{$k}{label};
                            $feats_full3{icon}{$k}=$hashref->{$k}{icon};
                            if ($hashref->{$k}{name})
                            {
                                $feats_full3{name}{$k}=string_from_resref($kseInitializer->{path}->{tjm},$hashref->{$k}{name});
                            }
                            if ( !($hashref->{$k}{label} =~ /XXX/))
                            {
                                $feats_short3{label}{$k}=$feats_full3{label}{$k};
                                $feats_short3{name}{$k}=$feats_full3{name}{$k};
                                $feats_short3{icon}{$k}=$feats_full3{icon}{$k};
                            }
                        }
                    }
                }
                ### soundset.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/soundset.2da")
                {
                    LogInfo ('Kotor 2 soundset.2da override detected.');
                    my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/soundset.2da");
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $soundset_hash3{$k}=$hashref->{$k}{label};
                        }
                    }
                }
                else
                {
                    my $temp2dafile=$k3_bif->get_resource('data\\2da.bif','soundset.2da');
                    unless (defined ($temp2dafile))
                    {
                        $temp2dafile=$k3_bif->get_resource('dataxbox\\2da.bif','soundset.2da');
                    }
                    my $hashref=$twoda_obj->read2da($temp2dafile);
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{label})
                        {
                            $soundset_hash3{$k}=$hashref->{$k}{label};
                        }
                    }
                }
                ### skills.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/skills.2da")
                {
                    LogInfo ('Kotor 2 skills.2da override detected.');
                    my $hashref=$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/skills.2da");
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{name})
                        {
                            $skills_hash3{$k}=string_from_resref($kseInitializer->{path}->{tjm},$hashref->{$k}{name},'Kotor 2 skills.2da');
                        }
                    }
                }
                else
                {
                    my $temp2dafile=$k3_bif->get_resource('data\\2da.bif','skills.2da');
                    unless (defined ($temp2dafile))
                    {
                        $temp2dafile=$k3_bif->get_resource('dataxbox\\2da.bif','skills.2da');
                    }
                    my $hashref=$twoda_obj->read2da($temp2dafile);
                    for my $k (keys %$hashref)
                    {
                        if ($hashref->{$k}{name})
                        {
                            $skills_hash3{$k}=string_from_resref($kseInitializer->{path}->{tjm},$hashref->{$k}{name});
                        }
                    }
                }
                ### classes.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/classes.2da")
                {
                    LogInfo ('Kotor 2 classes.2da override detected.');
                    my %classes_detail3=%{$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/classes.2da")};
                    for my $c (keys %classes_detail3){
                        if ($classes_detail3{$c}{spellgaintable})
                        {
                            $spellcasters3{$c}=2;
                        }
                        my $cname=string_from_resref($kseInitializer->{path}->{tjm},$classes_detail3{$c}{name},'Kotor 2 classes.2da');
                        if  ($cname eq "Bad StrRef")
                        {
                            $classes_hash3{$c}=$classes_detail3{$c}{label}
                        }
                        else
                        {
                            $classes_hash3{$c}=$cname;
                        }
                    }
                }
                else
                {
                    my $twodaref=$k3_bif->get_resource('data\\2da.bif','classes.2da');
                    unless (defined ($twodaref))
                    {
                        $twodaref=$k3_bif->get_resource('dataxbox\\2da.bif','classes.2da');
                    }
                    my %classes_detail3=%{$twoda_obj->read2da($twodaref)};
                    for my $c (keys %classes_detail3)
                    {
                        if ($classes_detail3{$c}{spellgaintable})
                        {
                            $spellcasters3{$c}=2;
                        }
                        my $cname=string_from_resref($kseInitializer->{path}->{tjm},$classes_detail3{$c}{name});
                        if  ($cname eq "Bad StrRef")
                        {
                            $classes_hash3{$c}=$classes_detail3{$c}{label}
                        }
                        else
                        {
                            $classes_hash3{$c}=$cname;
                        }
                    }
                }
                ### gender.2da ###
                if (-e $kseInitializer->{path}->{tjm}."/override/gender.2da")
                {
                    LogInfo ('Kotor 2 gender.2da override detected.');
                    my %gender_detail=%{$twoda_obj->read2da($kseInitializer->{path}->{tjm}."/override/gender.2da")};
                    for my $g (keys %gender_detail) {$gender_hash3{$g}=$gender_detail{$g}{constant}}
                }
                else
                {
                    my $twodaref=$k3_bif->get_resource('data\\2da.bif','gender.2da');
                    unless (defined ($twodaref))
                    {
                        $twodaref=$k3_bif->get_resource('dataxbox\\2da.bif','gender.2da');
                    }
                    my %gender_detail=%{$twoda_obj->read2da($twodaref)};
                    for my $g (keys %gender_detail)
                    {
                        $gender_hash3{$g}=$gender_detail{$g}{constant};
                    }
                }
            }
        }
    }
}
