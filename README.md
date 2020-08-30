# KotOR Savegame Editor

![](boba.bmp) 
![License](https://img.shields.io/badge/License-GPLv3-blue.svg) 
[![GitHub version](https://badge.fury.io/gh/nadrino%2Fkotor-savegame-editor-reloaded.svg)](https://github.com/nadrino/kotor-savegame-editor-reloaded/releases/)
[![Github all releases](https://img.shields.io/github/downloads/nadrino/kotor-savegame-editor-reloaded/total.svg)](https://GitHub.com/nadrino/kotor-savegame-editor-reloaded/releases/)

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
