#line 1 "Bioware/GFF.pm"

# Define package name
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::GFF; #~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#line 81

use strict;
use warnings;
require Exporter;
use vars qw ($VERSION @ISA @EXPORT);

use IO::Uncompress::Inflate;
use IO::Compress::Deflate qw(deflate $DeflateError) ;
use IO::File;
use File::Copy qw(copy);
use File::Basename;
use Win32API::File::Temp;
use Logger;

# set version
$VERSION=0.68; #Made more robust in the Bioware::GFF::Field::writeField sub for Lists that have only 1 or 0 structs
#0.67; #added check for array ref in get_field_ix_by_label
#0.66; #support for STRREF field (Jade Empire)
#0.65; #support for unicode RESREF, CEXOSTRING, CEXOLOCSTRING fields
@ISA    = qw(Exporter);

# export functions/variables
@EXPORT = qw(
              FIELD_BYTE
              FIELD_CHAR
              FIELD_WORD
              FIELD_SHORT
              FIELD_DWORD
              FIELD_INT
              FIELD_DWORD64
              FIELD_INT64
              FIELD_FLOAT
              FIELD_DOUBLE
              FIELD_CEXOSTRING
              FIELD_RESREF
              FIELD_CEXOLOCSTRING
              FIELD_BINARY
              FIELD_STRUCT
              FIELD_LIST
              FIELD_ORIENTATION
              FIELD_POSITION
              FIELD_STRREF
              );


# initialize globals
our %label_memory=();
our %write_info = ('fh_struct'=>undef,
                   'fh_field'=>undef,
                   'fh_label'=>undef,
                   'fh_fielddata'=>undef,
                   'struct_cnt'=>0,
                   'field_cnt'=>0,
                   'label_cnt'=>0);
our $sizeof_fieldindices=0;
our $sizeof_listindices=0;
our $list_cnt=0;
our %fieldindices_hash=();
our %listindices_hash=();

#define functions for export
############################################################################################################


sub FIELD_BYTE          {0};
sub FIELD_CHAR          {1};
sub FIELD_WORD          {2};
sub FIELD_SHORT         {3};
sub FIELD_DWORD         {4};
sub FIELD_INT           {5};
sub FIELD_DWORD64       {6};
sub FIELD_INT64         {7};
sub FIELD_FLOAT         {8};
sub FIELD_DOUBLE        {9};
sub FIELD_CEXOSTRING    {10};
sub FIELD_RESREF        {11};
sub FIELD_CEXOLOCSTRING {12};
sub FIELD_BINARY        {13};
sub FIELD_STRUCT        {14};
sub FIELD_LIST          {15};
sub FIELD_ORIENTATION   {16};
sub FIELD_POSITION      {17};
sub FIELD_STRREF        {18};

#line 169

sub new {
    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $struct0=Bioware::GFF::Struct->new('ID'=>-1, 'StructIndex'=>0);
    my $self={
              'sig'=>undef,
              'version'=>undef,
              'Main'=>$struct0,
              @_,
             };
    bless ($self,$class);
    return $self;
}


sub write_gff($$;$) {      #DEPRECATED FUNCTION...
                           #writes gff to file
                           #this function should be called by a struct, not a GFF object
    my ($struct, $fn, $fh)=@_;
    unless (ref $struct=="Bioware::GFF::Struct") {
        die "Not a Struct reference, use a different function --TK\n" . "ref: (ref $struct)"
    }
    $struct->writeStruct();
    my $total_written=$struct->writeHeader($fn,$fh);
    return $total_written;
}

sub write_gff2($) {      #writes gff to file, GFF object
                         #warning uses File::Temp!
    my ($gff, $fn)=@_;
    unless (ref $gff=="Bioware::GFF") {
        die "Not a GFF reference, use a different function --TK\n" . "ref: (ref $gff)"
    }
    my $struct=$gff->{Main};
    $struct->writeStruct2();
    my $total_written=$struct->writeHeader2($fn,$gff->{sig}.$gff->{version});
    return $total_written;
}


sub write_gff3($) {     #same as write_gff2 but uses Win32API::File::Temp
    my ($gff, $fn)=@_;
    unless (ref $gff=="Bioware::GFF") {
        die "Not a GFF reference, use a different function --TK\n" . "ref: (ref $gff)"
    }
    my $struct=$gff->{Main};
    $struct->writeStruct();
    my $total_written=$struct->writeHeader2($fn,$gff->{sig}.$gff->{version});
    return $total_written;
}

#line 230

sub read_gff_file($) {
    my ($gff, $fn)=@_;
    my $fh;
    $gff->{isCompressed} = 0;
    open my $realfh, "<:raw", $fn
      or die "Unable to open $fn: $!\n";
    read $realfh, my $header, 10;
    if ($header eq "_ASPRCOMP_") {
        $gff->{isCompressed} = 1;
        LogWarning "Uncompressing GFF: ".basename($fn)."...";
        my $inflateHandle = IO::Uncompress::Inflate->new($realfh, AutoClose => 1)
          or die "Unable to open decompression stream!\n";

        my $tempfile=Win32API::File::Temp->new();
        copy $inflateHandle, $tempfile->{'fh'};
        close $inflateHandle;

        open $fh, "<:raw", $tempfile->{'fn'};
    }
    else {
        seek $realfh, 0, 0;
        $fh = $realfh;
    }

    # (open my ($fh), "<", $fn) or (return 0);
    my $header_ref=Bioware::GFF::gffReader::Header($fh,0);
    $gff->{sig}=$$header_ref{'Signature'};
    $gff->{version}=$$header_ref{'Version'};
    Bioware::GFF::gffReader::ReadStruct($fh,$header_ref,$gff->{Main},0);
    close $fh;
    return 1;
}

sub read_gff_scalar($) {
    my ($gff, $scalar_ref)=@_;
    return unless (ref $scalar_ref eq 'SCALAR');
    use IO::Scalar;
    my $fh=new IO::Scalar $scalar_ref;
    my $header_ref=Bioware::GFF::gffReader::Header($fh,0);
    $gff->{sig}=$$header_ref{'Signature'};
    $gff->{version}=$$header_ref{'Version'};
    Bioware::GFF::gffReader::ReadStruct($fh,$header_ref,$gff->{Main},0);
    close $fh;
    return 1;
}
#line 266

sub write_gff_file($;$) {
    my ($gff, $fn, $use_native_file_temp)=@_;
    my $total_written;
    if ($use_native_file_temp) {
        $total_written=$gff->write_gff2($fn); }
    else {
        $total_written=$gff->write_gff3($fn);
    }

    if ( $gff->{isCompressed} ){
        LogWarning "Recompressing GFF file '".basename($fn)."'...";
        my $input = IO::File->new( "<$fn" )
          or die "Cannot open '$fn': $!\n" ;
        my $buffer ;
        deflate $input => \$buffer
          or die "deflate failed: $DeflateError\n";

        open my $outFh, ">", $fn
          or die "Unable to open $fn: $!\n";

        binmode $outFh;
        syswrite $outFh, "_ASPRCOMP_";
        syswrite $outFh, $buffer;
        close $outFh;
    }

    return $total_written;
}

#line 290

#line 301

sub read_gff_from_scalar($) {    #creates an struct from a gff memory stream (scalar ref)
    my $gffref=shift; unless (ref $gffref eq 'SCALAR') {return;}
    my $gff=$$gffref;
    my $fh;
    #use File::Temp qw /tempfile/;
    my $tempf=Win32API::File::Temp->new();
    $fh=$tempf->{'fh'};
    binmode $fh;
    my $tot_written=syswrite $fh,$gff;
    $gff=undef;
    sysseek $fh,0,0;
    my $struct0=read_gff($fh,0);
    close $fh;
    return ($struct0,$tot_written);
}

#line 329

