package modules::log;

#-------------------------------------------------------------------------------
# Uses / Constants
#-------------------------------------------------------------------------------

use strict;
use warnings;

#---------------------------------------
# Constant Settings
#---------------------------------------
use constant LOG_FILE         => 'emerge.log';

#-------------------------------------------------------------------------------
# Class Initialization
#-------------------------------------------------------------------------------

sub new($$)
{
  my $self    = shift;
  my $modman  = shift;
  my $stdout  = 1;
  my $filout  = 0;
  my $guiout  = undef;


  bless { 'modman'  => $modman,
          'stdout'  => $stdout,
          'filout'  => $filout,
          'guiout'  => $guiout }, $self;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
sub LogM($$)
{
  my $self = shift;
  my $msg  = shift;
  
  if($self->{'stdout'}) { print $msg; }
  if($self->{'filout'}) { $self->PrintToFile($msg); }
  if($self->{'guiout'}) { $self->{'guiout'}($self->{'modman'}->{'gui'}, $msg); }
}

sub PrintToFile($$)
{
  my $self = shift;
  my $msg  = shift;
  
  open OUT, ">>".LOG_FILE; print OUT $msg; close OUT;
}

1;