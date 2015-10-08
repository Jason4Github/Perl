#!/usr/local/bin/perl

iterate_dir("dir_to_chkin");

sub iterate_dir {

        my $dir_name=$_[0];
        opendir(my $dh, $dir_name) || die "can't opendir $dir_name: $!";
        my(@files) = readdir $dh;

        foreach(@files) {
                if( $_ eq '.' || $_ eq '..' || $_ eq '.ade_path' ) {
                        next;
                }
                if( -f "$dir_name/$_" ) {
                        print "File :::::::: $dir_name/$_\n";
						system("ade mkelem -nc $dir_name/$_");
                } else {
#                       print "Iterating -- $dir_name/$_\n";
						system("ade mkdir $dir_name/$_");
						system("ade ciall");
                        iterate_dir("$dir_name/$_");
                }
        }
						system("ade ciall");

		closedir $dh;

}