sub read_gff_from_scalar2($) { #creates a Bioware::GFF::Struct object from a scalar ref
    use IO::Scalar;
    my $scalarref=shift;
    unless (ref $scalarref eq 'SCALAR') {return;}
    my $fh;
    open($fh,"<",$scalarref);
    binmode $fh;
    seek $fh,0,0;
    my $struct0=read_gff2($fh,0);
    close $fh;
    return $struct0;
}

#line 357

sub write_gff_to_scalar($$) {    #creates a memory stream from an gff struct
    my ($struct0,$sig)=@_;
    my $gff_scalar;
    %write_info=();
    $struct0->writeStruct();
    #use File::Temp qw /tempfile/;
    my $tempf=Win32API::File::Temp->new();
    my $fh=$tempf->{'fh'};
    $struct0->writeHeader(undef,$fh,$sig);
    sysseek $fh,0,0;
    sysread $fh,$gff_scalar,(-s $fh);
    close $fh;
    return \$gff_scalar;
}

#line 381

sub as_scalar() {
    use IO::Scalar;
    my $self=shift;
    my $gff_scalar;
    my $struct=$self->{Main};
    $struct->writeStructScalar;
    my $sh=new IO::Scalar \$gff_scalar;
    $struct->writeHeaderScalar(undef,$sh,undef,$self->{sig}.$self->{version});
    return $gff_scalar;
}
########################################################################################################

sub unpackquad($) {
   my( $str )= @_;
   my $big;
   if(  ! eval { $big= unpack( "Q", $str ); 1; }  ) {
       my( $lo, $hi )= unpack "LL", $str;
       $big= $lo + $hi*( 1 + ~0 );
   }
   return $big;
}
sub packquad($) {
    my $big=shift;
    my $str;
    if ( ! eval { $str=pack('Q',$big); 1; } ) {
    my $hival=$big /(2**32);
    $hival=~s/(\.\d+)$//; #drop decimal
    if ($hival<0) {$hival--;} #if neg then round down
    my $hi=pack('V',$hival);
    my $lo=pack('V',($big % (2**32)));
    $str=$lo.$hi;

    }
    return $str;
}
sub unpacksquad($) {
   my( $str )= @_;
   my $big;
   if(  ! eval { $big= unpack( "Q", $str ); 1; }  ) {
       my( $lo, $hi )= unpack "Ll", $str;
       if(  $hi < 0  ) {
           $hi= ~$hi;
           $lo= ~$lo;
           $big= -1 -$lo - $hi*( 1 + ~0 );
       } else {
           $big= $lo + $hi*( 1 + ~0 );
       }
   }
   return $big;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::GFF::CExoLocSubString; #~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new{
    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $self={
              'StringID'=>undef,
              'Value'=>undef,
              @_,
             };
    bless ($self,$class);
    return $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::GFF::CExoLocString; #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new{
    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $self={
              'StringRef'=>undef,
              'Substrings'=>[],
              @_,
             };
    bless ($self,$class);
    return $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::GFF::Field; #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub writeField;


sub new {
    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $self={
              'Type'=>undef,
              'Label'=>undef,
              'Value'=>undef,
              'FieldIndex'=>undef,
              @_,
             };
    bless ($self,$class);

    return $self;
}




sub writeField {
#Purpose: writes a field to a temporary file for fields,

    my $field=shift;
    my $type=$field->{'Type'};
    $write_info{'field_cnt'}++;
    # Write Fields' 1st DWORD
    #~~~~~~~~~~~~~~~~~~~~~~~~
    syswrite $write_info{'fh_field'}, pack ('V',$type);

    # Write Field's 2nd DWORD
    #~~~~~~~~~~~~~~~~~~~~~~~~
    if ($label_memory{$field->{'Label'}}) {                                            #if we've recorded an index for this label,
        syswrite $write_info{'fh_field'},pack ('V',$label_memory{$field->{'Label'}}); }#then use it now
    else {                                                                             #otherwise,
        syswrite $write_info{'fh_label'}, pack ('a16',$field->{'Label'});              #we create a new label entry,
        $write_info{'label_cnt'}++;                                                    #increment label count
        syswrite $write_info{'fh_field'}, pack ('V',($write_info{'label_cnt'}-1));     #write the new index=count-1
        $label_memory{$field->{'Label'}}=$write_info{'label_cnt'}-1;                   #and remember it for next time
    }


    # Write Field's 3rd DWORD
    #~~~~~~~~~~~~~~~~~~~~~~~~

    if    ($type < 6) { #byte, char, word, short, dword, int  -- all nullpadded to 4 bytes
        syswrite $write_info{'fh_field'}, pack ('V',$field->{'Value'}); }
    elsif ($type < 8) { #DWORD64, INT64
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));  #write the field data offset
        syswrite $write_info{'fh_fielddata'}, Bioware::GFF::packquad($field->{'Value'}); }
    elsif ($type ==8) { #float
        syswrite $write_info{'fh_field'}, pack ('f',$field->{'Value'}); }
    elsif ($type ==9) { #double
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));  #write the field data offset
        syswrite $write_info{'fh_fielddata'}, pack('d',$field->{'Value'});      }
    elsif ($type==10) { #CExoString
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));  #write the field data offset
        my $cexostring_packed=pack('V',length($field->{'Value'})).$field->{'Value'};
        syswrite $write_info{'fh_fielddata'}, $cexostring_packed;    }
    elsif ($type==11) { #Resref
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));   #write the field data offset
        my $resref_packed=pack('C',length($field->{'Value'})).$field->{'Value'};
        syswrite $write_info{'fh_fielddata'}, $resref_packed; }
    elsif ($type==12) { #CExoLocString
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));   #write the field data offset
        my $exolocstr=$field->{'Value'};
        my $exolocsubstr_ref=$exolocstr->{'Substrings'};
        my @exolocsubstrs=@$exolocsubstr_ref;
        my $packed_substrs = "";
        for my $exolocsubstr (@exolocsubstrs) {
            my $exolocsubstr_len=length $exolocsubstr->{'Value'};
            $packed_substrs .= pack('V V',$exolocsubstr->{'StringID'},$exolocsubstr_len). $exolocsubstr->{'Value'};
        }
        my $substrs_len=do {use bytes; length $packed_substrs; };
        syswrite $write_info{'fh_fielddata'},                                            #writing cexolocstring to fielddata
        pack('V V V',($substrs_len+8),$exolocstr->{'StringRef'},scalar @exolocsubstrs) . $packed_substrs;     }
    elsif ($type==13) { #void/binary
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));   #write the field data offset
        my $binary_length=do {use bytes; length $field->{'Value'}; };
        syswrite $write_info{'fh_fielddata'},pack('V',$binary_length).$field->{'Value'};  }#write binary data with length prefix
    elsif ($type==14) { #struct
        my $struct=$field->{'Value'};
        syswrite $write_info{'fh_field'}, pack ('V',$write_info{'struct_cnt'});          #our new struct index=current struct count because the new struct hasn't been written yet
        $struct->writeStruct();  }
    elsif ($type==15) { #list\
        my $struct_array_ref=$field->{'Value'};
        #added v0.68...
        if (ref ($struct_array_ref) =~ /Bioware/) {
            $struct_array_ref = [$struct_array_ref];
        }
        elsif ($struct_array_ref eq '') {
            $struct_array_ref = [];
        }
        #...end v0.68
        my $list_id=$list_cnt;                                                           #remember who we are
        $list_cnt++;
        syswrite $write_info{'fh_field'},pack ('V',$sizeof_listindices);                 #write the current offset of list indices
                                                                                         #we must increment the offset before writing any structs
        $sizeof_listindices += 4*(1+scalar(@$struct_array_ref));                         #each list index is a DWORD plus one for length
        my $listindices_pack=pack('V',(scalar @$struct_array_ref));                      #write first element of new list index into a new variable to keep separated
        for my $struct (@$struct_array_ref) {                                            #scroll through each struct
            $listindices_pack .=pack ('V',$write_info{'struct_cnt'});                    #write its index to our scalar
            $struct->writeStruct();                                                      #now handle writing the structure
        }
        $listindices_hash{$list_id}= $listindices_pack;   }                              #store the new list indices in global array
    elsif ( ($type==16) || ($type==17) ) { #float16 array [4] or [3]
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));   #write the field data offset
        my $float_array_ref=$field->{'Value'};
        for my $float (@$float_array_ref) {
            syswrite $write_info{'fh_fielddata'},pack('f',$float);
        }
    }
    elsif ($type==18) { #STRREF
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));  #write the field data offset
        syswrite $write_info{'fh_fielddata'},pack('V V',(4,$field->{'Value'}));          #write size (4bytes) + STRREF (4bytes)
    }

}


