#line 1 "Bioware/TPC.pm"
# Define package name
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Bioware::TPC; #~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
use strict;
use IO::Scalar;
require Exporter;
use vars qw ($VERSION @ISA @EXPORT);

# set version
$VERSION=0.02;
@ISA    = qw(Exporter);

# export functions/variables
@EXPORT = qw();

# initialize globals
# our %label_memory=();


#define functions for export
############################################################################################################
sub new {
    my $invocant=shift;
    my $class=ref($invocant)||$invocant;
    my $self={
              @_,
             };
    bless ($self,$class);
    return $self;
}
sub read_tpc {
    my $self=shift;
    my $file_to_read=shift;
    if (ref $file_to_read eq 'SCALAR') { return read_tpc_scalar($self,$file_to_read) }
    if (ref $file_to_read eq 'GLOB')   { binmode $file_to_read; return read_tpc_fh($self,$file_to_read) }
    my $fh;
    open $fh,"<",$file_to_read or return 0;
	binmode $fh;
    $self->read_tpc_fh($fh);
    close $fh;
    return;
}
sub write_tga {
	my $self=shift;
	my $file_to_write=shift;
	if (ref $file_to_write eq 'SCALAR') { return write_tga_scalar($self,$file_to_write) }
    if (ref $file_to_write eq 'GLOB')   { binmode $file_to_write; return write_tga_fh($self,$file_to_write) }
	unless ($file_to_write)  { $file_to_write = $self->{name} .".tga" }
	open my $fh, ">", $file_to_write or return 0;
	binmode $fh;
	my $result=$self->write_tga_fh($fh);
	close $fh;
	return $result;
}
sub write_tga_scalar {
    my $self=shift;
    my $scalar_ref=shift;
    return unless ref $scalar_ref eq 'SCALAR';
    my $fh=new IO::Scalar $scalar_ref;
	my $result=$self->write_tga_fh($fh);
	close $fh;
	return $result;
}
sub write_tga_fh {
	my $self=shift;
	my $fh=shift;
	my $bits_per_pixel=32;
    $bits_per_pixel=24 if (($self->{tpc}{header}{data_size}==0) && ($self->{tpc}{header}{encoding}==2));
	my $tga_header=pack('C3 v2 C v4 C2',(0,0,2,
	                                       0,0,
										     0,
										 0,0,$self->{tpc}{header}{xsize},$self->{tpc}{header}{ysize},
										 $bits_per_pixel,0));
	my $bytes_written = syswrite $fh,$tga_header;
	my $ysz = $self->{tpc}{header}{ysize};
	my $pitch = $self->{tpc}{header}{xsize};
	my $pixel_ref=$self->{tpc}{pixels};
	my @pixels = @$pixel_ref;
	for (my $i = 0; $i < $ysz; $i++) {
		my $ix=$pitch*($ysz-$i-1);
		if ($bits_per_pixel==32) {
			$bytes_written += syswrite $fh,pack('V' x $pitch, @pixels[$ix..$ix+$pitch]);
		}
		else {
			my $packed_longs=pack('V' x $pitch, @pixels[$ix..$ix+$pitch]);
			my @bytes=unpack('C4'x$pitch,$packed_longs);
			my @bytes2;
			for (my $i=0; $i<scalar @bytes; $i++) {
				unless (($i+1) % 4 ==0)  {
					push @bytes2, $bytes[$i];
				}
			}
			my $packed_slice=pack('C'x scalar @bytes2, @bytes2);
			$bytes_written+=syswrite $fh,$packed_slice;
		}
	}
	return $bytes_written;
}

