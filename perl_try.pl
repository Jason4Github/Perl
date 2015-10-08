#!/usr/bin/perl -w

use strict;
=off
BEGIN{
    use CGI::Carp qw(fatalsToBrowser carpout set_message);
    #open(LOG,">>errors.log") or die "Couldn't open log file, $!\n";
    #carpout(LOG);

    sub handle_errors {
        my $msg = shift;
        print "<h1>Software Error Alert!!</h1>";
        print "<h2>Your program sent this error:<br><I>
        $msg</h2></I>";
    }
    set_message(\&handle_errors);

}

sub cgi_try {


    my $obj = CGI->new;
    print $obj->header;
    print $obj->start_html("WELCOME");
    print $obj->h2("hello word");

    &print_form($obj);
    &do_work($obj) if ($obj->param);

    print $obj->end_html;



}
#cgi_try;

sub print_form {
    my $obj = shift;

    print $obj->startform;
    print "what's your name";
    print $obj->textfield('name');
    print "what's your occupation?";
    print $obj->textfield(-name=>'occupation',
                          -default=>'software engineer',
                          -size=>60,
                          -maxlength=> 100);
    print $obj->br();
    print $obj->hr();
    print "choose your age<br>";
    print $obj->radio_group(-name => 'age',
                            -value => ["21-25", "25-30", "30-35", "35-40"],
                            -default => ["30-35"],
                            -linebreak => 'TRUE'
                           );
    print "<br><hr>";
#print <<CHECKBOX_GROUP; #this here doc print not valid when try to print $obj method
    print "choose your favourite<br>";
    print $obj->checkbox_group(-name => 'favorite',
                         -value => ['News', 'Sport', 'Fanancy'],
                         -default => ['News'],
                         -linebreak => 'TRUE');

#CHECKBOX_GROUP
    print "<br>";
    print $obj->submit('action', 'Enter');
    print $obj->reset();

    print $obj->endform;
    print $obj->hr();

}

sub do_work {
    my ($obj) = @_;
    my (@value, $key);

    print $obj->h2("here are the settings");

    foreach $key($obj->param) {
        print "$key: \n";
        @value = $obj->param($key);
        print join(", ", @value), "<br>";
    }
}

no CGI;

=cut

=off
{
print <<HTML; #this is ok
    #print <<HTML; this is wrong
        hello word

HTML
print "done\n";
}

sub print_welcom_info {
    print "Content-type: text/html\n\n";
print <<HTML;
        <html>
        <head><title> Decoding the input data</title></head>
        <body bgcolor="lavender">
        <font face="verdana", size="+1">
HTML
    print "<H3><U>Query the QUERY_STRING in ENV</U></H3>";
    #get the QUERY_STRING
    my $input_string = $ENV{QUERY_STRING};
    #split the key and value by &
    my @array = split /&/, $input_string;
    #handle the key and value
    my %decode;
    foreach (@array) {
        #replace plus to blank
        tr/+/ /;
        #split the content by =
        (my $key, my $value) = split /=/;
        #handle the hex value
        $key =~ s/%(..)/pack("C", hex $1)/ge;
        $value =~ s/%(..)/pack("C", hex $1)/ge;
        $value =~ s/\n/ /g;
        $value =~ s/\r//g;
        $value =~ s/\cM//g;
        $decode{$key} = $value;
    }
    print "<hr>";
    print "<P><B>After decoding</B></P>";
    while ((my $key, my $value) = each %decode) {
        print "$key: <I><U>$value</U></I><br>";
    }

print <<HTML;
        <hr>
        </font>
        </body>
        </html>
HTML
}
print_welcom_info;
=cut

=off
This is doing URL code parser
?dddddd&ddddd=ddddd+dddd%0f%fd;
?  --begin with URL code style code
+  --blank
&  --sperate key and value
%..--hex value indicate this charecter not number or alpha.
=cut
sub URL_code_parser($) {
	my $code = shift;

	print "$code\n";
	#split the key and value
	my @array = split /&/, $code;
	foreach (@array) {
		#replace plus to blank
		tr/+/ /;
		#second split key and value
		(my $key, my $value) = split /=/;
		#decode hex value
		$key =~ s/%(..)/pack "C", hex $1/ge;
		$value =~ s/%(..)/pack "C", hex $1/ge;
		print "key: $key, value: $value\n";
	}

}
#the para should be replaced by my $str = %ENV{QUERY_STRING};
#URL_code_parser("name=jaoson+yu+wangjing+street&phone=182%23%23%23%2E%2E%2E");

