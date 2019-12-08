#line 1 "Bioware/TwoDA.pm"
package Bioware::TwoDA;

use strict;
require Exporter;
use vars qw ($VERSION @ISA @EXPORT);
#use File::Temp qw (tempfile);
use File::Slurp;
use IO::Scalar;

# set library version
$VERSION=0.21; #added binmode

@ISA    = qw(Exporter);

# export functions/variables
@EXPORT = qw(  );


# define globals (use vars)

#private vars
#private subs

#line 41
    
sub get_2da_rows_and_1stcol{
    my $twoda_filename = shift;
    open my ($fh),"<",$twoda_filename;
    binmode $fh;
    # header
    read $fh, my ($header_packed),9;
    my $header=unpack('a*',$header_packed);
    #if ($header =~ /2DA V2\.0/) {

    unless ($header eq '2DA V2.b'.v10) { return ();}


    my $twoda=read_file($twoda_filename);

    #null separates the rows from the columns
    my $the_null_pos=0;
    while ($twoda=~/\0/g) {
        if (!$the_null_pos) { $the_null_pos=pos $twoda }
    }
    seek $fh, $the_null_pos,0;
    #row count is next DWORD
    read $fh,my ($num_of_rows_packed),4;
    my $num_of_rows=unpack('V',$num_of_rows_packed);
    #columns are separated by tabs before the null position
    my $tab_cnt=0;
    while ($twoda=~/\t/g) {
        my $this_pos = pos $twoda;
        if ($this_pos < $the_null_pos) {
            $tab_cnt++;
        }
    }
    my $num_of_cols=$tab_cnt;



    my $count=0;
    my $after_rownames_pos=0;
    while ($twoda=~/\t/g) {
        if (pos $twoda > $the_null_pos) {
            if (++$count==$num_of_rows) {
                $after_rownames_pos=pos $twoda;
            }
        }
    }


    my $num_of_pointers = $num_of_rows * $num_of_cols; #number of pointers (words)
    my $data_area = $after_rownames_pos+($num_of_pointers * 2)+2; #this many bytes of pointers

    my $row=0;
    my %row_to_label;
    for (my $i=0; $i<$num_of_pointers; $i+=$num_of_cols) {
        my $pointer_packed;
        seek $fh,$after_rownames_pos+($i*2),0;
        read $fh,$pointer_packed,2;
        my $pointer=unpack('v',$pointer_packed);
        seek $fh,$data_area,0;
        my $t=tell $fh;
        seek $fh,$pointer,1;
        my $t1=tell $fh;
        read $fh,my ($temp_pack),500;
        my $value=unpack('Z*',$temp_pack);
        if ($value eq '') { $row++; next; }
        $row_to_label{$row}=$value;
        $row++;
    }
    close $fh;
    return %row_to_label;

}

sub new {
    #this is a generic constructor method
    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $self={ @_ };
    bless $self,$class;
    return $self;
}

sub get_column_names
{
    my @columns;
    my $self=shift;
    my $file_to_read=shift;
    if (ref $file_to_read eq 'SCALAR') { return read2da_scalar($self,$file_to_read) }
    if (ref $file_to_read eq 'GLOB')   { return read2da_fh($self,$file_to_read) }
    my %table;
    my %table2;
    my @colwidths;
    (open my ($fh),"<",$file_to_read) or return;
    binmode $fh;
    my $header;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      @columns=split /\t/,$columnchunk;     #we now have column names
    }
    return @columns;
}

