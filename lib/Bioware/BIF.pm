#line 1 "Bioware/BIF.pm"
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::BIF; #~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use strict;
require Exporter;
use vars qw ($VERSION @ISA @EXPORT);

use Win32::TieRegistry;

$VERSION=0.02;
@ISA    = qw(Exporter);
@EXPORT = qw(  );

#private vars
our %res_types =(
0x0000 => 'res', 	#Misc. GFF resources
0x0001 => 'bmp', 	#Microsoft Windows Bitmap
0x0002 => 'mve',
0x0003 => 'tga', 	#Targa Graphics Format
0x0004 => 'wav', 	#Wave
0x0006 => 'plt', 	#Bioware Packed Layer Texture
0x0007 => 'ini', 	#Windows INI
0x0008 => 'mp3', 	#MP3
0x0009 => 'mpg', 	#MPEG
0x000A => 'txt', 	#Text file
0x000B => 'wma', 	#Windows Media audio?
0x000C => 'wmv', 	#Windows Media video?
0x000D => 'xmv',
0x07D0 => 'plh',
0x07D1 => 'tex',
0x07D2 => 'mdl', 	#Model
0x07D3 => 'thg',
0x07D5 => 'fnt', 	#Font
0x07D7 => 'lua',
0x07D8 => 'slt',
0x07D9 => 'nss', 	#NWScript source code
0x07DA => 'ncs', 	#NWScript bytecode
0x07DB => 'mod', 	#Module
0x07DC => 'are', 	#Area (GFF)
0x07DD => 'set', 	#Tileset (unused in KOTOR?)
0x07DE => 'ifo', 	#Module information
0x07DF => 'bic', 	#Character sheet (unused)
0x07E0 => 'wok', 	# walk-mesh
0x07E1 => '2da', 	#2-dimensional array
0x07E2 => 'tlk', 	#conversation file
0x07E6 => 'txi', 	#Texture information
0x07E7 => 'git', 	#Dynamic area information, game instance file, all area and objects that are scriptable
0x07E8 => 'bti',
0x07E9 => 'uti', 	#item blueprint
0x07EA => 'btc',
0x07EB => 'utc', 	#Creature blueprint
0x07ED => 'dlg', 	#Dialogue
0x07EE => 'itp', 	#tile blueprint pallet file
0x07EF => 'btt',
0x07F0 => 'utt', 	#trigger blueprint
0x07F1 => 'dds', 	#compressed texture file
0x07F2 => 'bts',
0x07F3 => 'uts', 	#sound blueprint
0x07F4 => 'ltr', 	#letter combo probability info
0x07F5 => 'gff', 	#Generic File Format
0x07F6 => 'fac', 	#faction file
0x07F7 => 'bte',
0x07F8 => 'ute', 	#encounter blueprint
0x07F9 => 'btd',
0x07FA => 'utd', 	#door blueprint
0x07FB => 'btp',
0x07FC => 'utp', 	#placeable object blueprint
0x07FD => 'dft', 	#default values file (text-ini)
0x07FE => 'gic', 	#game instance comments
0x07FF => 'gui', 	#GUI definition (GFF)
0x0800 => 'css',
0x0801 => 'ccs',
0x0802 => 'btm',
0x0803 => 'utm', 	#store merchant blueprint
0x0804 => 'dwk', 	#door walkmesh
0x0805 => 'pwk', 	#placeable object walkmesh
0x0806 => 'btg',
0x0807 => 'utg',
0x0808 => 'jrl', 	#Journal
0x0809 => 'sav', 	#Saved game (ERF)
0x080A => 'utw', 	#waypoint blueprint
0x080B => '4pc',
0x080C => 'ssf', 	#sound set file
0x080D => 'hak', 	#Hak pak (unused)
0x080E => 'nwm',
0x080F => 'bik', 	#movie file (bik format)
0x0810 => 'ndb',        #script debugger file
0x0811 => 'ptm',        #plot manager/plot instance
0x0812 => 'ptt',        #plot wizard blueprint
0x0BB8 => 'lyt',
0x0BB9 => 'vis',
0x0BBA => 'rim', 	#See RIM File Format
0x0BBB => 'pth', 	#Path information? (GFF)
0x0BBC => 'lip',
0x0BBD => 'bwm',
0x0BBE => 'txb',
0x0BBF => 'tpc', 	#Texture
0x0BC0 => 'mdx',
0x0BC1 => 'rsv',
0x0BC2 => 'sig',
0x0BC3 => 'xbx',
0x270D => 'erf', 	#Encapsulated Resource Format
0x270E => 'bif',
0x270F => 'key');