use Carp;
sub shell_cmd_try {
	my $path = `pwd`;
	chomp $path;

	print "$path\n";
	my $file1 = "$path/file1";
	`touch $file1`;
	`echo "hello_word" > $file1`;
	`cat $file1`;#the result do NOT be show in perl STDOUT
	
	print "==================\n";
	my $str = `tr [a-z] [A-Z] < $file1`;
	print "$str\n";
	#`echo $str > $file1`; #wrong, nothing will be included in file1
	`echo "$str" > $file1`;
	unlink $file1 or croak "unlink $file1 failure";
	print "$file1 also exist after invoke unlink\n" if -f $file1;
}
#shell_cmd_try();
no Carp;


sub file_operation {
    my $path = `pwd`;
    chomp $path;
    my $file1 = "$path/file_1";
    my $file2 = "$path/file_2";

    open FH, "| tr [a-z] [A-Z]";
    open FH1, "+>$file1" or die "can not open $file1\n";
    open FH2, "+>$file2" or die "can not open $file2\n";
    print FH2 "hello word";
    close FH2;

    open FH2, "$file2";
    while (<FH2>) {
        print;
        #$_ =~ tr/a-z/A-Z/;
        tr/a-z/A-Z/;
        print FH1;
        print FH ;
    }   
    close FH2;
    close FH1;
    close FH; 
}

#file_operation();




#run shell script
#system("/local/script/linux_memory_cpu_status.sh");
#

#This is writing for Windows OS
=off
use IO::Tee;
sub handle_file {
   my $path = shift;

   my @dirs = grep {-d $_} glob "$path\\*"; 
   foreach (@dirs){
      handle_file($_);
   }
   my @files = glob "$path\\*";
   foreach (@files) {
       my $fail_count = 0;

       #open LOG, "+>>$path\\result.log" or die "open log failuer\n";
       #print LOG "$_\n";
       my $tee = IO::Tee->new(">>$path\\result.log", \STDOUT);
       print $tee "$_";
       open FILE, $_;
       while (<FILE>) {
           ++$fail_count if grep(/FAIL/, $_);
       }
       close FILE;

       if ($fail_count > 0) {
           #print LOG "FAIL, $fail_count times FAIL be found\n\n";
           print $tee "FAIL, $fail_count times FAIL be found\n\n"
       } else {
           #print LOG "PASS, testing pass\n\n" ;
           print $tee "PASS, testing pass\n\n" ;          
       }
       
       #close LOG;
   }
}

#handle_file("D:\\Perl_script");

no IO::Tee
=cut

use Data::Dumper;
#use YAML;
sub data_for_path {
	my $path = shift;
	return undef if -f $path or -l $path;
	if (-d $path) {
		my %directory;
		opendir PATH, $path;
		my @names = readdir PATH;
		close PATH;
		for my $name (@names) {
			next if grep(/^\.\.?$/, $name);
			#next if $name eq '.' or $name eq '..'; #correct
			#next if $name eq '.' or eq '..'; #wrong
			$directory{$name} = data_for_path("$path/$name");
		}
		return \%directory;
	}

	warn "$path is neither a file nor a dir\n";
	return undef;
}
#print Dumper data_for_path "/home/hsyu/work/test1";	
#print Dumper data_for_path '.';	
#print Dump data_for_path "/home/hsyu/work";	

#no YAML;
no Data::Dumper;

sub dump_data_for_path {
	my $path = shift;
	my $data = shift;
	#print "$path\n" and return if not defined $data;
	print "$path\n";
	return if not defined $data;
	
	my %directory = %$data;
	for (sort keys %directory) {
		dump_data_for_path("$path/$_", $directory{$_});
	}
}
#dump_data_for_path('/home/hsyu/work/test1', data_for_path '/home/hsyu/work/test1');
#dump_data_for_path('.', data_for_path '.');



