# kse-reloaded
Kotor Savegame Editor - Recompiled with extra functionnalities

## Getting Started (Windows)

- Install perl 5.16.3.1 32bits (portable) http://strawberryperl.com/releases.html
- Unzip
- Exectue .bat file to setup the environement
- Install required dependencies :
```bat
cpan install Tk::HList
cpan install Tk::Autoscroll
cpan install Tk::DynaTabFrame
cpan install Win32::FileOp
```
- Compile the perl script :
```bat
pp --gui -o KSE.exe kse.pl
```
- KSE.exe

## Configuration
By default, kse.ini contains the kotor path to the Steam version. Feel free to set yours by hand or use KPF (https://bitbucket.org/kotorsge-team/kpf-gtk/src/master/).