sub writeFieldScalar {
#Purpose: for use with writeStructScalar (memory streams) (( -s, sizeof operator, cannot be used ))

    my $field=shift;
    my $type=$field->{'Type'};
    $write_info{'field_cnt'}++;
    # Write Fields' 1st DWORD
    #~~~~~~~~~~~~~~~~~~~~~~~~
    syswrite $write_info{'fh_field'}, pack ('V',$type);

    # Write Field's 2nd DWORD
    #~~~~~~~~~~~~~~~~~~~~~~~~
    if ($label_memory{$field->{'Label'}}) {                                            #if we've recorded an index for this label,
        syswrite $write_info{'fh_field'},pack ('V',$label_memory{$field->{'Label'}}); }#then use it now
    else {                                                                             #otherwise,
        syswrite $write_info{'fh_label'}, pack ('a16',$field->{'Label'});              #we create a new label entry,
        $write_info{'label_cnt'}++;                                                    #increment label count
        syswrite $write_info{'fh_field'}, pack ('V',($write_info{'label_cnt'}-1));     #write the new index=count-1
        $label_memory{$field->{'Label'}}=$write_info{'label_cnt'}-1;                   #and remember it for next time
    }


    # Write Field's 3rd DWORD
    #~~~~~~~~~~~~~~~~~~~~~~~~

    my $temp_size=length ${$write_info{'fh_fielddata'}->sref};

    if    ($type < 6) { #byte, char, word, short, dword, int  -- all nullpadded to 4 bytes
        syswrite $write_info{'fh_field'}, pack ('V',$field->{'Value'}); }
    elsif ($type < 8) { #DWORD64, INT64
        syswrite $write_info{'fh_field'}, pack ('V',$temp_size);  #write the field data offset
        syswrite $write_info{'fh_fielddata'}, Bioware::GFF::packquad($field->{'Value'}); }
    elsif ($type ==8) { #float
        syswrite $write_info{'fh_field'}, pack ('f',$field->{'Value'}); }
    elsif ($type ==9) { #double
        syswrite $write_info{'fh_field'}, pack ('V',$temp_size);  #write the field data offset
        syswrite $write_info{'fh_fielddata'}, pack('d',$field->{'Value'});      }
    elsif ($type==10) { #CExoString
        syswrite $write_info{'fh_field'}, pack ('V',$temp_size);  #write the field data offset
        my $cexostring_packed=pack('V',length($field->{'Value'})).$field->{'Value'};
        syswrite $write_info{'fh_fielddata'}, $cexostring_packed;    }
    elsif ($type==11) { #Resref
        syswrite $write_info{'fh_field'}, pack ('V',$temp_size);   #write the field data offset
        my $resref_packed=pack('C',length($field->{'Value'})).$field->{'Value'};
        syswrite $write_info{'fh_fielddata'}, $resref_packed; }
    elsif ($type==12) { #CExoLocString
        syswrite $write_info{'fh_field'}, pack ('V',$temp_size);   #write the field data offset
        my $exolocstr=$field->{'Value'};
        my $exolocsubstr_ref=$exolocstr->{'Substrings'};
        my @exolocsubstrs=@$exolocsubstr_ref;
        my $packed_substrs = "";
        for my $exolocsubstr (@exolocsubstrs) {
            my $exolocsubstr_len=length $exolocsubstr->{'Value'};
            $packed_substrs .= pack('V V',$exolocsubstr->{'StringID'},$exolocsubstr_len). $exolocsubstr->{'Value'};
        }
        my $substrs_len=do {use bytes; length $packed_substrs; };
        syswrite $write_info{'fh_fielddata'},                                            #writing cexolocstring to fielddata
        pack('V V V',($substrs_len+8),$exolocstr->{'StringRef'},scalar @exolocsubstrs) . $packed_substrs;     }
    elsif ($type==13) { #void/binary
        syswrite $write_info{'fh_field'}, pack ('V',$temp_size);   #write the field data offset
        my $binary_length=do {use bytes; length $field->{'Value'}; };
        syswrite $write_info{'fh_fielddata'},pack('V',$binary_length).$field->{'Value'};  }#write binary data with length prefix
    elsif ($type==14) { #struct
        my $struct=$field->{'Value'};
        syswrite $write_info{'fh_field'}, pack ('V',$write_info{'struct_cnt'});          #our new struct index=current struct count because the new struct hasn't been written yet
        $struct->writeStruct();  }
    elsif ($type==15) { #list
        my $struct_array_ref=$field->{'Value'};
        my $list_id=$list_cnt;                                                           #remember who we are
        $list_cnt++;
        syswrite $write_info{'fh_field'},pack ('V',$sizeof_listindices);                 #write the current offset of list indices
                                                                                         #we must increment the offset before writing any structs
        $sizeof_listindices += 4*(1+scalar(@$struct_array_ref));                         #each list index is a DWORD plus one for length
        my $listindices_pack=pack('V',(scalar @$struct_array_ref));                      #write first element of new list index into a new variable to keep separated
        for my $struct (@$struct_array_ref) {                                            #scroll through each struct
            $listindices_pack .=pack ('V',$write_info{'struct_cnt'});                    #write its index to our scalar
            $struct->writeStructScalar();                                                #now handle writing the structure
        }
        $listindices_hash{$list_id}= $listindices_pack;   }                              #store the new list indices in global array
    elsif ( ($type==16) || ($type==17) ) { #float16 array [4] or [3]
        syswrite $write_info{'fh_field'}, pack ('V',$temp_size);   #write the field data offset
        my $float_array_ref=$field->{'Value'};
        for my $float (@$float_array_ref) {
            syswrite $write_info{'fh_fielddata'},pack('f',$float);
        }
    }
    elsif ($type==18) { #STRREF
        syswrite $write_info{'fh_field'}, pack ('V',(-s $write_info{'fh_fielddata'}));  #write the field data offset
        syswrite $write_info{'fh_fielddata'},pack('V V',(4,$field->{'Value'}));          #write size (4bytes) + STRREF (4bytes)
    }


}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::GFF::Struct; #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#use File::Temp qw /tempfile/;
sub new;
sub writeStruct;
sub writeHeader;
sub buildStruct;


#line 717

sub new {
    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $self={
              'ID'=>undef,
              'StructIndex'=>undef,
              'Fields'=>[],
              @_,
             };
    bless ($self,$class);
    return $self;
}

#line 781

sub createField {
    my $struct=shift;
    my @params=@_;
    my %testhash=@params;
    my $fields_ref = $struct->{Fields};
    my $new_field;
    if ($testhash{'Type'}==12) { #special case for CExoLocString
        my $cexoloc;
        my $cexolocsub;
        if ($testhash{'StringRef'}==-1) {
            $cexolocsub=Bioware::GFF::CExoLocSubString->new('StringID'=>0,'Value'=>$testhash{'Value'});
        }
        $cexoloc= Bioware::GFF::CExoLocString->new('StringRef'=>$testhash{'StringRef'},'Substrings'=>[$cexolocsub]);
        $new_field= Bioware::GFF::Field->new('Type'=>12,'Label'=>$testhash{'Label'},'Value'=>$cexoloc);
    } else {
        $new_field= Bioware::GFF::Field->new(@params);
    }
    if (ref ($fields_ref) eq 'Bioware::GFF::Field') { #special case -- if only one field exists, we must make this an array
        my $old_field=$fields_ref;
        $struct->{Fields}=[$old_field, $new_field];
    } elsif (ref ($fields_ref) eq 'ARRAY') {
        if (scalar (@$fields_ref) == 0) { #special case -- array is empty, we must make this a field
            $struct->{Fields}=$new_field;
        } else {
            push @{$struct->{Fields}},$new_field;
        }
    }
}

