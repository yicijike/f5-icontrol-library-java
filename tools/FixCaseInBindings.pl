#!/usr/bin/perl

use File::Find::Rule;
use File::Basename;
use File::Slurp;
use File::Copy;
use File::Copy qw(copy);

$wsdl_dir = $ARGV[0];
$bindings_dir = $ARGV[1];

$pwd = `pwd`;
print "DIR: $pwd\n";
exit;

my @NAMES;

#--------------------------------------------
sub FindInNames() {
#--------------------------------------------
	my ($s) = @_;

	$found = 0;
	foreach my $i (@NAMES) {
		my @t = split /,/, $i, 2;
		if ( $s eq @t[0] ) {
			$found = 1;
		}
	}
	return $found;
}

#--------------------------------------------
sub GetBadName() {
#--------------------------------------------
	my ($s) = @_;

	return ucfirst($s);
}

#============================================
# Main Logic
#============================================
my @files = File::Find::Rule->new
	->name("*.wsdl")
	->maxdepth(1)
	->in($wsdl_dir);

foreach my $file (@files) {
	my($fname, $fdir, $fsuffix) = fileparse($file);
	my $bn = $fname;
	$bn =~ s/\.wsdl//g;

#	print "BASENAME: $bn\n";

	my @tokens = split /\./, $bn, 10;
	foreach my $t (@tokens) {
#		print "TOKEN: $t\n";
		my $c = substr($t, 0, 1);
		my $lc = lc($c);
#		print "C $c $lc\n";
		if ( $c eq $lc ) {
			print "$bn ($t)\n";
			if ( ! &FindInNames($t) ) {
#				print "ADDING TO LIST - $t\n";
				my $bad_name = &GetBadName($t);
				push @NAMES, "${t},${bad_name}";
			}
		}
	}
}

foreach my $n (@NAMES) {
	print "$n\n";
}

# Process Bindings

print "LOOKING FOR BINDINGS IN $bindings_dir\n";
my @bfiles = File::Find::Rule->new
	->name("*.java")
	->maxdepth(1)
	->in($bindings_dir);
foreach my $file (@bfiles) {
	my ($fname, $fdir, $fsuffix) = fileparse($file);
	my $bn = $fname;
	$bn =~ s/\.java//g;

#	print "BFILE: $file\n";

	foreach my $name (@NAMES) {
		@nt = split /,/, $name, 2;
		$good_name = @nt[0];
		$bad_name = @nt[1];

		if ( index($bn, $bad_name) != -1 ) {
			# Found a file match

#			print "BAD FILE NAME $bn ($good_name, $bad_name)\n";

			my $newname = $file;
			$newname =~ s/$bad_name/$good_name/g;

#			print "NEW NAME: $newname\n";
			print "RENAMING file $file -> $newname...\n";
			move $file, $newname;
		}
	}
}

# Content Changes

@bfiles = File::Find::Rule->new
	->name("*.java")
	->maxdepth(1)
	->in($bindings_dir);
foreach my $file (@bfiles) {
	$foundMatch = 0;

	$tmpfile = "/tmp/foo.java";


	my ($fname, $fdir, $fsuffix) = fileparse($file);
	my $bn = $fname;
	$bn =~ s/\.java//g;

	open(my $OUTFILE, ">", $tmpfile);
	open(my $INFILE, "<", $file);
	while(my $line = <$INFILE>) {

#		print "LINE: $line\n";
		my $newLine = $line;
		foreach my $name (@NAMES) {
			my @nt = split /,/, $name, 2;
			my $good_name = @nt[0];
			my $bad_name = @nt[1];

			if ( index($newLine, $bad_name) != -1 ) {
				# print "FIXING CONTENT LINE: $newLine\n";
				$newLine =~ s/$bad_name/$good_name/g;
				# print "FIXED CONTENT LINE: $newLine\n";
				$foundMatch = 1;
			}

		}
		print $OUTFILE $newLine;
	}

	close $INFILE;
	close $OUTFILE;

	if ( $foundMatch ) {
		# copy temp file to file

		print "UPDATING FILE CONTENTS for $file\n";
		copy $tmpfile, $file;
		unlink $tmpfile;
	}
}
