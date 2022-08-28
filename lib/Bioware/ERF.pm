#line 1 "Bioware/ERF.pm"
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::ERF; #~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#use strict;
require Exporter;
use vars qw ($VERSION @ISA @EXPORT);
$VERSION=0.21;

use IO::Uncompress::RawInflate;
use IO::Uncompress::Inflate;
use File::Copy qw(copy);
use File::Basename;
use Data::Dumper;
use Win32API::File::Temp;


#line 86

@ISA    = qw(Exporter);

# export functions/variables
@EXPORT = qw(  );


# define globals (use vars)

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


sub get_resource_id_by_name{
    #-----------------------------------------------------
    # this private sub will return the resource id
    # (which is also the index in 'resources' array)
    # given then name of the resource
    # INPUTS: resource name (incl. extension)
    # OUTPUTS: index number on success, undef on failure
    #-----------------------------------------------------
    my $self=shift;
    my $resource_name=shift;
    $resource_name= lc $resource_name;
    for my $resource (@{$self->{'resources'}}) {
        my $res_check = lc "$resource->{'res_ref'}.$resource->{'res_ext'}";
        if ($resource_name eq $res_check) {
            return $resource->{'res_id'};
        }
    }
    return undef;
}

sub get_resources_by_type
{
    my $self = shift;
    my $type = shift;

    my @resources;
    for my $resource (@{$self->{'resources'}})
    {
        if($resource->{'res_ext'} eq $type)
        { push(@resources, $resource->{'res_id'}); }
    }

    return @resources;
}

#line 234

sub new {
    #this is a generic constructor method
    

    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $self={ @_ };
    bless $self,$class;
    return $self;
}

#line 256

sub read_erf {
    #--------------------------
    #this method returns everything except acutal resource data from ERF
    #INPUTS: ERF filename
    #OUTPUTS: 1 on success, 0 on failure
    #--------------------------
    my $self=shift;
    my $erf_filename=shift;

    $self->{'isCompressed'} = 0;
    $self->{'unCompressedPath'} = $erf_filename;

    my $fh;
    open my $realfh, "<:raw", $erf_filename
      or die "Unable to open $erf_filename: $!\n";
    sysread $realfh, my $header, 10;
    if ($header eq "_ASPRCOMP_") {
        $self->{'isCompressed'} = 1;

        printf "Uncompressing ERF: ".basename($erf_filename)."...\n";
        my $inflateHandle = IO::Uncompress::Inflate->new($realfh, AutoClose => 1)
          or die "Unable to open decompression stream!\n";

        my $tempfile=Win32API::File::Temp->new();
        copy $inflateHandle, $tempfile->{'fh'};
        close $inflateHandle;

        open $fh, "<:raw", $tempfile->{'fn'};
        $self->{'erf_filename'} = $tempfile->{'fn'};
    }
    else {
        sysseek $realfh, 0, 0;
        $fh = $realfh;
        $self->{'erf_filename'}=$erf_filename;
    }

    binmode $fh;
    #header
    sysread $fh,$self->{'sig'},4;
    sysread $fh,$self->{'version'},4;
    my $tmp;
    sysread $fh,$tmp,36;
    ($self->{'localized_string_count'},
     $self->{'localized_string_size'},
     $self->{'entry_count'},
     $self->{'offset_to_localized_string'},
     $self->{'offset_to_key_list'},
     $self->{'offset_to_resource_list'},
     $self->{'build_year'},
     $self->{'build_day'},
     $self->{'description_str_ref'})=unpack('V9',$tmp);

    sysseek $fh,$self->{'offset_to_localized_string'},0;
    sysread $fh,$tmp,$self->{'localized_string_size'};
    my @localized_strings;
    for (my $localized_string_index=0; $localized_string_index<$self->{'localized_string_count'}; $localized_string_index++) {
        use bytes;
        my ($lang_id, $string)=unpack('VV/a', $tmp);
        $tmp=substr($tmp,8+length($string));
        my $hashref={'lang_id'=>$lang_id, 'string'=>$string};
        push @localized_strings, $hashref;
    }
    $self->{'localized_strings'}= [@localized_strings];

    sysseek $fh,$self->{'offset_to_key_list'},0;
    my @resources; my @files;
    if ($self->{version} eq 'V1.0') {
        for (my $resource_index=0; $resource_index<$self->{'entry_count'}; $resource_index++) {
            sysread $fh,$tmp,24;
            my ($resref, $resid, $restype)=unpack('a16V2',$tmp);
            $resref=unpack('Z*',$resref);
            my $hashref={'res_ref'=>$resref,
                         'res_id'=>$resid,
                         'res_type'=>$restype,
                         'res_ext'=>$res_types{$restype},
                         'res_offset'=>undef,
                         'res_size'=>undef};
            push @resources,$hashref; push @files, "$resref\." . $res_types{$restype};
        }
    }
    elsif ($self->{version} eq 'V1.1') {   #v1.1 has 32-char filenames
        for (my $resource_index=0; $resource_index<$self->{'entry_count'}; $resource_index++) {
            sysread $fh,$tmp,40;
            my ($resref, $resid, $restype)=unpack('a32V2',$tmp);
            $resref=unpack('Z*',$resref);
            my $hashref={'res_ref'=>$resref,
                         'res_id'=>$resid,
                         'res_type'=>$restype,
                         'res_ext'=>$res_types{$restype},
                         'res_offset'=>undef,
                         'res_size'=>undef};
            push @resources,$hashref;
        }

    }
    $self->{Files} = \@files;
    $self->{'resources'}=[@resources];

    sysseek $fh,$self->{'offset_to_resource_list'},0;
    for (my $resource_index=0; $resource_index<$self->{'entry_count'}; $resource_index++) {
        sysread $fh, $tmp, 8;
        ($self->{'resources'}[$resource_index]{'res_offset'},
         $self->{'resources'}[$resource_index]{'res_size'})=unpack('V2',$tmp);
         #(file data -> dynamic data)
         $self->{'resources'}[$resource_index]{'new_offset'}=$self->{'resources'}[$resource_index]{'res_offset'};
         $self->{'resources'}[$resource_index]{'new_size'}=$self->{'resources'}[$resource_index]{'res_size'};
    }

    # print Dumper($self);
    close $fh;
    return 1;
}
sub getfiles
{
    my $self = shift;
    my $a = $self->{Files};
#    print "Rim:\n" . join "\n", @$a;
    return $a;
}
sub get_resource_id_by_type{
    #-----------------------------------------------------
    # this private sub wil return the first resource that
    # matches the type given.
    # INPUTS: resource type(extension)'
    # OUTPUTS: index number on success, undef on failure
    #-----------------------------------------------------
    my $self = shift;
    my $type = shift;

    for my $resource (@{$self->{'resources'}}) {
        if($resource->{'res_ext'} eq $type)
        {
            my @data = ($resource->{'res_ref'} . "\.$type", $resource->{'res_id'});
            return @data;
        }
    }
    return undef;
}