#line 818

sub deleteField{
    my $struct=shift;
    my $field_ix=shift;
    my @new_field_arr;
    my $ix=0;
    while (scalar @{$struct->{Fields}}) {
        my $field=shift @{$struct->{Fields}};
        push @new_field_arr,$field unless $ix==$field_ix;
        $ix++;
    }
    $struct->{Fields}=[@new_field_arr];
}

#line 841

sub get_field_ix_by_label {#assumes array of fields, not single field
    my $struct=shift;
    my $label=shift;
    my $ix=0;
    my $foundit=0;
    return if ref($struct->{Fields}) ne 'ARRAY';
    
    for my $field (@{$struct->{Fields}}) {
        if ($field->{Label} eq $label) {
            $foundit=1;
            last;
        }
        $ix++;
    }
    if ($foundit) {return $ix;} else {return undef;}
}
sub fbl {#shorthand for the above function
    return get_field_ix_by_label(@_);
}

sub writeStruct {

#Purpose: writes the structure to disk
#Input: self
#side effects: populates write_info and creates temp files
    my ($struct)=shift;
    unless ($write_info{'fh_struct'}) {
        $write_info{'temp_struct'}   =Win32API::File::Temp->new();
        $write_info{'fh_struct'}     =$write_info{'temp_struct'}{'fh'};

        $write_info{'temp_field'}    =Win32API::File::Temp->new();
        $write_info{'fh_field'}      =$write_info{'temp_field'}{'fh'};

        $write_info{'temp_label'}    =Win32API::File::Temp->new();
        $write_info{'fh_label'}      =$write_info{'temp_label'}{'fh'};

        $write_info{'temp_fielddata'}=Win32API::File::Temp->new();
        $write_info{'fh_fielddata'}  =$write_info{'temp_fielddata'}{'fh'};
    }
    syswrite $write_info{'fh_struct'}, pack('V',$struct->{'ID'});
    my $temp_fields_arr_ref=$struct->{'Fields'};
    my $struct_dword2;

    if (ref $temp_fields_arr_ref eq 'Bioware::GFF::Field') {
        $struct_dword2=pack('V',$write_info{'field_cnt'});
        syswrite $write_info{'fh_struct'}, $struct_dword2;
        syswrite $write_info{'fh_struct'}, pack('V',1);
        $write_info{'struct_cnt'}++;                      #we have written a stuct, so increment count
        my $field=$struct->{'Fields'};
        $field->writeField(); }
    elsif (ref $temp_fields_arr_ref eq 'ARRAY') {

        if (scalar @$temp_fields_arr_ref == 0 ) {
            $struct_dword2=pack('V',-1); }
        else {
            $struct_dword2=pack('V',$sizeof_fieldindices);
        }
                                                                            #we've written the current offset, to make sure the next struct is handled
                                                                            #properly, we have to increment the offset before writing any fields
        syswrite $write_info{'fh_struct'}, $struct_dword2;
        syswrite $write_info{'fh_struct'}, pack('V',(scalar @$temp_fields_arr_ref));
        my $struct_index=$write_info{'struct_cnt'};                          #remember who we are
        $write_info{'struct_cnt'}++;                                         #we have written a struct, so increment count

        my $fields_arr_ref=$struct->{'Fields'};
        $sizeof_fieldindices+=4*(scalar @$temp_fields_arr_ref);              #each fieldindex is a DWORD
        my $fieldindices_pack;                                               #we need to store this struct's fieldindices separate from other structs
        for my $field (@$temp_fields_arr_ref) {
            $fieldindices_pack .= pack('V',$write_info{'field_cnt'});        #write the field index (field count)
            $field->writeField();
        }
        $fieldindices_hash{$struct_index}=$fieldindices_pack;                #put in global array for safe keeping
    }

}
sub writeStruct2 {

#Purpose: writes the structure to disk
#Input: self
#side effects: populates write_info and creates temp files

#note: this version of writeStruct uses File::Temp instead of Win32API::File::Temp
# this module possibly causes SIGALARM(14) to occur on WinXP!

    use File::Temp qw/ tempfile /;
    my ($struct)=shift;
    unless ($write_info{'fh_struct'}) {
        $write_info{'fh_struct'}    =tempfile();
        $write_info{'fh_field'}     =tempfile();
        $write_info{'fh_label'}     =tempfile();
        $write_info{'fh_fielddata'} =tempfile();
        #($write_info{'fh_struct'}      ,undef)=tempfile('strXXXX',SUFFIX=>'.dat',UNLINK=>1); binmode $write_info{'fh_struct'};
        #($write_info{'fh_field'}       ,undef)=tempfile('fieXXXX',SUFFIX=>'.dat',UNLINK=>1); binmode $write_info{'fh_field'};
        #($write_info{'fh_label'}       ,undef)=tempfile('lblXXXX',SUFFIX=>'.dat',UNLINK=>1); binmode $write_info{'fh_label'};
        #($write_info{'fh_fielddata'}   ,undef)=tempfile('fdaXXXX',SUFFIX=>'.dat',UNLINK=>1); binmode $write_info{'fh_fielddata'};
}
    syswrite $write_info{'fh_struct'}, pack('V',$struct->{'ID'});
    my $temp_fields_arr_ref=$struct->{'Fields'};
    my $struct_dword2;

    if (ref $temp_fields_arr_ref eq 'Bioware::GFF::Field') {
        $struct_dword2=pack('V',$write_info{'field_cnt'});
        syswrite $write_info{'fh_struct'}, $struct_dword2;
        syswrite $write_info{'fh_struct'}, pack('V',1);
        $write_info{'struct_cnt'}++;                      #we have written a stuct, so increment count
        my $field=$struct->{'Fields'};
        $field->writeField(); }
    elsif (ref $temp_fields_arr_ref eq 'ARRAY') {

        if (scalar @$temp_fields_arr_ref == 0 ) {
            $struct_dword2=pack('V',-1); }
        else {
            $struct_dword2=pack('V',$sizeof_fieldindices);
        }
                                                                            #we've written the current offset, to make sure the next struct is handled
                                                                            #properly, we have to increment the offset before writing any fields
        syswrite $write_info{'fh_struct'}, $struct_dword2;
        syswrite $write_info{'fh_struct'}, pack('V',(scalar @$temp_fields_arr_ref));
        my $struct_index=$write_info{'struct_cnt'};                          #remember who we are
        $write_info{'struct_cnt'}++;                                         #we have written a struct, so increment count

        my $fields_arr_ref=$struct->{'Fields'};
        $sizeof_fieldindices+=4*(scalar @$temp_fields_arr_ref);              #each fieldindex is a DWORD
        my $fieldindices_pack;                                               #we need to store this struct's fieldindices separate from other structs
        for my $field (@$temp_fields_arr_ref) {
            $fieldindices_pack .= pack('V',$write_info{'field_cnt'});        #write the field index (field count)
            $field->writeField();
        }
        $fieldindices_hash{$struct_index}=$fieldindices_pack;                #put in global array for safe keeping
    }
}


