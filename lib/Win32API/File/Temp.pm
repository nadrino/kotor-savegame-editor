#line 1 "Win32API/File/Temp.pm"
package Win32API::File::Temp;
use Win32::API;
use Fcntl;
use FileHandle;
use strict;
require Exporter;
use vars qw ($VERSION @ISA @EXPORT);

# set version
$VERSION=0.02;

@ISA    = qw(Exporter);

# export functions/variables
@EXPORT = qw( );

sub new {
    my ($invocant, $template) = @_;
    my $class=ref($invocant)||$invocant;
    
    my $fh;
    my $GetTempFileName=new Win32::API('kernel32','GetTempFileNameA','PPNP','N');
    my $GetTempPath    =new Win32::API('kernel32','GetTempPathA'    ,'NP'  ,'N');
    if(not defined $GetTempPath) {
        die "Can't import API GetTempPath: $!\n";
    }
    if(not defined $GetTempFileName) {
        die "Can't import API GetTempFileName: $!\n";
    }

    my $pathbuflen=260;
    my $pathbuf=' ' x $pathbuflen;
    my $len_returned = $GetTempPath->Call($pathbuflen,$pathbuf);
    
    $pathbuf=unpack('Z*',$pathbuf);
    $template=pack('Z*',$template);
    my $filebuf=' ' x 260;
    my $fileno = $GetTempFileName->Call($pathbuf,$template,0,$filebuf);
    unless ($fileno) { die "Could not create temp file. $!" }
    $filebuf=unpack('Z*',$filebuf);
#    $fh = new_from_fd FileHandle ($fileno,">");
    
    my $az= open ($fh, "+<", $filebuf);
#    my $success=sysopen ($fh, $filebuf, O_CREAT|O_RDWR|O_BINARY|O_TEMPORARY, 0777);
#    unless ($success) {return;}
    
    my $self={'fh'=>$fh,'fn'=>$filebuf};
    bless $self,$class;
    return $self;
}
sub DESTROY {
    my $self=shift;
    close $self->{'fh'};
    unlink $self->{'fn'};
}
1;