sub read2da_for_spreadsheet {
#this sub receives the twoda_obj and the filename to read as parameters
    my $self=shift;
    my $file_to_read=shift;
    if (ref $file_to_read eq 'SCALAR') { return read2da_scalar($self,$file_to_read) }
    if (ref $file_to_read eq 'GLOB')   { return read2da_fh($self,$file_to_read) }
    my %table;
    my %table2;
    my @colwidths;
    (open my ($fh),"<",$file_to_read) or return;
    binmode $fh;
    my $header;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      my @columns=split /\t/,$columnchunk;     #we now have column names

      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      my @rows;
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns))+2 ;
      #print "$data_start_pos\n";
      $/="\000";
      my $rix=1;
      for my $r (@rows) {
        $table2{"$rix,0"}=$r;
        $colwidths[0]=length($r) if length($r)>$colwidths[0];
        my $cix=1;
        for my $c (@columns) {
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $table{$r}{$c}=$_;                  #we now have the data for each cell
          $colwidths[$cix]=length($_) if length($_)>$colwidths[$cix];
          $table2{"$rix,$cix"}=$_;
          $table2{"0,$cix"}=$c;
          $colwidths[$cix]=length($c) if length($c)>$colwidths[$cix];
          $cix++;

          seek $fh,$pointer_cursor,0;
        }
        $rix++;
      }
    }
    close $fh;
    return (\%table,\%table2,\@colwidths);
}
sub read2da {
#this sub receives the twoda_obj and the filename to read as parameters
    my $self=shift;
    my $file_to_read=shift;
    if (ref $file_to_read eq 'SCALAR') { return read2da_scalar($self,$file_to_read) }
    if (ref $file_to_read eq 'GLOB')   { return read2da_fh($self,$file_to_read) }
    my %table;
    (open my ($fh),"<",$file_to_read) or return;
    binmode $fh;
    my $header;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      my @columns=split /\t/,$columnchunk;#	print join "\n", @columns; print "\n";     #we now have column names
      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      my @rows;
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }

#	if($file_to_read == "placeables.2da"){	print join "\n", @rows; print "\n"; }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns))+2 ;
      #print "$data_start_pos\n";
      $/="\000";
      for my $r (@rows) {                      # Is the row of the 2da
        for my $c (@columns) {                 # Is the column name of the 2da
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $table{$r}{$c}=$_;                  #we now have the data for each cell
          seek $fh,$pointer_cursor,0;
        }
      }
    }
    close $fh;
    return \%table;
}

sub readFS
{
	our @rows;
	our @columns;
	our %table;
#this sub receives the twoda_obj and the filename to read as parameters
    my $self=shift;
    my $file_to_read=shift;
    if (ref $file_to_read eq 'SCALAR') { return read2da_scalar($self,$file_to_read) }
    if (ref $file_to_read eq 'GLOB')   { return read2da_fh($self,$file_to_read) }
#    my %table;
    (open my ($fh),"<",$file_to_read) or return;
    binmode $fh;
    my $header;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      @columns=split /\t/,$columnchunk;#	print join "\n", @columns; print "\n";     #we now have column names
      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }

#	if($file_to_read == "appearance.2da"){	print join "\n", @rows; print "\n"; }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns))+2 ;
      #print "$data_start_pos\n";
      $/="\000";
      for my $r (@rows) {                      # Is the row of the 2da
        for my $c (@columns) {                 # Is the column name of the 2da
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $table{$r}{$c}=$_;                  #we now have the data for each cell
          seek $fh,$pointer_cursor,0;
        }
      }
    }
    close $fh;
    my %s={};

	for my $zz (@columns)
	{
		$s{columns}->{"Column_$zz"}=$zz;
	}

	for my $ii (@rows)
	{
		$s{rows}->{"Row_$ii"}=$ii;
	}

#	for my $i(@rows)
#	{
#		$s{"row $i"}= $table{$i};
#	}
#	my %t={columns=>\@columns, rows=>{\%s}};

	return %s;
}