sub writeStructScalar {

#Purpose: writes the structure to scalar
#Input: self
#side effects: populates write_info and creates scalar file handles
    use IO::Scalar;
    my ($struct)=shift;
    unless ($write_info{'fh_struct'}) { #create new IO scalars if not already created...
        #$write_info{'temp_struct'}   =Win32API::File::Temp->new();
        $write_info{'fh_struct'}     =new IO::Scalar;

        #$write_info{'temp_field'}    =Win32API::File::Temp->new();
        $write_info{'fh_field'}      =new IO::Scalar; #$write_info{'temp_field'}{'fh'};

        #$write_info{'temp_label'}    =Win32API::File::Temp->new();
        $write_info{'fh_label'}      =new IO::Scalar; #$write_info{'temp_label'}{'fh'};

        #$write_info{'temp_fielddata'}=Win32API::File::Temp->new();
        $write_info{'fh_fielddata'}  =new IO::Scalar; #$write_info{'temp_fielddata'}{'fh'};
    }
    syswrite $write_info{'fh_struct'}, pack('V',$struct->{'ID'});
    my $temp_fields_arr_ref=$struct->{'Fields'};
    my $struct_dword2;

    if (ref $temp_fields_arr_ref eq 'Bioware::GFF::Field') {
        $struct_dword2=pack('V',$write_info{'field_cnt'});
        syswrite $write_info{'fh_struct'}, $struct_dword2;
        syswrite $write_info{'fh_struct'}, pack('V',1);
        $write_info{'struct_cnt'}++;                      #we have written a stuct, so increment count
        my $field=$struct->{'Fields'};
        $field->writeFieldScalar(); }
    elsif (ref $temp_fields_arr_ref eq 'ARRAY') {

        if (scalar @$temp_fields_arr_ref == 0 ) {
            $struct_dword2=pack('V',-1); }
        else {
            $struct_dword2=pack('V',$sizeof_fieldindices);
        }
                                                                            #we've written the current offset, to make sure the next struct is handled
                                                                            #properly, we have to increment the offset before writing any fields
        syswrite $write_info{'fh_struct'}, $struct_dword2;
        syswrite $write_info{'fh_struct'}, pack('V',(scalar @$temp_fields_arr_ref));
        my $struct_index=$write_info{'struct_cnt'};                          #remember who we are
        $write_info{'struct_cnt'}++;                                         #we have written a struct, so increment count

        my $fields_arr_ref=$struct->{'Fields'};
        $sizeof_fieldindices+=4*(scalar @$temp_fields_arr_ref);              #each fieldindex is a DWORD
        my $fieldindices_pack;                                               #we need to store this struct's fieldindices separate from other structs
        for my $field (@$temp_fields_arr_ref) {
            $fieldindices_pack .= pack('V',$write_info{'field_cnt'});        #write the field index (field count)
            $field->writeFieldScalar();
        }
        $fieldindices_hash{$struct_index}=$fieldindices_pack;                #put in global array for safe keeping
    }

}




sub writeHeader{
    my (undef, $fn, $fh, $sig, $literal)=@_;    #input: calling struct (discarded), filename, filehandle (one or the other)
    my $total_written=0;

    if ($fn) {
        (open $fh,">",$fn) or die "$!";
    }

    #binmode $fh;
    $fh->binmode;
    if ($literal) {
        $total_written += syswrite $fh, $literal; }
    elsif ($fn=~/savenfo/i) {
        $total_written += syswrite $fh,"NFO V3.2"; }
    elsif($fn=~/party/i)  {
        $total_written +=syswrite $fh,"PT  V3.2"; }
    elsif($fn=~/globalvars/i) {
        $total_written +=syswrite $fh,"GVT V3.2"; }
    else {    #if only filehandle was supplied, we need $sig info
        if ($sig eq 'ifo') {
            $total_written +=syswrite $fh,"IFO V3.2";}
        elsif ($sig eq 'utc') {
            $total_written +=syswrite $fh,"UTC V3.2";
        }
    }
    my $struct_offset=56;
    my $field_offset=$struct_offset+(-s $write_info{'fh_struct'});
    my $label_offset=$field_offset+(-s $write_info{'fh_field'});
    my $fielddata_offset=$label_offset+(-s $write_info{'fh_label'});
    my $fieldindices_offset=$fielddata_offset+(-s $write_info{'fh_fielddata'});
    my $listindices_offset=$fieldindices_offset+$sizeof_fieldindices;

    $total_written +=syswrite $fh,pack('V12',
                     $struct_offset,      $write_info{'struct_cnt'},
                     $field_offset ,      $write_info{'field_cnt'},
                     $label_offset ,      $write_info{'label_cnt'},
                     $fielddata_offset,   (-s $write_info{'fh_fielddata'}),
                     $fieldindices_offset,$sizeof_fieldindices,
                     $listindices_offset, $sizeof_listindices);

    sysseek $write_info{'fh_struct'},0,0;
    sysread $write_info{'fh_struct'},my $struct_data,(-s $write_info{'fh_struct'});
    $total_written +=syswrite $fh,$struct_data;

    sysseek $write_info{'fh_field'},0,0;
    sysread $write_info{'fh_field'},my $field_data,(-s $write_info{'fh_field'});
    $total_written +=syswrite $fh,$field_data;

    sysseek $write_info{'fh_label'},0,0;
    sysread $write_info{'fh_label'},my $label_data,(-s $write_info{'fh_label'});
    $total_written +=syswrite $fh,$label_data;

    sysseek $write_info{'fh_fielddata'},0,0;
    sysread $write_info{'fh_fielddata'},my $fielddata_data,(-s $write_info{'fh_fielddata'});
    $total_written +=syswrite $fh,$fielddata_data;
    for my $fieldindex (sort {$a <=> $b} keys %fieldindices_hash){
        $total_written +=syswrite $fh,$fieldindices_hash{$fieldindex};
    }

    for my $listindex (sort {$a <=> $b} keys %listindices_hash){
        $total_written +=syswrite $fh,$listindices_hash{$listindex};
    }
    if ($fn) {close $fh;}  #close file if a filename was supplied instead of a filehandle
    close $write_info{'fh_struct'};
    close $write_info{'fh_field'};
    close $write_info{'fh_label'};
    close $write_info{'fh_fielddata'};
    %write_info=();
    %fieldindices_hash=();
    %listindices_hash=();
    %write_info = ('fh_struct'=>undef,
                   'fh_field'=>undef,
                   'fh_label'=>undef,
                   'fh_fielddata'=>undef,
                   'struct_cnt'=>0,
                   'field_cnt'=>0,
                   'label_cnt'=>0);
    %label_memory=();
    $list_cnt=0;
    $sizeof_listindices=0;
    $sizeof_fieldindices=0;
    return $total_written;
}
sub writeHeaderScalar{  #for use with writeStructScalar (using IO::Scalar handles)
    my (undef, $fn, $fh, $sig, $literal)=@_;    #input: calling struct (discarded), filename, filehandle (one or the other)
    my $total_written=0;

    if ($fn) {
        (open $fh,">",$fn) or die "$!";
    }


    if ($literal) {
        $total_written += syswrite $fh, $literal; }
    elsif ($fn=~/savenfo/i) {
        $total_written += syswrite $fh,"NFO V3.2"; }
    elsif($fn=~/party/i)  {
        $total_written +=syswrite $fh,"PT  V3.2"; }
    elsif($fn=~/globalvars/i) {
        $total_written +=syswrite $fh,"GVT V3.2"; }
    else {    #if only filehandle was supplied, we need $sig info
        if ($sig eq 'ifo') {
            $total_written +=syswrite $fh,"IFO V3.2";}
        elsif ($sig eq 'utc') {
            $total_written +=syswrite $fh,"UTC V3.2";
        }
    }

    my $fh_struct_len=length ${$write_info{'fh_struct'}->sref};
    my $fh_field_len=length ${$write_info{'fh_field'}->sref};
    my $fh_label_len=length ${$write_info{'fh_label'}->sref};
    my $fh_fielddata_len=length ${$write_info{'fh_fielddata'}->sref};
    my $struct_offset=56;
    my $field_offset=$struct_offset+ $fh_struct_len;
    my $label_offset=$field_offset+ $fh_field_len;
    my $fielddata_offset=$label_offset+ $fh_label_len;
    my $fieldindices_offset=$fielddata_offset+$fh_fielddata_len;
    my $listindices_offset=$fieldindices_offset+$sizeof_fieldindices;

    $total_written +=syswrite $fh,pack('V12',
                     $struct_offset,      $write_info{'struct_cnt'},
                     $field_offset ,      $write_info{'field_cnt'},
                     $label_offset ,      $write_info{'label_cnt'},
                     $fielddata_offset,   $fh_fielddata_len,
                     $fieldindices_offset,$sizeof_fieldindices,
                     $listindices_offset, $sizeof_listindices);

    #sysseek $write_info{'fh_struct'},0,0;
    #sysread $write_info{'fh_struct'},my $struct_data,length ${$write_info{'fh_struct'}->sref};
    $total_written +=syswrite $fh,${$write_info{'fh_struct'}->sref};

    #sysseek $write_info{'fh_field'},0,0;
    #sysread $write_info{'fh_field'},my ($field_data),$fh_field_len;
    $total_written +=syswrite $fh,${$write_info{'fh_field'}->sref};

    #sysseek $write_info{'fh_label'},0,0;
    #sysread $write_info{'fh_label'},my ($label_data),$fh_label_len;
    $total_written +=syswrite $fh,${$write_info{'fh_label'}->sref};

    #sysseek $write_info{'fh_fielddata'},0,0;
    #sysread $write_info{'fh_fielddata'},my ($fielddata_data),(-s $write_info{'fh_fielddata'});
    $total_written +=syswrite $fh,${$write_info{'fh_fielddata'}->sref};
    for my $fieldindex (sort {$a <=> $b} keys %fieldindices_hash){
        $total_written +=syswrite $fh,$fieldindices_hash{$fieldindex};
    }

    for my $listindex (sort {$a <=> $b} keys %listindices_hash){
        $total_written +=syswrite $fh,$listindices_hash{$listindex};
    }
    if ($fn) {close $fh;}  #close file if a filename was supplied instead of a filehandle
    close $write_info{'fh_struct'};
    close $write_info{'fh_field'};
    close $write_info{'fh_label'};
    close $write_info{'fh_fielddata'};
    %write_info=();
    %fieldindices_hash=();
    %listindices_hash=();
    %write_info = ('fh_struct'=>undef,
                   'fh_field'=>undef,
                   'fh_label'=>undef,
                   'fh_fielddata'=>undef,
                   'struct_cnt'=>0,
                   'field_cnt'=>0,
                   'label_cnt'=>0);
    %label_memory=();
    $list_cnt=0;
    $sizeof_listindices=0;
    $sizeof_fieldindices=0;
    return $total_written;
}



