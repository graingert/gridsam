package gridsam_util;

use Exporter ();
@ISA = qw(Exporter);
@EXPORT = qw
(
  $DEBUG
  $webdav_user $webdav_password
  $remote_server_url $webdav_protocol $webdav_server $webdav_host $webdav_port $webdav_base_url $webdav_base_jsp_url

  read_server_details
  run_jobs
);

use strict;
use warnings;

# webdav username and password to be used
our ($webdav_user, $webdav_password) = ('tomcat', 'tomcat');

# it can take a number of attempts to download a given file if the server is busy
our $number_of_download_retries = 25;

# write extra output to the terminal to help with diagnosing problems
our $DEBUG = 0;

our ($remote_server_url, $webdav_protocol, $webdav_server, $webdav_host, $webdav_port, $webdav_base_url, $webdav_base_jsp_url);

sub read_server_details();
sub run_jobs(@);

sub read_server_details()
{
  # read server details from registry.properties
  $remote_server_url = 'http://localhost:8080'; # default
  $webdav_protocol = 'http://'; # default
  $webdav_server = 'localhost:8080'; # default
  if(-f 'registry.properties')
  {
    open(REG, 'registry.properties') or warn("failed to open registry.properties");
    while(<REG>)
    {
      if( /^remote_server_url=(.+)/ )
      { $remote_server_url = $1 }
      if( /^remote_server_webdav_url=(https?:\/\/)(.+)/ )
      {
        $webdav_protocol = $1;
        $webdav_server = $2;
      }
    }
  }

  ($webdav_host, $webdav_port) = split(':', $webdav_server, 2);
  $webdav_base_jsp_url = $webdav_protocol . $webdav_user . ':' . $webdav_password . '@' . $webdav_server;
  # $webdav_base_url = $webdav_protocol . $webdav_user . ':' . $webdav_password . '@' . $webdav_host . ":80/webdav"; # assume apache on 80
  $webdav_base_url = $webdav_base_jsp_url; # use webdav on tomcat
}

# run the jobs
sub run_jobs(@)
{
  my %job_ids;
  my $batch_size = 50;

  # submit the jobs $batch_size at a time
  my $cwd = "$ENV{PWD}";
  
  my @jsdls = @_;
  my $base = 0;
  while(scalar(@jsdls))
  {
    my @batch;
    for(my $n=0; ($n<$batch_size && scalar(@jsdls)); $n++)
    {
      push @batch, $cwd . "/" . shift @jsdls
    }

    my $submit_command = "java -cp .. GridSAMClient GridSAMSubmit -s $remote_server_url/gridsam/services/gridsam " . join(' ', @batch);
    print "Submitting " . scalar(@batch) . " jobs...";
    my $rv = `$submit_command`;
    print " jobs submitted.\n";
    my @returned_job_ids = split /[[:space:]]+/, $rv;

    foreach my $j (1..scalar(@batch))
    {
      my $job = $base + $j;
      my $gs_id = shift @returned_job_ids;
      $job_ids{$gs_id} = $job; # Links gridsam job ID to "visible" name
    }
    $base += scalar(@batch);
  }

  return %job_ids;
}

1;