sub new {
    #this is a generic constructor method
    my $invocant=shift;
    my $registered_path=shift;
    my $bif_ix_filter=shift;  #templates.bif=23
    my $bif_type_filter=shift;

    unless ($registered_path) {
        eval {
            my  $kotor_key= new Win32::TieRegistry "LMachine/Software/Bioware/SW/Kotor",             #read registry
                            {Access=>Win32::TieRegistry::KEY_READ, Delimiter=>"/"};
            $registered_path= $kotor_key->GetValue("Path")

            };
        if ($@) { return }  # no path found
    }
    unless (-e $registered_path.'/chitin.key') { return }

    my %r = ();
#------------
    (open (KEY, "<", $registered_path.'/chitin.key')) or (return );
    binmode (KEY);
    # read key file header
    sysread KEY, my ($filetype),4;
    unless ($filetype eq "KEY ") { close KEY; return; }
    sysseek (KEY,8,0);

    my $tmp;
    sysread KEY, $tmp, 16;
    my ($bifcount,$keycount,$offset_filetable,$offset_keytable)=unpack('V4',$tmp);
    my $bifhash={};
    for (my $i=0;$i<$keycount;$i++)
    {
        my ($resref,
            $restype,
            $resid,
            $bif_index,
            $bif_size,
            $bif_name_offset,
            $bif_name_size,
            $bif_name,
            $index_in_bif);

        sysseek (KEY,$offset_keytable+($i*22),0);
        sysread (KEY,$tmp,22);
        ($resref,$restype,$resid)=unpack('a16vV',$tmp);
        $resref=unpack('Z*',$resref);
        $bif_index=$resid >> 20;
        if (defined $bif_ix_filter) {
            unless ($bif_index == $bif_ix_filter) { next; }
        }
        if (defined $bif_type_filter) {
            unless ($res_types{$restype} eq $bif_type_filter) { next; }
        }
        $index_in_bif=$resid-($bif_index<<20);
        $r{$res_types{$restype}} .= " " . $resref . "." . $res_types{$restype};

        sysseek (KEY,$offset_filetable+($bif_index*12),0);
        sysread (KEY,$tmp,10);
        ($bif_size,$bif_name_offset,$bif_name_size)=unpack('V2v',$tmp);

        sysseek (KEY,$bif_name_offset,0);
        sysread (KEY,$tmp,$bif_name_size);
        $bif_name=unpack('Z*',$tmp);
        my $subhsh1={'Ix'=>$index_in_bif,
                     'Type_ID'=>$restype,
                     'ID'=>$resid};
        $bifhash->{$bif_name}{Resources}{"$resref.$res_types{$restype}"}=
            {'Ix'=>$index_in_bif,
             'Type_ID'=>$restype,
             'ID'=>$resid};
#        if ($resref eq "feat") { print "Resource $index_in_bif" . ":\n  Name: $resref.$res_types{$restype}\n  ID: $resid\n\n"; }
        $bifhash->{$bif_name}{Bif_Ix}=$bif_index;
    }
    close KEY;
#-------
    my $class=ref($invocant)||$invocant;
    my $self={ 'path'=>$registered_path, 'BIFs'=>$bifhash, 'Array'=>\%r};
    bless $self,$class;
    return $self;
}

sub extract_resource{
    use Win32API::File::Temp;
    my $self=shift;
    my $bifname=shift;
    my $resource_name=shift;
    unless ($bifname) {return}
    unless ($self->{BIFs}{$bifname}) {return}
    unless ($self->{BIFs}{$bifname}{Resources}{$resource_name}) {return}
    (open BIF,"<","$self->{path}/$bifname") or return;
    binmode BIF;

    my $tmpfil=Win32API::File::Temp->new();
    binmode ($tmpfil->{'fh'});
    sysseek (BIF,24+(16*($self->{BIFs}{$bifname}{Resources}{$resource_name}{Ix})),0);
    my $tmp;
    sysread BIF,$tmp,8;
    my ($res_offset, $res_size)=unpack('V2',$tmp);
    sysseek BIF, $res_offset, 0;
    sysread BIF, $tmp, $res_size;
    syswrite $tmpfil->{'fh'},$tmp;
    close BIF;
    return $tmpfil;
}

sub get_resource{
    my $self=shift;
    my $bifname=shift;
    my $resource_name=shift;

#    print "Self: $self->{path}/$bifname\nBif name: $bifname\nResource Name: $resource_name\n";

    unless ($bifname) {return}
    unless ($self->{BIFs}{$bifname}) {return}
    unless ($self->{BIFs}{$bifname}{Resources}{$resource_name}) {return}
    (open BIF,"<","$self->{path}/$bifname") or return;
    binmode BIF;
    sysseek (BIF,24+(16*($self->{BIFs}{$bifname}{Resources}{$resource_name}{Ix})),0);
    my $resource;
    sysread BIF,$resource,8;
    my ($res_offset, $res_size)=unpack('V2',$resource);
    sysseek BIF, $res_offset, 0;
    sysread BIF, $resource, $res_size;
    close BIF;
    return \$resource;
}
1;