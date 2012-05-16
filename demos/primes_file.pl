#!/usr/bin/perl

use strict;
use warnings;

use gridsam_util;

## Parameters ##

my $range_min = 0;
my $range_max = 20000;
my $number_of_jobs = shift;
   $number_of_jobs = 10 if !$number_of_jobs || $number_of_jobs !~ /^[0-9]+$/;

## Run the jobs ##

# carve up the range into sub-ranges for each job
my %jobs;
my $interval = int(($range_max - $range_min) / $number_of_jobs);
my $job = 1;
for(my $n=$range_min; $n<$range_max; $n+=$interval )
{
  $jobs{"$job.min"} = $n;
  $jobs{"$job.max"} = $n+$interval-1;
  ++$job;
}

# read the local config file to find out the details of the server to use
read_server_details();

# generate the job wrapper script, make the assumption that the PATH is the same as 'here'
open(JOB, "+> primes.sh");
print JOB <<EOF;
#!/bin/bash
hostname
PATH=$ENV{PATH}
java -Djava.awt.headless=true Primes \$1 \$2
EOF
close(JOB);
`chmod +x primes.sh`;

my $stage_data = '/tmp/';
`cp primes.sh Primes.class $stage_data`;

# clean out previous results
`rm -rf results`;
`mkdir -p results`;

# construct a set of jsdl files describing the jobs to be run
my @jsdls;
foreach my $job (1..$number_of_jobs)
{
    open(JSDL, "+> ${job}.jsdl");
    print JSDL <<EOT;
<JobDefinition xmlns="http://schemas.ggf.org/jsdl/2005/11/jsdl">
    <JobDescription>
        <JobIdentification>
            <JobName>primes job</JobName>
            <Description>calculate primes in a given range</Description>
            <JobAnnotation>no annotation</JobAnnotation>
            <JobProject>gridsam project</JobProject>
        </JobIdentification>
        <Application>
            <POSIXApplication xmlns="http://schemas.ggf.org/jsdl/2005/11/jsdl-posix">
                <Executable>./primes.sh</Executable>
                <Argument>$jobs{"$job.min"}</Argument>
                <Argument>$jobs{"$job.max"}</Argument>
                <Output>stdout.txt</Output>
                <Error>stderr.txt</Error>
                <Environment name="PATH">/bin:/usr/bin</Environment>
            </POSIXApplication>
        </Application>
        <DataStaging>
            <FileName>primes.sh</FileName>
            <CreationFlag>overwrite</CreationFlag>
            <Source>
                <URI>file://$stage_data/primes.sh</URI>
            </Source>
        </DataStaging>
        <DataStaging>
            <FileName>Primes.class</FileName>
            <CreationFlag>overwrite</CreationFlag>
            <Source>
                <URI>file://$stage_data/Primes.class</URI>
            </Source>
        </DataStaging>
        <DataStaging>
            <FileName>stdout.txt</FileName>
            <CreationFlag>overwrite</CreationFlag>
            <DeleteOnTermination>true</DeleteOnTermination>
            <Target>
                <URI>file://$stage_data/$job.txt</URI>
            </Target>
        </DataStaging>
    </JobDescription>
</JobDefinition>
EOT
    close(JSDL);
    push @jsdls, "${job}.jsdl";
}

my %job_ids = run_jobs(@jsdls);


# check jobs for completion
print "Checking for job completion.\n";
my $failures = 0;
my $jobs_list_file = "./jobs_list";
my $cwd = "$ENV{PWD}";
while(scalar keys %job_ids)
{
  open(JOBS, ">".$jobs_list_file);
  print JOBS join("\n", keys %job_ids);
  close(JOBS);

  open(STATUS, "java -cp .. GridSAMClient GridSAMStatus -s '$remote_server_url/gridsam/services/gridsam?wsdl' -file '$cwd/$jobs_list_file' |");

  while(<STATUS>)
  {
    if(m/^Job Progress '(urn:gridsam:[[:xdigit:]]+)': (.*)$/)
    {
      my $gs_id = $1;
      my $status = $2;
      my $j = $job_ids{$gs_id};
      if($status =~ m/-> done$/)
      {
        delete $job_ids{$gs_id};
        print "Job $j has run successfully.\n";
        `cp $stage_data/$j.txt results`;
        print "$j - $_" if $DEBUG;
      }
      elsif($status =~ m/-> failed$/)
      {
        delete $job_ids{$gs_id};
        print "Job $j has failed to run.\n";
        print "$j - $_" if $DEBUG;
        ++$failures;
      }
      else
      {
        print "Job $j has current status of $status\n" if $DEBUG;
      }
    }
  }
  close(STATUS);
  unlink($jobs_list_file);
  print "Jobs outstanding: ".(scalar keys %job_ids);
  print ". Jobs completed: ".($number_of_jobs-(scalar keys %job_ids));
  print ". Jobs failed: ".$failures."\n";

  sleep 10 if scalar keys %job_ids;
}

# delete jsdl files and destroy the webdav staging area
foreach my $job (1..$number_of_jobs) { unlink("$job.jsdl") }

# summarise the results, each file is the hostname of the executing node followed by one prime per line
print "Results\n";
foreach my $job (1..$number_of_jobs)
{
  my $ok=1;
  open(RESULTS, "results/$job.txt") or $ok=0;
  if($ok)
  {
    my @results = <RESULTS>;
    printf("%05d - %05d : %s primes found\n", $jobs{"$job.min"}, $jobs{"$job.max"}, scalar(@results)-1); 
  }
  else
  {
    print "could not find results/$job.txt\n";
  }
}
