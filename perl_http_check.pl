#!/usr/bin/perl -w
#使用正则表达式中"零宽断言"来匹配主机IP
#负向零宽后发断言为 (?<!表达式)
#author:pandaychen
use strict;
use warnings;
 
my $grub_ip;
my %ip_hash;
 
#(?<![\d\.]) 环视,$1左侧不是数字或.
my $ip_regex=qr{
    (?<![\d\.]) ##环视,左侧不是数字或.
    (
    ##捕获
      (?:2[0-4]\d | 25[0-5] | [01]?\d\d? ) ##第一组
      \.
      (?:2[0-4]\d | 25[0-5] | [01]?\d\d? ) ##第二组
      \.
      (?:2[0-4]\d | 25[0-5] | [01]?\d\d? ) ##第三组
      \.
      (?:2[0-4]\d | 25[0-5] | [01]?\d\d? ) ##第四组
    )
    (?![\d\.]) ##环视,$1右侧不是数字或.
}x;
 
while(<>)
{
    if(m{$ip_regex})    #匹配ip_regex
    {
        #捕获成功
        $grub_ip=$1;       
        print $grub_ip,"\n";
        $ip_hash{$grub_ip}++;
    }
}
 
my ($key,$value);
 
#遍历Hash的常用做法
while( ($key,$value) = each %ip_hash )
{
    print "$key==>$value","\n";
    #keys(%ip_hash);    #返回Hash首址  
    sleep(2);
}
