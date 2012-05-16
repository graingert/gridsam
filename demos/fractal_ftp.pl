#!/usr/bin/perl

# Renders tiles of a larger Mandelbrot fractal via GridSAM
# Justin Bradley

use strict;
use warnings;
use IPC::Open2;
use POSIX;

sub kill_all($);

# the width and height in tiles to be rendered
my ($width, $height) = (4, 3);

# the size in pixels of each square tile
my $tile_size = 200;

my %param_set;
push @{$param_set{1}}, (-0.5, 0, 1);
push @{$param_set{2}}, (-0.112, 0.866, 25);
push @{$param_set{3}}, (-0.069, 0.885, 100);
push @{$param_set{4}}, (-0.087, 0.871, 110);
push @{$param_set{5}}, (-0.736176135, 0.137590512, 3000);

my $set;
   $set = shift or $set = 1;
die("Invalid set name, try one of: " . join(', ', sort keys %param_set) . "\n") if(not exists($param_set{$set}));

# The centre of the rendered area (x coordinate may need to be flipped)
my ($x_centre, $y_centre, $zoom_level) = @{$param_set{$set}};

# Compute a working $tile_extent based on the fact that we only want a 3-unit-wide and 2-unit-high chunk of the Mandelbrot space
my $te_x = 3.0 / $width;
my $te_y = 2.0 / $height;
# the size of each square tile in Mandelbrot space
my $tile_extent = ($te_x > $te_y) ? $te_x : $te_y; # Pick the larger tile extent of the two
   $tile_extent /= $zoom_level;

# read remote_server_url from ../registry.properties
my $remote_server_url = 'http://localhost:8080'; # default
my $ip = '';
if(-f 'registry.properties')
{
  open(REG, 'registry.properties');
  while(<REG>)
  {
    if( /^remote_server_url=(.+)/ )
    { $remote_server_url = $1 }
    elsif( /^default_client_ip_address=(.+)/ ) # which interface to bind to
    { $ip = $1 }
  }
}

if(!$ip) # then guess
{
  open(IFCONFIG, "/sbin/ifconfig |");
  while(<IFCONFIG>)
  {
    if(!$ip && /inet addr:([0-9.]+)/)
    {
      my $i = $1;
      $ip = $i unless $i =~ /192\.168\./ || $i =~ /127\.0\.0\.1/;
    }
  }
}

my $cwd = "$ENV{PWD}";

# the port number for the local ftp server
my $ftp_port = 3333;

my %arg_sets;
foreach my $x (1..$width)
{
  foreach my $y (1..$height)
  {
    my @tmp;
    $arg_sets{"${x}x${y}"} = \@tmp;
    `rm -f ${x}x${y}.jsdl`; # in case there are any remaining from a previous failed run
  }
}

my $x_min = $x_centre - ($width/2.0 * $tile_extent);
my $y_min = $y_centre - ($height/2.0 * $tile_extent);

foreach my $y (1..$height)
{
  foreach my $x (1..$width)
  {
    my $x_val = $x_min + (($x - 1) * $tile_extent);
    my $y_val = $y_min + (($y - 1) * $tile_extent);
    push @{$arg_sets{"${x}x${y}"}}, ($x_val, $y_val, $x_val + $tile_extent, $y_val + $tile_extent);
  }
}

`rm -rf ftpdata`;
`mkdir -p ftpdata`;
`tar -czf ftpdata/fractal_worker.tgz fractal`;

# generate the job wrapper script, make the assumption that the PATH is the same as 'here'
open(JOB, "+> ftpdata/fractal.sh");
print JOB <<EOF;
#!/bin/bash
PATH=$ENV{PATH}
tar -xzf fractal_worker.tgz
java -Djava.awt.headless=true -cp fractal Fractal hide \$1 \$2 \$3 \$4 \$5 \$6 \$7
rm -rf fractal
rm -f fractal_worker.tgz
EOF
close(JOB);
`chmod +x ftpdata/fractal.sh`;

# construct a set of jsdl files describing the jobs to be run
my @jsdls;
foreach my $x (1..$width)
{
  foreach my $y (1..$height)
  {
    open(JSDL, "+> ${x}x${y}.jsdl");
    print JSDL <<EOT;
<JobDefinition xmlns="http://schemas.ggf.org/jsdl/2005/11/jsdl">
    <JobDescription>
        <JobIdentification>
            <JobName>fractal job</JobName>
            <Description>render a fractal tile</Description>
            <JobAnnotation>no annotation</JobAnnotation>
            <JobProject>gridsam project</JobProject>
        </JobIdentification>
        <Application>
            <POSIXApplication xmlns="http://schemas.ggf.org/jsdl/2005/11/jsdl-posix">
                <Executable>./fractal.sh</Executable>
EOT

    foreach (@{$arg_sets{"${x}x${y}"}})
    {
      print JSDL "                <Argument>$_</Argument>\n";
    }

    print JSDL <<EOT;
                <Argument>${x}x${y}.jpg</Argument>
                <Argument>$tile_size</Argument>
                <Argument>$tile_size</Argument>
                <Output>stdout.txt</Output>
                <Error>stderr.txt</Error>
                <Environment name="PATH">/bin:/usr/bin</Environment>
            </POSIXApplication>
        </Application>
        <DataStaging>
            <FileName>fractal.sh</FileName>
            <CreationFlag>overwrite</CreationFlag>
            <Source>
                <URI>ftp://anonymous:anonymous\@$ip:$ftp_port/fractal.sh</URI>
            </Source>
        </DataStaging>
        <DataStaging>
            <FileName>fractal_worker.tgz</FileName>
            <CreationFlag>overwrite</CreationFlag>
            <Source>
                <URI>ftp://anonymous:anonymous\@$ip:$ftp_port/fractal_worker.tgz</URI>
            </Source>
        </DataStaging>
        <DataStaging>
            <FileName>${x}x${y}.jpg</FileName>
            <CreationFlag>overwrite</CreationFlag>
            <DeleteOnTermination>true</DeleteOnTermination>
            <Target>
                <URI>ftp://anonymous:anonymous\@$ip:$ftp_port/${x}x${y}.jpg</URI>
            </Target>
        </DataStaging>
    </JobDescription>
</JobDefinition>
EOT
    close(JSDL);
    push @jsdls, "$cwd/${x}x${y}.jsdl";
  } 
}