#line 387

sub export_resource {
    #-----------------------
    # exports a resource to hard disk.  if the data has been 'loaded'
    #  then it will be what is written to disk.  otherwise, it will
    #  be read from 'erf_filename' and written.
    # INPUTS: resource_name, output_path
    # OUTPUTS: bytes written on success, 0 on failure
    #-----------------------

    my ($self, $resource_name, $output_path)=@_;
    return 0 unless $resource_name;

    my $resource;
    my $written;

    if (($output_path) && (substr($output_path,-1) ne "\\")) {
        $output_path .= "\\"
    }


    my $res_ix=$self->get_resource_id_by_name($resource_name);
    return 0 unless defined $res_ix;
    $resource=$self->{'resources'}[$res_ix];

    (open my ($out_fh),">",$output_path.$resource_name) or
       (return 0);
    if($resource_name =~ /\.(txi|nss|vis|lyt)/) { }
    else                                        { binmode $out_fh; }

    if ($resource->{'res_data'}) {
        syswrite $out_fh, $resource->{'res_data'}; }
    else {
        (open my ($in_fh),"<", $self->{'erf_filename'}) or
          (return 0);
        binmode $in_fh;
        sysseek $in_fh, $resource->{'res_offset'},0;
        my $tmp;
        sysread $in_fh,$tmp,$resource->{'res_size'};
        $written=syswrite $out_fh,$tmp;
        close $in_fh;
    }
    close $out_fh;
    return $written;
}

#line 438