sub writeHeader2{                #for use with File::Temp or Win32API::File::Temp
    my (undef, $fn, $sig)=@_;    #input: calling struct (discarded), filename, filehandle (one or the other)
    my $total_written=0;
    (open my ($fh),">",$fn) or die "Could not open $fn for writing.";


    binmode $fh;
    $total_written += syswrite $fh, $sig;

    my $struct_offset=56;
    my $field_offset=$struct_offset+(-s $write_info{'fh_struct'});
    my $label_offset=$field_offset+(-s $write_info{'fh_field'});
    my $fielddata_offset=$label_offset+(-s $write_info{'fh_label'});
    my $fieldindices_offset=$fielddata_offset+(-s $write_info{'fh_fielddata'});
    my $listindices_offset=$fieldindices_offset+$sizeof_fieldindices;

    $total_written +=syswrite $fh,pack('V12',
                     $struct_offset,      $write_info{'struct_cnt'},
                     $field_offset ,      $write_info{'field_cnt'},
                     $label_offset ,      $write_info{'label_cnt'},
                     $fielddata_offset,   (-s $write_info{'fh_fielddata'}),
                     $fieldindices_offset,$sizeof_fieldindices,
                     $listindices_offset, $sizeof_listindices);

    sysseek $write_info{'fh_struct'},0,0;
    sysread $write_info{'fh_struct'},my $struct_data,(-s $write_info{'fh_struct'});
    $total_written +=syswrite $fh,$struct_data;

    #open my ($temp_fh),"<",$write_info{'temp_field'}{'fn'};
    sysseek $write_info{'fh_field'},0,0;
    sysread $write_info{'fh_field'},my $field_data,(-s $write_info{'fh_field'});
    $total_written +=syswrite $fh,$field_data;

    sysseek $write_info{'fh_label'},0,0;
    sysread $write_info{'fh_label'},my $label_data,(-s $write_info{'fh_label'});
    $total_written +=syswrite $fh,$label_data;

    sysseek $write_info{'fh_fielddata'},0,0;
    sysread $write_info{'fh_fielddata'},my $fielddata_data,(-s $write_info{'fh_fielddata'});
    $total_written +=syswrite $fh,$fielddata_data;
    for my $fieldindex (sort {$a <=> $b} keys %fieldindices_hash){
        $total_written +=syswrite $fh,$fieldindices_hash{$fieldindex};
    }

    for my $listindex (sort {$a <=> $b} keys %listindices_hash){
        $total_written +=syswrite $fh,$listindices_hash{$listindex};
    }
    if ($fn) {close $fh;}  #close file if a filename was supplied instead of a filehandle
    close $write_info{'fh_struct'};
    close $write_info{'fh_field'};
    close $write_info{'fh_label'};
    close $write_info{'fh_fielddata'};
    %write_info=();
    %fieldindices_hash=();
    %listindices_hash=();
    %write_info = ('fh_struct'=>undef,
                   'fh_field'=>undef,
                   'fh_label'=>undef,
                   'fh_fielddata'=>undef,
                   'struct_cnt'=>0,
                   'field_cnt'=>0,
                   'label_cnt'=>0);
    %label_memory=();
    $list_cnt=0;
    $sizeof_listindices=0;
    $sizeof_fieldindices=0;
    return $total_written;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::GFF::gffReader; #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub Readgff;
sub Header;
sub ReadStruct;
sub ReadFields;
sub ReadField;
sub ReadLabel;

sub Readgff {

#Purpose to read entire gff file into memory and store with objStructs and objFields
#Inputs: a filehandle opened for read access at the header position, offset from beginning of SAV file if any
#Outputs: ref to populated struct0
    my ($fh, $sav_offset)=@_;
    my $header_ref=Header($fh,$sav_offset);
    my $struct0=Bioware::GFF::Struct->new();
    ReadStruct($fh,$header_ref,$struct0,0);
    return $struct0;
}
sub Readgff2 {

#Purpose to read entire gff file into memory and store with objStructs and objFields
#Inputs: a filehandle opened for read access at the header position, offset from beginning of SAV file if any
#Outputs: ref to populated struct0
    my ($fh, $sav_offset)=@_;
    my $header_ref=Header2($fh,$sav_offset);
    my $struct0=Bioware::GFF::Struct->new();
    ReadStruct2($fh,$header_ref,$struct0,0);
    return $struct0;
}
sub Header {
#Purpose to read gff header into memory
#Inputs: a filehandle opened for read access at the header position, offset from beginning of SAV file if any
#Outputs: ref to header hash
    my ($fh,$extra_offset)=@_;
    my $header_packed;
    sysread $fh,$header_packed,56;
    my %hh;
    ($hh{'Signature'}, $hh{'Version'},$hh{'StructOffset'},$hh{'StructCount'},
     $hh{'FieldOffset'},$hh{'FieldCount'},$hh{'LabelOffset'},$hh{'LabelCount'},
     $hh{'FieldDataOffset'},$hh{'FieldDataSize'},$hh{'FieldIndicesOffset'},
     $hh{'FieldIndicesSize'},$hh{'ListIndicesOffset'},$hh{'ListIndicesSize'})
      =unpack('a4a4V12',$header_packed);
    $hh{'gffOffset'}=$extra_offset;
    return \%hh;
}
sub Header2 {
#Purpose to read gff header into memory
#Inputs: a filehandle opened for read access at the header position, offset from beginning of SAV file if any
#Outputs: ref to header hash
    my ($fh,$extra_offset)=@_;
    my $header_packed;
    read $fh,$header_packed,56;
    my %hh;
    ($hh{'Signature'}, $hh{'Version'},$hh{'StructOffset'},$hh{'StructCount'},
     $hh{'FieldOffset'},$hh{'FieldCount'},$hh{'LabelOffset'},$hh{'LabelCount'},
     $hh{'FieldDataOffset'},$hh{'FieldDataSize'},$hh{'FieldIndicesOffset'},
     $hh{'FieldIndicesSize'},$hh{'ListIndicesOffset'},$hh{'ListIndicesSize'})
      =unpack('a4a4V12',$header_packed);
    $hh{'gffOffset'}=$extra_offset;
    return \%hh;
}
sub ReadStruct {
#Purpose: populates struct object with data
#Inputs: fh, headerhashref, struct object, struct index
#Outputs: none
    my ($fh, $hhr, $struct, $struct_index)=@_;
    my ($struct_packed);
    sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'StructOffset'}+($struct_index*12),0;
    sysread $fh, $struct_packed,12;
    my ($struct_type,$struct_dataoffset,$struct_fieldcount)=unpack('V3',$struct_packed);

    $struct->{'ID'}=$struct_type;
    $struct->{'StructIndex'}=$struct_index;
    if ($struct_fieldcount>1) {
        $struct->{'Fields'}=ReadFields($fh, $hhr, $struct, $struct_dataoffset, $struct_fieldcount) }
    elsif ($struct_fieldcount==1) {
        $struct->{'Fields'}=ReadField($fh, $hhr, $struct_dataoffset) }
    return;
}
sub ReadStruct2 {
#Purpose: populates struct object with data
#Inputs: fh, headerhashref, struct object, struct index
#Outputs: none
    my ($fh, $hhr, $struct, $struct_index)=@_;
    my ($struct_packed);
    seek $fh, $hhr->{'gffOffset'}+$hhr->{'StructOffset'}+($struct_index*12),0;
    read $fh, $struct_packed,12;
    my ($struct_type,$struct_dataoffset,$struct_fieldcount)=unpack('V3',$struct_packed);

    $struct->{'ID'}=$struct_type;
    $struct->{'StructIndex'}=$struct_index;
    if ($struct_fieldcount>1) {
        $struct->{'Fields'}=ReadFields2($fh, $hhr, $struct, $struct_dataoffset, $struct_fieldcount) }
    elsif ($struct_fieldcount==1) {
        $struct->{'Fields'}=ReadField2($fh, $hhr, $struct_dataoffset) }
    return;
}
sub ReadFields{
#Purpose: to return array reference of field objects for a structure
#Inputs: fh, headerhashref, struct object, struct's field data offset, struct's field count
#Outputs: reference to array of field objects
    my ($fh, $hhr, $struct, $fielddata_offset, $fieldcount)=@_;
    sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldIndicesOffset'}+$fielddata_offset,0;
    my ($field_indices_packed,$field_index);
    sysread $fh, $field_indices_packed, 4*$fieldcount;
    my @field_indices=unpack('V'.$fieldcount,$field_indices_packed);
    my @objFields=();
    foreach $field_index (@field_indices) {
        push @objFields, ReadField($fh, $hhr, $field_index);
    }
    return \@objFields;
}
sub ReadFields2{
#Purpose: to return array reference of field objects for a structure
#Inputs: fh, headerhashref, struct object, struct's field data offset, struct's field count
#Outputs: reference to array of field objects
    my ($fh, $hhr, $struct, $fielddata_offset, $fieldcount)=@_;
    seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldIndicesOffset'}+$fielddata_offset,0;
    my ($field_indices_packed,$field_index);
    read $fh, $field_indices_packed, 4*$fieldcount;
    my @field_indices=unpack('V'.$fieldcount,$field_indices_packed);
    my @objFields=();
    foreach $field_index (@field_indices) {
        push @objFields, ReadField2($fh, $hhr, $field_index);
    }
    return \@objFields;
}

