#line 1 "Win32/FileOp.pm"
package Win32::FileOp;

use vars qw($VERSION);
$Win32::FileOp::VERSION = '0.16.02';

use Win32::API;
use File::Find;
use File::Path;
use File::DosGlob qw(glob);
use Cwd;
use strict;
use warnings;
no warnings 'uninitialized';
use Carp;

use Data::Lazy;
use File::Spec;
sub Relative2Absolute {#inplace
	foreach (@_) {
		$_ = File::Spec->rel2abs($_)
	}
}
sub RelativeToAbsolute {
	if (@_ == 1) {
		return File::Spec->rel2abs($_[0]);
	}
	my @list = @_;
	foreach (@list) {
		$_ = File::Spec->rel2abs($_)
	}
	return @list;
}


require Exporter;
@Win32::FileOp::ISA = qw(Exporter);

$Win32::FileOp::BufferSize = 65534;

my @FOF_flags = qw(
	FOF_SILENT FOF_RENAMEONCOLLISION FOF_NOCONFIRMATION FOF_ALLOWUNDO
	FOF_FILESONLY FOF_SIMPLEPROGRESS FOF_NOCONFIRMMKDIR FOF_NOERRORUI
	FOF_NOCOPYSECURITYATTRIBS FOF_MULTIDESTFILES FOF_CREATEPROGRESSDLG
);

my @OFN_flags = qw(
	OFN_READONLY OFN_OVERWRITEPROMPT OFN_HIDEREADONLY OFN_NOCHANGEDIR OFN_SHOWHELP
	OFN_ENABLEHOOK OFN_ENABLETEMPLATE OFN_ENABLETEMPLATEHANDLE OFN_NOVALIDATE
	OFN_ALLOWMULTISELECT OFN_EXTENSIONDIFFERENT OFN_PATHMUSTEXIST OFN_FILEMUSTEXIST
	OFN_CREATEPROMPT OFN_SHAREAWARE OFN_NOREADONLYRETURN OFN_NOTESTFILECREATE
	OFN_NONETWORKBUTTON OFN_NOLONGNAMES OFN_EXPLORER OFN_NODEREFERENCELINKS
	OFN_LONGNAMES OFN_SHAREFALLTHROUGH OFN_SHARENOWARN OFN_SHAREWARN
);

my @BIF_flags = qw(
	BIF_RETURNONLYFSDIRS BIF_DONTGOBELOWDOMAIN BIF_STATUSTEXT BIF_RETURNFSANCESTORS
	BIF_BROWSEFORCOMPUTER BIF_BROWSEFORPRINTER BIF_BROWSEINCLUDEFILES
	BIF_EDITBOX BIF_VALIDATE BIF_NEWDIALOGSTYLE BIF_USENEWUI BIF_BROWSEINCLUDEURLS
	BIF_UAHINT BIF_NONEWFOLDERBUTTON BIF_NOTRANSLATETARGETS BIF_SHAREABLE
);

my @CSIDL_flags = qw(
	CSIDL_DESKTOP CSIDL_PROGRAMS CSIDL_CONTROLS CSIDL_PRINTERS CSIDL_PERSONAL
	CSIDL_FAVORITES CSIDL_STARTUP CSIDL_RECENT CSIDL_SENDTO CSIDL_BITBUCKET
	CSIDL_STARTMENU CSIDL_DESKTOPDIRECTORY CSIDL_DRIVES CSIDL_NETWORK CSIDL_NETHOOD
	CSIDL_FONTS CSIDL_TEMPLATES CSIDL_COMMON_STARTMENU CSIDL_COMMON_PROGRAMS
	CSIDL_COMMON_STARTUP CSIDL_COMMON_DESKTOPDIRECTORY CSIDL_APPDATA CSIDL_PRINTHOOD
);

my @CONNECT_flags = qw(
	CONNECT_UPDATE_PROFILE CONNECT_UPDATE_RECENT CONNECT_TEMPORARY CONNECT_INTERACTIVE
	CONNECT_PROMPT CONNECT_NEED_DRIVE CONNECT_REFCOUNT CONNECT_REDIRECT CONNECT_LOCALDRIVE
	CONNECT_CURRENT_MEDIA CONNECT_DEFERRED CONNECT_RESERVED
);

my @SW_flags = qw(
	SW_HIDE SW_MAXIMIZE SW_MINIMIZE SW_RESTORE SW_SHOW
	SW_SHOWDEFAULT SW_SHOWMAXIMIZED SW_SHOWMINIMIZED
	SW_SHOWMINNOACTIVE SW_SHOWNA SW_SHOWNOACTIVATE SW_SHOWNORMAL
);

@Win32::FileOp::EXPORT = (
 qw(  Recycle RecycleConfirm RecycleConfirmEach RecycleEx
      Delete DeleteConfirm DeleteConfirmEach DeleteEx
      Copy CopyConfirm CopyConfirmEach CopyEx
      Move MoveConfirm MoveConfirmEach MoveEx
      MoveAtReboot DeleteAtReboot MoveFile MoveFileEx CopyFile
      FillInDir UpdateDir
      FindInPATH FindInPath Relative2Absolute RelativeToAbsolute
      AddToRecentDocs EmptyRecentDocs
	  ReadINISectionKeys ReadINISections
      WriteToINI WriteToWININI ReadINI ReadWININI DeleteFromINI DeleteFromWININI
      OpenDialog SaveAsDialog BrowseForFolder
      recycle
      DesktopHandle GetDesktopHandle WindowHandle GetWindowHandle
      Compress Uncompress UnCompress Compressed SetCompression GetCompression CompressedSize CompressDir UncompressDir UnCompressDir
      Map Connect Unmap Disconnect Mapped
      Subst Unsubst Substed SubstDev
	  GetLargeFileSize GetDiskFreeSpace ShellExecute ShellExecuteEx
 ),
 @FOF_flags,
 @OFN_flags,
 @BIF_flags,
 @CSIDL_flags,
 @SW_flags
);
#     FOF_CONFIRMMOUSE FOF_WANTMAPPINGHANDLE

*Win32::FileOp::EXPORT_OK = [@Win32::FileOp::EXPORT, @CONNECT_flags];

%Win32::FileOp::EXPORT_TAGS = (
    INI => [qw( ReadINISectionKeys ReadINISections WriteToINI WriteToWININI ReadINI ReadWININI DeleteFromINI DeleteFromWININI )],
    DIALOGS => [qw( OpenDialog SaveAsDialog BrowseForFolder),
               @OFN_flags, @BIF_flags, @CSIDL_flags],
    _DIALOGS => [@OFN_flags, @BIF_flags, @CSIDL_flags],
    HANDLES => [qw( DesktopHandle GetDesktopHandle WindowHandle GetWindowHandle )],
    BASIC => [qw(
               Delete DeleteConfirm DeleteConfirmEach DeleteEx
               Copy CopyConfirm CopyConfirmEach CopyEx
               Move MoveConfirm MoveConfirmEach MoveEx
               MoveAtReboot DeleteAtReboot MoveFile MoveFileEx CopyFile
             ),
             @FOF_flags],
    _BASIC => [@FOF_flags],
    RECENT => [qw(AddToRecentDocs EmptyRecentDocs)],
    DIRECTORY => [qw(UpdateDir FillInDir)],
    COMPRESS => [qw(Compress Uncompress UnCompress Compressed SetCompression GetCompression CompressedSize CompressDir UncompressDir UnCompressDir)],
    MAP => [qw(Map Connect Unmap Disconnect Mapped)],
	_MAP => \@CONNECT_flags,
    SUBST => [qw(Subst Unsubst Substed SubstDev)],
	EXECUTE => ['ShellExecute ShellExecuteEx', @SW_flags],
	_EXECUTE => \@SW_flags,
);


use vars qw($ReadOnly $DesktopHandle $fileop $ProgressTitle);
$Win32::FileOp::DesktopHandle = 0;
$Win32::FileOp::WindowHandle = 0;
sub Win32::FileOp::GetDesktopHandle;
sub Win32::FileOp::GetWindowHandle;
$Win32::FileOp::ProgressTitle = '';

sub FO_MOVE     () { 0x01 }
sub FO_COPY     () { 0x02 }
sub FO_DELETE   () { 0x03 }
sub FO_RENAME   () { 0x04 }