sub export_resource_by_index {
    my ($self, $res_ix, $output_filepath)=@_;
    return 0 unless defined $res_ix;
    my $resource=$self->{'resources'}[$res_ix];
    #my $resource_name = lc "$resource->{'res_ref'}.$resource->{'res_ext'}";

    (open my ($out_fh),">",$output_filepath) or (return 0);
    if($resource_name =~ /\.(txi|nss|vis|lyt)/) { }
    else                                        { binmode $out_fh; }
    my $written;
    if ($resource->{'res_data'}) {
        $written=syswrite $out_fh, $resource->{'res_data'};
    }
    else {
        (open my ($in_fh),"<", $self->{'erf_filename'})  or (return -3);
        binmode $in_fh;
        sysseek $in_fh, $self->{'resources'}[$res_ix]{'res_offset'},0;
        my $chunk;
        my $bytes_to_read=$self->{'resources'}[$res_ix]{'res_size'};
        while ($bytes_to_read>0) {
            $bytes_to_read -= sysread $in_fh, $chunk, $bytes_to_read;
            $written += syswrite $out_fh,$chunk;
        }
        close $in_fh;
    }
    close $out_fh;

#    Added by Fair Strides for later projects. Commented out so as not to interfere with KSE.
#    my $old = $_;
#    $_ = $output_filepath;
#    /(...)$/;
#    my $t = $1;

#    $_ = $old;

#    if($t ~~ ["dlg", "utc", "utd", "ute", "uti", "utm", "utp", "uts", "utt", "utw", "fac", "are", "git", "ifo", "pth"])
#    {
#        my $gff = Bioware::GFF->new();
#        $gff->read_gff_file($output_filepath);
#        $written = $gff->write_gff_file($output_filepath);
#    }

    return $written;
}
sub export_resource_to_temp_file {
    #-----------------------
    # exports a resource to hard disk.  if the data has been 'loaded'
    #  then it will be what is written to disk.  otherwise, it will
    #  be read from 'erf_filename' and written.
    # INPUTS: resource_name, output_path
    # OUTPUTS: tempfile object
    #-----------------------

    my ($self, $resource_name)=@_;
    return 0 unless $resource_name;

    my $resource;
    my $written;



    my $res_ix=$self->get_resource_id_by_name($resource_name);
    return 0 unless defined $res_ix;

    $resource=$self->{'resources'}[$res_ix];
    my $tempfile=Win32API::File::Temp->new();
    binmode $tempfile->{'fh'};
#    my $tempfile = %tempfile;

    if ($resource->{'res_data'}) {
        syswrite $tempfile->{'fh'}, $resource->{'res_data'}; }
    else {
        (open my ($in_fh),"<", $self->{'erf_filename'}) or
          (return 0);
        binmode $in_fh;
        sysseek $in_fh, $resource->{'res_offset'},0;
        my $tmp;
        sysread $in_fh,$tmp,$resource->{'res_size'};
        $written=syswrite $tempfile->{'fh'},$tmp;
        close $in_fh;
    }
    return $tempfile;
}


#line 536

sub import_resource {

    #-------------------------
    # this method will read a resource from a file
    # and put it into the ERF. if an identical resource
    # (res_ref + res_type) exists in the erf, it will
    # be replaced.
    # INPUTS: filename, store_as
    # OUTPUTS: 1 on success, 0 on failure
    #-------------------------
    my $self=shift;
    my $new_resource_file=shift;
    my $store_as=shift;
    my $n=shift;

    return 0 unless ($new_resource_file);
    unless ($n) { $n = 0; }
    unless ($store_as) { $store_as = (split /\\/,$new_resource_file)[-1] }
    my $res_ix=$self->get_resource_id_by_name($store_as);
    (open my ($in_fh),"<",$new_resource_file) or return 0;#die "Can't: $!\n";
    binmode $in_fh;

    if (defined $res_ix) {
        sysread $in_fh,
                $self->{'resources'}[$res_ix]{'res_data'},
                (-s $in_fh);

    }
    else {
        $store_as=~/(.*)\.(.*)/;
        my $new_res_ref=$1;
        my $new_ext=$2;
        my %reversed = reverse %res_types;
        unless (exists $reversed{$new_ext}) {
            close $in_fh;
            return 0; print "Reverse failed\n";
        }
        my $new_res_type=$reversed{$new_ext};
        $res_ix=scalar @{$self->{'resources'}};
        my $new_offset=$self->{resources}[$res_ix-1]{'res_offset'}+$self->{resources}[$res_ix-1]{'res_size'};
        if($n == 1) { print "ResRef: $new_res_ref\nRes Type: $new_res_type\nRes Extension: $new_ext\nRes ID: $res_ix\nRes Size: " . (-s $in_fh) . "\n\n"; }
        my $hashref={'res_ref'=>$new_res_ref,
                     'res_id'=>$res_ix,
                     'res_type'=>$new_res_type,
                     'res_ext'=>$new_ext,
                     'res_offset'=>$new_offset,
                     'res_size'=>(-s $in_fh)};
        push @{$self->{'resources'}}, $hashref;
        sysread $in_fh,
                $self->{'resources'}[$res_ix]{'res_data'},
                (-s $in_fh);
    }
    close $in_fh;
    $self->{'resources'}[$res_ix]{'is_new'}=1;
    $self->recalculate_packing();
    return 1;
}

