#!/usr/bin/perl -w

use strict;
use warnings;
use Cwd;

use modules::modman;

#---------------------------------------
# Constant Settings
#---------------------------------------
use constant GLOBAL_VERSION   => '0.1.30';

#---------------------------------------
# Initialization
#---------------------------------------
my %argparams;
my $modman = new modules::modman();
if($modman->InitModules())
{
    &ParseCmd();
    $modman->{'db'}->SaveDB();
}
exit;

#---------------------------------------
# Subs
#---------------------------------------
sub ParseCmd()
{
    if($#ARGV >=0)
    {
        FilterArguments();
        
        if($argparams{'cmd'})
        {
          if($argparams{'cmd'} eq 'y')
          {
            $modman->{'sync'}->DoSync();
            return;
          }
          if($argparams{'cmd'} eq 's')
          {
            $modman->{'merge'}->Search(\%{$argparams{'addons'}});
            return;
          }
          if($argparams{'cmd'} eq 'd')
          {
            $modman->{'merge'}->Unmerge(\%{$argparams{'addons'}}, \%{$argparams{'parm'}});
            return;
          }
          if($argparams{'cmd'} eq 'l')
          {
            $modman->{'merge'}->ListNonAce();
            return;
          }
	  if($argparams{'cmd'} eq 'g')
          {
            $modman->{'gui'}->Show();
            return;
          }
        }
        $modman->{'merge'}->Emerge(\%{$argparams{'addons'}}, \%{$argparams{'parm'}});
        return;
    }
    
    ShowUsage();
}

sub FilterArguments()
{
    for(my $i=0;$i<=$#ARGV;$i++)
    {
        if($ARGV[$i] =~ /^-([^-].*)/)
        {
            SetMultiParam($1);
        } else
        {
          if($ARGV[$i] =~ /^--(.*)/)
          {
            SetSingleParam($1);
          } else
          {
            $argparams{'addons'}{$ARGV[$i]} = 1;
          }
        }
    }
}

sub SetSingleParam($)
{
    my $param = shift;
    
    if(($param eq "search")     ||($param eq "s")) { $argparams{'cmd'}           = 's';  }
    if(($param eq "update")     ||($param eq "u")) { $argparams{'cmd'}           = 'u';  }
    if(($param eq "sync")       ||($param eq "y")) { $argparams{'cmd'}           = 'y';  }
    if(($param eq "unmerge")    ||($param eq "d")) { $argparams{'cmd'}           = 'd';  }
    if(($param eq "listnonace") ||($param eq "l")) { $argparams{'cmd'}           = 'l';  }
    if(($param eq "showgui")    ||($param eq "g")) { $argparams{'cmd'}           = 'g';  }
    if(($param eq "fetch")      ||($param eq "f")) { $argparams{'parm'}{'fo'}    = 1;    }
    if(($param eq "pretend")    ||($param eq "p")) { $argparams{'parm'}{'pret'}  = 1;    }
    if(($param eq "reinstall")  ||($param eq "r")) { $argparams{'parm'}{'reinst'} = 1;    }
}

sub SetMultiParam($)
{
    my $mparam = shift;
    my @lt = split('|', $mparam);
    for(my $i=0;$i<=$#lt;$i++)
    {
        SetSingleParam($lt[$i]);
    }
}

sub ShowUsage()
{
    $modman->{'log'}->LogM("WoWAce Portage ".GLOBAL_VERSION."\n\n");
    $modman->{'log'}->LogM("usage:\n");
    $modman->{'log'}->LogM("emerge.pl cmd <param1> ...\n");
    $modman->{'log'}->LogM("--------------------------\n");
    $modman->{'log'}->LogM("   <name>\tEmerges selected Addon(s)\n\n");
    $modman->{'log'}->LogM(" List of Options:\n");
    $modman->{'log'}->LogM("   --search\t-s\tSearch for Packages\n");
    $modman->{'log'}->LogM("   --sync\t-y\tSyncs the local Portage Directory\n");
    $modman->{'log'}->LogM("   --update\t-u\tUpdate Selected Packages\n");
    $modman->{'log'}->LogM("   --unmerge\t-r\tRemoves selected Addons\n");
    $modman->{'log'}->LogM("   --fetch\t-f\tFetches Addon Zip's without installing them\n");
    $modman->{'log'}->LogM("   --pretend\t-p\tPretends to Update without actually doing anything\n");
    $modman->{'log'}->LogM("   --reinstall\t-r\tForces Installation even if same Version\n");
    $modman->{'log'}->LogM("   --showgui\t-g\tDisplays the Graphical User Interface\n");
    $modman->{'log'}->LogM("\n");
    $modman->{'log'}->LogM(" Examples:\n");
    $modman->{'log'}->LogM("   Update all Installed Packages:\n");
    $modman->{'log'}->LogM("     emerge.pl --update world\n\n");
    $modman->{'log'}->LogM("   Update Cartographer and FuBar:\n");
    $modman->{'log'}->LogM("     emerge.pl --update Cartographer FuBar\n\n");
    $modman->{'log'}->LogM("   Pretend to Update all Installed Packages:\n");
    $modman->{'log'}->LogM("     emerge.pl -up world\n");
    $modman->{'log'}->LogM("   Search FuBar Addons\n");
    $modman->{'log'}->LogM("     emerge.pl --search FuBar\n\n");
    $modman->{'log'}->LogM("   Install BigWigs\n");
    $modman->{'log'}->LogM("     emerge.pl BigWigs");
}