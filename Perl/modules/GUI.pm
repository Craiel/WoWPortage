package modules::GUI;

#-------------------------------------------------------------------------------
# Uses / Constants
#-------------------------------------------------------------------------------

use strict;
use warnings;
use Tk;
use threads;


my $blog;
#-------------------------------------------------------------------------------
# Class Initialization
#-------------------------------------------------------------------------------

sub new($$$$$)
{
  my $class  = shift;
  my $modman = shift;


  bless { 'modman' => $modman }, $class;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
sub Show($)
{
  my $self = shift;
  
  $self->{'modman'}->{'log'}->{'guiout'} = \&ShowMsg;

  my $mw = new MainWindow;

  # main menu
  # {
      my $mmenu = $mw->Frame()->pack(-side =>'top', -fill=>'x');
      my $mb_file = $mmenu->Menubutton(-text=>'File')->pack(-side => "left");

      $mb_file->command(-label   => "Sync Portage", -command => sub { $self->GC_Sync(); });                    
      $mb_file->command(-label   => "Exit", -command => sub { exit; });
                    
      #my $db_menu2 = $menu_bar->Menubutton(-text      => "Welt", -underline => 1) ->pack(-side      => "left");                           
      #$db_menu2->command(-label   => "Neue Welt", -command => \&neue_welt);                    
      #$db_menu2->command(-label   => "Welt neustarten",  -command => \&welt_neustart);
  # }

  # main view
  # {
      my $vframe = $mw->Frame(-relief => "groove",-borderwidth => "2")->pack(-fill => "both", -expand => "1", -anchor => "n");

      my $tframe  = $vframe->Frame(-relief => "groove",-borderwidth => "2")->pack(-fill => "both", -expand => "1", -anchor => "n", -side => "right");
      my $ttframe = $tframe->Frame(-relief => "groove",-borderwidth => "2")->pack(-fill => "both", -expand => "1", -anchor => "n", -side => "top");

      my $addlst = $ttframe -> Listbox(-selectmode=>'single', -width => "30")->pack(-fill => "both", -expand => "1", -anchor => "n", -side => "right");
      my $catlst = $ttframe -> Listbox(-selectmode=>'single', -width => "30")->pack(-fill => "y", -expand => "0", -anchor => "w", -side => "left");
      

      $blog = $tframe -> Scrolled('Text', -scrollbars => 'oe', -width => "30", -height => 15)->pack(-fill => "x", -anchor => "s", -side => "bottom");
      #tie (*STDOUT, 'Tk::Text' , $blog);

      my $lframe = $vframe->Frame(-relief => "groove",-borderwidth => "2")->pack(-fill => "y", -expand => "1", -anchor => "w");
      my $optlst = $lframe -> Listbox(-selectmode=>'single', -width => "30")->pack(-fill => "both", -expand => "1");
  # }  

  MainLoop;
  return;

#  $lst -> insert('end',"Student","Teacher","Clerk","Business Man",
#	"Militry Personal","Computer Expert","Others");
}

sub GC_Sync($)
{
  my $self = shift;
  $self->{'modman'}->{'sync'}->DoSync();
}

sub ShowMsg($$)
{
  my $self = shift;
  my $msg  = shift;
  
  if($blog)
  {
    $blog->insert("end", $msg);
  }
}

1;