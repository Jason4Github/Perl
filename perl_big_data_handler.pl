#! /bin/env perl
#
#
use warnings;
#use strict;

use constant FILE_UNIT_SIZE => 10*1024*1024;

sub get_cwd {
	#my $file = `pwd`;
	#my $file =~ s/[\n\r]//;

	my $file = $ENV{PWD};
	return "$file";
}

sub create_big_file_digital {
	my ($file, $size) = @_;

	open(my $FH, ">$file");
	
	my $file_size = 0;
	while(1) {
		my $line = int(rand(999999)) + 1;
		print $FH "$line\n";
		print $FH "$file_size\n";
		$file_size += length("$line") + 1 + length("$file_size") + 1;
		last if $file_size >= $size;
		#last if ((-s $FH) >= $size); ###performance worse than above one algorithm, create 200 files, performance slow 70 secs###
	}
						
	close($FH);
}

sub create_big_file_string {
	my ($file, $size) = @_;

	open(my $fh, ">$file") || die "create file \"$file\" failure";
	my $file_size = 0;
	my @strArray = (0..9, 'a'..'z', 'A'..'Z');
	my $strArrayLen = @strArray;

	while(1) {
		my $strLen = int(rand(10)) + 1;
		my $string = join("", map({$strArray[int(rand($strArrayLen))]} 1..$strLen));		
		print $fh "$string\n";
		$file_size += $strLen + 1;
		last if $file_size >= $size;
	}

	close($fh);
}

sub create_dir {
	my $dir = shift;

	-d $dir || mkdir("$dir", 0666) or die "create dir \"$dir\" failure, $!";
}

sub get_dir_name {
	my $path =  shift;

	return substr($path, 0, rindex($path, "/"));
}

sub get_file_name {
	my $path = shift;

	return substr($path, rindex($path, "/")+1);
}

sub split_file {
	use Carp;
	use IO::Prompt;
	
	my ($file_dir, $file_name, $file_nums) = @_;
	my $file_full_name = "$file_dir/$file_name";

	printf("\n\tspliting file \"%s\" to %d files\n", $file_full_name, $file_nums);
	my $answer = prompt("start to bark original file? [y/n]", -ynt);

	if ($answer =~ /[yY]/) {
		#use File::Copy;
		#use Cwd;
		my $dest_file = "${file_full_name}.bark";
		
		system("cp $file_full_name $dest_file");
		
		#no Cwd;
		#no File::Copy;
	}

	open(FH_ORI, "<$file_full_name") or die("open file \"$file_full_name\" failure, $!");
	
	#create splited files
	my $splited_dir = "$file_dir/dir_splited";
	create_dir($splited_dir);
	my @FH;
	for (my $i=0; $i<$file_nums; $i++) {
		my $target = "$splited_dir/${file_name}_$i";
		$FH[$i] = "FH_$i"; #file handle must be attached to a existent var
		open($FH[$i], "+>$target") or die "open file \"$target\" failure, $!";
		#printf("file handle nb: %d\n", fileno($FH[$i])); #for debug
	}
	
	while (1) {
		read(FH_ORI, my $buffer_read, 4*1024);
		if ($buffer_read =~ /^$/) {
			print "read to the end of the file\n";			
			last;
		} else {
			#if read the content not include a full line
			if ($buffer_read !~ /[\n\r]$/) {
				my $pos = tell(FH_ORI);
				#print "current file \"$file_full_name\" pos: $pos\n"; #for debug
				while (my $line=<FH_ORI>) {
					$buffer_read .= $line;
					last if $buffer_read =~ /[\n\r]$/;
				}
			}
		}

		#put all numbers into difference files by the length of the number
		while($buffer_read =~ /\w+-?\w*/g) {
			my $line = "$& \n" if defined $&;
			#### 将指定内容放入指定文件 by 取模算法 ####
			my $len = length("$line") - 1; #becasue the line include "\n" or "\r", so the length should reduce(-) 1
			#print "length of the line \"$line\" == $len\n"; #for debug
			my $num = $len % $file_nums;
			my $handle = $FH[$num];
			print $handle "$line";
		}
	}

	for (my $i=0; $i<$file_nums; $i++) {
		close($FH[$i]) or croak "close($FH[$i]) failure, $!";
	}

	close(FH_ORI);
	no IO::Prompt;
	no Carp;

	print "\nsplit done\n";
	return "$splited_dir";
}

