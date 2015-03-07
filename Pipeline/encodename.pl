#!/usr/bin/env perl

#
# encodename.pl -- see below or run w/o arguments for switch list
# 


if (!@ARGV) {
	print <<END_OF_INTRO;
	######################################################################
	encodename.pl -- encodes Phylip interleaved sequence files 
	with species numbers in the form of ctx001...
	---------------------------------------------------------------
	The input sequence file should come last!
	To decode with a premade look-up table, use decodename.pl
	Filenames are autogenerated as infile.root.phy (or .fta)

	-p input file is interleaved phylip
	default is fasta (or NBRF or Stockholm format)
	-f -s  output in fasta or sequential phylip
	default is interleaved phylip
	-t output to screen instead of file (still writes lutfile unless -l)
	-r use the following parameter as the prefix for generating seq names 
	(recommend lowercase, default 'ctx')
	-l do NOT make a Lookup file
	-c convert format only, don't change names or make LUT
	-h provide your own Lookup table file name  to use (Hash table)
	-x pad end of sequence with dashes to make same length 
	-j join sequences together if occurring as multiples
	-k skip second occurrence of sequence when multiple
	-d diagnostic mode -- just print out seq names and lengths

	If you use this to generate the lookup table, it will need phylip-compatible
	(<10 character) names.      
	
	To join fasta files, use -j (makes fasta file, no lut).

	Version 1.86 by Steven Haddock (beroe [at] mac {dot} com)
    
	rev 1.86 fixed a typo in the numsite2 variable
	rev 1.85 added skipping of repeated sequences
	rev 1.84 fixed a bug where a | in the name could lead to false duplicates
	rev 1.83 added sequence numbering to diagnostic mode
	rev 1.81 additional digit to accommodate 10000 sequences
	rev 1.8  added sequence joiner option, fixed bug where it skipped first seq?
	rev 1.7  added diagnostic mode and fixed double-name
	rev 1.6  fixed padding for phyml
	rev 1.5  added Stockholm format

	Usage: perl -w encodename.pl [-r ctx] [-f] [-x] [-k] [-c] [-p] [-t] test.fta 

	##########################################################################
END_OF_INTRO

exit;
}
# make infile and outfile options? Figure out lutfile or not?

$totalsite=0; $numotu=0;
$interleave=1; # coded a little backwards..

$fasta=0; $ticker=0; $rootnext=0; $fasta=1; $fastaout=0; $skipper=0;
$lutnext = 0; $makelut=1; $rootnext=0; $textout=0; $macfile=0;
$pad=0; $convert=0; $maxsites=0; $stockholm=0; $diagnostic=0; $joiner=1;

$root = "ctx"; #default

$lutfile="";
$name="";
$nothing="";$noname="";

@names=();
@seqs=();

foreach $inarg (@ARGV) {
	# print "F: $inarg\n";
	if ($inarg eq "-s"){
		$interleave = 0;
		next;
	}
	if ($inarg eq "-p"){
		$fasta = 0; # relates to input files, not output
		next;
	}
	if ($rootnext) {
		$rootnext = 0;
		($root) = ($inarg =~ /(\w{0,5})/); # for safety just the first 5 chars
		#		print "root: $root\n";
		next;
	}
	if ($lutnext) {
		$lutnext = 0;
		$lutfile = $inarg;
		$makelut = 1;
		next;
	}
	if ($inarg eq "-x"){
		$pad = 1;
		next;
	}
	if ($inarg eq "-h"){
		$lutnext = 1;
		next;
	}
	if ($inarg eq "-c"){
		$convert = 1;
		$makelut = 0;
		next;
	}
	if ($inarg eq "-l"){
		$makelut = 0;
		next;
	}
	if ($inarg eq "-k"){
		$skipper = 1;
		$joiner = 1; # joiner is opposite
		$convert = 1;
		$makelut = 0;
		$joiner = 1;
		$fastaout = 1;

		next;
	}
	if ($inarg eq "-j"){
		$convert = 1;
		$makelut = 0;
		$joiner = 0; # joiner is opposite
		$skipper = 0;
		$fastaout = 1;
		next;
	}
	if ($inarg eq "-f"){
		$fastaout = 1;
		next;
	}
	if ($inarg eq "-t"){
		$textout=1;
	}
	if ($inarg eq "-r"){
		$rootnext = 1;
		next;
	}
	if ($inarg eq "-d"){
		$diagnostic = 1;
		next;
	}
	if ($inarg eq "-m"){
		#	    No longer necessary -- should detect mac files.
		$macfile=1;
		$/="\r";  # set indicator to mac CR
		next;
	}
	$file=$inarg;

} # foreach file  -- drops through on last file name - we hope!
(-e $file) || die  "Can't open $file: $!\n";