use YAML;
{
	my $count = 10;
	sub count_sum{ ++$count;}
	sub count_get{ print "$count\n";}
	sub count_return{ return $count;}
}

#print Dump count_sum();
#print Dump count_sum();
#print Dump count_sum();
#print Dump count_sum();

#Dump count_get();
#print Dump count_return(), "\n";

no YAML;

#parameters:
#1: dir path
#2: file name key words
#3: new key words
sub rename_replace{
	my $dir_path = shift;
	my $file_name_key = shift;
	my $new_words_key = shift;

	print "$dir_path\n";
	#tranverse dir
	my @dir = grep { -d $_ } glob "$dir_path/*";
	foreach (@dir) {
		rename_replace($_, $file_name_key, $new_words_key);
	}
	my @files = grep { $_ =~ ".*$file_name_key"} glob "$dir_path/*";
	foreach (@files){
		#get basename
		my @known_file_name = split "/", $_;
		$known_file_name[-1] =~ s/$file_name_key/$new_words_key/g;
		my $new_file_path = join "/", @known_file_name;
		my $ret = rename $_, $new_file_path;
		print "========rename done, $ret\n";
	}
}
use File::Basename;
rename_replace("/home/opentv/windows_data/Maldives_share", "JPG", "jpg");
no File::Basename;

sub calculate_average{
	my $key_word = "chop succesfully";
	my $sum = 0;
	my $count = 0;

	while(defined(my $line=<>)){
		if ($line =~ $key_word){
			$line =~ s/:\d+//g;
			$line =~ s/\D//g;
			#$line =~ s/[[:punct:]]//g;
			$sum += $line;
			$count++;
			print "sum: $sum, count: $count\n"; 
		}
	}
	$sum /= $count;
	print "\n\n";
	print "*******************\n";
	print "*average: $sum ms*\n";
	print "*******************\n";
	print "\n\n";
}
#calculate_average();

#work fine, rename is build-in function
#rename "abc", "abc_bark";
#copy, move not built-in function
#copy "abc_bark", "abc_cp";
#move "abc_back", "abc_mv";

sub calculate_word_repeat_reference {
    my $word_list = shift;

    while(my $word=<>) {
        $word =~ s/[[:punct:]]//g;
        while ($word =~ /\S+/g) {
            #the folllowint two method all can dereference of harsh, but $word_list->$& is NOT correct
            #++$$word_list{$&};
            ++$word_list->{$&};
        }
    }
}

sub sort_harsh_reference {
    my $harsh_table =  shift;
    my $i = 0;
    #the folllowint two method all can dereference of harsh
    #for (sort {$$harsh_table{$b} <=> $$harsh_table{$a} or $a cmp $b} keys %$harsh_table) {
    #   printf "%-4d, %s\n", $$harsh_table{$_}, $_;
    #}
    for my $key (sort {$harsh_table->{$b} <=> $harsh_table->{$a} or $a cmp $b} keys %$harsh_table) {
        printf "%-4d, %s\n", $harsh_table->{$key}, $key;
        #only print 10 items
        return if ++$i == 10;
    }

}

sub get_and_sort_words_reference {
    my %words;
    calculate_word_repeat_reference(\%words);
    sort_harsh_reference(\%words);
}




#
#@ARGV[0]
#
our %wordList;
sub get_word_1{
	while(defined(my $line=<>)){
		#print("line: $line\n");
		$line =~ s/[[:punct:]]//g;
		#extract word
		while($line =~ /\S+/g){
			my $word = $&;
			#print("word: $word\n");
			$wordList{$word} += 1;
			#printf("%-4d %s\n", $wordList{$word}, $word);
		}
	}
}

#note:  //g, the 'g' indicate match will be occurred on global line
sub get_word_2{
	while(<>){
		#remove punctuation
		s/[[:punct:]]//g;
		#extract word
		while(/\S+/g){
			my $word = $&;
			#print "word: $word\n";
			$wordList{$word} += 1;
		}
	}
}


#blank line will be handled by last word, this method not good
#use defined() to remove blank line, defined() can't used $_
sub get_word_3{
	print "please input several string, end by CTRL+D\n";
	my @word;
	while(defined(my $line=<>)){
		#print "line: $line\n";
		$line =~ s/[[:punct:]]+//g;
		$line =~ s/^\s+|\s+$//g;
		my @word=split(/\s+/, $line);
		foreach(@word){
			#print "word: $_\n";
			$wordList{$_}++;
		}
	}
}