sub split_file_by_size {
	use Carp;
	
	my ($file_dir, $file_name, $file_nums) = @_;
	my $file_full_name = "$file_dir/$file_name";
	my $file_size = -s $file_full_name;

	printf("\n\t spliting file \"%s\" to %d files\n", $file_full_name, $file_nums);
	open(FH_ORI, "<$file_full_name") or die("open file failure, $!");
	
	#create splited files
	my $splited_dir = "$file_dir/dir_splited";
	create_dir($splited_dir);
	my @FH;
	for (my $i=0; $i<$file_nums; $i++) {
		my $target = "$splited_dir/${file_name}_$i";
		$FH[$i] = "FH_$i"; #file handle must be attached to a existent var
		open($FH[$i], "+>$target") or die "open file \"$target\" failure, $!";
		#printf("file handle nb: %d\n", fileno($FH[$i]));  #for debug
	}
	
	my $size = 0;
	my $num = 0;
	while (1) {
		read(FH_ORI, my $buffer_read, 4*1024);
		if ($buffer_read =~ /^$/) {
			print "read to the end of the file\n";			
			last;
		} else {
			#if read the content not include a full line
			if ($buffer_read !~ /[\n\r]$/) {
				my $pos = tell(FH_ORI);
				#print "current file \"$file_full_name\" pos: $pos\n"; #for debug
				while (my $line=<FH_ORI>) {
					$buffer_read .= $line;
					last if $buffer_read =~ /[\n\r]$/;
				}
			}
		}
		
		$size += length("$buffer_read");
		if($size < FILE_UNIT_SIZE) {	
			my $handle = $FH[$num];
			print $handle $buffer_read;
		} else {
			$num++;
			my $handle = $FH[$num];
			print $handle $buffer_read;
			$size = 0;	
		}
	}

	for (my $i=0; $i<$file_nums; $i++) {
		close($FH[$i]) or croak "close($FH[$i]) failure, $!";
	}

	close(FH_ORI);
	no Carp;

	print "\nsplit file by size done\n";
	return "$splited_dir";
}

############################################################################
# function: sort_file()
# description:
#		This function will sort specified files 
#		and save the sorted files into specified dir
# args:
#		[input]  file dir, dir path, e.g. /home
#		[input]  file name, e.g. file_1
#		[input]  file numbers, indicate how many files should be handled
#
###########################################################################
sub sort_file {
	my ($file_dir, $file_name, $sorted_dir) = @_;
	my $file_path = "$file_dir/$file_name";
	my %file_sorted;

	print "start to sort all spiltted files\n";
	open(my $FH, "<$file_path") or die "open file \"$file_path\" failure, $!";
	while (my $line=<$FH>) {
		$file_sorted{$line}++;
	}
	
	my $file_sorted_path = "$sorted_dir/$file_name";
	open(my $FH_NEW, ">$file_sorted_path");
	for my $key(sort {$file_sorted{$b} <=> $file_sorted{$a}} keys %file_sorted) {
		print $FH_NEW "$file_sorted{$key}", "\t\t\t", "$key";
	}

	close($FH_NEW);
	close($FH);
	print "file \"$file_path\" already be sorted\n";
}