open(FILE, "< $file") || die  "Can't open $file: $!\n";
$_ = <FILE>;
if (!$macfile && /\r/){ # if you find mac cr in line
	print "Macfile detected.\n" unless $textout;
	$/="\r";  # set indicator to mac CR
	$macfile=1;
	seek FILE, 0,0;
	#			next;
}
if (/STOCKHOLM/){ # if you find stockholm in line 1
	print "Stockholm file detected.\n" unless $textout;
	$stockholm=1;
	$fasta=0;
	$notblank=1;
}			
seek FILE, 0,0;   
if ($fasta){ #this refers to input, not output format.
# $lines=0;
	while(<FILE>)	{		
		next if /^\s*$/; #blank line skip
		#			next if (/^\s*#/);  # comment line skip
		if (/^>/) {
			die "First line super long -- try running with Mac option on/off (-m) ?" if (length($_)>250);
			#			$name = $_;
			if (/^>DL;/ || /^>P1;\ */){
				print "NBRF format detected.\n" unless ($nbrf || $textout);
				$nbrf=1;
				($name, $nothing) = ($_ =~ /^>\w\w;\ *(.*)(\r|\n)/ ) ;
				#				print "$name\n";
				$noname=<FILE>; #grab line after next
			}
			else { #normal fasta
				($name) = ($_ =~  /^\>(.*)$/);
			}
			# print "$name\n";
			$name =~  s/\t/_/g ;
			$name =~  s/(\r|\n)//g ; 
			$searchname = quotemeta $name;
			if (grep(/^$searchname$/,@names)) {    # repeated name, die unless joining -- doesn't work with |
				if ($skipper){
					print "Skipping repeated sequence $name. Use -j to join instead\n";
					$name ="";
				}
				elsif ($joiner) {                              
					die "FATAL ERROR: Identifier \"$name\" is double defined. Use -j to join, -k to skip.\n" ;   
				}
			}
			else {
				push (@names,$name); 
							# print "name: $name";
				$numotu++;   
			}
		}	
		#need a provision for blank lines before first name			
		elsif ($name ne "") {
			chomp;
			$seq = $_;
			$seq =~ s/\s//g;
			if ($nbrf){
				$seq =~ s/\*//g;
			}
			$seqs{$name} .= $seq;
		}
		} # while file w/in fasta


		$numsite = length($seqs{$names[0]});


		#		print "numsite: $numsite\n";
		close FILE;
} 
elsif ($stockholm){  # stockholm format from above
	$noslash=1;
	$notMidblank=1;
	while ( $noslash ){
		$_ = <FILE>;
		next if ($notblank) && (/^\s*$/ || /^\s*#/);  # top comment line skip
		#	we have skipped the intro lines -- anything further is a break between seqs
		$notblank=0;
		# next chunk is sequences
		chomp;
		if (/^\s*\/\//){
			$noslash=0;
			next;
		}
		if ($notMidblank && /^\s*$/) { # we have already skipped intro blanks, so first time on this triggers
			$notMidblank=0;
			next;   # this will skip from the first set loading to the next phase.
		}
		next if (/^\s*$/ || /^\s*#/) ;  # skip comment and blank lines, after first

		# stockholm format ends with //
		chomp;
		($name,$seq) = ( $_ =~ /\s*(\S*)\s*(.*)$/);
		print "$i $name\n";
		print "$seq\n";
		#temp cheat changing name >16
		die "name abnormal or too long (>40): $_\n" unless ($name and (length($name)<40));
		if ($notMidblank){ # after noMidblank, append seqs but don't build array
			$searchname = quotemeta $name;
			die "FATAL ERROR: Identifier \"$name\" is double defined. Use -j to join.\n"if (grep(/^$searchname$/,@names) && ($joiner));		# this shouldn't happen before we come across a line of all spaces.
		push(@names,$name);
		$numotu++;
		#print "hash: $names[$i]\n";
	}
	$seq =~ s/\s//g;
	$seqs{$name} .= uc($seq);
	#		$infos{$name} = $info;


	$i++;
	} #   while 
	$numsite = length($seqs{$names[0]});

	# print "numsite: $numsite\n";
	# print "numotu: $numotu\n";	
	close FILE;

} 
else { # not fasta or stockholm, so must be phylip **interleaved**
	# can write seq or interleaved, but only reads interleaved..
	$notblank=1;
	while ($notblank) {  # first line
		$_=<FILE>;
		$notblank = 0 unless /^\s*$/;  # white line skip
		$notblank = 0 unless /^\s*#/;  # comment line skip
	} 
	chomp;
	die "First line too long -- try running with Mac option on/off (-m) ?" if (length($_)>2500);
	($numotu,$numsite) = ( $_ =~ /(\d+)\s+(\d+)/ );
	$i=0;
	#			print "$i $name\n";
	#			print "$seq\n";
	die "Format error: Phylip files must begin with numbers of taxa and sites: $_\n" unless ($numotu>0 and $numsite>1) ;
	while ( ($i < $numotu) && ($ticker++ < 10000) ){
		$_ = <FILE>;
		next if /^\s*$/;  # white line skip at top of file
		next if /^\s*#/;  # comment line skip at top of file

		chomp;
		($name,$seq) = ( $_ =~ /\s*(\S*)\s*(.*)$/);
		#		print "$i $name\n";
		#		print "$seq\n";
		#temp cheat changing name >16
		die "name abnormal or too long (>10): $_\n" unless ($name and (length($name)<18));
		$searchname = quotemeta $name;
		die "FATAL ERROR: Identifier \"$name\" is double defined. Use -j to join, -s to skip the second one.\n"if (grep(/^$searchname$/,@names) && ($joiner));		push(@names,$name);
		#			print "hash: $names[$i]\n";
		$seq =~ s/\s//g;
		$seqs{$name} .= $seq;
		#		$infos{$name} = $info;
		$i++;
		} # while 
		die "\ngot stuck in a loop near 68\n" if ($ticker>9999);
		$ticker=0;
		$i=0;
		$leng = length($seqs{$names[$i]});
		# print "\nLENGTH: $leng \n";

		while(($leng < $numsite) && ($ticker++<10000)){ 
			$i=0;
			while  (($i < $numotu) && ($ticker++ < 10000)) { 
				$_ = <FILE>;
				next if /^\s*$/;  # white line skip
				chomp;
				#next if /^\s*#/;  # comment line skip
				s/\s//g;
				$seq = $_;
				$seqs{$names[$i]} .= $seq;
				$leng = length($seqs{$names[$i]});
				#			print "$names[$i] $leng $seq\n";
				die "$names[$i]: abnormal sequence size, $leng sites\n"	if ($leng > $numsite);
				$i++;
			}
		}
		print "$leng\n";
		die "\ngot stuck in a loop near 210\n" if ($ticker>9999);


		close FILE;

  		}  # end not fasta

$/="\n";  # set indicator back to unix CR
      
##### DOME WITH INPUT, CREATE OUTPUT

# generate ctxnames here
$ctxi=1;                
if ($diagnostic)  {
	print "   #: len: name";
	foreach $name (@names){
		$nowsites=length($seqs{$name});
		print  $ctxi . " :\t" . $nowsites . "\t" . $name . "\n";
		$ctxi++;
	}
}  

else {
	foreach $name (@names){
		$ctxname{$name}= sprintf("$root%04d",$ctxi++); 
		$nowsites=length($seqs{$name});
		if ((!$fastaout) && (!$pad) && ($nowsites ne $numsite)){
			die "\n** Sorry, can't output phylip format with variable length sequences\nTry pad option (-x) with fasta output format (-f)\n";
		}
		# changed this to find the maximum number
		if ($nowsites gt $maxsites) {
			$maxsites = $nowsites;
			#	print "Maxsites to ". $maxsites;
		}

		# for debugging...
		# 	$tl=length($seqs{$name}) ;
		# 	print"name: $ctxname{$name} len: $tl - maxlen: $maxlen\n";
		# 	if ($tl > $maxlen ){
			# 		print "resetting maxlen\n";
			# 		$maxlen=length($seqs{$name}) ;
			# 		
			# 	}
		}

		$fileroot=$file;
		$fileroot =~ s/\.\w+$//;

		$outroot="phy";
		$outroot="fta" if ($fastaout);

		$outfile = $fileroot . ".$root.$outroot";

		if ((-e $outfile) && (!$textout)) {
			print "\n*** File $outfile exists.\n   Overwrite? (y/[n]/new_filename): ";
			$answer = <STDIN>;  chomp $answer;
			if (length($answer) <4) { 
				#anything more than 3 chars is interpreted as a file name
				if ( $answer =~ /^(Y|y)/) {
					print "Overwriting... \n";
					} else {
						die "Gracefully exiting without overwrite.";
					}
					} else {
						$outfile = $answer;
						$lutfile=$outfile;
						$lutfile =~ s/\.\w+$/\.lut/;

					}
				}

				#		print "\nSaving to $outfile \n";

				# OUTPUT OPTIONS
				if (!$textout){
					open (OUTFILE, ">$outfile");
					select (OUTFILE);
				}
				if ($fastaout) {
					foreach $name (@names) {
						if ($convert){
							printf (">%-10s\n",$name);
							}else{
								printf (">%-10s\n",$ctxname{$name});
							}
							$seq = $seqs{$name};
							$totalsite=length($seq);
							if (($pad) && ($totalsite < $maxsites)) {
								for ($di=$totalsite; $di<$maxsites; $di += 1){
									$seq .= "-";
								}
							}
							$totalsite=length($seq);
							$line = substr($seq, 0, 60);
							print "$line\n";
							for ($offset = 60; $offset<$totalsite +1; $offset += 60) {
								$line = substr($seq, $offset, 60);
								if ($line ne "" ){
									print "$line\n";
								}
							}
						}
					} 
					else {
						# not fasta, so phylip of one kind or another
						if (($pad) && ($numsite2 < $maxsites)) {
							$numsite2=$maxsites;
						}
						else{
							$numsite2 = length($seqs{$names[0]});
						}
						if (not($interleave)) {
							print " $numotu  $numsite2\n";
							foreach $name (@names) {
								if ($convert){
									printf ("%-14s",$name);		
									}
								else{
										printf ("%-14s",$ctxname{$name});		
								}

								$seq = $seqs{$name};
								# adding for padding
								$totalsite=length($seq);
								if (($pad) && ($totalsite < $numsite2)) {
									for ($di=$totalsite; $di<$numsite2; $di += 1){
										$seq .= "-";
									}
									$seqs{$name}=$seq;
								}
								# added the part above to try to pad
								$line = substr($seq, 0, 50);
								print  "$line\n";
								for ($offset = 50; $offset<($numsite2+1); $offset += 50) {
									if ($offset < length($seq)){
										$line = substr($seq, $offset, 50);
										print  "              "; 
										print  "$line\n";
									}
								}
							}
						} # end not interleave

						else{  
							# interlaced phylip
							# print $datainfo ? "$numotu2 $numsite2 $datainfo\n" : "$numotu2 $numsite2\n";

							print  " $numotu  $numsite2\n";
							foreach $name (@names) {
								if ($convert){
									printf ("%-14s",$name);		
									}
								else{
									printf ("%-14s",$ctxname{$name});		
								}
								$seq = $seqs{$name};
								# adding for padding
								$totalsite=length($seq);
								if (($pad) && ($totalsite < $numsite2)) {
									for ($di=$totalsite; $di<$numsite2; $di += 1){
										$seq .= "-";
									}
									$seqs{$name}=$seq;
								}
								# added the part above to try to pad

								$line = substr($seq, 0, 50);
								print  "$line\n";
							} #end foreach

							print  "\n";
							for ($offset = 50; $offset<($numsite2 +1); $offset += 50) {
								foreach $name (@names) {
									#printf("%-3d %-10s %s\n", $num, $name, $info);
									$seq = $seqs{$name};
									if ($offset < length($seq)){
										$line = substr($seq, $offset, 50);
										print  "              "; 
										print  "$line\n";
									} 
								}
								print  "\n";
							}
						}
					} # end phylip formats (else fastaout)

					close(OUTFILE) unless $textout;
					select (STDOUT);
					if ($numotu>0){
						print "Saved $numotu sequences to: $outfile...\n" unless ($textout);
					}
					else{
						print "No sequences found in data file. Check format...\n";
					}
					if ($makelut){
						if ($lutfile eq "") {
							$lutfile = $fileroot . ".$root.lut";
						}
						open(LUTFILE, ">$lutfile")  || die "can't open output file";
						foreach $name (@names){
							$nt = sprintf ("%-10s",$name);
							print LUTFILE "$ctxname{$name}\t$nt\n";
						}
						close (LUTFILE);
						print "Created lookup file:  $lutfile\n" unless ($textout);

					} # if makelut
				}  #else  	 # end else diagnostic mode                                  