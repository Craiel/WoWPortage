package modules::Config;

#-------------------------------------------------------------------------------
# Uses / Constants
#-------------------------------------------------------------------------------

use strict;

#-------------------------------------------------------------------------------
# Class Initialization
#-------------------------------------------------------------------------------

sub new($$)
{
  my $self   = shift;
  my $modman = shift;
  my %cfg;
  my %masked;

  bless { 'modman'  => $modman,
	  'cfg'     => \%cfg,
          'masked'  => \%masked }, $self;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
sub LoadCFG($$)
{
  my $self = shift;
  my $cfgf = shift;

  if(-e $cfgf)
  {
    open IN, "$cfgf"; my @in = <IN>; close IN;
    for(my $i=0;$i<=$#in;$i++)
    {
      if($in[$i] =~ /^([^\#].*?)=(.*?)$/)
      {
	my $val = $2;
	chomp($val);
        $self->{'cfg'}{$1} = $val;
      }
    }
  }
}

sub CheckCFG($)
{
  my $self = shift;
  
  # Check WoW Folder
  my $tmp  = $self->GetWoWRoot().'WoW.exe';
  if(!( -e $tmp)) { return -1; }
  
  # Check if Server is set
  $tmp = $self->GetConf('WWWROOT');
  if(length($tmp)<=0) { return -1; }
  
  # Check if local Portage folder is set
  $tmp = $self->GetPortDir();
  if(!(-d $tmp)) { return -3; }
  
  return 0;
}

sub GetConf($$)
{
  my $self = shift;
  my $id   = shift;
  
  if(defined($self->{'cfg'}{$id}))
  {
    return $self->{'cfg'}{$id};
  } else
  {
    return "";
  }
}

sub LoadMasked($$)
{
  my $self = shift;
  my $file = shift;
  
  if(-e $file)
  {
    open IN, "$file"; my @in = <IN>; close IN;
    for(my $i=0;$i<=$#in;$i++)
    {
      my $id = $in[$i];
      chomp($id);
      $self->{'masked'}{$id}=1;
    }
  }
}

#----------------------------------------------
# Special Routines, specific to this use

sub GetPathDelim($)
{
  my $self = shift;
  return $self->GetConf('PATHDELIM');
}

sub GetInterfaceDir($)
{
  my $self = shift;
  return $self->GetWoWRoot().'interface/';
}

sub GetPortDir($)
{
  my $self = shift;
  my $pdir = $self->GetConf('PORTDIR');
  $pdir =~ s/^(.*)[\/\\]+$/$1/;
  return $pdir.$self->GetPathDelim();
}

sub GetPortSubDir($$)
{
  my $self  = shift;
  my $addon = shift;
  return $self->GetPortDir().$addon.$self->GetPathDelim();
}

sub GetDistDir($)
{
  my $self = shift;
  my $ddir = $self->GetConf('DISTDIR');
  $ddir =~ s/^(.*)[\/\\]+$/$1/;
  return $ddir.$self->GetPathDelim();
}

sub GetWoWRoot($)
{
  my $self = shift;
  my $dir = $self->GetConf('WOWROOT');
  $dir =~ s/^(.*)[\/\\]+$/$1/;
  return $dir.$self->GetPathDelim();
}

sub GetWoWAddOnsDir($)
{
  my $self = shift;
  return $self->GetWoWRoot().'Interface'.$self->GetPathDelim().'AddOns'.$self->GetPathDelim();
}

sub GetWoWAddonDir($$)
{
  my $self  = shift;
  my $addon = shift;
  return $self->GetWoWRoot().'Interface'.$self->GetPathDelim().'AddOns'.$self->GetPathDelim().$addon.$self->GetPathDelim();
}

sub GetPortDB($)
{
  my $self = shift;
  return $self->GetPortDir().'portage.db';
}

sub GetWWWRoot($)
{
  my $self = shift;
  my $wwwr = $self->GetConf('WWWROOT');
  $wwwr =~ s/^(.*)[\/\\]+$/$1/;
  return $wwwr.'/';
}

sub GetWWWSubDir($$)
{
  my $self = shift;
  my $addon = shift;
  return $self->GetWWWRoot().$addon.'/';
}

sub GetWWWSubDirNoExt($$)
{
  my $self = shift;
  my $addon = shift;
  return $self->GetWWWRoot().$addon.'/no-ext/';
}

sub GetWWWLatest($$)
{
  my $self = shift;
  my $addon = shift;
  return $self->GetWWWRoot().$addon.'/latest.txt';
}

sub CheckUse($$)
{
  my $self = shift;
  my $flag = shift;
  my $flags = $self->GetConf('USE');
  
  if($flags =~ /$flag/) { return 1; }
  return 0;
}

sub CheckMasked($$)
{
  my $self  = shift;
  my $addon = shift;
  
  my @keys = keys(%{$self->{'masked'}});
  for(my $i=0;$i<=$#keys;$i++)
  {
    my $id = $keys[$i];
    if($addon =~ /^$id$/i) { return 1; }
  }
  return 0;
}


1;