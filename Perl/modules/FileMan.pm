package modules::FileMan;

#-------------------------------------------------------------------------------
# Uses / Constants
#-------------------------------------------------------------------------------

use strict;
use LWP::UserAgent;
use HTTP::Request;
use Archive::Zip;
use Cwd;
use File::Temp qw/ tempdir /;
use File::Path;
use File::Copy;

#-------------------------------------------------------------------------------
# Class Initialization
#-------------------------------------------------------------------------------

sub new($$$)
{
  my $class  = shift;
  my $modman = shift;

  bless { 'modman'     => $modman }, $class;
}

#-------------------------------------------------------------------------------
# Main Functions
#-------------------------------------------------------------------------------
sub GetFile($$$)
{
  my $self = shift;
  my $file = shift;
  my $link = shift;
  my $dest = $self->{'modman'}->{'conf'}->GetDistDir();
  my $ua = LWP::UserAgent->new;
  if(-e $dest.$file)
  {
    $self->{'modman'}->{'log'}->LogM(" * ".$dest.$file." ;-) ...\n\n");
    return 1;
  }
  
  $self->{'modman'}->{'log'}->LogM(">>> Downloading '".$link.$file."'\n");
  $self->{'modman'}->{'log'}->LogM("    => ".$dest.$file."\n\n");
  my $length;
  my $bdone = 0;
  my $lastv = -1;  
  
  open OUT, ">$dest$file";
  binmode(OUT);
  my $res = $ua->request(HTTP::Request->new(GET => $link.$file),
                    sub {
                          my ( $chunk, $res ) = @_;
                          $bdone += length($chunk);
                          unless(defined $length)
                          {
                            $length = $res->content_length || 0;
                            $self->{'modman'}->{'log'}->LogM("Length: $length [".$res->content_type."\n\n");
                            $self->{'modman'}->{'log'}->LogM("[");
                          } else
                          {
                            if($length)
                            {
                              my $value= int (100 * $bdone / $length) || 0;
                              if($value != $lastv)
                              {
                                $self->{'modman'}->{'log'}->LogM(".");
                                $lastv = $value;
                              }
                            }
                          }
                          print OUT $chunk;
                        }
                         
                        );
  $self->{'modman'}->{'log'}->LogM("]\n\n");
  close OUT;
  
  if($bdone == $length)
  {
    $self->{'modman'}->{'log'}->LogM("File Downloaded successfully!\n\n");
    return 1;
  } else
  {
    rmdir($dest.$file);
    $self->{'modman'}->{'log'}->LogM("Download Incomplete!\n\n");
  }
  return 0;
}



sub InstallFile($$$)
{
  my $self  = shift;
  my $file  = shift;
  my $fname = shift;
  my $dest  = $self->{'modman'}->{'conf'}->GetWoWAddOnsDir();
  $file = $self->{'modman'}->{'conf'}->GetDistDir().$file;
  
  if(-e $file)
  {
    my $tmpd = tempdir( CLEANUP => 1 );  
    my $zip = Archive::Zip->new($file);
    my $cwd = getcwd();
    
    chdir($tmpd);
    my $ret = $zip->extractTree();
    chdir($cwd);
    if($ret == 0)
    {
      my $from = $tmpd.$self->{'modman'}->{'conf'}->GetPathDelim().$fname;
      if(-d $from)
      {
        if($self->{'modman'}->{'conf'}->CheckUse('replace'))
        {
          rmtree($dest.$fname, 0, 1);
        }
        copyFile($from, $dest);
      } else
      {
        $self->{'modman'}->{'log'}->LogM("Error in Archive, Extracted OK but expected folder missing\n");
      }      
    } else
    {
      $self->{'modman'}->{'log'}->LogM("Error Extracting ZIP Archife: $file\n");
    }    
  }
}

sub UninstAddon($$)
{
  my $self  = shift;
  my $addon = shift;
  my $dest  = $self->{'modman'}->{'conf'}->GetWoWAddOnsDir();
  if(-d $dest.$addon)
  {
    rmtree($dest.$addon, 0, 1);
    $self->{'modman'}->{'log'}->LogM("  -- DEL: ".$dest.$addon."\n");
  } else
  {
    $self->{'modman'}->{'log'}->LogM("Selected Addon could not be unmerged: $addon\n");
  }
}

sub copyFile 
{ 
    my ($copyFile, $path) = @_; 

    #$self->{'modman'}->{'log'}->LogM(">>> $copyFile\n");
    unless(copy($copyFile, $path)) 
    { 
        failedToCopy($copyFile, $path); 
    } 

} 

sub failedToCopy 
{ 
    my ($copyFile, $path) = @_;
    my $dir = "";
    if($copyFile =~ /[\/\\]([^\/\\]+)$/)
    {
      $dir = $path.$1.'/';
    } else
    {
      $dir = $path.'/';
    }

    if(!-e $dir) 
    {
        #$self->{'modman'}->{'log'}->LogM("--- $dir\n");
        unless(mkdir($dir)) 
        { 
            
            return; 
        } 
    } 

    my @subdirectoryFiles = <$copyFile/* >; 

    foreach(@subdirectoryFiles) 
    { 
        copyFile($_, $dir); 
    }
}

1;