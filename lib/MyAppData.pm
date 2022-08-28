#line 1 "MyAppData.pm"
use warnings;
use strict;
package MyAppData;

sub new
{
	my $class = shift;
	my $self = { };

	bless $self, $class;

	return $self;
}

sub getusername
{
	return getlogin || getpwuid($<) || "kaleb";
}

sub getappdata
{
	my ($self) = @_;
	my $appdataVPlus64 = "C:\\Users\\" . $self->getusername() . "\\AppData\\Local\\VirtualStore\\Program Files (x86)\\LucasArts";
	my $appdataVPlus86 = "C:\\Users\\" . $self->getusername() . "\\AppData\\Local\\VirtualStore\\Program Files\\LucasArts";
	my $appdataVSub = "C:\\Documents and Settings\\" . $self->getusername() . "\\AppData\\Local\\VirtualStore\\Program Files\\LucasArts";

	if(opendir DIR, $appdataVPlus64)
	{
		close DIR;
		return $appdataVPlus64;
	}
	elsif(opendir DIR, $appdataVPlus86)
	{
		close DIR;
		return $appdataVPlus86;
	}
	elsif(opendir DIR, $appdataVSub)
	{
		close DIR;
		return $appdataVSub;
	}
	else
	{
		return "Failed to detect directory!";
	}
}

1;