sub sort_by_repeatTimes{
	print "================================================\n";
	my %wordList = @_;

	foreach(sort {$wordList{$b}<=>$wordList{$a} or $a cmp $b}keys(%wordList)){
		printf "%-4d%s\n", $wordList{$_}, $_;
	}
	print "================================================\n";
}

sub get_and_sort_words {
    get_word_1();
    sort_by_repeatTimes(%wordList);
}

#performance 1 == 2 > 3
#get_word_1();
#get_word_2();
#get_word_3();

#sort_by_repeatTimes(%wordList);


sub getWords {
    my %wordRepeat;

    while (defined(my $line = <>)) {
        #print "====== $line";
        $line =~ s/[[:punct:]]//g;
        #print "====== $line";
        my @words = split(/\s+/, $line);
        #print "words: @words";
        foreach (@words) {
            $wordRepeat{$_}++;
        }

    }

    return \%wordRepeat;

}

sub sortRepeat {
    my $p = shift;
    print "=====================\n";
    foreach ( sort{$p->{$b}<=>$p->{$a} or $p->{$a} cmp $p->{$b}} keys %$p) {
        printf("%-4d, %s\n", $p->{$_}, $_);
    }
    print "=====================\n";
}

sortRepeat(getWords());


our %alphaList;

sub get_alpha{
	print "please input several string, end by CTRL+D\n";
	while(defined(my $line=<>)){
		$line =~ s/\s+//g;
		$line =~ s/[[:punct:]]+//g;
		#print "\$line: $line\n";
		my $i=0;
		my @alpha;
		while($i < length $line){
			my $alpha = substr($line, $i, 1);
			push(@alpha, $alpha);
			#print "@alpha\n";
			$alphaList{$alpha}++;

			$i++;
		}
	}
}

#get_alpha();
#sort_by_repeatTimes(%alphaList);


#18210113587
#1[3458]
#13[0-9]{9}
#14[57][0-9]{8}
#15[0-35-9][0-9]{8}
#18[025-9][0-9]{8}
#01069969178
#077363957397
#
sub check_phone{

	while(<>){
		chomp;
		if (/13\d{9}|14[57]\d{8}|15[0-35-8]\d{8}|18[025-9]\d{8}/) {
			print "CORRECT cell phone number: $_\n";
		} else {
			print "NOT correct cell phone number: $_\n";
		}
	}
}
#check_phone();

sub check_phone_grep{

	while(<>){
		chomp ;
		my $correct = "CORRECT cell phone number, $_\n";
		my $wrong = "WRONG cell phone number, $_\n";
		grep(/13\d{9}|14[57]\d{8}|15[0-35-8]\d{8}|18[025-9]\d{8}/, $_) ? print $correct : print $wrong;
	}
}
#check_phone_grep();

 #try IO::Prompt
sub _begin_phase{
     my ($content)=@_;
 
     #print {*STDERR} "$content\n";
     print STDERR "$content\n";
}
 
sub _continue_phase{
    #print {*STDERR} ".\n";
    print STDERR ".\n";
}
 
sub _end_phase{
    #print {*STDERR} "Done\n";
    print STDERR "Done\n";
}
 
 
 
sub _try_prompt{
	use IO::Prompt;
	use Smart::Comments;

	### starting... done
	_begin_phase("starting...");
	my $line=prompt "enter a line:";
	print "line: $line\n";

	_continue_phase();
	$line=prompt "enter a passwer: ", -echo => "*";
	print "line: $line\n";

	#$line=prompt(get_prompt_str( ), -fail_if => $QUIT);    
	#print "line: $line\n";

	_end_phase();
	no IO::Prompt;
	no Smart::Comments;
}
#my $i=5;
#while($i--){
#_try_prompt();
#}

#split in perl awk shell
#perl                       awk                    shell
#@a=split /m/, $str   split($str, $array, /m/)     split -l(-opt) 10 filename newfilename