sub read_tpc_scalar {
    my $self=shift;
    my $scalar_ref=shift;
    return unless ref $scalar_ref eq 'SCALAR';
    my $fh=new IO::Scalar $scalar_ref;
    $self->read_tpc_fh($fh);
    close $fh;
    return;
}
sub read_tpc_fh {
    my $self=shift;
    my $fh=shift;
    sysseek $fh, 0, 0;

    my $tpc_header_packed;
    sysread $fh, $tpc_header_packed,128;

    #u32 data_size PACKED;  //1-4
	#u32 reserved PACKED;   //5-8
	#u16 xsize PACKED;      //9-10
 	#u16 ysize PACKED;      //11-12
	#u8 encoding PACKED;    //13
	#u8 dummy[115] PACKED;  //14-128

    my ($hdr_data_size,$hdr_reserved,$hdr_xsize,$hdr_ysize,$hdr_encoding)=unpack('VVvvC',$tpc_header_packed);
    $self->{tpc}{header}{data_size}=$hdr_data_size;
    $self->{tpc}{header}{reserved}=$hdr_reserved;
    $self->{tpc}{header}{xsize}=$hdr_xsize;
    $self->{tpc}{header}{ysize}=$hdr_ysize;
    $self->{tpc}{header}{encoding}=$hdr_encoding;

    my @pixels;
    $#pixels=($hdr_xsize * $hdr_ysize)-1;
#void decode_rgba(tpc_file *file, FILE *fp) {
#	for (u32 y = file->hdr.ysize; y; --y) {
#		u32 off = file->hdr.xsize * (y-1);
#		fread(file->pixels + off, 4, file->hdr.ysize, fp);
#		for (u32 x = 0; x < file->hdr.xsize; ++x) {
#			file->pixels[off+x] = bgra32_to_rgba32(file->pixels[off+x]);
#		}
#	}
#}


    if (($hdr_data_size==0) & ($hdr_encoding==2)) {
        for (my $y=$hdr_ysize; $y; --$y) {
            my $off=$hdr_xsize*($y-1);
            my $this_line_packed;
            sysread ($fh,$this_line_packed,3*($hdr_ysize));
			my @bytes=unpack('C3'x$hdr_ysize,$this_line_packed);
			my @bytes2;
			my $j;
			for (my $i=0; $i<scalar @bytes; $i++) {
				if (($i % 3 == 0) & ($i>0)) {
					$bytes2[$j]=0;
					$j++;
				}
				$bytes2[$j]=$bytes[$i];
				$j++;
			}
			$bytes2[$j]=0;
			$this_line_packed=pack('C'x scalar @bytes2,@bytes2);
			@pixels[$off..$off+$hdr_ysize]=unpack('V'x$hdr_ysize,$this_line_packed);
            for (my $x=0; $x<$hdr_xsize; ++$x) {
                $pixels[$off+$x]=bgr24_to_rgb24($pixels[$off+$x]);
            }
        }
        $self->{tpc}{pixels}=[@pixels];
        return scalar @pixels;
    }
	if (($hdr_data_size==0) & ($hdr_encoding==4)) {
	    for (my $y=$hdr_ysize; $y>0; $y--) {
			my $off=$hdr_xsize*($y-1);
			my $this_line_packed;
			sysread ($fh,$this_line_packed,4*($hdr_ysize));
			@pixels[$off..$off+$hdr_ysize]=unpack('V'x$hdr_ysize,$this_line_packed);
			for (my $x=0; $x<$hdr_xsize; $x++) {
                $pixels[$off+$x]=bgra32_to_rgba32($pixels[$off+$x]);
            }
		}
		$self->{tpc}{pixels}=[@pixels];
		return scalar @pixels;
	}
    if ($hdr_encoding==2) {
		$self->decode_dxt1($fh);
    }
    elsif ($hdr_encoding==4) {
		$self->decode_dxt5($fh);
    }
	return scalar @{$self->{tpc}{pixels}};
}
sub bgra32_to_rgba32 { #function not method
    my $color=shift;
	my $a=($color & 0xFF000000)>>24;
	my $r=($color & 0x00FF0000)>>16;
	my $g=($color & 0x0000FF00)>>8;
	my $b=($color & 0x000000FF);
	my $newcolor=($a<<24) | ($b<<16) | ($g<<8) | ($r);
#	return $color & 0xFF00FF00 | ($color&0x00FF0000)>>16 | ($color&0x000000FF)<<16;
	return $newcolor;
}
sub bgr24_to_rgb24 {
   my $color=shift;
	my $b=($color & 0xFF0000)>>16;
	my $g=($color & 0x00FF00)>>8;
	my $r=($color & 0x0000FF);
	my $newcolor=($r<<16) | ($g<<8) | ($b);
}
sub decode_dxt1 {
	my $self=shift;
	my $fh=shift;
	my ($color_0, $color_1, $tex_pixels);
	my $tex_packed;
	my @blended;
	my @pixels;
	my $pitch=$self->{tpc}{header}{xsize};
	for (my $ty=$self->{tpc}{header}{ysize}; $ty; $ty -=4) {
		for (my $tx=0; $tx<$self->{tpc}{header}{xsize}; $tx+=4) {
			sysread $fh, $tex_packed,8;
			($color_0,$color_1,$tex_pixels)=unpack('vvV',$tex_packed);
			my $cpx=reverse_bytes($tex_pixels);
			if ($color_0>$color_1) {
				$blended[0]=rgb565_to_rgba32($color_0);
				$blended[1]=rgb565_to_rgba32($color_1);
				$blended[2]=interpolate_rgba32(0.333333, $blended[0], $blended[1]);
				$blended[3]=interpolate_rgba32(0.666666, $blended[0], $blended[1]);
			}
			else {
				$blended[0]=rgb565_to_rgba32($color_0);
				$blended[1]=rgb565_to_rgba32($color_1);
				$blended[2]=interpolate_rgba32(0.5, $blended[0], $blended[1]);
				$blended[3]=0;
			}
			for (my $y=0; $y<4; $y++) {
				for (my $x=0; $x<4; $x++) {
					my $px = $cpx & 3;
					$pixels[($ty-4+$y)*$pitch +($tx+$x)]=$blended[$px];
					$cpx >>=2;
				}
			}
		}
	}
	$self->{tpc}{pixels}=[@pixels];
}
sub reverse_bytes {
	my $in=shift;
	return unpack('V',pack('C4',reverse (unpack('C4',pack('V',$in)))));
}
sub rgb565_to_rgba32 {
	my $color=shift;
	return  (($color&0x1F)<<3)              # blue
		    | ((($color>>5)&0x3F)<<10)      # green
				| ((($color>>11)&0x1F)<<19) # red
				| 0xFF000000;               # alpha
}
sub interpolate_rgba32 {
	my ($weight, $color_0, $color_1)=@_;
	my ($r,$g,$b,$a);
	$r=sprintf('%u',((1-$weight)*($color_0 & 0xFF))+(($weight) * ($color_1 & 0xFF)));
	$g=sprintf('%u',((1-$weight)*(($color_0 & 0xFF00)>>8))+(($weight) * (($color_1 & 0xFF00)>>8)));
	$b=sprintf('%u',((1-$weight)*(($color_0 & 0xFF0000)>>16))+(($weight) * (($color_1 & 0xFF0000)>>16)));
	$a=sprintf('%u',((1-$weight)*(($color_0 & 0xFF000000)>>24))+(($weight) * (($color_1 & 0xFF000000)>>24)));
	return rgba32($r,$g,$b,$a);
}
sub rgba32 {
	my ($r, $g, $b, $a) =@_;
	return $r | $g<<8 | $b<<16 | $a<<24;
}
sub decode_dxt5 {
	my $self=shift;
	my $fh=shift;
	my ($color_0, $color_1, $tex_pixels);
	my ($alpha_0, $alpha_1);
	my @alphabl;
	my @alphab;
	my @blended;
	my $tex_packed;
	my @pixels;
	my $pitch=$self->{tpc}{header}{xsize};
	for (my $ty=$self->{tpc}{header}{ysize}; $ty; $ty -=4) {
		for (my $tx=0; $tx<$self->{tpc}{header}{xsize}; $tx+=4) {
			sysread $fh,$tex_packed,16;
			($alpha_0,$alpha_1,@alphabl[0..5],$color_0,$color_1,$tex_pixels)
			  =unpack('C C C6 v v V',$tex_packed);
			my $cpx=reverse_bytes($tex_pixels);
			$alphab[0]=$alpha_0;
			$alphab[1]=$alpha_1;
			if ($alpha_0 > $alpha_1) {
				$alphab[2] = sprintf("%u",((6 * $alphab[0] + 1 * $alphab[1] + 3) / 7));
				$alphab[3] = sprintf("%u",((5 * $alphab[0] + 2 * $alphab[1] + 3) / 7));
				$alphab[4] = sprintf("%u",((4 * $alphab[0] + 3 * $alphab[1] + 3) / 7));
				$alphab[5] = sprintf("%u",((3 * $alphab[0] + 4 * $alphab[1] + 3) / 7));
				$alphab[6] = sprintf("%u",((2 * $alphab[0] + 6 * $alphab[1] + 3) / 7));
				$alphab[7] = sprintf("%u",((1 * $alphab[0] + 6 * $alphab[1] + 3) / 7));
			}
			else {
				$alphab[2] = sprintf("%u",((4 * $alphab[0] + 1 * $alphab[1] + 2) / 5));
				$alphab[3] = sprintf("%u",((3 * $alphab[0] + 2 * $alphab[1] + 2) / 5));
				$alphab[4] = sprintf("%u",((2 * $alphab[0] + 3 * $alphab[1] + 2) / 5));
				$alphab[5] = sprintf("%u",((1 * $alphab[0] + 4 * $alphab[1] + 2) / 5));
				$alphab[6] = 0;
				$alphab[7] = 255;
			}
			$blended[0] = rgb565_to_rgba32($color_0) & 0x00FFFFFF;
			$blended[1] = rgb565_to_rgba32($color_1) & 0x00FFFFFF;
			$blended[2] = interpolate_rgba32(0.333333, $blended[0], $blended[1]);
			$blended[3] = interpolate_rgba32(0.666666, $blended[0], $blended[1]);
			my $conva=compose_bits(@alphabl);
			for (my $y=0; $y<4; $y++) {
				for (my $x=0; $x<4; $x++) {
					my $px=$cpx & 3;
					my $alpha=$alphab[($conva>>(3*(4*(3-$y)+$x)))&7];
					$pixels[ ($ty-4+$y)*$pitch + ($tx+$x) ] = $blended[$px] | ($alpha<<24);
					$cpx >>= 2;
				}
			}
		}
	}
	$self->{tpc}{pixels}=[@pixels];
}
sub compose_bits {
	my @b=@_;
	return $b[0] + 256 * ($b[1] + 256 * ($b[2] + 256 * ($b[3] + 256 * ($b[4] + 256 * $b[5]))));
}
1;