#line 604

sub import_resource_scalar {
    my $self=shift;
    my $resource_name_with_extension=shift;
    my $scalar=shift;
    $resource_name_with_extension=~/(.*)\.(.*)/;
    my $resref=$1;
    my $resext=$2;
    return 0 if length($resref)>16;
    my %res_types_rev=reverse %res_types;
    return 0 unless exists ($res_types_rev{$resext});

    my $res_ix=$self->get_resource_id_by_name($resource_name_with_extension);
    if (ref $scalar eq 'SCALAR') {
        $scalar=$$scalar;
    }
    elsif (ref $scalar) { #something else
        return 0;
    }
    if (defined $res_ix) {
        $self->{'resources'}[$res_ix]{'new_data'}=$scalar;
        $self->{'resources'}[$res_ix]{'new_size'}=length($scalar);
        my $i=$res_ix+1;
        my $new_offset=$self->{'resources'}[$res_ix]{'new_offset'}+length($scalar);
        while ($i<scalar @{$self->{'resources'}}) {
            $self->{'resources'}[$i]{'new_offset'}=$new_offset;
            $new_offset += $self->{'resources'}[$i]{'new_size'};
            $i++;
        }
    }
    else {
        my $new_res_type=$res_types_rev{$resext};
        $res_ix=scalar @{$self->{'resources'}};
        my $new_offset=$self->{resources}[$res_ix-1]{'res_offset'}+$self->{resources}[$res_ix-1]{'res_size'};
        my $hashref={'res_ref'=>$resref,
                     'res_id'=>$res_ix,
                     'res_type'=>$new_res_type,
                     'res_ext'=>$resext,
                     'res_offset'=>0,
                     'new_offset'=>$new_offset,
                     'res_size'=>0,
                     'new_size'=>length($scalar),
                     'new_data'=>$scalar};
        push @{$self->{'resources'}}, $hashref;
    }
    $self->{'resources'}[$res_ix]{'is_new'}=1;
    $self->recalculate_packing();
    return 1;
}

#line 665


sub load_erf {
    #-----------------
    # this method will actually load the entire erf incl. resource data
    # INPUTS: filename (optional).  if read_erf has already been called
    #   and filename is omitted, the value of 'erf_filename' will be used.
    # OUTPUTS: 1 on success, 0 on failure
    #-----------------
    my $self=shift;
    my $erf_filename=shift;
    if ($erf_filename) {
        $self->read_erf($erf_filename);
    }
    (open my ($fh), "<", $self->{'erf_filename'}) or (return 0);
    binmode $fh;

    my $resource_arr_ref=$self->{'resources'};
    my $resource;
    for $resource (@$resource_arr_ref) {
        sysseek $fh,$resource->{'res_offset'},0;
        sysread $fh,$resource->{'res_data'},$resource->{'res_size'};
        $resource->{'is_new'}=0;
    }
    $self->recalculate_packing();

    close $fh;
    return 1;
}

#line 709

sub load_erf_resource {
    #---------------------------
    # this method will load a single resource data into 'res_data' value
    # INPUTS: resource name
    # OUTPUTS: 0 or greater = resource index, <0 is failure
    #---------------------------
    my $self=shift;
    my $res_name=shift;
    return -1 unless ($res_name);
    my $res_ix=$self->get_resource_id_by_name($res_name);
    (return -2) unless defined ($res_ix);


    (open my ($in_fh),"<", $self->{'erf_filename'})  or (return -3);
    binmode $in_fh;
    sysseek $in_fh, $self->{'resources'}[$res_ix]{'res_offset'},0;
    my $total_read=sysread $in_fh,
                    $self->{'resources'}[$res_ix]{'res_data'},
                    $self->{'resources'}[$res_ix]{'res_size'};
    close $in_fh;
    $self->{'resources'}[$res_ix]{'is_new'}=0;
    $self->recalculate_packing();


    return $res_ix;

}