#my $str="i love you, see u~";
#my $love=substr($str,index($str, "love"));
#print "$love\n";
#my $rename=substr($str, index($str, "love"));
#print "$rename\n";


#my $str="hello world!!";
#$where=index $str, "o";
#print "$where\n";
#$where1=index $str, "o", $where+1;
#print "$where1\n";
#$where2=rindex $str, "o";
#print "$where2\n";

#file check: -e -s -A -M -r[R] -w[W] -x[X] -o[O] -z(file exist, but size = 0) -f -d -l -p -S(socket)
#my @ori=qw/agc bcd abc/;
#my @old;

#for(@ARGV)
#{
#	print "$_\n";
#	#push @old, $_ if -s $_>10 and -A $_>2;
#	#push @old, $_ if -A $_>2;
#}
#print "old: @old\n";

#$filename="cmd.log";
#die "$filename didn't exist\n" if -e $filename;
#warn "$filename was not accessed with 1 day\n" if -M $filename > 1;

#regular file ./s /x /i ; \d \s \w \D \S \W;

#$var="hello world!!";
#print "$var\n";
#$var=~s#(\w+)#\u$1#g;
#print "$var\n";





#my %statisticFail=(
#		"FAIL" => 0,
#		"PASS" => 0,
#		"WARN" => 0,
#);

#my $file=shift @ARGV;
#print "current file: $ARGV[0]\n";


#	in biaoLiang env, <HANDLE> indicate a line
#	in list env, <HANDLE> indicate a array, when open a file by +>> mode, please note the pos is end of file.

sub handle_in_list_env{

	open FILE, "+>>qatest" or die "can't open file qatest, $!";
	#rewind(FILE); #don't work
	my $pos=tell(FILE);
	print "pos: $pos\n";
	seek(FILE, 0, 0);
	my $ipos=tell(FILE);
	print "pos: $pos\n";
	my $lines=join('', <FILE>);
	#print "$lines\n";
	#ADD A FLAG BEFORE EACH LINE	
	$lines =~ s/^/BEGIN\t/mg;
	#print "$lines\n";
	$pos=tell(FILE);	
	print "pos: $pos\n";
	print FILE "$lines\n";
	close FILE;
}

#handle_in_list_env();

#remove all .svn dir and thumbs.db file in specify dir
#use File::Path;
#use File::Find;

#sub doc_remove{
#	print "please input a dir path:\n";
#	while(<=>){
#		find(\&rm_dir_file, $_);
#		print "remove specify doc done\n";
#	}
#}

#sub rm_dir_file{		
#	remove_tree(File::Find::name) if /^\.svn$/ and -d ;
#	unlink(File::Find::name) if /\bthumbs.db\b/ and -f;
#}


#doc_remove();

#no File::Path;
#no File::Find;


sub doc_remove_2{
	my ($path)=@_;
	my $DIR;
	opendir($DIR, $path);
	
	print "enter dir: $path\n";
	#my $docTEMP=readdir DIR;
	#print "docTEMP: $docTEMP\n";
	
	#while(my $doc=<DIR>){ #don't work #but file handle used while<FILE_HANDLE> works well.
	while(my $doc=readdir $DIR){
		if ($doc !~ /^\.\.?$/){
			$doc="$path"."/$doc";
			print "current doc: $doc\n";

			if (-d $doc){
				doc_remove_2($doc) ;
				if ($doc =~ m%/\.svn/?%){
					print "++++++++++rmdir $doc\n";
					rmdir($doc);
				}
			}
			elsif(-f $doc){
				if ($doc =~ m%/thumbs\.db$% || $doc =~ m%/\.svn/%){
					print "++++++++++unlink $doc\n";
					unlink $doc;
				}
			}
		}
	}
	
	closedir($DIR);
}

#my $path=@ARGV[0];
#print "\@ARGV[0]: @ARGV[0]\n";
#doc_remove_2($path) or die "no dir path be input";
#print "=====================================\n";

our %statisticFail;

sub file_search{
	foreach(@ARGV)
	{	
		my $file=$_;
		print"current file: $file\n";
		open HANDLE_F, $file or die "open file $file failure";

		while(<HANDLE_F>){
        	if(/(\bFAIL\b)+/){
                	$statisticFail{"FAIL"} += 1;
        	}
        	elsif(/(\bPASS\b)+/){
                	$statisticFail{"PASS"} += 1;
	       	}
		}
	}
}