sub ReadField{
#Purpose: to create a populated field object for a given field index
#Inputs: fh, headerhashref, field index
#Outputs: field object
    my ($fh, $hhr, $field_index)=@_;
    my ($field_packed,$field_data);
    my $objField=Bioware::GFF::Field->new( 'FieldIndex'=>$field_index );
    sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldOffset'}+(12*$field_index),0;
    sysread $fh, $field_packed,8;
    sysread $fh, $field_data,4;
    my ($field_type, $label_index)=unpack('V2',$field_packed);

    $objField->{'Label'}=ReadLabel($fh,$hhr,$label_index);
    #$objField->{'Type'}=$data_types{$field_type};
    $objField->{'Type'}=$field_type;
    if ( ($field_type<3)||($field_type==4)) {   #BYTE, CHAR, WORD, DWORD
        my $data=unpack('V',$field_data);#print "Label: " . $objField->{'Label'} . " Type: $field_type Data: $data\n";
        $objField->{'Value'}=$data; }
    elsif ($field_type==3) { #SHORT
        my $data=unpack('s',$field_data);
        $objField->{'Value'}=$data; }
    elsif ($field_type==5) { #INT
        my $data=unpack('i',$field_data);
        $objField->{'Value'}=$data; }
    elsif ($field_type==6) { #DWORD64
        my $data_packed;
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh, $data_packed,8;
        $objField->{'Value'}=Bioware::GFF::unpackquad($data_packed); }
    elsif ($field_type==7) { #INT64
        my $data_packed;
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh, $data_packed,8;
        $objField->{'Value'}=Bioware::GFF::unpacksquad($data_packed);  }
    elsif ($field_type==8) { #float
        my $data=unpack('f',$field_data);
        $objField->{'Value'}=$data; }
    elsif ($field_type==9) { #double
        my $data_packed;
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh, $data_packed,8;
        $objField->{'Value'}=unpack('d',$data_packed);  }
    elsif ($field_type==10) { #CExoString
        my ($data,$data_length_packed);
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh, $data_length_packed,4;
        sysread $fh, $data,unpack('V',$data_length_packed);
        $objField->{'Value'}=$data; }
    elsif ($field_type==11) { #ResRef
        my $data_length_packed;
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh, $data_length_packed,17;
        $objField->{'Value'}=unpack('C/a',$data_length_packed); }
    elsif ($field_type==12) { #CExoLocString
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        my $objCExoLocString=Bioware::GFF::CExoLocString->new();
        my ($data_length_packed,$exo_string_packed,$stringcount,$substrings);
        sysread $fh, $data_length_packed,4;
        sysread $fh, $exo_string_packed,unpack('V',$data_length_packed);
        ($objCExoLocString->{'StringRef'},$stringcount,$substrings)=unpack('lVa*',$exo_string_packed);
        my @substr_arr=();
        for (my $i=0; $i<$stringcount; $i++) {
            my $str_len;
            my $objSubStr=Bioware::GFF::CExoLocSubString->new();
            ($objSubStr->{'StringID'},$str_len)=unpack('V2',$substrings);
            $substrings=substr($substrings,4);
            $objSubStr->{'Value'}=unpack('V/a',$substrings);
            $substrings=substr($substrings,4+$str_len);
            push @substr_arr,$objSubStr;
        }
        $objCExoLocString->{'Substrings'}=\@substr_arr;
        $objField->{'Value'}=$objCExoLocString; }
    elsif ($field_type==13) { #VOID/binary
        my ($size_packed,$data_size);
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;

        sysread $fh, $size_packed,4;
        $data_size=unpack('V',$size_packed);
        my $data_position=sysseek $fh,0,1;          #need this for inplace edits later
        sysread $fh, $objField->{'Value'},$data_size;
        $objField->{'Location'}= $data_position;  } #this is an extra hash key

        #sysread $fh, my ($binary_temp),$data_size;
        #$objField->{'Value'}=$binary_temp; }
    elsif ($field_type==14) { #struct
        my $struct=Bioware::GFF::Struct->new();
        ReadStruct($fh,$hhr,$struct,unpack('V',$field_data));
        $objField->{'Value'}=$struct; }
    elsif ($field_type==15) { #list
        my ($number_of_struct_indices_packed, $struct_indices_packed);
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'ListIndicesOffset'}+unpack('V',$field_data),0;
        sysread $fh, $number_of_struct_indices_packed,4;
        my $number_of_struct_indices=unpack('V',$number_of_struct_indices_packed);
        sysread $fh, $struct_indices_packed,4*$number_of_struct_indices;
        my @struct_indices=unpack('V'.$number_of_struct_indices,$struct_indices_packed);
        my @struct_arr=();
        for my $struct_index (@struct_indices) {
            my $struct=Bioware::GFF::Struct->new();
            ReadStruct($fh,$hhr,$struct,$struct_index);
            push @struct_arr,$struct;
        }
        $objField->{'Value'}=\@struct_arr; }
    elsif ($field_type==16) { #float array [4]
        my $data_packed;
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh, $data_packed,16;
        $objField->{'Value'}=[unpack('f4',$data_packed)] ;  }
    elsif ($field_type==17) { #float array [3]
        my $data_packed;
        sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh, $data_packed,12;
        $objField->{'Value'}=[unpack('f3',$data_packed)] ;
    }
    elsif ($field_type==18) { #STRREF
        my $data_packed;
        sysseek $fh,$hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        sysread $fh,$data_packed,8;
        (undef,$objField->{'Value'})=unpack('V2',$data_packed);
    }
    return $objField;
}
sub ReadField2{
#Purpose: to create a populated field object for a given field index
#Inputs: fh, headerhashref, field index
#Outputs: field object
    my ($fh, $hhr, $field_index)=@_;
    my ($field_packed,$field_data);
    my $objField=Bioware::GFF::Field->new( 'FieldIndex'=>$field_index );
    seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldOffset'}+(12*$field_index),0;
    read $fh, $field_packed,8;
    read $fh, $field_data,4;
    my ($field_type, $label_index)=unpack('V2',$field_packed);

    $objField->{'Label'}=ReadLabel2($fh,$hhr,$label_index);
    #$objField->{'Type'}=$data_types{$field_type};
    $objField->{'Type'}=$field_type;
    if ( ($field_type<3)||($field_type==4)) {   #BYTE, CHAR, WORD, DWORD
        my $data=unpack('V',$field_data);
        $objField->{'Value'}=$data; }
    elsif ($field_type==3) { #SHORT
        my $data=unpack('s',$field_data);
        $objField->{'Value'}=$data; }
    elsif ($field_type==5) { #INT
        my $data=unpack('i',$field_data);
        $objField->{'Value'}=$data; }
    elsif ($field_type==6) { #DWORD64
        my $data_packed;
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh, $data_packed,8;
        $objField->{'Value'}=Bioware::GFF::unpackquad($data_packed); }
    elsif ($field_type==7) { #INT64
        my $data_packed;
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh, $data_packed,8;
        $objField->{'Value'}=Bioware::GFF::unpacksquad($data_packed);  }
    elsif ($field_type==8) { #float
        my $data=unpack('f',$field_data);
        $objField->{'Value'}=$data; }
    elsif ($field_type==9) { #double
        my $data_packed;
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh, $data_packed,8;
        $objField->{'Value'}=unpack('d',$data_packed);  }
    elsif ($field_type==10) { #CExoString
        my ($data,$data_length_packed);
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh, $data_length_packed,4;
        read $fh, $data,unpack('V',$data_length_packed);
        $objField->{'Value'}=$data; }
    elsif ($field_type==11) { #ResRef
        my $data_length_packed;
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh, $data_length_packed,17;
        $objField->{'Value'}=unpack('C/a',$data_length_packed); }
    elsif ($field_type==12) { #CExoLocString
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        my $objCExoLocString=Bioware::GFF::CExoLocString->new();
        my ($data_length_packed,$exo_string_packed,$stringcount,$substrings);
        read $fh, $data_length_packed,4;
        read $fh, $exo_string_packed,unpack('V',$data_length_packed);
        ($objCExoLocString->{'StringRef'},$stringcount,$substrings)=unpack('lVa*',$exo_string_packed);
        my @substr_arr=();
        for (my $i=0; $i<$stringcount; $i++) {
            my $str_len;
            my $objSubStr=Bioware::GFF::CExoLocSubString->new();
            ($objSubStr->{'StringID'},$str_len)=unpack('V2',$substrings);
            $substrings=substr($substrings,4);
            $objSubStr->{'Value'}=unpack('V/a',$substrings);
            $substrings=substr($substrings,4+$str_len);
            push @substr_arr,$objSubStr;
        }
        $objCExoLocString->{'Substrings'}=\@substr_arr;
        $objField->{'Value'}=$objCExoLocString; }
    elsif ($field_type==13) { #VOID/binary
        my ($size_packed,$data_size);
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;

        read $fh, $size_packed,4;
        $data_size=unpack('V',$size_packed);
        my $data_position=seek $fh,0,1;          #need this for inplace edits later
        read $fh, $objField->{'Value'},$data_size;
        $objField->{'Location'}= $data_position;  } #this is an extra hash key

        #read $fh, my ($binary_temp),$data_size;
        #$objField->{'Value'}=$binary_temp; }
    elsif ($field_type==14) { #struct
        my $struct=Bioware::GFF::Struct->new();
        ReadStruct2($fh,$hhr,$struct,unpack('V',$field_data));
        $objField->{'Value'}=$struct; }
    elsif ($field_type==15) { #list
        my ($number_of_struct_indices_packed, $struct_indices_packed);
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'ListIndicesOffset'}+unpack('V',$field_data),0;
        read $fh, $number_of_struct_indices_packed,4;
        my $number_of_struct_indices=unpack('V',$number_of_struct_indices_packed);
        read $fh, $struct_indices_packed,4*$number_of_struct_indices;
        my @struct_indices=unpack('V'.$number_of_struct_indices,$struct_indices_packed);
        my @struct_arr=();
        for my $struct_index (@struct_indices) {
            my $struct=Bioware::GFF::Struct->new();
            ReadStruct2($fh,$hhr,$struct,$struct_index);
            push @struct_arr,$struct;
        }
        $objField->{'Value'}=\@struct_arr; }
    elsif ($field_type==16) { #float array [4]
        my $data_packed;
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh, $data_packed,16;
        $objField->{'Value'}=[unpack('f4',$data_packed)] ;  }
    elsif ($field_type==17) { #float array [3]
        my $data_packed;
        seek $fh, $hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh, $data_packed,12;
        $objField->{'Value'}=[unpack('f3',$data_packed)] ;
    }
    elsif ($field_type==18) { #STRREF
        my $data_packed;
        seek $fh,$hhr->{'gffOffset'}+$hhr->{'FieldDataOffset'}+unpack('V',$field_data),0;
        read $fh,$data_packed,8;
        (undef,$objField->{'Value'})=unpack('V2',$data_packed);
    }

    return $objField;
}

sub ReadLabel{
#Purpose returns a label for a field
#Inputs: $fh, $hhr, $label_index
#Outputs: label
    my ($fh,$hhr,$label_index)=@_;
    my $label_packed;
    sysseek $fh, $hhr->{'gffOffset'}+$hhr->{'LabelOffset'}+($label_index*16),0;
    sysread $fh, $label_packed,16;
    my $label=unpack('Z*',$label_packed);
    return $label;
}
sub ReadLabel2{
#Purpose returns a label for a field
#Inputs: $fh, $hhr, $label_index
#Outputs: label
    my ($fh,$hhr,$label_index)=@_;
    my $label_packed;
    seek $fh, $hhr->{'gffOffset'}+$hhr->{'LabelOffset'}+($label_index*16),0;
    read $fh, $label_packed,16;
    my $label=unpack('Z*',$label_packed);
    return $label;
}


#line 1719

1;