sub load_erf_resource_by_index {
    #---------------------------
    # this method will load a single resource data into 'res_data' value
    # INPUTS: resource name
    # OUTPUTS: 0 or greater = resource index, <0 is failure
    #---------------------------
    my $self=shift;
    my $res_ix=shift;
    my $no_recalc=shift;
    return -1 unless defined ($res_ix);

    (open my ($in_fh),"<", $self->{'erf_filename'})  or (return -3);
    binmode $in_fh;
    sysseek $in_fh, $self->{'resources'}[$res_ix]{'res_offset'},0;
    my $total_read=sysread $in_fh,
                    $self->{'resources'}[$res_ix]{'res_data'},
                    $self->{'resources'}[$res_ix]{'res_size'};
    close $in_fh;
    $self->{'resources'}[$res_ix]{'is_new'}=0;
    unless($no_recalc) {$self->recalculate_packing() }

    return $total_read;
}

#line 775

sub write_erf {
    #---------------------------------------------
    # this subroutine writes the erf from memory
    # files are packed in the order of their resource indexing
    # offsets/sizes are redefined after writing occurs
    # INPUTS:  output file, flag of whether or not to update build date
    # OUTPUTS: total bytes written on success, 0 on failure
    #---------------------------------------------
    my ($self, $output_file, $update_build)=@_;
   
   #why did I do this? vvv
   
   # my $working_output;  #we may need to read the original erf before we overwrite it.
   # unless ($output_file) { $output_file=$self->{'erf_filename'} }
   # $working_output=$output_file.'_temp';
    if ($update_build) {
        $self->{'build_year'}=(localtime)[5];
        $self->{'build_day'}=(localtime)[7];
    }

    $self->recalculate_packing();


    #(open my ($out_fh), ">", $working_output) or (return 0);
    (open my ($out_fh), ">", $output_file) or (return 0);
    binmode $out_fh;
    my $total_written=0;
    my $tmp;

    # write header

    $total_written += syswrite $out_fh, $self->{'sig'};
    $total_written += syswrite $out_fh, $self->{'version'};
    $tmp=pack('V9',($self->{'localized_string_count'},
                    $self->{'localized_string_size'},
                    $self->{'entry_count'},
                    $self->{'offset_to_localized_string'},
                    $self->{'offset_to_key_list'},
                    $self->{'offset_to_resource_list'},
                    $self->{'build_year'},
                    $self->{'build_day'},
                    $self->{'description_str_ref'},
                   ));
    $total_written += syswrite $out_fh, $tmp;
    $total_written += syswrite $out_fh, "\0" x 116;

    # write localized strings

    for my $loc_string_struct (@{$self->{'localized_strings'}}) {
        $tmp = pack('V2',$loc_string_struct->{'lang_id'},length $loc_string_struct->{'string'});
        $total_written += syswrite $out_fh, $tmp;
        $total_written += syswrite $out_fh, $loc_string_struct->{'string'};
    }

    # write key list

    for my $resource (@{$self->{'resources'}}) {
        $total_written += syswrite $out_fh, pack('a16 V V', $resource->{'res_ref'}, $resource->{'res_id'}, $resource->{'res_type'});
    }

    # write resource list

    for my $resource (@{$self->{'resources'}}) {
        $total_written += syswrite $out_fh, pack('V V', $resource->{'new_offset'}, $resource->{'new_size'});
    }

    # write resource data
    my $r = 0;
    for my $resource (@{$self->{'resources'}}) {
        if (length ($resource->{'new_data'})) {
            $resource->{'res_data'}=$resource->{'new_data'};
        }
        unless (length ($resource->{'res_data'})) {#print "F " . $resource->{'res_ref'} . "\." . $resource->{'res_ext'} . " Number: " . $resource->{'res_id'} . "\n";
            if($resource->{'res_ext'} eq 'mdx') { }
            else
            {
                my $result=$self->load_erf_resource_by_index($resource->{'res_id'},1);  #do not perform recalculation
                return $result unless $result>0;
            }
        }
        $total_written += syswrite $out_fh, $resource->{'res_data'};
        $resource->{'is_new'}=0;
        $resource->{'res_offset'}=$resource->{'new_offset'};
        $resource->{'res_size'}=$resource->{'new_size'};
$r++;
    }
    close $out_fh;

    #if (rename $working_output, $output_file) {
    #    return $total_written;
    #}
    #else {
    #    return 0;
    #}
    return $total_written;
}

#line 887