#file_search();
#sort_by_repeatTimes(%statisticFail);


sub get_word_new{
	my %tempList;
	use Smart::Comments;
	use POSIX qw/strftime/;
	use IO::Prompt;

	print strftime("current time: %H-%M-%S\n", localtime());
	while (<>){
		#my @word=grep { /abc/ } $_;#if grep match, will  return the total line content
		s/[[:punct:]]//g;
		while (/\w+/g){
			push my @word, $&;
			$tempList{$&}++;			
			###continue...
		}
	}

	print strftime("current time: %H-%M-%S\n", localtime());
	
	my $choice=prompt("start sorting...?[yn]");
	return 1 if grep /[Nn]/, $choice;

	
	#local $.=1; #can't reset the $.
	
	my $i=10;
	foreach (sort {$tempList{$b} <=> $tempList{$a}
					or $a cmp $b} 
			 keys %tempList){

		#print "$_" if (1..10);
		if ($i != 0){
			printf "%g\t\t%-4g\t%s\n", $i, $tempList{$_}, $_;
			$i--;
		}

	}

	no Smart::Comments;
	no POSIX;
	no IO::Prompt;
}

#get_word_new();


sub _getinfo{
	#读取串口数据
	my ($com)=@_;
	my $char;

	print "shandle: $com\n";
	
	if (read($com, $char, 1)){
		$char = ord($char);
		print "$char\n";
	}
	else{
		print "none";
	}
}
sub _read_from_serial{
	use IO::Handle;
	use IO::Prompt;

	##初始化串口
	system("stty -echo raw 115200 </dev/ttyS0");
	system("stty -a");
	
	##打开串口
	open my $ser,'+>','/dev/ttyS0' or die "can't open serial port\n";
	print "serial port handle: $ser\n";
	
	##向串口写数据
	#print $ser chr(3);
	#$ser->autoflush(1);
	
	while(1){
	##得到串口数据
		my $info = _getinfo($ser);
		
        print $info;
		my $str=prompt("go on...[yn]");
		return 1 if grep /[Nn]/, $str;
		
        #向串口发送数据
        #print $ser chr(65);#A

    } 

	close $ser;
    no IO::Handle;
	no IO::Prompt;
}

#_read_from_serial();


sub benchmark_try{
	use Benchmark qw/:all/;

    my $r = timethese( -5, {
                a => get_and_sort_words_reference(),
                b => get_and_sort_words(),
            } );
    cmpthese $r;

	no Benchmark;


}

#benchmark_try();






#while(<>)
#{
	#my $failCnt = grep /\bFAIL\b/g, $_; #input: FAIL FAIL ; the $failCnt show 1, NOT 2!!!!!!
	#print "$failCnt\n";
#	#if(/(\bFAIL$)+/)
#	if(/(\bFAIL\b)+/)
#	{
#		$statisticFail{"FAIL"} += 1;
#		#print "met FAIL $statistic{\"FAIL\"} times\n";
#		print "met \"FAIL\" $statisticFail{\"FAIL\"} times\n";
#		#print "$_";
#		print;
#	}
#	elsif(/(\bPASS\b)+/)
#	{		
#		$statisticFail{"PASS"} += 1;
#		#print "met \"PASS\" $statisticFail{\"PASS\"} times\n";
#	}
#}

#$FAIL=$statisticFail{"FAIL"};
#$PASS=$statisticFail{"PASS"};
#$WARN=$statisticFail{"WARN"};

#print "fail: $FAIL\npass: $PASS\nwarn: $WARN\n";


#while(<>)
#{
#	if(/^\w\s(\bFAIL)+/)
#	{
#		print "match $1\n";
#	}
#	else
#	{
#		print "$_";
#	}
#}


#my %family_name=(
#	"fred" => "abc",
#	"dino" => undef,
#	"barney" => "cba",
#	"betty" => "rubble",
#);
#$family_name{"fred"}="flintstone";
#$family_name{"barney"}="rubble";

#foreach(qw/fred barney/)
#{
#	print "name: $_, family_name: $family_name{$_}\n";
#}

1
