package modules::PortageDB;
 
#-------------------------------------------------------------------------------
# Uses / Constants
#-------------------------------------------------------------------------------

use strict;
use Time::Local;
use POSIX qw(strftime);

#-------------------------------------------------------------------------------
# Class Initialization
#-------------------------------------------------------------------------------

sub new($$)
{
  my $self  = shift;
  my $modman = shift;
  my %db;

  bless { 'db'     => \%db,
          'modman' => $modman }, $self;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
sub Init($)
{
  my $self = shift;
  my $dbf  = $self->{'modman'}->{'conf'}->GetPortDB();
  
  if(-e $dbf)
  {
    $self->LoadDB($dbf);
  }
  
  return 1;
}

sub LoadDB($$)
{
  my $self = shift;
  my $dbf  = shift;
  
  if(-e $dbf)
  {
    open IN, "$dbf"; my @in = <IN>; close IN;
    for(my $i=0;$i<=$#in;$i++)
    {
      $self->UnpackEntry($in[$i]);
    }
  }
}

sub SaveDB($)
{
  my $self = shift;
  my $dbf  = $self->{'modman'}->{'conf'}->GetPortDB();
  
  open OUT, ">$dbf";
  my @keys = keys(%{$self->{'db'}});
  for(my $i=0;$i<=$#keys;$i++)
  {
    print OUT $self->PackEntry($keys[$i])."\n";
  }
  close OUT;
}

sub PackEntry($$)
{
  my $self   = shift;
  my $id     = shift;
  my $out    = "";
  
  if(defined($self->{'db'}{$id}))
  {
    $out .= $id;
    $out .= '|'.$self->{'db'}{$id}{'date'};
    $out .= '|'.$self->{'db'}{$id}{'latest'};
    $out .= '|'.$self->{'db'}{$id}{'desc'};
  }
  return $out;
}

sub UnpackEntry($$)
{
  my $self   = shift;
  my $packed = shift;
  chomp($packed);
  my @data   = split('\|', $packed);
  if($#data == 3)
  {
    $self->{'db'}{$data[0]}{'date'}   = $data[1];
    $self->{'db'}{$data[0]}{'latest'} = $data[2];
    $self->{'db'}{$data[0]}{'desc'}   = $data[3];
    $self->{'db'}{$data[0]}{'mod'}    = 0;
  } else
  {
    $self->{'modman'}->{'log'}->LogM("Error in DB: ".$packed."\n");
  }
}

sub CheckAddonUpdate($$$)
{
  my $self  = shift;
  my $addon = shift;
  my $ver   = shift;
  
  if(defined($self->{'db'}{$addon}))
  {
    return ($self->{'db'}{$addon}{'latest'} eq $ver);
  }
  return 0;
}

sub UpdateAddon($$$$$$)
{
  my $self  = shift;
  my $name  = shift;
  my $ver   = shift;
  my $date  = shift;
  my $desc  = shift;  
  
  $self->{'db'}{$name}{'date'}   = $self->GetGoodDate($date);
  $self->{'db'}{$name}{'latest'} = $ver;
  $self->{'db'}{$name}{'desc'}   = $self->MakeGoodDesc($desc);
  $self->{'db'}{$name}{'mod'}    = 1;
}

sub MakeGoodDesc($$)
{
  my $self = shift;
  my $desc = shift;

  $self->{'modman'}->{'log'}->LogM("Desc: <<  $desc\n");
  $desc =~ s/\|c[0-9a-f]{8}(.*?)\|r/$1/i;
  $self->{'modman'}->{'log'}->LogM("Desc: >>  $desc\n");
  return $desc;
}

sub CheckDeletes($$)
{
  my $self    = shift;
  my $updated = shift;
  my @keys    = keys(%{$self->{'db'}});
  my $count   = 0;

  for(my $i=0;$i<=$#keys;$i++)
  {
    my $found = -1;
    my $name  = $keys[$i];  

    for(my $j = 0; $j<=$#{$updated}; $j++)
    {
      my $nam2  = ${$updated}[$j];

      if($nam2 =~ /$name/i)
      {
        $found = $j; $j = $#{$updated}+1;
      }
    }
    if(!($found >= 0))
    {
      $self->{'modman'}->{'log'}->LogM("<<< $name\n");
      delete($self->{'db'}{$name});
      $count++;
    }
  }
  return $count;
}

sub GetBadDate($$)
{
  my $self = shift;
  my $date = shift;
  
  if(!($date =~ /^$/))
  {
    return strftime "%Y-%B-%d %H:%M:%S ", localtime($date);
  }
  return $date;
}

sub GetGoodDate($$)
{
  my $self = shift;
  my $date = shift;
  if($date =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})\s([0-9]{2}):([0-9]{2}):([0-9]{2})/)
  {
    my $year   = $1;
    my $month  = $2;
    my $day    = $3;
    my $hour   = $4;
    my $minute = $5;
    my $second = $6;
    
    return timelocal($second,$minute,$hour,$day,$month - 1,$year);
  }
}

sub VTSearch($$$$$)
{
  my $self = shift;
  my $what = shift;
  my $dest = shift;
  my $exact= shift;
  my $clear= shift;
  if($clear)
  {
    @{$dest} = ();
  }
  
  my $sre;
  if($exact)
  {
    $sre = '^'.$what.'$';
  } else
  {
    $sre = $what;
  }
  
  my @keys = keys(%{$self->{'db'}});
  for(my $i=0;$i<=$#keys;$i++)
  {
    if($keys[$i] =~ /$sre/i)
    {
      push(@{$dest}, $keys[$i]);
    }
  }
}

sub GetVersion($$)
{
  my $self = shift;
  my $id   = shift;
  
  if($self->{'db'}{$id})
  {
    return $self->{'db'}{$id}{'latest'};
  }
  return "";
}

sub GetDate($$)
{
  my $self = shift;
  my $id   = shift;
  
  if($self->{'db'}{$id})
  {
    return $self->{'db'}{$id}{'date'};
  }
  return "";
}

sub GetDesc($$)
{
  my $self = shift;
  my $id   = shift;
  
  if($self->{'db'}{$id})
  {
    return $self->{'db'}{$id}{'desc'};
  }
  return "";
}

sub IsAceAddon($$)
{
  my $self = shift;
  my $id   = shift;
  
  if($self->{'db'}{$id}) { return 1; }
  return 0;
}

sub GetServerFileName($$$)
{
  my $self = shift;
  my $id   = shift;
  my $ver  = shift;
  
  return $id.'-r'.$ver.'.zip';
}

sub GetWWWBase($$)
{
  my $self = shift;
  my $id   = shift;
  my $base = $self->{'modman'}->{'conf'}->GetWWWSubDir($id);
  if($self->{'modman'}->{'conf'}->CheckUse('noext'))
  {
    $base = $self->{'modman'}->{'conf'}->GetWWWSubDirNoExt($id);
  }
}

1;