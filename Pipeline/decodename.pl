#!/usr/bin/env perl
#
if (!@ARGV) {
print <<END_OF_INTRO;

######################################################################
decodename.pl -- decodes any text file (treefile, etc)
    replacing shortname (e.g. ctx001) with its 
    appropriate name from a look-up table.  
---------------------------------------------------------------

    [-h filename]   use 'filename' instead of default for lookup table
    [-t ]           output to screen instead of file
    [-u ]           replace spaces, :, /, (, or ) with _ in name
    [-i ]           ignore line length limit
	[-o ]           use outfilename instead of default
    
Use encodename.pl to encode phylip files (or eventually fasta?)
Default lookup table is 'infile.ctx.lut'

The encodename.pl program will only generate 10-char names in
the lookup table, but if you have another tab-delimited table,
this will make the substitution for you. 

This doesn't care what format the files are in, for the most
part -- it just does search and replace.

Since this is most commonly used with tree files, it will rename
.txt files as .tre files by default. Turn this off with -n

Version 1.4 by Steven Haddock (beroe [at] mac {dot} com)
	1.4 added ability to specify output name

Usage: perl -w decodename.pl [-h lookupname] [-o outfilename] [-u] [-t] infile.ctx.phy

##########################################################################

END_OF_INTRO
exit;
}

## also, create hash file to make a list be numbered by root...

$ticker=0;
$nextlut=0;
$lutfile="";
$outfilein="";
$nextout=0;
$textout=0;
$despace=0;
$reend=1;
$ignorelen=1;

%lut=();
foreach $file (@ARGV) {

    if ($nextlut){
        $nextlut = 0;
        $lutfile=$file;
        next;
    }
   if ($nextout){
        $nextout = 0;
        $outfilein=$file;
        next;
    }

    if ($file eq "-h"){
        $nextlut = 1;
        next;
    }
    if ($file eq "-o"){
        $nextout = 1;
        next;
    }

    if ($file eq "-n"){
        $reend = 0;
        next;
    }
    if ($file eq "-t"){
        $textout = 1;
        next;
    }

    if ($file eq "-u"){
        $despace = 1;
        next;
    }
    if ($file eq "-i"){
        $ignorelen = 0;
        next;
    }
#print "file: $file\n";
$filename=$file;
} #end foreach file
print $filename;
chomp($filename);
#something like this??
#Only works with 3 components
#($fileroot,$root,$suffix) = ($filename =~ /(.*)(\.\w+)(\.\w+)$/);
$dotnum= ($filename =~ tr/\.//);
#print "dotnum",$dotnum,"\n";
if ($dotnum>1) {
	($fileroot,$root,$suffix) = ($filename =~ /(.*)(\.\w+)(\.\w+)$/);
}else {
	($fileroot,$presuffix)=($filename =~ /(.*)(\.\w+)$/);
	$suffix="-de".$presuffix;
}
# ($fileroot,$root,$suffix) = split("\.",$filename);

#print "Fileroot: ",$fileroot," \n  Suffix: ",$suffix," \n   Root: ",$root,"\n";

#if ($fileroot =="") {
#	print "no\n";
#	$fileroot = $root;
#	}

if (($suffix =="\.txt")&($reend)){
	$outfile = $fileroot."\.tre";
}
else {
	$outfile = $fileroot.$suffix;
}
if ($outfilein ne "") {
	$outfile=$outfilein;
}

if ($lutfile eq "") {

    $lutfile = $fileroot . ".lut";
}

        open(LUTFILE, $lutfile) || die "Can't find lookup table $lutfile: $!\n Specify with -h option\n"; 
        while ($_= <LUTFILE>){# && $ticker++ < 1000){
#           print $_;
        ($lkey, $lval)= split(/\t/,$_);
		$lval =~ s/(\r|\n)//g; # no CRs in subs
		if ($despace) { 
			$lval =~ s/(\s|\:|\(|\)|\/|\-)/\_/g;  #confusing enough?
		}
		$lval =~ s/(\s|\_)+$//g; # no trailing spaces
#        chomp($lval);
        $lut{$lkey}=$lval;
#           push (@lut, $lkey, $lval);
#           push (@lut, $_);

        }
        close(LUTFILE);
($lutroot) = ($lkey =~ /(\w+)\d{3}/);
#print "LUTROOT: $lutroot\n";
$ticker=1;
@lkey = sort(keys(%lut));

if ((-e $outfile) && (!$textout)) {
    print "\n*** File $outfile exists.\n   Overwrite? ([y]/n/new_filename): ";
    $answer = <STDIN>;  chomp $answer;
    if (length($answer) <4) {
        if ( $answer =~ /^(N|n)/) {
            print "Gracefully exiting without overwrite.\n";
			exit;
        } else {
            print "Overwriting... \n";
        }
    } else {
        $outfile = $answer;
	    die "** Not advisable to read from and write to the same file. **\n"
			if  ($outfile eq $filename);
	
    }
}

(-e $filename) || die "Can't find $filename $!\n";

if (!$textout) {
    open(OUTFILE, ">$outfile") || die "Can't open outputfile $outfile\n";
    select(OUTFILE);
}

open(FILE, $filename);
    while (<FILE>){# && $ticker++ < 10000){
			if (!$macfile && /\r/){ # if you fine mac cr in line
				# print "Macfile detected.\n" unless $textout;
				$/="\r";  # set indicator to mac CR
				$macfile=1;
				seek FILE, 0,0;
				next;
			}

        die "Line too long -- run with Mac option on/off (-m) or ignore length (-i)?\n" 
            if ( (length($_)>2500) && $ignorelen);
            

#### NEED TO have three digit keys, or else ctx1 will replace ctx13
        foreach $mykey (@lkey) {
	#removed #if /$lutroot/ so it could work with non ctx filex
#       print "$first : $lut{$first}\n";
            $_ =~ s/$mykey/$lut{$mykey}/g;
        } # for hashes
		$_ =~ s/\r/\n/g;
		$_ =~ s/\n\s*\n/\n/g;
        print $_ unless /^\s*$/ ; # brazenly deletes blank lines

   } # while FILE
    close(FILE);
	if (!$textout) {
	    close(OUTFILE);
	}


select (STDOUT);

print "\nSaved to $outfile using $lutfile\n" unless ($textout);