sub recalculate_packing {
    #---------------------------------------
    # this method determines the size of each res_data,
    # adjusts the res_size accordingly, and readjusts
    # res_offsets
    # INPUTS: none
    # OUTPUTS: none
    #---------------------------------------
    my $self=shift;

    # tune localized strings

    $self->{'localized_string_count'}=scalar @{$self->{'localized_strings'}};
    my $loc_string_size_total=0;
    use bytes;
    for my $loc_string_struct (@{$self->{'localized_strings'}}) {
        $loc_string_size_total += 8;
        $loc_string_size_total += length $loc_string_struct->{'string'};
    }
    $self->{'localized_string_size'}=$loc_string_size_total;
    $self->{'offset_to_key_list'}=$self->{'offset_to_localized_string'}+$self->{'localized_string_size'};

    # tune entry count

    $self->{'entry_count'}=scalar @{$self->{'resources'}};
    if ($self->{version} eq 'V1.0') {
        $self->{'offset_to_resource_list'}=$self->{'offset_to_key_list'}+(24* $self->{'entry_count'});
    }
    elsif ($self->{version} eq 'V1.1') {
        $self->{'offset_to_resource_list'}=$self->{'offset_to_key_list'}+(40* $self->{'entry_count'});
    }
    
    my $offset_to_resource_data=$self->{'offset_to_resource_list'} + (8* $self->{'entry_count'});

    # tune resource list

    my $prev_resource_offset=$offset_to_resource_data;
    my $prev_resource_length=0;
    my $prev_resource_offset_memory=$offset_to_resource_data;
    my $prev_resource_length_memory=0;
    for my $resource (@{$self->{'resources'}}) {
        $resource->{'res_offset'}=$prev_resource_offset+$prev_resource_length;
        $resource->{'new_offset'}=$prev_resource_offset_memory+$prev_resource_length_memory;
        if (length($resource->{'res_data'})) {
            $resource->{'res_size'}=length $resource->{'res_data'};
            $resource->{'new_size'}=length($resource->{'res_data'});
        }
        if (length($resource->{'new_data'})) {
            $resource->{'new_size'}=length($resource->{'new_data'});
        }
        $prev_resource_offset=$resource->{'res_offset'};
        $prev_resource_offset_memory=$resource->{'new_offset'};
        $prev_resource_length=$resource->{'res_size'};
        $prev_resource_length_memory=$resource->{'new_size'};
    }
    return;
}

#line 985


1;



__END__




