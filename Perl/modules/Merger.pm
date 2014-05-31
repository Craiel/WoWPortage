package modules::Merger;

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
  my %dep;
  my %inst;

  bless { 'modman'   => $modman,
	  'dep'      => \%dep,
	  'inst'     => \%inst}, $self;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
sub LoadDependencies($$)
{
  my $self = shift;
  my $file = shift;
  
  if(-e $file)
  {
    open IN, $file; my @in = <IN>; close IN;
    for(my $i=0;$i<=$#in;$i++)
    {
      my @tmp = split('\|', $in[$i]);

      if($#tmp == 1)
      {
        my $id = $tmp[0];
        @tmp = split(',', $tmp[1]);
	$self->{'dep'}{$id} = \@tmp;
      }
    }
  }
}

sub ScanInstalled($)
{
  my $self = shift;
  my $intd = $self->{'modman'}->{'conf'}->GetWoWAddOnsDir();
  
  if(-d $intd)
  {
    opendir(DIR, $intd);
    my @contents = readdir(DIR);
    closedir DIR;
  
    for(my $i=0;$i<=$#contents;$i++)
    {
      if(!($contents[$i] eq '.')&&!($contents[$i] eq '..'))
      {
        $self->CheckInstalled($contents[$i]);
      }
    }
  }
}

sub CheckInstalled($$)
{
  my $self = shift;
  my $id   = shift;

  if($id =~ /^Blizzard_/i) { return; }
  
  if($self->{'modman'}->{'db'}->IsAceAddon($id))
  {
    $self->{'inst'}{$id} = $self->GetInstalledVersion($id);
    return;
  }
  $self->{'inst'}{$id} = 0;
}

sub GetInstalledVersion($$)
{
  my $self = shift;
  my $id   = shift;
  my $ldir = $self->{'modman'}->{'conf'}->GetWoWAddonDir($id);
  my $ver  = 0;
  if(-d $ldir)
  {
    opendir(DIR, $ldir);
    my @files = readdir(DIR);
    closedir DIR;
    
    for(my $i=0;$i<=$#files;$i++)
    {
      if($files[$i] =~ /changelog.*-r([0-9]+)\.txt/i)
      {
	if($1 > $ver) { $ver = $1; }
      }
    }
  }
  return $ver;
}

sub InstalledVersion($$)
{
  my $self = shift;
  my $id   = shift;
  
  if($self->{'inst'}{$id})
  {
    return $self->{'inst'}{$id};
  }
  return "";
}

sub GetInstalledName($$)
{
  my $self = shift;
  my $id   = shift;
  
  my @instk = keys(%{$self->{'inst'}});
  for(my $i=0;$i<=$#instk;$i++)
  {
    if($instk[$i] =~ /$id/i) { return $instk[$i]; }
  }
  return "";
}

sub GetHits($$$$)
{
  my $self   = shift;
  my $what   = shift;
  my $target = shift;
  my $exact  = shift;
  my $depend = shift;
  my @what   = keys(%{$what});
  
  for(my $i=0;$i<=$#what;$i++)
  {
    $what = $what[$i];
    if($what =~ /^world$/i)
    {
      my @keys = keys(%{$self->{'inst'}});
      push(@{$target}, @keys);
    } else
    {
      if($what =~ /^allfordev$/i)
      {
        #$self->{'modman'}->{'log'}->LogM("WARNING, you should not use this call!!!\n");
        #$self->{'modman'}->{'db'}->VTSearch(".*", $target, $exact, 0);
      } else
      {
        $self->{'modman'}->{'db'}->VTSearch($what, $target, $exact, 0)
      }
    }
  }
  
  if(($self->{'modman'}->{'conf'}->CheckUse('noext')) && ($depend))
  {
    $self->{'modman'}->{'log'}->LogM("\nChecking Dependencies...\n");
    $self->ProcessDependencies($target);
  }
  
  my %clean;
  for(my $i=0;$i<=$#{$target};$i++)
  {
    if(!(${$target}[$i] =~ /^~/))
    {
      $clean{${$target}[$i]} = 1;
    }
  }
  @{$target} = sort keys(%clean);
}

sub ProcessDependencies($$)
{
  my $self = shift;
  my $adds = shift;
  my @out;
  my %nodep;
  
  for(my $i=0;$i<=$#{$adds};$i++)
  {
    my $id = ${$adds}[$i];
    chomp($id);
    push(@out, $id);
    if($self->{'dep'}{$id})
    {
      my @tmp = @{$self->{'dep'}{$id}};
      $self->ProcessDependencies(\@tmp);
      push(@out, @tmp);
    } else
    {
      if(!($id eq '~NONE~'))
      {
        $nodep{$id} = 1;
      }
    }
  }

  #my @keys = sort keys(%nodep);
  #for(my $i=0;$i<=$#keys;$i++)
  #{
  #  $self->{'modman'}->{'log'}->LogM("DEBUG: $keys[$i] has no Dependencys\n");
  #}

  push(@{$adds},@out);
}

sub Search($$)
{
  my $self = shift;
  my $what = shift;
  my @hits;
  
  $self->{'modman'}->{'log'}->LogM("Searching...\n");
  $self->GetHits($what, \@hits, 0, 0);
  if($#hits < 0)
  {
    $self->{'modman'}->{'log'}->LogM("No matching Addons found\n");
    return;
  }
  $self->ShowMergeList(\@hits, 1);
}

sub Emerge($$$$)
{
  my $self    = shift;
  my $what    = shift;
  my $parm    = shift;
  
  # Search and Update selected package
  my @hits;
  $self->GetHits($what, \@hits, 1, 1);

  if($#hits < 0)
  {
    $self->{'modman'}->{'log'}->LogM("No Addons to Emerge found\n");
    return;
  }
  
  my @mergelist;
  for(my $i=0;$i<=$#hits;$i++)
  {
    my $id = $hits[$i];
    if($self->{'modman'}->{'conf'}->CheckMasked($id))
    {
      $self->{'modman'}->{'log'}->LogM("$id is Masked!\n");
      return;
    }
      
    my $ver  = $self->{'modman'}->{'db'}->GetVersion($id);
    my $iver = $self->InstalledVersion($id);
      
    if(!($ver eq "") && ($ver > 0))
    {
      my $bskip = 0;
      if(!(${$parm}{'reinst'}))
      {
        if($iver eq $ver)
        {
    	  $bskip = 1;
        }
      }
      if($bskip == 0)
      {
        push(@mergelist, $id);
      }
    }
  }
  
  if($#mergelist < 0)
  {
    $self->{'modman'}->{'log'}->LogM("No Packages to emerge\n");
    return;
  }
  
  if(${$parm}{'pret'})
  {
    $self->{'modman'}->{'log'}->LogM("These are the Packages that would be merged, in order:\n\n");
    $self->ShowMergeList(\@mergelist, 2);
  } else
  {
    $self->StartMerge(\@mergelist, ${$parm}{'fo'});
  }
}

sub Unmerge($$$)
{
  my $self = shift;
  my $what = shift;
  my $parm = shift;
  
  my @hits = keys(%{$what});
  my @queue;
  for(my $i=0;$i<=$#hits;$i++)
  {
    my $id = $self->GetInstalledName($hits[$i]);
    if(!($id eq "")) { push(@queue, $id); }
  }
  
  if($#queue < 0)
  {
    $self->{'modman'}->{'log'}->LogM("No Addons to Unmerge found\n");
    return;
  }
  
  for(my $i=0;$i<=$#queue;$i++)
  {
    my $id = $queue[$i];
    $self->{'modman'}->{'log'}->LogM("\n>>> Unmerging (".($i+1)." of ".($#hits+1).") ".$id."\n");
    $self->{'modman'}->{'fileman'}->UninstAddon($id);
  }
}

sub ListNonAce($$)
{
  my $self = shift;
  my $what = shift;
  
  my @nonace;
  my @instk = keys(%{$self->{'inst'}});
  for(my $i=0;$i<=$#instk;$i++)
  {
    my $id = $instk[$i];
    if(!($id =~ /^blizzard_/i))
    {
      my $ver  = $self->{'modman'}->{'db'}->GetVersion($id);
      if(($ver eq "")||($ver <= 0))
      {
        push(@nonace, $id);
      }
    }
  }
  
  if($#nonace >= 0)
  {
    $self->{'modman'}->{'log'}->LogM("List of Non-Ace Addons:\n");
    $self->ShowMergeList(\@nonace, 2);
  } else
  {
    $self->{'modman'}->{'log'}->LogM("No Non-Ace Addons found\n");
  }
}

sub StartMerge($$$)
{
  my $self  = shift;
  my $todo  = shift;
  my $fetch = shift;
  
  for(my $i=0;$i<=$#{$todo};$i++)
  {
    my $id  = ${$todo}[$i];
    my $ver = $self->{'modman'}->{'db'}->GetVersion($id);
    my $refn = $self->{'modman'}->{'db'}->GetServerFileName($id, $ver);
    my $refd = $self->{'modman'}->{'db'}->GetWWWBase($id);
    
    $self->{'modman'}->{'log'}->LogM("\n>>> Emerging (".($i+1)." of ".($#{$todo}+1).") ".$id."\n");
    if($self->{'modman'}->{'fileman'}->GetFile($refn, $refd))
    {
      if(!($fetch))
      {
        $self->{'modman'}->{'fileman'}->InstallFile($refn, $id);
      }
    }
  }
}

sub ShowMergeList($$$)
{
  my $self   = shift;
  my $list   = shift;
  my $format = shift;
  
  my @list = sort @{$list};
  
  for(my $i=0;$i<=$#list;$i++)
  {
    my $ver  = $self->{'modman'}->{'db'}->GetVersion($list[$i]);
    my $iver = $self->InstalledVersion($list[$i]);
    my $date = $self->{'modman'}->{'db'}->GetBadDate($self->{'modman'}->{'db'}->GetDate($list[$i]));
    my $size = "";
    my $desc = $self->{'modman'}->{'db'}->GetDesc($list[$i]);
    my $mask = "";
    if($self->{'modman'}->{'conf'}->CheckMasked($list[$i]))
    {
      $mask = "[ Masked ]";
    }
    
    if($format == 1)
    {
      $self->{'modman'}->{'log'}->LogM("\n");
      $self->{'modman'}->{'log'}->LogM("*  ".$list[$i]."\n");
      $self->{'modman'}->{'log'}->LogM("\tLatest version avaliable: ".$ver." ".$mask."\n");
      $self->{'modman'}->{'log'}->LogM("\tLatest version installed: ".$iver."\n");
      $self->{'modman'}->{'log'}->LogM("\tSize of Files: ".$size."\n");
      $self->{'modman'}->{'log'}->LogM("\tDescription  : ".$desc."\n");
      $self->{'modman'}->{'log'}->LogM("\tlast changed : ".$date."\n");
    }
    if($format == 2)
    {
      my $status = "[    ]";
      if($iver eq "")
      {
	$status = "[  N ]";
      } else
      {
	if($iver eq $ver)
	{
	  $status = "[R   ]";
	} else
	{
	  if($iver < $ver)
	  {
	    $status = "[   U]";
	  } else
	  {
	    $status = "[ D  ]";
	  }
	}
	
	$iver = '['.$iver.']';
      }
      print $status." ".$list[$i]."-r".$ver." ".$iver."\n";
    }
  }
}

1;