sub FOF_CREATEPROGRESSDLG     () { 0x0000 } # default
sub FOF_MULTIDESTFILES        () { 0x0001 } # more than one dest for files
#sub FOF_CONFIRMMOUSE         () { 0x0002 } # not implemented
sub FOF_SILENT                () { 0x0004 } # don't create progress/report
sub FOF_RENAMEONCOLLISION     () { 0x0008 } # rename if coliding
sub FOF_NOCONFIRMATION        () { 0x0010 } # Don't prompt the user.
#sub FOF_WANTMAPPINGHANDLE    () { 0x0020 } # Fill in FILEOPSTRUCT.hNameMappings
sub FOF_ALLOWUNDO             () { 0x0040 } # recycle bin instead of delete
sub FOF_FILESONLY             () { 0x0080 } # on *.*, do only files
sub FOF_SIMPLEPROGRESS        () { 0x0100 } # means don't show names of files
sub FOF_NOCONFIRMMKDIR        () { 0x0200 } # don't confirm making needed dirs
sub FOF_NOERRORUI             () { 0x0400 } # don't put up error UI
sub FOF_NOCOPYSECURITYATTRIBS () { 0x0800 } # dont copy file Security Attributes

sub MOVEFILE_REPLACE_EXISTING   () { 0x00000001 }
sub MOVEFILE_COPY_ALLOWED       () { 0x00000002 }
sub MOVEFILE_DELAY_UNTIL_REBOOT () { 0x00000004 }

sub OFN_READONLY              () { 0x00000001}
sub OFN_OVERWRITEPROMPT       () { 0x00000002}
sub OFN_HIDEREADONLY          () { 0x00000004}
sub OFN_NOCHANGEDIR           () { 0x00000008}
sub OFN_SHOWHELP              () { 0x00000010}
sub OFN_ENABLEHOOK            () { #0x00000020;
    carp "OFN_ENABLEHOOK not implemented" }
sub OFN_ENABLETEMPLATE        () { #0x00000040;
    carp "OFN_ENABLEHOOK not implemented" }
sub OFN_ENABLETEMPLATEHANDLE  () { #0x00000080;
    carp "OFN_ENABLEHOOK not implemented" }
sub OFN_NOVALIDATE            () { 0x00000100}
sub OFN_ALLOWMULTISELECT      () { 0x00000200}
sub OFN_EXTENSIONDIFFERENT    () { 0x00000400}
sub OFN_PATHMUSTEXIST         () { 0x00000800}
sub OFN_FILEMUSTEXIST         () { 0x00001000}
sub OFN_CREATEPROMPT          () { 0x00002000}
sub OFN_SHAREAWARE            () { 0x00004000}
sub OFN_NOREADONLYRETURN      () { 0x00008000}
sub OFN_NOTESTFILECREATE      () { 0x00010000}
sub OFN_NONETWORKBUTTON       () { 0x00020000}
sub OFN_NOLONGNAMES           () { 0x00040000} # // force no long names for 4.x modules
                                               #if(WINVER >() { 0x0400)
sub OFN_EXPLORER              () { 0x00080000} # // new look commdlg
sub OFN_NODEREFERENCELINKS    () { 0x00100000}
sub OFN_LONGNAMES             () { 0x00200000} # // force long names for 3.x modules

sub OFN_SHAREFALLTHROUGH  () { 2}
sub OFN_SHARENOWARN       () { 1}
sub OFN_SHAREWARN         () { 0}


sub BIF_RETURNONLYFSDIRS   () { 0x0001 } #// For finding a folder to start document searching
sub BIF_DONTGOBELOWDOMAIN  () { 0x0002 } #// For starting the Find Computer
sub BIF_STATUSTEXT         () { 0x0004 } # Includes a status area in the dialog box.
      # The callback function can set the status text
      # by sending messages to the dialog box.

sub BIF_EDITBOX	() { 0x0010 } # Add an editbox to the dialog
sub BIF_VALIDATE	() { 0x0020 } # insist on valid result (or CANCEL)

sub BIF_NEWDIALOGSTYLE	() { 0x0040 } # Use the new dialog layout with the ability to resize
                                        # Caller needs to call OleInitialize() before using this API

sub BIF_USENEWUI	() { (BIF_NEWDIALOGSTYLE | BIF_EDITBOX) }

sub BIF_BROWSEINCLUDEURLS	() { 0x0080 } # Allow URLs to be displayed or entered. (Requires BIF_USENEWUI)
sub BIF_UAHINT	() { 0x0100 } # Add a UA hint to the dialog, in place of the edit box. May not be combined with BIF_EDITBOX
sub BIF_NONEWFOLDERBUTTON	() { 0x0200 } # Do not add the "New Folder" button to the dialog.  Only applicable with BIF_NEWDIALOGSTYLE.
sub BIF_NOTRANSLATETARGETS	() { 0x0400 } # don't traverse target as shortcut

sub BIF_RETURNFSANCESTORS  () { 0x0008 }
sub BIF_BROWSEFORCOMPUTER  () { 0x1000 } # Browsing for Computers.
sub BIF_BROWSEFORPRINTER   () { 0x2000 } # Browsing for Printers
sub BIF_BROWSEINCLUDEFILES () { 0x4000 } # Browsing for Everything
sub BIF_SHAREABLE	() { 0x8000 } # sharable resources displayed (remote shares, requires BIF_USENEWUI)

#BIF_BROWSEFORCOMPUTER	Only returns computers. If the user selects
#anything other than a computer, the OK button is grayed.

#BIF_BROWSEFORPRINTER	Only returns printers. If the user selects
#anything other than a printer, the OK button is grayed.

#BIF_DONTGOBELOWDOMAIN	Does not include network folders below the
#domain level in the tree view control.

#BIF_RETURNFSANCESTORS	Only returns file system ancestors. If the user
#selects anything other than a file system ancestor, the OK button is
#grayed.

#BIF_RETURNONLYFSDIRS	Only returns file system directories. If the
#user selects folders that are not part of the file system, the OK button
#is grayed.

#BIF_STATUSTEXT	Includes a status area in the dialog box. The callback
#function can set the status text by sending messages to the dialog box.

sub CSIDL_DESKTOP                   () { 0x0000 }
sub CSIDL_PROGRAMS                  () { 0x0002 }
sub CSIDL_CONTROLS                  () { 0x0003 }
sub CSIDL_PRINTERS                  () { 0x0004 }
sub CSIDL_PERSONAL                  () { 0x0005 }
sub CSIDL_FAVORITES                 () { 0x0006 }
sub CSIDL_STARTUP                   () { 0x0007 }
sub CSIDL_RECENT                    () { 0x0008 }
sub CSIDL_SENDTO                    () { 0x0009 }
sub CSIDL_BITBUCKET                 () { 0x000a }
sub CSIDL_STARTMENU                 () { 0x000b }
sub CSIDL_DESKTOPDIRECTORY          () { 0x0010 }
sub CSIDL_DRIVES                    () { 0x0011 }
sub CSIDL_NETWORK                   () { 0x0012 }
sub CSIDL_NETHOOD                   () { 0x0013 }
sub CSIDL_FONTS                     () { 0x0014 }
sub CSIDL_TEMPLATES                 () { 0x0015 }
sub CSIDL_COMMON_STARTMENU          () { 0x0016 }
sub CSIDL_COMMON_PROGRAMS           () { 0x0017 }
sub CSIDL_COMMON_STARTUP            () { 0x0018 }
sub CSIDL_COMMON_DESKTOPDIRECTORY   () { 0x0019 }
sub CSIDL_APPDATA                   () { 0x001a }
sub CSIDL_PRINTHOOD                 () { 0x001b }

#=rem
#sub FILE_SHARE_READ                 () { 0x00000001  }
#sub FILE_SHARE_WRITE                () { 0x00000002  }
#sub FILE_SHARE_DELETE               () { 0x00000004  }
#
#sub FILE_FLAG_WRITE_THROUGH         () { 0x80000000 }
#sub FILE_FLAG_OVERLAPPED            () { 0x40000000 }
#sub FILE_FLAG_NO_BUFFERING          () { 0x20000000 }
#sub FILE_FLAG_RANDOM_ACCESS         () { 0x10000000 }
#sub FILE_FLAG_SEQUENTIAL_SCAN       () { 0x08000000 }
#sub FILE_FLAG_DELETE_ON_CLOSE       () { 0x04000000 }
#sub FILE_FLAG_BACKUP_SEMANTICS      () { 0x02000000 }
#sub FILE_FLAG_POSIX_SEMANTICS       () { 0x01000000 }
#
#
#sub CREATE_NEW          () { 1 }
#sub CREATE_ALWAYS       () { 2 }
#sub OPEN_EXISTING       () { 3 }
#sub OPEN_ALWAYS         () { 4 }
#sub TRUNCATE_EXISTING   () { 5 }
#=cut

sub DDD_RAW_TARGET_PATH         () { 0x00000001 }
sub DDD_REMOVE_DEFINITION       () { 0x00000002 }
sub DDD_EXACT_MATCH_ON_REMOVE   () { 0x00000004 }
sub DDD_NO_BROADCAST_SYSTEM     () { 0x00000008 }

