package modules::modman;

#-------------------------------------------------------------------------------
# Uses / Constants
#-------------------------------------------------------------------------------

use strict;
use warnings;

use modules::Config;
use modules::Sync;
use modules::PortageDB;
use modules::FileMan;
use modules::Merger;
use modules::GUI;
use modules::log;
use modules::history;

#---------------------------------------
# Constant Settings
#---------------------------------------
use constant CFG_FILE         => 'emerge.cfg';
use constant MASK_FILE        => 'emerge.mask';
use constant DEP_FILE         => 'emerge.depend';

#-------------------------------------------------------------------------------
# Class Initialization
#-------------------------------------------------------------------------------

sub new($)
{
  my $self = shift;
  my $conf;
  my $db;
  my $sync;
  my $fileman;
  my $merge;
  my $gui;
  my $log;
  my $history;

  bless { 'fileman'   => $fileman,
          'conf'      => $conf,
          'sync'      => $sync,
          'merge'     => $merge,
          'history'   => $history,
          'gui'       => $gui,
          'log'       => $log,
	  'db'        => $db }, $self;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
sub InitModules($)
{
    my $self = shift;
    
    # Initialize Log
    $self->{'log'}     = new modules::log($self);
    
    # Initialize Configuration
    $self->{'conf'} = new modules::Config();
    $self->{'conf'}->LoadCFG(CFG_FILE);
    $self->{'conf'}->LoadMasked(MASK_FILE);
    
    # Initialize Database
    $self->{'db'} = new modules::PortageDB($self);
    if(!$self->{'db'}->Init())
    {
      $self->{'modman'}->{'log'}->LogM("DB Initialization Error\n");
      exit;
    }

    # Initialize Workers
    $self->{'fileman'} = new modules::FileMan($self);
    $self->{'sync'}    = new modules::Sync($self);
    $self->{'merge'}   = new modules::Merger($self);
    $self->{'history'} = new modules::history($self);
    $self->{'gui'}     = new modules::GUI($self);
    
    
    if($self->{'conf'}->CheckCFG() == 0)
    {
      $self->{'merge'}->LoadDependencies(DEP_FILE);
      $self->{'merge'}->ScanInstalled();
      
      return 1;
    }
    
    return 0;
}


1;