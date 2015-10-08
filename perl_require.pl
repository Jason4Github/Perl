#!/usr/bin/perl 
#
use warnings;
use strict;

use lib qw(/local/script);
require 'perl_try.pl';

#print @INC;
dump_data_for_path('.', data_for_path('.'));