sub CONNECT_UPDATE_PROFILE () {0x00000001}
sub CONNECT_UPDATE_RECENT () {0x00000002}
sub CONNECT_TEMPORARY () {0x00000004}
sub CONNECT_INTERACTIVE () {0x00000008}
sub CONNECT_PROMPT () {0x00000010}
sub CONNECT_NEED_DRIVE () {0x00000020}
sub CONNECT_REFCOUNT () {0x00000040}
sub CONNECT_REDIRECT () {0x00000080}
sub CONNECT_LOCALDRIVE () {0x00000100}
sub CONNECT_CURRENT_MEDIA () {0x00000200}
sub CONNECT_DEFERRED () {0x00000400}
sub CONNECT_RESERVED () {0xFF000000}

sub SW_HIDE () { 0 }
sub SW_SHOWNORMAL () { 1 }
sub SW_NORMAL () { 1 }
sub SW_SHOWMINIMIZED () { 2 }
sub SW_SHOWMAXIMIZED () { 3 }
sub SW_MAXIMIZE () { 3 }
sub SW_SHOWNOACTIVATE () { 4 }
sub SW_SHOW () { 5 }
sub SW_MINIMIZE () { 6 }
sub SW_SHOWMINNOACTIVE () { 7 }
sub SW_SHOWNA () { 8 }
sub SW_RESTORE () { 9 }
sub SW_SHOWDEFAULT () { 10 }
sub SW_FORCEMINIMIZE () { 11 }
sub SW_MAX () { 11 }

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

tie $Win32::FileOp::fileop, 'Data::Lazy', sub {
  new Win32::API("shell32", "SHFileOperation", ['P'], 'I')
  or
  die "new Win32::API::SHFileOperation: $!\n"
}, &LAZY_READONLY;

%Win32::FileOp::SHFileOperation_ret = (
	0x71 => 'The source and destination files are the same file.',
	0x72 => 'Multiple file paths were specified in the source buffer, but only one destination file path.',
	0x73 => 'Rename operation was specified but the destination path is a different directory. Use the move operation instead.',
	0x74 => 'The source is a root directory, which cannot be moved or renamed.',
	0x75 => 'The operation was cancelled by the user, or silently cancelled if the appropriate flags were supplied to SHFileOperation.',
	0x76 => 'The destination is a subtree of the source.',
	0x78 => 'Security settings denied access to the source.',
	0x79 => 'The source or destination path exceeded or would exceed MAX_PATH.',
	0x7A => 'The operation involved multiple destination paths, which can fail in the case of a move operation.',
	0x7C => 'The path in the source or destination or both was invalid.',
	0x7D => 'The source and destination have the same parent folder.',
	0x7E => 'The destination path is an existing file.',
	0x80 => 'The destination path is an existing folder.',
	0x81 => 'The name of the file exceeds MAX_PATH.',
	0x82 => 'The destination is a read-only CD-ROM, possibly unformatted.',
	0x83 => 'The destination is a read-only DVD, possibly unformatted.',
	0x84 => 'The destination is a writable CD-ROM, possibly unformatted.',
	0x85 => 'The file involved in the operation is too large for the destination media or file system.',
	0x86 => 'The source is a read-only CD-ROM, possibly unformatted.',
	0x87 => 'The source is a read-only DVD, possibly unformatted.',
	0x88 => 'The source is a writable CD-ROM, possibly unformatted.',
	0xB7 => 'MAX_PATH was exceeded during the operation.',
	0x402 => 'An unknown error occurred. This is typically due to an invalid path in the source or destination. This error does not occur on Windows Vista and later.',
	0x10000 => 'An unspecified error occurred on the destination.',
	0x10074 => 'Destination is a root directory and cannot be renamed.',
	0 => undef,
);

tie $Win32::FileOp::copyfile, 'Data::Lazy', sub {
  new Win32::API("KERNEL32", "CopyFile", [qw(P P I)], 'I')
  or
  die "new Win32::API::CopyFile: $!\n";
}, &LAZY_READONLY;

tie $Win32::FileOp::movefileexDel, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "MoveFileEx", ['P','L','N'], 'I')
    or
    die "new Win32::API::MoveFileEx for delete: $!\n";
}, &LAZY_READONLY;

tie $Win32::FileOp::movefileex, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "MoveFileEx", ['P','P','N'], 'I')
    or
    die "new Win32::API::MoveFileEx: $!\n";
}, &LAZY_READONLY;

tie $Win32::FileOp::SHAddToRecentDocs, 'Data::Lazy', sub {
    new Win32::API("shell32", "SHAddToRecentDocs", ['I','P'], 'I')
    or
    die "new Win32::API::SHAddToRecentDocs: $!\n";
}, &LAZY_READONLY;

tie $Win32::FileOp::writeINI, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "WritePrivateProfileString", [qw(P P P P)], 'I')
    or
    die "new Win32::API::WritePrivateProfileString: $!\n"
}, &LAZY_READONLY;


tie $Win32::FileOp::writeWININI, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "WriteProfileString", [qw(P P P)], 'I')
    or
    die "new Win32::API::WriteProfileString: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::deleteINI, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "WritePrivateProfileString", [qw(P P L P)], 'I')
    or
    die "new Win32::API::WritePrivateProfileString for delete: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::deleteWININI, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "WriteProfileString", [qw(P P L)], 'I')
    or
    die "new Win32::API::WriteProfileString for delete: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::readINI, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "GetPrivateProfileString", [qw(P P P P N P)], 'N')
    or
    die "new Win32::API::GetPrivateProfileString: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::readWININI, 'Data::Lazy', sub {
    new Win32::API("KERNEL32", "GetProfileString", [qw(P P P P N)], 'N')
    or
    die "new Win32::API::GetProfileString: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::GetOpenFileName, 'Data::Lazy', sub {
    new Win32::API("comdlg32", "GetOpenFileName", ['P'], 'N')
    or
    die "new Win32::API::GetOpenFileName: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::GetSaveFileName, 'Data::Lazy', sub {
    new Win32::API("comdlg32", "GetSaveFileName", ['P'], 'N')
    or
    die "new Win32::API::GetSaveFileName: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::CommDlgExtendedError, 'Data::Lazy', sub {
    new Win32::API("comdlg32", "CommDlgExtendedError", [], 'N')
    or
    die "new Win32::API::CommDlgExtendedError: $!\n"
}, &LAZY_READONLY;


tie $Win32::FileOp::CreateFile, 'Data::Lazy', sub {
    new Win32::API( "kernel32", "CreateFile", [qw(P N N P N N P)], 'N')
    or
    die "new Win32::API::CreateFile: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::CloseHandle, 'Data::Lazy', sub {
    new Win32::API( "kernel32", "CloseHandle", ['N'], 'N')
    or
    die "new Win32::API::CloseHandle: $!\n"
};

tie $Win32::FileOp::GetFileSize, 'Data::Lazy', sub {
    new Win32::API( "kernel32", "GetFileSize", ['N','P'], 'N')
    or
    die "new Win32::API::GetFileSize: $!\n"
};

tie $Win32::FileOp::GetDiskFreeSpaceEx, 'Data::Lazy', sub {
    new Win32::API( "kernel32", "GetDiskFreeSpaceEx", ['P','P','P','P'], 'N')
    or
    die "new Win32::API::GetDiskFreeSpaceEx: $!\n"
};

