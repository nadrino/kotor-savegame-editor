# KotOR Savegame Editor

Recompiled with extra functionnalities

## Getting Started (Windows)

- Install perl 5.16.3.1 32bits (portable) http://strawberryperl.com/releases.html
- Unzip
- Open Powershell
- Exectue .bat file in the unzipped directory to setup the environement for perl
- Install required dependencies :
```bat
cpan install Tk::HList
cpan install Tk::Autoscroll
cpan install Tk::DynaTabFrame
cpan install Win32::FileOp
cpan -fi PAR::Packer
```
- Compile the perl script :
```bat
pp --gui -o KSE.exe kse.pl
```
- Launch KSE.exe

## Configuration
By default, kse.ini contains the kotor path to the Steam version. Feel free to set yours by hand or use KPF (https://bitbucket.org/kotorsge-team/kpf-gtk/src/master/).