############################################################################
# function: map_file()
# description:
#		map the big file, split it to many small file, 
#		the small file size be specified by constant FILE_UNIT_SIZE
#
# args:
#		[input]  file dir, dir path, e.g. /home
#		[input]  file name, e.g. file_1
#		[input]  file numbers, indicate how many files should be handled
#		[output] dir path, retutn what the dir include the sorted files 
#
###########################################################################
sub map_file {
	my ($file_dir, $file_name, $file_nbs) = @_;

#=off	
	my $splited_dir = split_file($file_dir, $file_name, $file_nbs);
	#my $splited_dir = "$file_dir/dir_splited"; #for debug
	my $sorted_dir = "${splited_dir}_sorted"; 
	
	create_dir($sorted_dir);	
	for (my $i=0; $i<$file_nbs; $i++) {
		my $file_full_name = "$splited_dir/${file_name}_$i";	
		my $file_size = -s $file_full_name;	
		if ($file_size == 0) {
			unlink($file_full_name);
			print "removed the empty file $file_full_name\n";
			next;
		} elsif ($file_size > FILE_UNIT_SIZE) {
			my $file_name_size = "${file_name}_$i";
			print "the file \"$splited_dir/$file_name_size\" size > 10M, go on spilt it\n";
			my $file_nbs_size = int($file_size/FILE_UNIT_SIZE) + 1;
			my $splited_dir_size = split_file_by_size($splited_dir, $file_name_size, $file_nbs_size);
		
			for(my $j=0; $j<$file_nbs_size; $j++ ) {
				sort_file($splited_dir_size, "${file_name_size}_$j", $sorted_dir);
			}
		} else {
			sort_file($splited_dir, "${file_name}_$i", $sorted_dir);
		}
	}

	print "map file into dir \"$sorted_dir\" done\n";
	return "$sorted_dir";
#=cut
}


############################################################################
# function: reduce_file()
# descrition:
#			reduce the sorted files,
#			put the top N hot words into a file, 
#			and return the file's full path.
# args:
#		[input]  a dir, which include what you want to be reduced files
#		[output] a file full path, the file include top N  hot words
#
###########################################################################
sub reduce_file {
	my $file_dir = shift;
	my $reduce_dir = "${file_dir}_reduce";

	print "start to reduce the sorted files\n";
	create_dir($reduce_dir);
	#get what already be sorted files
	my @files = `du '$file_dir'/* | sort -n | awk '{print \$NF}'`;

	my $i = 0;
	my %hash_1;
	foreach my $file (@files) {
		print "file: $file\n";
		open(my $FH, $file);
		my @array;
		while (my $line= <$FH>) {
			@array = split(/\s+/, $line);
			$hash_1{$array[1]} += $array[0];
			#print "top N hot words: $array[1]\t\t$hash_1{$array[1]}\n"; #for debug
			$i++;
			if ($i >= 1000 || eof) {
				$i = 0;
				last;
			}; #only read 1000 lines
		}
		close($FH);
	}
	
	my $reduce_file_full = "$reduce_dir/top_N_hot_words";
	open(my $fh, ">$reduce_file_full");
	my @buf;
	foreach my $key (sort {$hash_1{$b}<=>$hash_1{$a} or $a cmp $b} keys %hash_1) {
		my $line = sprintf("%-20s%-4d\n", $key, $hash_1{$key});
		push(@buf, $line);
	}
	
	print $fh "@buf";
	close($fh);
	print "reduce files into dir \"$reduce_dir\" done\n";
}

sub map_reduce_file {
	my ($file_dir, $file_name, $file_nums) = @_;
	my $sorted_dir = map_file($file_dir, $file_name, $file_nums);

	reduce_file($sorted_dir);
}

sub useage {
	print <<ABC
		
		this script is using for find hot words from big size file
		the top 1000 hot words will be get

		usage: $0 "your file's full path, e.g. /home/file" 

ABC
}

sub main() {
	my $input_file = $ARGV[0];
	if (! defined $input_file) {
		useage();
		exit;
	}

	my $file_size_byte = -s $input_file;
	my $file_nums  = int($file_size_byte/FILE_UNIT_SIZE) + 1;

	print "split file into $file_nums files\n";
	my $file_dir = get_dir_name($input_file);
	my $file_name = get_file_name($input_file); 

	
	map_reduce_file($file_dir, $file_name, $file_nums);


	#get_and_sort_words_reference(); 
	printf("\n\n\t\tTesting done!\n\n");
}


main();

#my $file = get_cwd();
#create_big_file_string("$file/file_big_string_try", 40*1024*1024);


1