tie $Win32::FileOp::DeviceIoControl, 'Data::Lazy', sub {
    new Win32::API( "kernel32", "DeviceIoControl", ['N', 'N', 'P', 'N', 'P', 'N', 'P', 'P'], 'N')
    or
    die "new Win32::API::DeviceIoControl: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::SHBrowseForFolder, 'Data::Lazy', sub {
   new Win32::API("shell32", "SHBrowseForFolder", ['P'], 'N')
   or
   die "new Win32::API::SHBrowseForFolder: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::SHGetPathFromIDList, 'Data::Lazy', sub {
   new Win32::API("shell32", "SHGetPathFromIDList", ['N','P'], 'I')
   or
   die "new Win32::API::SHGetPathFromIDList: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::SHGetSpecialFolderLocation, 'Data::Lazy', sub {
   new Win32::API("shell32", "SHGetSpecialFolderLocation", ['N','I','P'], 'I')
   or
   die "new Win32::API::SHGetSpecialFolderLocation: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::CoTaskMemFree, 'Data::Lazy', sub {
   new Win32::API("Ole32", "CoTaskMemFree", ['P'], 'V')
   or
   die "new Win32::API::CoTaskMemFree: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::GetFileVersionInfoSize, 'Data::Lazy', sub {
   new Win32::API( "version", "GetFileVersionInfoSize", ['P', 'P'], 'N')
   or
   die "new Win32::API::GetFileVersionInfoSize: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::GetFileVersionInfo, 'Data::Lazy', sub {
   new Win32::API( "version", "GetFileVersionInfo", ['P', 'N', 'N', 'P'], 'N')
   or
   die "new Win32::API::GetFileVersionInfo: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::GetCompressedFileSize, 'Data::Lazy', sub {
   new Win32::API("kernel32", "GetCompressedFileSize", ['P','P'], 'L')
   or
   die "new Win32::API::GetCompressedFileSize: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::VerQueryValue, 'Data::Lazy', sub {
   new Win32::API( "version", "VerQueryValue", ['P', 'P', 'P', 'P'], 'N')
   or
   die "new Win32::API::VerQueryValue: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::WNetAddConnection3, 'Data::Lazy', sub {
  new Win32::API("mpr.dll", "WNetAddConnection3", ['L','P','P','P','L'], 'L')
  or
  die "new Win32::API::WNetAddConnection3: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::WNetGetConnection, 'Data::Lazy', sub {
  new Win32::API("mpr.dll", "WNetGetConnection", ['P','P','P'], 'L')
  or
  die "new Win32::API::WNetGetConnection: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::WNetCancelConnection2, 'Data::Lazy', sub {
  new Win32::API("mpr.dll", "WNetCancelConnection2", ['P','L','I'], 'L')
  or
  die "new Win32::API::WNetCancelConnection2: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::GetLogicalDrives, 'Data::Lazy', sub {
  new Win32::API("kernel32.dll", "GetLogicalDrives", [], 'N')
  or
  die "new Win32::API::GetLogicalDrives: $!\n"
}, &LAZY_READONLY;


tie $Win32::FileOp::QueryDosDevice, 'Data::Lazy', sub {
  new Win32::API("kernel32.dll", "QueryDosDevice", ['P','P','L'], 'L')
  or
  die "new Win32::API::QueryDosDevice: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::DefineDosDevice, 'Data::Lazy', sub {
  new Win32::API("kernel32.dll", "DefineDosDevice", ['L','P','P'],'I')
  or
  die "new Win32::API::DefineDosDevice: $!\n"
}, &LAZY_READONLY;

tie $Win32::FileOp::ShellExecute, 'Data::Lazy', sub {
  new Win32::API("shell32", "ShellExecute", ['N','P','P','P','P','N'], 'I')
  or
  die "new Win32::API::ShellExecute: $!\n"
}, &LAZY_READONLY;

Win32::API::Struct->typedef(
	SHELLEXECUTEINFO => qw{
		DWORD     cbSize;
		ULONG     fMask;
		HWND      hwnd;
		LPCTSTR   lpVerb;
		LPCTSTR   lpFile;
		LPCTSTR   lpParameters;
		LPCTSTR   lpDirectory;
		int       nShow;
		HINSTANCE hInstApp;
		LPVOID    lpIDList;
		LPCTSTR   lpClass;
		HKEY      hkeyClass;
		DWORD     dwHotKey;
		HANDLE    hIcon;
		HANDLE    hProcess;
	}
);

tie $Win32::FileOp::ShellExecuteEx, 'Data::Lazy', sub {
  new Win32::API('shell32', 'BOOL ShellExecuteEx(SHELLEXECUTEINFO &shellex)')
  or
  die "new Win32::API::ShellExecuteEx: $!\n"
}, &LAZY_READONLY;


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub ShellExecute {
	my ($operation, $file, $params, $dir, $show, $handle) = @_;
	if (@_ == 1) { #ShellExecute( $file)
		$file = $operation;
		$operation = undef;
	} elsif (ref $file) { #ShellExecute( $file, {options})
		($params, $file, $operation) = ($file, $operation, undef);
	}
	if (ref $params) {
		$params = { map {lc($_) => $params->{$_}} keys %$params}; # lowercase the keys
		$show = $params->{show};
		$dir = $params->{dir};
		$handle = $params->{handle};
		$params = $params->{params};
	}
	if (defined $show) {
		$show+=0;
	} else {
		$show = SW_SHOWDEFAULT;
	}
	$handle = Win32::FileOp::GetWindowHandle unless defined $handle;
	return unless $handle;

	my $result;
	if (ref($operation) eq 'ARRAY') {
		foreach my $op (@$operation) {
			$result = $Win32::FileOp::ShellExecute->Call( $handle, $op, $file, $params, $dir, $show);
			last if $result != 31; # 31 = unknown operation
		}
	} else {
		$result = $Win32::FileOp::ShellExecute->Call( $handle, $operation, $file, $params, $dir, $show);
	}

	return $result > 32;
}


