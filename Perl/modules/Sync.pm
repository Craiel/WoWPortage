package modules::Sync;

#-------------------------------------------------------------------------------
# Uses / Constants
#-------------------------------------------------------------------------------

use strict;
use LWP::UserAgent;
use HTTP::Request;

#-------------------------------------------------------------------------------
# Class Initialization
#-------------------------------------------------------------------------------

sub new($$$)
{
  my $class  = shift;
  my $modman = shift;
  my $updated= 0;

  bless { 'modman'   => $modman,
          'updated'  => $updated }, $class;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------

sub DoSync($)
{
    my $self = shift;
    my $wwwroot = $self->{'modman'}->{'conf'}->GetWWWRoot();
    
    if(length($wwwroot) > 0)
    {
        $self->{'modman'}->{'log'}->LogM("Synching with $wwwroot\n");
        my $data = "";
        if($self->GetWWWContent($wwwroot, \$data))
        {
          $self->ProcessData($data);
        }
    }
}

sub GetWWWContent($$$)
{
    my $self = shift;
    my $url  = shift;
    my $target = shift;
    
    $self->{'modman'}->{'log'}->LogM(" ==> $url\n");
    
    my $browser = LWP::UserAgent->new();
    $browser->timeout(25);
    my $request = HTTP::Request->new(GET => $url);
    my $data = $browser->request($request);
      
    if($data->is_error())
    {
        $self->{'modman'}->{'log'}->LogM("ERROR: ".$data->status_line()."\n");
    } else
    {
        $$target = $data->content();
        return 1;
    }
    return 0;
}

# Syncs from a local saved webpage
# NOTE: This should normally not be used, good for initially setting up a portage without bothering the server
sub DoSyncLocal($$)
{
    my $self = shift;
    my $wwwfile = shift;
    
    if(-e $wwwfile)
    {
        open IN, $wwwfile; my @in = <IN>; my $in = join('', @in); close IN;
        $self->ProcessData($in);
    } else
    {
        $self->{'modman'}->{'log'}->LogM("Local Sync-File could not be found\n");
    }
}

sub ProcessData($$)
{
    my $self = shift;
    my $data = shift;
    my $entrys = 0;
    my @checked;
    
    $self->{'updated'} = 0;
    
    $self->{'modman'}->{'log'}->LogM("Processing ".length($data)." bytes...\n");
    $data =~ s/\n//g;
    $data =~ s/^.*<table id= 'addons'.*?(<tr>.*$)/$1/i;
    $data =~ s/^(.*?)<\/table>.*$/$1/i;

    while($data =~ /<tr>(.*?)<\/tr>/g)
    {        
        if($self->ProcessDatLine($1, \@checked)) { $entrys++; }
    }

    my $delcount = $self->{'modman'}->{'db'}->CheckDeletes(\@checked);

    $self->{'modman'}->{'log'}->LogM("$entrys Entrys Processed, ".$self->{'updated'}." Updated, ".$delcount." Deleted\n");
}

sub ProcessDatLine($$$)
{
    my $self    = shift;
    my $line    = shift;
    my $checked = shift;
    my $name    = "";
    my $date    = "";
    my $ver     = -1;
    my $desc    = "";
    my @fields;
    my @checked;

    while($line =~ /<td.*?>(.*?)<\/td>/gi)
    {
	print "$1\n";
      push(@fields, $1);
    }
    
    if($#fields == 3)
    {
      if($fields[0] =~ /<a href=\"(.*?)\">(.*?)<\/a>/i)
      {
        if($1 eq '#') { return 1; }
        $name = $2;
        
        $ver = $fields[1];
        $ver =~ s/^r([0-9]+)$/$1/i;
        
        $date = $fields[2];
        $date =~ s/&nbsp;/ /gi;
        $date =~ s/-0500//;
        
        $desc = $fields[3];
        
        if(!($self->MergeEntry($name, $ver, $date, $desc)))
        {
          $self->{'modman'}->{'log'}->LogM("Error Processing \"$name\" Addon\n");
        } else
	{
	  push(@{$checked}, $name);
	}
      }
    }

    

    return 1;
}

sub MergeEntry($$$$$)
{
    my $self = shift;
    my $name = shift;
    my $ver  = shift;
    my $date = shift;
    my $desc = shift;

    if(!($self->{'modman'}->{'db'}->CheckAddonUpdate($name, $ver)))
    {
	$self->{'modman'}->{'log'}->LogM(">>> $name\n");
        $self->{'modman'}->{'db'}->UpdateAddon($name, $ver, $date, $desc);
        
        $self->{'updated'}++;
    } else
    {
        $self->{'modman'}->{'log'}->LogM("--- $name\n");
    }
    
    return 1;
}

1;