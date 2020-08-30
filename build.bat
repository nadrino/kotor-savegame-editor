:: Not echoing commands
@echo off

:: This script folder
set HERE=%~dp0

:: Does perl is installed here ?
if not exist "%HERE%\strawberry-perl-5.16.3.1-32bit-portable\portableshell.bat" (
    echo Expected %HERE%\strawberry-perl-5.16.3.1-32bit-portable\portableshell.bat has not been found.
    echo Please download the corresponding archive on http://strawberryperl.com/releases.html
    echo Will try to compile with system wide perl.
)

:: Adding local perl libs
set PATH=%HERE%\strawberry-perl-5.16.3.1-32bit-portable\perl\bin;%PATH%
set PATH=%HERE%\strawberry-perl-5.16.3.1-32bit-portable\perl\site\bin;%PATH%

:: Compile
echo Compiling KSE...
call pp kse.pl -u -o KSE.exe
:: call pp kse.pl -o KSE.exe --gui

echo Applying icon...
:: Causes corruption -> not used for debug
:: call perl -e "use Win32::Exe; $exe = Win32::Exe->new('KSE.exe'); $exe->set_single_group_icon('boba.ico'); $exe->write;"
:: perl icon.pl kse.exe boba.ico

echo Launching KSE...
call .\KSE.exe