sub read2da_asarray {
    my $self=shift;
    my $file_to_read=shift;
    if (ref $file_to_read eq 'SCALAR') { return read2da_asarray_scalar($self,$file_to_read) }
    if (ref $file_to_read eq 'GLOB')   { return read2da_asarray_fh($self,$file_to_read) }

    my @table;
    
    (open my ($fh),"<",$file_to_read) or return;
    binmode $fh;
    my $header;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      my @columns=split /\t/,$columnchunk;     #we now have column names
      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      my @rows;
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns))+2 ;
      #print "$data_start_pos\n";
      $/="\000";
      for my $r (@rows) {
        my %row;
        $row{row}=$r;
        for my $c (@columns) {
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $row{$c}=$_;
          #$table{$r}{$c}=$_;                  #we now have the data for each cell
          seek $fh,$pointer_cursor,0;
        }
        push @table,\%row;
      }
      
    }
    close $fh;
    return \@table;

}
sub read2da_fh {
# this sub receives the twoda object and the open filehandle as parameters
    my $self=shift;
    my $fh=shift;
    my $header;
    my %table;
    binmode $fh;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      my @columns=split /\t/,$columnchunk;     #we now have column names
      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      my @rows;
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns)) +2;
      #print "$data_start_pos\n";
      $/="\000";
      for my $r (@rows) {
        for my $c (@columns) {
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $table{$r}{$c}=$_;                  #we now have the data for each cell
          seek $fh,$pointer_cursor,0;
        }
      }
    }
    return \%table;
}
sub read2da_asarray_fh {
# this sub receives the twoda object and the open filehandle as parameters
    my $self=shift;
    my $fh=shift;
    my $header;
    my @table;
    binmode $fh;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      my @columns=split /\t/,$columnchunk;     #we now have column names
      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      my @rows;
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns)) +2;
      #print "$data_start_pos\n";
      $/="\000";
      for my $r (@rows) {
        my %row;
        $row{row}=$r;
        for my $c (@columns) {
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $row{$c}=$_;
          seek $fh,$pointer_cursor,0;
        }
        push @table,\%row;
      }
    }
    return \@table;
}

sub read2da_scalar {
#this sub receives the twoda_obj and a scalar reference (containing the twoda) as parameters
    my $self=shift;
    my $scalar_ref=shift;
    return unless ref $scalar_ref eq 'SCALAR';
    my $fh=new IO::Scalar $scalar_ref;
    my %table;
    my $header;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      my @columns=split /\t/,$columnchunk;     #we now have column names
      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      my @rows;
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns)) +2;
      #print "$data_start_pos\n";
      $/="\000";
      for my $r (@rows) {
        for my $c (@columns) {
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $table{$r}{$c}=$_;                  #we now have the data for each cell
          seek $fh,$pointer_cursor,0;
        }
      }
    }
    close $fh;
    return \%table;

}
sub read2da_asarray_scalar {
#this sub receives the twoda_obj and a scalar reference (containing the twoda) as parameters
    my $self=shift;
    my $scalar_ref=shift;
    return unless ref $scalar_ref eq 'SCALAR';
    my $fh=new IO::Scalar $scalar_ref;
    my @table;
    my $header;
    read $fh, $header,9;
    unless ($header eq '2DA V2.b'.v10) { return ();}
    { local $/="\000";
      my $columnchunk=<$fh>;
      chop $columnchunk;
      my @columns=split /\t/,$columnchunk;     #we now have column names
      read $fh, my ($rowcnt),4;
      $rowcnt=unpack('V',$rowcnt);             #we now know the number of rows
      $/="\t";
      my @rows;
      for (1..$rowcnt) {
         $_=<$fh>;
         chop;
         push @rows, $_;                       #we now have the row headers
      }
      my $pointer_cursor;
      my $data_start_pos=tell ($fh) + (2*$rowcnt*(scalar @columns)) +2;
      #print "$data_start_pos\n";
      $/="\000";
      for my $r (@rows) {
        my %row;
        $row{row}=$r;
        for my $c (@columns) {
          read $fh,(my $p),2;
          $pointer_cursor=tell $fh;
          $p=unpack('v',$p);
          seek $fh,$data_start_pos+$p,0;
          $_=<$fh>;
          chop;
          $row{$c}=$_;
          seek $fh,$pointer_cursor,0;
        }
        push @table,\%row;
      }
    }
    close $fh;
    return \@table;

}


sub write_2da_from_spreadsheet {
    my ($self,$spreadsheet_hashref,$new_filename)=@_;
    return unless (ref $spreadsheet_hashref eq 'HASH');
    return unless $new_filename;
    (open my $fh,">",$new_filename) or return;
    binmode $fh;
    print $fh "2DA V2.b".chr(10);
    my @col_headers;
    my @row_headers;
    for my $k (keys %$spreadsheet_hashref) {
        if ($k=~/0,(\d+)/) {
          $col_headers[$1-1]=$spreadsheet_hashref->{$k};
        }
        if ($k=~/(\d+),0/) {
          $row_headers[$1-1]=$spreadsheet_hashref->{$k};
        }
    }
}
1;
#&new &read_keys &fetch_resource &insert_resource &export_resource &import_resource