#private subs
my $get_resource_id_by_name=sub {
    my $self=shift;
    my $res_name=shift;
    sysseek $self->{'fh'},16,0;
    sysread $self->{'fh'},my ($entry_count_packed),4;
    my $entry_count=unpack ('V',$entry_count_packed);
    sysseek $self->{'fh'},4,1;
    sysread $self->{'fh'},my ($entry_offset_packed),4;
    my $entry_offset=unpack('V',$entry_offset_packed);
    sysseek $self->{'fh'},$entry_offset,0;
    for (1..$entry_count) {
        sysread $self->{'fh'},my ($key_entry_packed),24;
        my ($key_fn, $key_id, $key_type) =unpack('Z16V2',$key_entry_packed);
        if ("\L$key_fn.$res_types{$key_type}" eq "\L$res_name") {
            return $key_id;
        }
    }
};
my $get_resource_count=sub {
    my $self=shift;
    sysseek $self->{'fh'},16,0;
    sysread $self->{'fh'},my ($entry_count_packed),4;
    my $entry_count=unpack ('V',$entry_count_packed);
    return $entry_count;
};
my $get_offset_to_keylist=sub {
    my $self=shift;
    sysseek $self->{'fh'},24,0;
    sysread $self->{'fh'},my ($packed),4;
    my $offset=unpack ('V',$packed);
    return $offset;
};
my $get_offset_to_resourcelist=sub {
    my $self=shift;
    sysseek $self->{'fh'},28,0;
    sysread $self->{'fh'},my ($packed),4;
    my $offset=unpack ('V',$packed);
    return $offset;
};
my $get_resource_entry_by_id=sub {
    my $self=shift;
    my $res_id=shift;
    my $res_offset=$self->$get_offset_to_resourcelist;
    sysseek $self->{'fh'},$res_offset+(8*$res_id),0;
    sysread $self->{'fh'},my ($entry_packed),8;
    my ($offset,$size)=unpack('V2',$entry_packed);
    return ($offset,$size);
};
my $increment_resource_count=sub {
    my $self=shift;
    my $new_resource_count=($self->$get_resource_count)+1;
    sysseek $self->{'fh'},16,0;
    syswrite $self->{'fh'},pack('V',$new_resource_count);
};
#public subs
sub new2 {
    my ($invocant, $sourcetype, $source, $modulename) = @_;
    my $class=ref($invocant)||$invocant;
    my $fh;
    my $erf_size=0;
    if    ($sourcetype eq 'file') {
        unless (open $fh,"+<",$source) {return; }
        binmode $fh;
        $erf_size=(-s $fh); }
    elsif ($sourcetype eq 'scalar') {
        $fh=Win32API::File::Temp->new();
         #($fh, undef)=tempfile(UNLINK=>1);
        binmode $fh;
        if ((ref $source) eq 'SCALAR') {
            $erf_size +=syswrite $fh, $$source; }
        elsif ( not ref $source ) {
            $erf_size +=syswrite $fh, $source; }
        else { return;
        }
    }
    else { return; }
    my $self={'fh'=>$fh,
              'modulename'=>$modulename  };

    bless $self,$class;
    return ($self,$erf_size);
}
sub DESTROY {
    my $self=shift;
    close $self->{'fh'};
}
sub read_keys {
    my $self=shift;
    my $entry_count=$self->$get_resource_count;
    my $entry_offset=$self->$get_offset_to_keylist;
    sysseek $self->{'fh'},$entry_offset,0;
    my @keyentries;
    for (1..$entry_count) {
        sysread $self->{'fh'},my ($key_entry_packed),24;
        my ($key_fn,undef,$key_type) =unpack('Z16V2',$key_entry_packed);
        push @keyentries,"$key_fn.$res_types{$key_type}";
    }
    return \@keyentries;
}
sub fetch_resource {  #returns a reference to a scalar that contains the requested resource
    my ($self, $resource_name)=@_;
    my $res_size_read=0;
    unless ($resource_name)   { return; }

    my $entry_count=$self->$get_resource_count;
    my $entry_offset=$self->$get_offset_to_keylist;
    my $res_offset=$self->$get_offset_to_resourcelist;
    sysseek $self->{'fh'},$entry_offset,0;
    my $res_id=$self->$get_resource_id_by_name($resource_name);
    unless (defined ($res_id)) { return; }
    sysseek $self->{'fh'},$res_offset+($res_id*8),0;
    sysread $self->{'fh'},my ($res_entry_packed),8;
    my ($res_data_offset,$res_data_size)=unpack('V2',$res_entry_packed);
    sysseek $self->{'fh'},$res_data_offset,0;
    $res_size_read+=sysread $self->{'fh'},my ($resource),$res_data_size;
    return (\$resource,$res_size_read);
}
sub export_resource { #extracts resource to hard disk, returns TRUE if successful
    my ($self, $resource_name, $fn)=@_;
    my $res_ref = $self->fetch_resource($resource_name);
    unless ($res_ref) {return;}
    unless (open TMP, ">", $fn) { return; }
    binmode TMP;
    print TMP $$res_ref;
    close TMP;
    return 1;
}
sub insert_resource { #inserts a resource from a scalar
    my ($self, $resource_name, $resource_ref, $replace, $resource_size_to_write)=@_;
    my $total_written=0;
    my $temp;
    my $new_res_id;
    my $old_res_size;
    my $old_res_offset;
    my $resource=$$resource_ref;
    my $new_res_size=do {use bytes; length $resource;};
    my $resource_preexists=0;
    my $resource_is_last=0;
    my $res_offset=$self->$get_offset_to_resourcelist;
    my $old_resource_count=$self->$get_resource_count;
    my $prev_data_len;
    my $prev_data2_len;
    my $new_module_size;
    if ($replace) {
        $new_res_id=$self->$get_resource_id_by_name($resource_name);
    }
    if (defined $new_res_id) {
        if ($new_res_id==$old_resource_count-1) {$resource_is_last=1;}
        $resource_preexists=1;
        ($old_res_offset,$old_res_size)=$self->$get_resource_entry_by_id($new_res_id); }
    else {
        $new_res_id=$self->$get_resource_count;
        $resource_is_last=1;
    }
    my $size_delta = $new_res_size - $old_res_size;
    my $old_erf_size=(-s $self->{'fh'});
    if ($resource_preexists) {
        # STEPS
        # 1. read all data that comes after the resource to be replaced
        my $tmp=Win32API::File::Temp->new();
        #my ($tmp,undef)=tempfile(UNLINK=>1);
        binmode $tmp;
        unless ($resource_is_last) {
            my ($nextres_offset,undef)=$self->$get_resource_entry_by_id($new_res_id+1);
            sysseek ($self->{'fh'},$nextres_offset,0);
            $prev_data_len=sysread $self->{'fh'},my ($other_data),$old_erf_size;
            syswrite $tmp,$other_data;
            $other_data=undef;
        }
        # 2. replace the resource
        sysseek $self->{'fh'},$old_res_offset,0;
        syswrite $self->{'fh'},$resource;
        # 3. re-write the the resources that come afterwards
        unless ($resource_is_last) {
            sysseek $tmp,0,0;
            $temp=sysread $tmp,my ($other_data),(-s $tmp);
            $prev_data2_len=syswrite $self->{'fh'},$other_data;
        }
        close $tmp;
        $new_module_size=$prev_data2_len+$new_res_size+$old_res_offset;
        # 4. truncate if not at EOF -- this doesn't work
        #unless ( eof ($self->{'fh'}) ) {
        #    my $pos=sysseek($self->{'fh'},0,1);
        #    truncate ($self->{'fh'},$pos);
        #    select((select($self->{'fh'}), $|=1 )[0]);
        #}
        # 5. update resource entries' offsets
        for (my $res_entry_to_update=$new_res_id+1;$res_entry_to_update<$old_resource_count;$res_entry_to_update++) {
            sysseek $self->{'fh'},$res_offset+(8*$res_entry_to_update),0;
            $temp=sysread $self->{'fh'},my ($res_offset_packed),4;
            my $this_res_offset=unpack('V',$res_offset_packed) +  $size_delta ;
            sysseek $self->{'fh'},-4,1;
            $temp=syswrite $self->{'fh'},pack('V',$this_res_offset);
        }
        # 6. Update this resource entries' size
        sysseek $self->{'fh'},$res_offset+($new_res_id*8)+4,0;
        syswrite $self->{'fh'},pack('V',$new_res_size);
    } else {
        # STEPS
        # 1. read resource list data, read resource data
        #my ($rld,undef)=tempfile(UNLINK=>1); binmode $rld;
        #my ($rd,undef)=tempfile(UNLINK=>1);  binmode $rd;
        my $rld=Win32API::File::Temp->new();
        my $rd=Win32API::File::Temp->new();
        sysseek $self->{'fh'},$res_offset,0;

        $temp=sysread $self->{'fh'},my ($rld_data),$old_resource_count*8;
        $temp=syswrite $rld,$rld_data;
        $rld_data=0;

        $temp=sysread $self->{'fh'},my ($rd_data),$old_erf_size;
        $temp=syswrite $rd,$rd_data;
        $rd_data=0;

        # 2. add new key entry to end of key entry list (size=24)
        sysseek $self->{'fh'},$res_offset,0;
        my %revhash=reverse %res_types;
        $resource_name=~/(.+)\.(.+)$/;
        my $new_res_name=$1;
        my $new_type=$revhash{$2};
        unless (defined $new_type) { die "unknown extension. error!" }
        $temp=syswrite $self->{'fh'},pack('a16Vv2',$new_res_name,$new_res_id,$new_type,0);

        # 3. write old resource list, shifting all offsets by 32 bytes
        sysseek $rld,0,0;
        $temp=sysread $rld,$rld_data,$old_resource_count*8;
        close $rld;
        my @datum=unpack('V'.($old_resource_count*2),$rld_data);
        $rld_data=undef;
        for (my $i=0;$i<scalar @datum;$i+=2) {  $datum[$i]+=32;   }
        $temp=syswrite $self->{'fh'},pack('V'.($old_resource_count*2),@datum);

        # 4. write new resource list entry (size=8) -- offset will be size of old erf file + 32
        $temp=syswrite $self->{'fh'},pack('V2',$old_erf_size+32,$new_res_size);

        # 5. write old resource data
        sysseek $rd,0,0;
        $temp=sysread $rd,$rd_data,(-s $rd);
        close $rd;
        $temp=syswrite $self->{'fh'},$rd_data;
        $rd_data=undef;

        # 6. write new resource data at the end
        $total_written=syswrite $self->{'fh'},$resource;

        # 7. update header: resource offset +=24
        sysseek $self->{'fh'},28,0;
        $temp=syswrite $self->{'fh'},pack('V2',$res_offset+24,$old_resource_count+1);

        # 8. update header: increment count
        $self->$increment_resource_count;
        $new_module_size=$new_res_size+$old_erf_size;
    }
    return $new_module_size;

}

sub import_resource { #inserts a resource from a file
    my ($self, $filename, $replace)=@_;
    my @shortfn=split /\\/, $filename;
    my $shortfn1=pop @shortfn;
    open R,"<",$filename;
    binmode R;
    sysread R, my ($data),(-s $filename);
    close R;
    $self->insert_resource($shortfn1,\$data,$replace);
}

1;
#&new &read_keys &fetch_resource &insert_resource &export_resource &import_resource