sub ShellExecuteEx {
	my ($operation, $file, $params, $dir, $show, $handle, $expand, $unicode) = @_;

	if (@_ == 1) { #ShellExecuteEx( $file)
		$file = $operation;
		$operation = undef;
	} elsif (ref $file) { #ShellExecuteEx( $file, {options})
		($params, $file, $operation) = ($file, $operation, undef);
	}
	if (ref $params) {
		$params = { map {lc($_) => $params->{$_}} keys %$params}; # lowercase the keys
		$show = $params->{show};
		$dir = $params->{dir};
		$handle = $params->{handle};
		$expand = $params->{expand};
		$unicode = $params->{unicode};
		$params = $params->{params};
	}
	if (defined $show) {
		$show+=0;
	} else {
		$show = SW_SHOWDEFAULT;
	}
	$handle = Win32::FileOp::GetWindowHandle unless defined $handle;

	my $mask = ($unicode) ? 0x4000 : 0;
	$mask |= 0x200 if $expand || ! defined $expand;

	my $shellex = Win32::API::Struct->new('SHELLEXECUTEINFO');

	$shellex->{'cbSize'} = $shellex->sizeof();

	# I would like to offer a value of 0x100 for fMask, to wait for completion, but it does not work.
	$shellex->{'fMask'} = $mask;
	$shellex->{'hwnd'} = $handle;

	$shellex->{'lpVerb'} = (defined($operation) ? $operation."\0" : undef);
	$shellex->{'lpFile'} = $file."\0";
	$shellex->{'lpParameters'} = (defined($params) ? $params."\0" : undef);
	$shellex->{'lpDirectory'} = (defined($dir) ? $dir."\0" : undef);
	$shellex->{'nShow'} = $show;
	$shellex->{'hInstApp'} = 0;

	return $Win32::FileOp::ShellExecuteEx->Call($shellex);
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub Recycle {
    &DeleteEx (@_, FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT |
      FOF_NOERRORUI);
}

sub RecycleConfirm { &DeleteEx (@_, FOF_ALLOWUNDO); }

sub RecycleEx { my $opt = pop; $opt |= FOF_ALLOWUNDO; &DeleteEx (@_, $opt); }

sub Delete {
    &DeleteEx (@_, FOF_NOCONFIRMATION | FOF_SILENT | FOF_NOERRORUI);
}

sub DeleteConfirm { &DeleteEx (@_, FOF_CREATEPROGRESSDLG); }

sub DeleteEx {
    undef $Win32::FileOp::Error;
    my $options = pop;
    my ($opstruct, $filename);
    my @files = map {if (/[*?]/) {glob($_)} elsif (-e $_) {$_} else {()}} @_; # since we change the names, make a copy of the list
    return unless @files;

    # pass all files at once, join them by \0 and end by \0\0

    # fix to full paths
    Relative2Absolute @files;

    $filename = join "\0", @files;
    $filename .= "\0\0";        # double term the filename

	my $handle = Win32::FileOp::GetWindowHandle;

    # pack fileop structure (really more like lLppIilP)
    # sizeof args = l4, L4, p4, p4, I4, i4, l4, P4 = 32 bytes
    if ($Win32::FileOp::ProgressTitle and $options & FOF_SIMPLEPROGRESS) {
        $Win32::FileOp::ProgressTitle .= "\0" unless $Win32::FileOp::ProgressTitle =~ /\0$/;
        $opstruct = pack ('LLpLILC2p', $handle, FO_DELETE,
                            $filename, 0, $options, 0, 0,0, $Win32::FileOp::ProgressTitle);
    } else {
        $opstruct = pack ('LLpLILLL', $handle, FO_DELETE,
                            $filename, 0, $options, 0, 0, 0);
    }
    # call delete SHFileOperation with structure

	my $ret = $Win32::FileOp::fileop->Call($opstruct);
    return 1 if $ret == 0;

	$Win32::FileOp::Error = (exists ($Win32::FileOp::SHFileOperation_ret{$ret}) ? $Win32::FileOp::SHFileOperation_ret{$ret} : "Unknown result code $ret");
	return;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub RecycleConfirmEach { &_DeleteConfirmEach (@_, FOF_ALLOWUNDO); }

sub DeleteConfirmEach  { &_DeleteConfirmEach (@_, FOF_CREATEPROGRESSDLG); }

sub _DeleteConfirmEach {
    undef $Win32::FileOp::Error;
    my $options =  pop;

    return unless @_;

    my $res = 0;
    my ($filename,$opstruct);
	my $handle = Win32::FileOp::GetWindowHandle;

    while (defined($filename = shift)) {

        Relative2Absolute $filename;
        $filename .= "\0\0";        # double term the filename
        my $was = -e $filename;

        if ($Win32::FileOp::ProgressTitle and $options & FOF_SIMPLEPROGRESS) {
            $Win32::FileOp::ProgressTitle .= "\0" unless $Win32::FileOp::ProgressTitle =~ /\0$/;
            $opstruct = pack ('LLpLILC2p', $handle, FO_DELETE,
                                $filename, 0, $options, 0, 0,0, $Win32::FileOp::ProgressTitle);
        } else {
            $opstruct = pack ('LLpLILLL', $handle, FO_DELETE,
                                $filename, 0, $options, 0, 0, 0);
        }

		my $ret = $Win32::FileOp::fileop->Call($opstruct);
        if ($ret == 0) {
            $res++ if ($was and !-e $filename);
        } else {
			$Win32::FileOp::Error = (exists ($Win32::FileOp::SHFileOperation_ret{$ret}) ? $Win32::FileOp::SHFileOperation_ret{$ret} : "Unknown result code $ret");
		}
    }
    $res;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub Copy {
    &_MoveOrCopyEx (@_, FOF_NOCONFIRMATION | FOF_NOCONFIRMMKDIR |
    FOF_SILENT # | FOF_NOERRORUI
      , FO_COPY);
}

sub CopyConfirm { &_MoveOrCopyEx (@_, FOF_CREATEPROGRESSDLG, FO_COPY); }

*CopyConfirmEach = \&CopyConfirm;

sub CopyEx { &_MoveOrCopyEx (@_, FO_COPY); }

sub Move   {
    &_MoveOrCopyEx (@_, FOF_NOCONFIRMATION | FOF_NOCONFIRMMKDIR | FOF_SILENT # | FOF_NOERRORUI
      , FO_MOVE);
}

sub MoveConfirm { &_MoveOrCopyEx (@_, FOF_CREATEPROGRESSDLG, FO_MOVE); }

*MoveConfirmEach = \&MoveConfirm;

sub MoveEx { &_MoveOrCopyEx (@_, FO_MOVE); }

sub _MoveOrCopyEx {
    undef $Win32::FileOp::Error;
    my $func = pop;
    my $options = pop;
    my ($opstruct, $filename, $hash, $res, $from, $to);

    if (@_ % 2) { die "Wrong number of arguments to Win32::FileOp::CopyEx!\n" };

	my $handle = Win32::FileOp::GetWindowHandle;

    my $i = 0;
    while (defined ($from = $_[$i++]) and defined ($to = $_[$i++])) {

    # fix to full paths

        if (UNIVERSAL::isa($from, "ARRAY")) {

            my @files = map {
                my $s = $_;
                Relative2Absolute $s;
                $s;
            } @$from;
            $from = join "\0", @files;

        } else {

            Relative2Absolute $from;
            $from =~ s#/#\\#g;

            # if to ends in slash, get filename from from

            if ($to =~ m{[\\/]$} and $to !~ /^\w:\\$/) {
                my $tmp = $from;
                $tmp =~ s#^.*[\\/](.*?)$#$1#;
                $to .= $tmp;
            }
            $to .= '\\' if $to =~ /:$/;
        }
        $from .= "\0\0";        # double term the filename

        my $options = $options;
        if (UNIVERSAL::isa($to, "ARRAY")) {
            my $strto='';
            foreach (@$to) {
                $strto .= RelativeToAbsolute($_) . "\0";
            }
            $to = $strto;
            $options |= FOF_MULTIDESTFILES;
        } else {
            Relative2Absolute($to);
        }
        $to .= "\0\0";        # double term the filename
        $to =~ s#/#\\#g;

        if ($Win32::FileOp::ProgressTitle and $options & FOF_SIMPLEPROGRESS) {

            $Win32::FileOp::ProgressTitle .= "\0" unless $Win32::FileOp::ProgressTitle =~ /\0$/;
            $opstruct = pack ('LLppILC2p', $handle, $func,
              $from, $to, $options, 0, 0,0, $Win32::FileOp::ProgressTitle);

        } else {

            $opstruct = pack ('LLppILLL', $handle, $func,
              $from, $to, $options, 0, 0, 0);

        }

        unless ($Win32::FileOp::fileop->Call($opstruct)) {
            $res++;
        } else {
            return;
        }
    }
    $res;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub MoveFile {
    MoveFileEx(@_,MOVEFILE_REPLACE_EXISTING | MOVEFILE_COPY_ALLOWED);
}

sub MoveAtReboot {
    if (Win32::IsWinNT) {
        MoveFileEx(@_,MOVEFILE_REPLACE_EXISTING | MOVEFILE_DELAY_UNTIL_REBOOT);
    } else {
        undef $Win32::FileOp::Error;
        my @a;
        my $i=0;
        while ($_[$i]) {
            $a[$i+1]= Win32::GetShortPathName $_[$i];
            ($a[$i]= $_[$i+1]) =~ s#^(.*)([/\\].*?)$#Win32::GetShortPathName($1).$2#e;
            $i+=2;
        }
        Relative2Absolute(@a);
        WriteToINI($ENV{WINDIR}.'\\wininit.ini','Rename',@a);
    }
}

sub CopyFile {
    undef $Win32::FileOp::Error;
    my ($from,$to);

    while (defined($from = shift) and defined($to = shift)) {
#        Relative2Absolute($to,$from);
        $to .= "\0";
        $from .= "\0";
        $Win32::FileOp::copyfile->Call($from,$to, 0);
    }
}


sub DeleteAtReboot {
    undef $Win32::FileOp::Error;
    if (Win32::IsWinNT)  {
        my $file;
        while (defined($file = shift)) {
            Relative2Absolute($file);
            $Win32::FileOp::movefileexDel->Call($file, 0, MOVEFILE_DELAY_UNTIL_REBOOT);
        }
    } else {
        my @a;
        foreach (@_) {
            my $tmp=$_;
            Relative2Absolute($tmp);
            $tmp = Win32::GetShortPathName $tmp;
            push @a, 'NUL', $tmp;
        }
        WriteToINI($ENV{WINDIR}.'\\wininit.ini','Rename',@a);
    }
    1;
}

sub MoveFileEx {
    undef $Win32::FileOp::Error;
    my $options = pop;

    my ($from,$to);
    while (defined($from = shift) and defined($to = shift)) {
        Relative2Absolute($to,$from);
        $to .= "\0";
        $from .= "\0";
        $Win32::FileOp::movefileex->Call($from,$to, $options);
    }
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub UpdateDir {
 undef $Win32::FileOp::Error;
 local ($Win32::FileOp::from,$Win32::FileOp::to,$Win32::FileOp::callback) = @_;
 -d $Win32::FileOp::from or return;
 -d $Win32::FileOp::to or File::Path::mkpath $Win32::FileOp::to, 0777 or return;
 Relative2Absolute($Win32::FileOp::to);
 my $olddir = cwd;
 chdir $Win32::FileOp::from;
 find(\&_UpdateDir, '.');
 chdir $olddir;
}

sub _UpdateDir {
  undef $Win32::FileOp::Error;
  my $fullto = "$Win32::FileOp::to\\$File::Find::dir\\$_";
  $fullto =~ s#/#\\#g;
  $fullto =~ s#\\\.\\#\\#;
  if (-d $_) {
    return if /^\.\.?$/ or -d $fullto;
    mkdir $fullto, 0777;
  } else {
    my $age = -M($fullto);
    if (! -e($fullto) or $age > -M($_)) {
      if (! defined $Win32::FileOp::callback or &$Win32::FileOp::callback()) {
        CopyFile $_, $fullto;
      }
    }
  }
}


sub FillInDir {
 undef $Win32::FileOp::Error;
 local ($Win32::FileOp::from,$Win32::FileOp::to,$Win32::FileOp::callback) = @_;
 -d $Win32::FileOp::from or return;
 -d $Win32::FileOp::to or File::Path::mkpath $Win32::FileOp::to, 0777 or return;
 Relative2Absolute($Win32::FileOp::to);
 my $olddir = cwd;
 chdir $Win32::FileOp::from;
 find(\&_FillInDir, '.');
 chdir $olddir;
}

sub _FillInDir {
  my $fullto = "$Win32::FileOp::to\\$File::Find::dir\\$_";
  $fullto =~ s#/#\\#g;
  $fullto =~ s#\\\.\\#\\#;
  if (-d $_) {
    return if /^\.\.?$/ or -d $fullto;
    mkdir $fullto, 0777;
  } else {
    if (! -e($fullto)) {
      if (! defined $Win32::FileOp::callback or &$Win32::FileOp::callback()) {
        CopyFile $_, $fullto;
      }
    }
  }
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub AddToRecentDocs {
 undef $Win32::FileOp::Error;

 my $file;
 my $res=0;
 while (defined($file = shift)) {
  next unless -e $file;
  Relative2Absolute($file);
  $file .= "\0";
  $Win32::FileOp::SHAddToRecentDocs->Call(2,$file);
  $res++;
 }
 $res;
}

sub EmptyRecentDocs {
 undef $Win32::FileOp::Error;
 my $x = 0;
 $Win32::FileOp::SHAddToRecentDocs->Call(2,$x);
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub WriteToINI {
    undef $Win32::FileOp::Error;
    my ($INI) = RelativeToAbsolute(shift());$INI .= "\0";
    my $section = shift;$section .= "\0";
    my ($name,$value);
    while (defined($name = shift) and defined($value = shift)) {
        $name .= "\0";$value .= "\0";
        $Win32::FileOp::writeINI->Call($section,$name,$value,$INI)
        or return;
    }
    1;
}

sub WriteToWININI {
    undef $Win32::FileOp::Error;
    my $section = shift;$section .= "\0";
    my ($name,$value);
    while (defined($name = shift) and defined($value = shift)) {
        $name .= "\0";$value .= "\0";
        $Win32::FileOp::writeWININI->Call($section,$name,$value)
        or return;
    }
    1;
}

sub DeleteFromINI {
    undef $Win32::FileOp::Error;
    my ($INI) = RelativeToAbsolute(shift());$INI .= "\0";
    my $section = shift;$section .= "\0";
    my $name;
    while (defined($name = shift)) {
        $name .= "\0";
        $Win32::FileOp::deleteINI->Call($section,$name,0,$INI)
        or return;
    }
    1;
}

sub DeleteFromWININI {
    undef $Win32::FileOp::Error;
    my $section = shift;$section .= "\0";
    my $name;
    while (defined($name = shift)) {
        $name .= "\0";
        $Win32::FileOp::deleteWININI->Call($section,$name,0)
        or return;
    }
    1;
}

sub ReadINI {
    undef $Win32::FileOp::Error;
    my ($INI) = RelativeToAbsolute(shift());$INI .= "\0";
    my $section = shift;$section .= "\0";
    my $name = shift;$name .= "\0";
    my $default = shift;$default .= "\0";
    my $value = _ReadINI($section,$name,$default,$INI);

    $value =~ s/\0.*$// or return;
    return $value;
}

# MTY hack : Michael Yamada <myamada@gj.com>
sub ReadINISectionKeys {
    undef $Win32::FileOp::Error;
    my ($INI) = RelativeToAbsolute(shift());$INI='win.ini' unless $INI;$INI .= "\0";
    my $section = shift;$section .= "\0";
	my $name = 0; # pass null to API
	my $default = "\0";
	my @values;

	@values = split(/\0/,_ReadINI($section,$name,$default,$INI));
	@{$_[0]} = @values if (UNIVERSAL::isa($_[0], "ARRAY"));
	return wantarray() ? @values : (@values ? \@values : undef);
}
# END MTY Hack

sub ReadINISections {
    undef $Win32::FileOp::Error;
    my ($INI) = RelativeToAbsolute(shift());$INI='win.ini' unless $INI;$INI .= "\0";
    my $section = 0; # pass null to API
	my $name = 0;
	my $default = "\0";
	my @values;

	@values = split(/\0/,_ReadINI($section,$name,$default,$INI));
	@{$_[0]} = @values if (UNIVERSAL::isa($_[0], "ARRAY"));
	return wantarray() ? @values : (@values ? \@values : undef);
}


sub ReadWININI {
    undef $Win32::FileOp::Error;
    my $section = shift;$section .= "\0";
    my $name = shift;$name .= "\0";
    my $default = shift;$default .= "\0";
    my $value = "\0" x 2048;

    $Win32::FileOp::readWININI->Call($section,$name,$default,$value,256)
    or return;

    $value =~ s/\0.*$// or return;
    return $value;
}

sub _ReadINI { # $section, $name, $default, $INI
	my $size = 10;#24;
    my $value = "\0" x $size; # large buffer to accomodate many keys
    my $retsize = $size-2;
    while ($size-$retsize <=2) {
     $size*=2;$value = "\0" x $size;
     $retsize = $Win32::FileOp::readINI->Call($_[0],$_[1],$_[2],$value,$size,$_[3])
     or return '';
    }
    return $value;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub OpenDialog {
   OpenOrSaveDialog($Win32::FileOp::GetOpenFileName,@_);
}

sub SaveAsDialog {
   OpenOrSaveDialog($Win32::FileOp::GetSaveFileName,@_);
}

sub OpenOrSaveDialog {
    undef $Win32::FileOp::Error;
    my $fun = shift;
    my $params;
    if (UNIVERSAL::isa($_[0], "HASH")) {
        $params = $_[0];
        $params->{filename} = $_[1] if defined $_[1];
    } else {
        if (@_ % 2) {
            my $filename = pop;
            $params = {@_};
            $params->{filename} = $filename;
        } else {
            $params = {@_};
        }
    }
    foreach (grep {s/^-//} keys %$params) {$params->{$_} = $params->{"-$_"};delete $params->{"-$_"}};

    $params->{handle} = 'self' unless exists $params->{handle};
    $params->{options} = 0 unless exists $params->{options};


    my $lpstrFilter = '';
    if (UNIVERSAL::isa($params->{filters}, "HASH")) {
        foreach (keys %{$params->{filters}}) {
            $lpstrFilter .= $_ . "\0" . $params->{filters}->{$_} . "\0";
        }
    } elsif (UNIVERSAL::isa($params->{filters}, "ARRAY")) {
        my ($title,$filter,$i);
        $i=0;$lpstrFilter='';
        while ($title = ${$params->{filters}}[$i++] and $filter = ${$params->{filters}}[$i++]) {
            $lpstrFilter .= $title . "\0" . $filter . "\0";
        }
        $params->{defaultfilter} = $title if $title && !$params->{defaultfilter};
    } elsif ($params->{filters}) {
        $lpstrFilter = $params->{filters};
        $lpstrFilter .= "\0\0" unless $lpstrFilter =~ /\0\0$/
    } else {
        $lpstrFilter = "\0\0";
    }

local $^W = 0;

    my $nFilterIndex = $params->{defaultfilter};
    $nFilterIndex = 1 unless $nFilterIndex>0; # to be sure it's a reasonable number

    my $lpstrFile = $params->{filename}."\0".
    ($params->{options} & OFN_ALLOWMULTISELECT
     ? ' ' x ($Win32::FileOp::BufferSize - length $params->{filename})
     : ' ' x 256
    );

    my $lpstrFileTitle = "\0";
    my $lpstrInitialDir = $params->{dir} . "\0";
    my $lpstrTitle  = $params->{title} . "\0";
    my $Flags = $params->{options};
    my $nFileExtension = "\0\0";
    my $lpstrDefExt = $params->{extension}."\0";
    my $lpTemplateName = "\0";
    my $Handle = $params->{handle};
    if ($Handle =~ /^self$/i) {$Handle = GetWindowHandle()};

#    my $struct = pack "LLLpLLLpLpLppLIIpLLp",
    my $struct = pack "LLLpLLLpLpLppLIppLLp",
     (
      76,                        #'lStructSize'       #  DWORD
      $Handle,                   #'hwndOwner'         #  HWND
      0,                         #'hInstance'         #  HINSTANCE
      $lpstrFilter,              #'lpstrFilter'       #  LPCTSTR
      0,
      0,
#     $lpstrCustomFilter,        #'lpstrCustomFilter' #  LPTSTR
#     length $lpstrCustomFilter, #'nMaxCustFilter'    #  DWORD
#I'm not able to make it work with CustomFilter

      $nFilterIndex,                         #'nFilterIndex'      #  DWORD
      $lpstrFile,                #'lpstrFile'         #  LPTSTR
      length $lpstrFile,         #'nMaxFile'          #  DWORD
      $lpstrFileTitle,           #'lpstrFileTitle'    #  LPTSTR
      length $lpstrFileTitle,    #'nMaxFileTitle'     #  DWORD
      $lpstrInitialDir,          #'lpstrInitialDir'   #  LPCTSTR
      $lpstrTitle,               #'lpstrTitle'        #  LPCTSTR
      $Flags,                    #'Flags'             #  DWORD
      0,                         #'nFileOffset'       #  WORD
#      0,                         #'nFileExtension'    #  WORD
      $nFileExtension,           #'nFileExtension'    #  WORD
      $lpstrDefExt,              #'lpstrDefExt'       #  LPCTSTR
      0,                         #'lCustData'         #  DWORD
      0,                         #'lpfnHook'          #  LPOFNHOOKPROC
      $lpTemplateName            #'lpTemplateName'    #  LPCTSTR
     );

   if ($fun->Call($struct)) {
        $Flags = unpack("L", substr $struct, 52, 4);
        $Win32::FileOp::SelectedFilter = unpack("L", substr $struct, 6*4, 4);

        $Win32::FileOp::ReadOnly = ($Flags & OFN_READONLY);

        if ($Flags & OFN_ALLOWMULTISELECT) {
            $lpstrFile =~ s/\0\0.*$//;
            my @result;
            if ($Flags & OFN_EXPLORER) {
                @result = split "\0", $lpstrFile;
            } else {
                @result = split " ", $lpstrFile;
            }
            my $dir = shift @result;
            $dir =~ s/\\$//; # only happens in root
            return $dir unless @result;
            return map {$dir . '\\' . $_} @result;
        } else {
           $lpstrFile =~ s/\0.*$//;
           return $lpstrFile;
        }
#   } else {
#    my $err = $Win32::FileOp::Error = $Win32::FileOp::CommDlgExtendedError->Call();
#    if ($err == 12291)  {
#        print "Sh!t, the buffer was too small!\n";
#        $fun->Call($struct);
#    }
   }
   return;
}

#=======================

sub BrowseForFolder {
   undef $Win32::FileOp::Error;
   my $lpszTitle = shift() || "\0";
   my $nFolder = shift();
   my $ulFlags= (shift() || 0) | 0x0000;
   my $hwndOwner = (defined $_[0] ? shift() : GetWindowHandle());

   my ($pidlRoot, $pszDisplayName, $lpfn, $lParam, $iImage, $pszPath)
      = ("\0"x260, "\0"x260, 0, 0, 0, "\0"x260 );

   $nFolder = CSIDL_DESKTOP() unless defined $nFolder;

   $Win32::FileOp::SHGetSpecialFolderLocation->Call($hwndOwner, $nFolder, $pidlRoot)
   and return;

   my $pidlRootUnpacked = hex unpack 'H*',(join'', reverse split//, $pidlRoot);

   my $browseinfo = pack 'LLppILLI',
      ($hwndOwner, $pidlRootUnpacked, $pszDisplayName, $lpszTitle,
       $ulFlags, $lpfn, $lParam, $iImage);

   my $bool = $Win32::FileOp::SHGetPathFromIDList->Call(
               $Win32::FileOp::SHBrowseForFolder->Call($browseinfo),
               $pszPath
              );

   $pszPath =~ s/\0.*$//s;

   $Win32::FileOp::CoTaskMemFree->Call($pidlRoot);
   $bool ? $pszPath : undef;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub FindInPATH {
    undef $Win32::FileOp::Error;
    my $file = shift;
    return $file if -e $file;
    foreach (split ';',$ENV{PATH}) {
        return $_.'/'.$file if -e $_.'/'.$file;
    }
    return;
}
*FindInPath = \&FindInPATH;


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub GetDesktopHandle {
    undef $Win32::FileOp::Error;
    my ($function, $handle);

# if handle already saved, use that one

    return $Win32::FileOp::DesktopHandle if $Win32::FileOp::DesktopHandle != 0;

# find GetDesktopWindow routine

$function = new Win32::API("user32", "GetDesktopWindow", [], 'I') or
  die "new Win32::API::GetDesktopHandle: $!\n";

# call it, get window handle back, save it and return it

$Win32::FileOp::DesktopHandle = $function->Call();

}

sub GetWindowHandle {
    undef $Win32::FileOp::Error;
    if (! $Win32::FileOp::WindowHandle) {
        my $GetConsoleTitle = new Win32::API("kernel32", "GetConsoleTitle", ['P','N'],'N');
        my $SetConsoleTitle = new Win32::API("kernel32", "SetConsoleTitle", ['P'],'N');
        my $SleepEx = new Win32::API("kernel32", "SleepEx", ['N','I'],'V');
        my $FindWindow = new Win32::API("user32", "FindWindow", ['P','P'],'N');

        my $oldtitle = " " x 1024;
        $GetConsoleTitle->Call($oldtitle, 1024);
        my $newtitle = sprintf("PERL-%d-%d", Win32::GetTickCount(), $$);
        $SetConsoleTitle->Call($newtitle);
        $SleepEx->Call(40,1);
        $Win32::FileOp::WindowHandle = $FindWindow->Call(0, $newtitle);
        $SetConsoleTitle->Call($oldtitle);
    }
    return $Win32::FileOp::WindowHandle;
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub SetCompression {
    undef $Win32::FileOp::Error;
    my $file;
    my $flag;
    if ($_[-1] eq ($_[-1]+0)) {
        $flag = pop
    } else {
        $flag = 1;
    }
    $_[0] = $_ unless @_;
    while (defined($file = shift)) {

#print "\t$file\n";

     my $handle;
     $handle = $Win32::FileOp::CreateFile->Call($file, 0xc0000000, # FILE_READ_ATTRIBUTES | FILE_WRITE_ATTRIBUTES |
		7, 0, 3, 0x2000000, 0);
#     $handle = $Win32::FileOp::CreateFile->Call($file, FILE_FLAG_WRITE_THROUGH | FILE_FLAG_OVERLAPPED,
#     FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, 0,
#     OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);

     if($handle != -1) {
         my $br = pack("L", 0);
         my $inbuffer = pack("S", $flag);
         my $comp = $Win32::FileOp::DeviceIoControl->Call(
             $handle, 639040, $inbuffer, 2, 0, 0, $br, 0,
         );
         if(!$comp) {
             $Win32::FileOp::Error = "DeviceIoControl failed: "
                . Win32::FormatMessage(Win32::GetLastError);
             return;
         }
         $Win32::FileOp::CloseHandle->Call($handle);
         next;
     } else {
         $Win32::FileOp::Error = "CreateFile failed: "
            . Win32::FormatMessage(Win32::GetLastError);
         return;
     }
    }
    return 1;
}

sub GetCompression {
    undef $Win32::FileOp::Error;
    my ($file) = @_;
    $file = $_ unless defined $file;
    my $permission = 0x0080; # FILE_READ_ATTRIBUTES
    my $handle = $Win32::FileOp::CreateFile->Call($file, $permission, 0, 0, 3, 0, 0);
    if($handle != -1) {
        my $br = pack("L", 0);
        my $outbuffer = pack("S", 0);
        my $comp = $Win32::FileOp::DeviceIoControl->Call(
            $handle, 589884, 0, 0, $outbuffer, 2, $br, 0,
        );
        if(!$comp) {
            $Win32::FileOp::Error = "DeviceIoControl failed: "
               . Win32::FormatMessage(Win32::GetLastError);
            return;
        }
        $Win32::FileOp::CloseHandle->Call($handle);
        return unpack("S", $outbuffer);
    } else {
        $Win32::FileOp::Error = "CreateFile failed: "
			. Win32::FormatMessage(Win32::GetLastError);
        return;
    }
}

sub Compress {SetCompression(@_,1)}
sub Uncompress {SetCompression(@_,0)}
*UnCompress = \&Uncompress;
sub Compressed {&GetCompression}

sub CompressedSize {
 my $file = $_[0];
 my $hsize = "\0" x 4;
 my $lsize = $Win32::FileOp::GetCompressedFileSize->Call( $file, $hsize);
 return $lsize + 0x10000*unpack('L',$hsize);
}

sub UncompressDir {
    undef $Win32::FileOp::Error;
    if (ref $_[-1] eq 'CODE') {
        my $fun = pop;
        find( sub{Uncompress if &$fun}, @_);
    } else {
        find( sub {Uncompress}, @_);
    }
}
*UnCompressDir = \&UncompressDir;

sub CompressDir {
    undef $Win32::FileOp::Error;
    if (ref $_[-1] eq 'CODE') {
        my $fun = pop;
        find( sub{Compress if &$fun}, @_);
    } else {
        find( sub {Compress}, @_);
    }
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub GetLargeFileSize {
    undef $Win32::FileOp::Error;
    my ($file) = @_;
    my $handle = $Win32::FileOp::CreateFile->Call($file, 0x0080, 0, 0, 3, 0, 0); # 0x0080 = FILE_READ_ATTRIBUTES
    if($handle != -1) {
        my $buff = "\0" x 4;
        my $size1 = $Win32::FileOp::GetFileSize->Call(
            $handle, $buff
        );
        $Win32::FileOp::CloseHandle->Call($handle);
		$size1 = $size1 & 0xFFFFFFFF;
		if (wantarray()) {
			return ($size1,unpack('L',$buff));
		} else {
			return unpack('L',$buff)*0xFFFFFFFF + $size1
		}
    } else {
        $Win32::FileOp::Error = "CreateFile failed: " . Win32::FormatMessage(Win32::GetLastError);
        return;
    }
}

sub GetDiskFreeSpace {
    undef $Win32::FileOp::Error;
    my ($file) = @_;
	$file .= '\\' if $file =~ /^\\\\/ and $file !~ /\\$/;
	$file .= ':' if $file =~ /^[a-zA-Z]$/;
    my ($freePerUser,$total, $free) = ("\x0" x 8) x 3;

	$Win32::FileOp::GetDiskFreeSpaceEx->Call($file, $freePerUser,$total, $free)
		or return;

	if (wantarray()) {
		my @res;
		for ($freePerUser,$total, $free) {
			my ($lo,$hi) = unpack('LL',$_);
			push @res, ($hi & 0xFFFFFFFF) * 0xFFFFFFFF + ($lo & 0xFFFFFFFF);
		}
		return @res;
	} else {
		my ($lo,$hi) = unpack('LL',$freePerUser);
		return ($hi & 0xFFFFFFFF) * 0xFFFFFFFF + ($lo & 0xFFFFFFFF);
	}
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub FreeDriveLetters {
   undef $Win32::FileOp::Error;
   my (@dr, $i);

   my $bitmask = $Win32::FileOp::GetLogicalDrives->Call();
   for $i(0..25) {
     push (@dr, ('A'..'Z')[$i]) unless $bitmask & 2**$i;
   }
   @dr;
}


sub Map {
 undef $Win32::FileOp::Error;
 my $disk = $_[0] =~ m#^[\\/]# ? (FreeDriveLetters())[-1] : shift;
 if (!defined $disk or $disk eq '') {
  undef $disk;
 } else {
  $disk =~ s/^(\w)(:)?$/$1:/;
  $disk .= "\0";
 }
 my $type = 0; # RESOURCETYPE_ANY
 my $share = shift || croak('Ussage: Win32::FileOp::Map([$drive,]$share[,\%options])',"\n");
 $share =~ s{/}{\\}g;
 $share .= "\0";

 my $opt = shift || {};
 croak 'Ussage: Win32::FileOp::Map([$drive,]$share[,\%options])',"\n"
  unless (UNIVERSAL::isa($opt, "HASH"));
 my $username = 0;
 if (defined $opt->{user}) {
  $username = $opt->{user}."\0";
#  $username =~ s/(.)/\0$1/g if Win32::IsWinNT;
 }
 my $passwd = 0;
 if (defined $opt->{passwd} or defined $opt->{password} or defined $opt->{pwd}) {
  $passwd = ($opt->{passwd} || $opt->{password} || $opt->{pwd})."\0";
#  $passwd =~ s/(.)/\0$1/g if Win32::IsWinNT;
 }
 my $options = 0;
 $options += CONNECT_UPDATE_PROFILE if $opt->{persistent};
 $options += CONNECT_INTERACTIVE if $opt->{interactive};
 $options += CONNECT_PROMPT if $opt->{prompt};
 $options += CONNECT_REDIRECT if $opt->{redirect};

$options += CONNECT_UPDATE_RECENT;

 my $struct = pack('LLLLppLL',0,$type,0,0,$disk,$share,0,0);
 my $res;
 my $handle = undef;
 if ($opt->{interactive}) {
	 $handle = $opt->{interactive}+0;
	 $handle = GetWindowHandle() || GetDesktopHandle();
 }

 if ($res = $Win32::FileOp::WNetAddConnection3->Call( $handle, $struct, $passwd, $username, $options)) {
    if (($res == 1202 or $res == 85) and ($opt->{overwrite} or $opt->{force_overwrite})) {
        Unmap($disk,{force => $opt->{force_overwrite}})
			or return;
		$Win32::FileOp::WNetAddConnection3->Call( $handle, $struct, $passwd, $username, $options)
			and return;
	} elsif ($res == 997) { # Overlapped I/O operation is in progress.
		return 1;
    } else {
        return;
    }
 }
 if (defined $disk and $disk) {$disk} else {1};
}

sub Connect {
	Map(undef,@_);
}

sub Disconnect {
 undef $Win32::FileOp::Error;
 croak 'Ussage: Win32::FileOp::Map([$drive,]$share[,\%options])',"\n"
  unless @_;
 my $disk = shift() . "\0";$disk =~ s/^(\w)\0$/$1:\0/;
 my $opt = shift() || {};
 croak 'Ussage: Win32::FileOp::Map([$drive,]$share[,\%options])',"\n"
  unless (UNIVERSAL::isa($opt, "HASH"));
 my $options = $opt->{persistent} ? 1 : 0;
 my $force   = $opt->{force} ? 1 : 0;

 $Win32::FileOp::WNetCancelConnection2->Call($disk,$options,$force)
  and return;
 1;
}

sub Unmap {
    undef $Win32::FileOp::Error;
    if (UNIVERSAL::isa($_[1], "HASH")) {
        $_[1]->{persistent} = 1 unless exists $_[1]->{persistent};
    } else {
        $_[1] = {persistent => 1}
    }
    goto &Disconnect;
}

sub Mapped {
 undef $Win32::FileOp::Error;
 goto &_MappedAll unless (@_);
 my $disk = shift();
 if ($disk =~ m#^[\\/][\\/]#) {
    $disk =~ tr#/#\\#;
    $disk = uc $disk;
    my %drives = _MappedAll();
    my ($drive,$share);
    while (($drive,$share) = each %drives) {
        return uc($drive).':' if (uc($share) eq $disk);
    }
    return;
 } else {
  $disk =~ s/^(\w)$/$1:/;$disk.="\0";
  my $size = 1024;
  my $share = "\0" x $size;

  $size = pack('L',$size);
  $Win32::FileOp::WNetGetConnection->Call($disk,$share,$size)
   and return;
  $share =~ s/\0.*$//;
  return $share;
 }
}

sub _MappedAll {
    my %hash;
    my $share;
    foreach (('A'..'Z')) {
        $share = Mapped $_
        and
        $hash{$_}=$share;
    }
    return %hash;
}

sub Connected {
	# use WNetOpenEnum , WNetEnumResource and WNetCloseEnum
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub Subst {
 my $drive = shift;
 return unless $drive =~ s/^(\w):?$/$1:\0/;
 my $path = shift();
 return unless -e $path;
 $path.="\0";
 $Win32::FileOp::DefineDosDevice->Call(0,$drive,$path);
}

sub SubstDev {
 my $drive = shift;
 return unless $drive =~ s/^(\w):?$/$1:\0/;
 my $path = shift();
# return unless -e $path;
 $path = "\\Device\\$path" unless $path =~ /\\Device\\/i;
 $path.="\0";
 $Win32::FileOp::DefineDosDevice->Call(&DDD_RAW_TARGET_PATH,$drive,$path);
}

sub Unsubst {
 my $drive = shift;
 return unless $drive =~ s/^(\w):?$/$1:\0/;
 $Win32::FileOp::DefineDosDevice->Call(&DDD_REMOVE_DEFINITION,$drive,0);
}

sub Substed {
 my $drive = shift;
 if (defined $drive) {
  return unless $drive =~ s/^(\w):?$/$1:\0/;
  my $path = "\0" x 1024;
  my $device;
  $Win32::FileOp::QueryDosDevice->Call($drive,$path,1024)
   or return;

  $path =~ s/\0.*$//;

  $path =~ s/^\\\?\?\\UNC/\\/ and $device = 'UNC'
  or
  $path =~ s/\\Device\\(.*?)\\\w:/\\/ and $device = $1
  or
  $path =~ s/\\Device\\(.*)$// and $device = $1;

  return wantarray ? ($path,$device) : $path;
 } else {
  my ($drive,$path,%data);
  foreach $drive (('A'..'Z')) {
    $drive.=':';
    $path = Substed($drive);
    $data{$drive} = $path if defined $path;
  }
  return wantarray() ? %data : \%data;
 }
}


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

package Win32::FileOp::Error;
require Tie::Hash;
@Win32::FileOp::Error::ISA=qw(Tie::Hash);

sub TIEHASH {
    my $pkg = shift;
    my %hash = @_;
    my $self = \%hash;
    bless $self, $pkg;
}

sub FETCH { $_[0]->{$_[1]} || Win32::FormatMessage($_[1]) || "Unknown error ($_[1])" };

package Win32::FileOp;

tie %Win32::FileOp::ERRORS, 'Win32::FileOp::Error', (
 12291 => 'The buffer was too small!'
);

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

1;

__END__

#line 3088