# launch the local ftp server
my $cmd = "java -cp .. -DFtpServer.server.config.self.host=$ip GridSAMClient GridSAMFTPServer -p $ftp_port -d $cwd/ftpdata > /dev/null 2>&1";
my $reader;
my $writer;
my $pid = open2($reader, $writer, $cmd);
sleep 2; # give it a chance to start up
close($reader);
close($writer);

my $failures = 0;

# launch the viewer
open(SPECFILE, "+> fractal_specfile.txt");
print SPECFILE "$height\n$width\n";
foreach my $y (1..$height)
{
  foreach my $x (1..$width)
  {
    print SPECFILE "ftpdata/${x}x${y}.jpg\n";
  }
}
close(SPECFILE);
system("java -cp tic TileImageClient fractal_specfile.txt $tile_size &> /dev/null &");

# randomize the order of the JSDL files
my $jsdls = "";
while(scalar @jsdls)
{
    $jsdls .= ' "';
    $jsdls .= splice @jsdls, int rand scalar @jsdls, 1;
    $jsdls .= '"';
}

# run the jobs
my %job_ids;

my $submit_command = "java -cp .. GridSAMClient GridSAMSubmit -s $remote_server_url/gridsam/services/gridsam $jsdls";
unlink @jsdls; # finished with the JDSL files now
my $rv = `$submit_command`;
#print "Job IDs:\n";
#print $rv;
my @returned_job_ids = split /[[:space:]]+/, $rv;

foreach my $a (keys %arg_sets)
{
    my $gs_id = shift @returned_job_ids;
    $job_ids{$gs_id} = $a; # Links gridsam job ID to "visible" name
}

# check jobs for completion
my $jobs_list_file = "./jobs_list";
while(scalar keys %job_ids)
{
    # print "--- Status run started at ".strftime("%Y-%m-%d %T", localtime)."\n";
    open(JOBS, ">".$jobs_list_file);
    foreach my $gs_id (keys %job_ids)
    {
	print JOBS $gs_id, "\n";
    }
    close(JOBS);

    open(STATUS, "java -cp .. GridSAMClient GridSAMStatus -s $remote_server_url/gridsam/services/gridsam -file '$cwd/$jobs_list_file' |");
    while(<STATUS>)
    {
	if(m/^Job Progress '(urn:gridsam:[[:xdigit:]]+)': (.*)$/)
	{
	    my $gs_id = $1;
	    my $status = $2;
	    my $a = $job_ids{$gs_id};
	    if($status =~ m/-> done$/)
	    {
		delete $job_ids{$gs_id};
		print "Tile $a has rendered successfully.\n";
	    }
	    elsif($status =~ m/-> failed$/)
	    {
		delete $job_ids{$gs_id};
		print "Tile $a has failed to render.\n";
		++$failures;
	    }
	}
    }
    close(STATUS);
    unlink($jobs_list_file);
    print "Jobs outstanding: ".(scalar keys %job_ids);
    print ". Jobs completed: ".((scalar keys %arg_sets)-(scalar keys %job_ids));
    print ". Jobs failed: ".$failures."\n";
    # print "--- Status run finished at ".strftime("%Y-%m-%d %T", localtime)."\n";

    sleep 2 if scalar keys %job_ids;
}

# remove the local ftp server
# when the ftp server was launched, it was done so in a new shell, $pid is the PID of the shell
# rather than the java ftp server, so we need to kill off the whole process tree
kill_all($pid);

#if($failures == 0)
#{ print "no failures detected\n" }
#else
#{ print "$failures failures detected\n" }

foreach my $a (keys %arg_sets)
{
  unlink("$a.jsdl");
}
 unlink('fractal_specfile.txt');

sub kill_all($)
{
  my ($parent_pid) = @_;
  our %parents;
  sub t($);

  open(PS, 'ps -o pid,ppid |');
  my $headings = <PS>;
  while(<PS>)
  {
    my ($pid, $ppid) = ( /([0-9]+)[^0-9]+([0-9]+)/ );
    $parents{$pid} = $ppid;
  }

  my $cmd = "kill -9 $parent_pid " . t($parent_pid);
  `$cmd`;

  sub t($)
  {
    my ($pid) = @_;
    my @c;
    my $retval = '';

    foreach my $p (sort {$a <=> $b} keys %parents)
    {
      push @c, $p if($parents{$p} == $pid);
    }

    foreach my $p (@c)
    {
      my @l = t($p);
      next if(scalar(@l) == 0);
      $retval .= "$p ". join(' ', @l). " ";
    }

    return $retval;
  }
}
