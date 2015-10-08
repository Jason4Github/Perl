#!/usr/bin/perl -w

#use Fcntl qw(:flock);

use strict;
use Mail::Sender;
use Sys::Statistics::Linux;
use Fetion;
my $cpu_max=90;        #cpu最大占用率

my $mem_free_mix=10;    #最小可用内才能

my $disk_free_mix=50;    #最小可用磁盘空间

my $max_io=1;        #最大的io wait队列

#my $max_send_times=2;        

#my $match_count=0;

my %opt=(sysinfo => 0,
        cpustats => 1,
        procstats => 0,
        memstats => 1,
        pgswstats =>0,
        netstats => 0,
        sockstats => 1,
        diskstats => 0,
        diskusage => 1,
        loadavg => 1,
        filestats => 1,
        processes => 0,    
);
my $lxs = Sys::Statistics::Linux->new(\%opt);
my $cad_check_time=(localtime)[2];        #cad mean cpu and ddram

my $io_check_time=$cad_check_time;
my $disk_usage_check_time=$cad_check_time;
my $warn_flag=0;
my $pre_flag=0;
my $pre_io_check=0;
my $cur_io_flag=0;
my $pre_space_flag=0;
my $cur_space_flag=0;
my $small_space={{},1};
my @space;
my $counter=1;
#print STDOUT Dumper($small_space),"\n";

my $stat;
my @iostat;
while(sleep 2){
    my ($cad_flag,$space_flag,$io_flag)=(0,0,0);
    $stat = $lxs->get;
    @iostat=split /\s/,(`vmstat`)[2];        
    #这句为后面的IO检查做准备
    #如果cpu的占用率大于90％，或者内存占用达到90％，并且平均负载大于5，发送警报邮件和短信通知,这个部分还需要改良，最好进一步分开内存和cpu，因为内存占用很高，负载不一定高的
    #--------------------检查cpu和内存的使用情况－－－－－－－－－－－－－－－－－－－

    if($stat->cpustats->{cpu}->{total} > $cpu_max || \
      ($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100 < $mem_free_mix)
    #这里都是用百分比来计算的
    {
        if($stat->loadavg->{avg_1}>2)
        {
            $pre_flag=$warn_flag;
            $warn_flag=1;        #警报标志
            if($pre_flag==1)    #为1时，证明之前出现过警报的情况
            {
                if((localtime)[2]!=$cad_check_time)            #检查是否在同一时段出现警报，默认时间间隔为1小时，同一时段内，只发送一次短信和邮件
                {
                    print 'send when cpu&&ram busy and time !=',"\n";
                    #&sendMail('loadavg is too hight',$stat->cpustats->{cpu}->{total},($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100,$stat->loadavg->{avg_1});#sendMail(subject,cpu_usage,ram_free,loadavg)

                    &sendMail(1);            #1 mean cpu&&ram
                    &sendSms(1,'your phone number','you passwd');
                    $cad_check_time=(localtime)[2];            #更新最近一次的警报时间   
            }
        }
        else
        {
            #初次发送

            print 'send when flag=0, that is the first time',"\n";
            #&sendMail('loadavg is too hight',$stat->cpustats->{cpu}->{total},($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100,$stat->loadavg->{avg_1});#sendMail(subject,cpu_usage,ram_free,loadavg)

            &sendMail(1);
            &sendSms(1,'your phone number','you passwd');
        }
        $cad_flag=1;
    }
    else
    {
        $pre_flag=0;
        $cad_flag=0;
        
    }
}
#---------------------------cpu&& 内存检查完毕－－－－－－－－－－－－－－－－－－－－－－－－

#-------------------------------------------------------

#----------------检查磁盘空间 -----------------------------

#这部分还需要改进，如何去进一步的区别容量满的分区

my $driver;
foreach $driver(keys %{$stat->diskusage})
{
    next if $driver!~/^\/dev\//;
    #print $driver,"\n";

    my $drive=$driver;
    #print $drive,"\n";

    $driver=~s/\/dev\///gi;
    
    #print $driver,"\n";    

    #print $drive,"\n";

    if($stat->diskusage->{$drive}->{usage}/$stat->diskusage->{$drive}->{total}*100>$disk_free_mix)
    {
        if(!exists $small_space->{$driver})            #设备是否重复，重复的跳过

        {
                $small_space->{$driver}->{check_time}=(localtime)[2];            #记录出现警报的时间

                $small_space->{$driver}->{space_flag}=1;                #0 mean had checked before,1 not before

                $small_space->{$driver}->{free}=sprintf "%.2f",$stat->diskusage->{$drive}->{free}/$stat->diskusage->{$drive}->{total}*100;    #容量取两位小数

                print "send when the first time that $driver space is hardly full","\n";
                #&sendMail(2);

        }                    
        $space_flag=1;
    }
    else
    {
        if(exists $small_space->{$driver})
        {
            delete     $small_space->{$driver}
        }
        $space_flag=0;
    }
}
if((keys %{$small_space})>1)        #排除本来的没用HASH

{
    if($counter==1)
    {
        &sendMail(2);
        &sendSms(2,'your phone number','you passwd');
        $counter=2;
    }
    else
    {
        foreach $driver(keys %{$small_space})
        {
            next if $driver=~/^HASH/;
            if($small_space->{$driver}->{space_flag}==1)            
            {    
                if($small_space->{$driver}->{check_time}!=(localtime)[2])            #检查是否为同一时段，相同的跳过，避免重复发信，默认为1小时

                {
                    print 'send when someone disk space is fulland time !=',"\n";
                    $small_space->{$driver}->{check_time}=(localtime)[2];            #更新时间点

                    &sendMail(2);
                    &sendSms(2,'your phone number','you passwd');
                }
            }
        }    
    }
    
}
#－－－－－－－－－－检查磁盘空间结束－－－－－－－－－－－－－－－－－

#－－－－－－－－－－－检查磁盘io操作－－－－－－－－－－－－－－－－－

#@iostat=split /\s/,(`vmstat`)[2];        #要求有vmstat这个脚本，在/proc里边

if($iostat[-1]>$max_io)
{
    $pre_io_check=$cur_io_flag;
    $cur_io_flag=1;
    if($pre_io_check==1)
    {
        if((localtime)[2]!=$io_check_time)
        {
            print 'send when io busy and time !=',"\n";
            $io_check_time=(localtime)[2];
            &sendMail(3);
            &sendSms(3,'your phone number','you passwd');
        }
    }
    else
    {
        print 'send when pre_io_check=0, that is the first time',"\n";
        &sendMail(3);
        &sendSms(3,'your phone number','you passwd');
    }
    $io_flag=1;
}
else
{
    $io_flag=0;
}
#---------------------检查磁盘IO结束－－－－－－－－－－－－－－－－－

&writeLog($cad_flag,$space_flag,$io_flag);                #无论遇到什么警报，都记录在日志上

}        #主循环结束


#---------------------------函数部分－－－－－－－－－－－－－－－－－－－－－－－－－－－－－－

#----------------------writeLog fun----------------------------------------------

sub writeLog{
#use Data::Dumper;

my ($cad_flag,$space_flag,$io_flag)=@_;
if($cad_flag||$space_flag||$io_flag)
{
    my $time=localtime;
    my $log_file='log.txt';
    open LOG,">>",$log_file||die "can't open $log_file for write:$!\n"; 
    foreach my $dev(keys %{$small_space})        
    #因为日之中磁盘空间那里比较特别，所以要特殊处理；将整个字段作为一个数组处理，待会儿可以进行join
    {
        next if $dev=~/^HASH/;
        push @space,"$dev:$small_space->{$dev}->{free}";
    }
    printf LOG ("%s %.2f %.2f %.2f %s %s %d\n",
	        $time,
		$stat->cpustats->{cpu}->{total},$stat->loadavg->{avg_1},
		($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100,
	        join(",",@space),
		$iostat[-1],
		$stat->sockstats->{tcp});
#}

#select STDOUT;

#flock(LOG,LOCK_UN)||die "can't unlock $log_file:$!\n";

    @space=();
    close LOG;
}
}
#------------------------writeLog end ------------------------------

#---------------------sendSms fun-----------------------------------

sub sendSms{
my ($warn_type,$num,$passwd,$to_num)=@_;
#my $sms='cpu usage:'.$stat->cpustats->{cpu}->{total}.'% freemem:'.sprintf("%.2f",($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100).'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp};

my $sms;
if($warn_type==1)
{
    $sms='warning:Loadavg is too high.'.'cpu usage:'.$stat->cpustats->{cpu}->{total}.'% freemem:'.sprintf("%.2f",($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100).'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp};
}
elsif($warn_type==2)
{
    $sms='warning:Disk space is full.'.'cpu usage:'.$stat->cpustats->{cpu}->{total}.'% freemem:'.sprintf("%.2f",($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100).'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp};
}
else
{
    $sms='warning:Disk io are busy.'.'cpu usage:'.$stat->cpustats->{cpu}->{total}.'% freemem:'.sprintf("%.2f",($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100).'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp};
}
print "init..", Fetion::fx_init(), "\n";
if(Fetion::fs_login($num , $passwd ))#|| die " cannot login , try again please\n";

{#print "get account", Dumper( Fetion::fx_get_account() ), "\n";

    print "send to self......";
    Fetion::fs_send_sms_to_self($sms);
    print "\n";
    #print "send to $to_num..";

    #Fetion::fs_send_sms_by_mobile_no($to_num, $sms)||die "can't send:$!\n";

    #send to someuser of feixin

    #print "send to 440227509", Fetion::fs_send_sms(440227509, "你这个白痴"), "\n";

    print "loginout", Fetion::fx_loginout(), "\n";
    print "terminate", Fetion::fx_terminate(), "\n";
}
else
{
    if(open ERR,">>",'err.log')
    {    
        print ERR "can't send sms,please check the usename&&password again or make sure you internet is available\n";
        close ERR;
    }
    else
    {
        print "can't open err.log to write:$!\n";
    }
    print "can't send sms,please check the usename&&password again or make sure you internet is available\n";
    return -1;
}
}
#-----------------------sendSms fun end------------------------------

#-----------------------sendMail fun------------------------------------

sub sendMail{
my ($warn_type)=@_;
my $subject;
my $msg='cpu usage:'.$stat->cpustats->{cpu}->{total}.'% freemem:'.sprintf("%.2f",($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100).'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp};
if($warn_type==1)
{
    $subject='warning:Loadavg is too high';
    #$msg="cpu usage:$stat->cpustats->{cpu}->{total}% ".'freemem:'.($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100.'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp}.' Disk space:'.join(",",@space);

}
elsif($warn_type==2)
{
    $subject='warning:Disk space is full';
    foreach my $dev(keys %{$small_space})        #因为日之中磁盘空间那里比较特别，所以要特殊处理；将整个字段作为一个数组处理，待会儿可以进行join

    {
        next if $dev=~/^HASH/;
        push @space,"$dev:$small_space->{$dev}->{free}";
    }
    $msg='cpu usage:'.$stat->cpustats->{cpu}->{total}.'% freemem:'.sprintf("%.2f",($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100).'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp}.' '.join(",",@space);
}
else
{
    $subject='warning:Disk io are busy';
}
@space=();
#$msg='cpu usage:'.$stat->cpustats->{cpu}->{total}.'% freemem:'.sprintf("%.2f",($stat->memstats->{memfree}+$stat->memstats->{buffers}+$stat->memstats->{cached})/$stat->memstats->{memtotal}*100).'% system loadavg:'.$stat->loadavg->{avg_1}.'% IO wait:'.$iostat[-1].' TCP:'.$stat->sockstats->{tcp};#.' Disk space:'.join(",",@space);

my $sender;
eval{
    $sender=new Mail::Sender();

    #my @protocols = $sender->QueryAuthProtocols(); 查询服务器支持的认证方式

if ($sender->MailMsg({
               #smtp => 'smtp.163.com',by Default，test@163.com

               #from => 'test@163.com', by Default

               to =>'test98@163.com',
               subject => $subject,     #主题

               msg => $msg, #内容

               auth => 'LOGIN',            #smtp的验证方式

               authid => 'user',        #user

               authpwd => 'passwd',    #pwd

     }) < 0) {
              warn "$Mail::Sender::Error\n";
         }
    print "warning Mail sent OK.\n";
};
if($@)
{
    if(open ERR,">>",'err.log')
    {    
        print ERR "$Mail::Sender::Error\n";
        close ERR;
    }
    else
    {
        print "can't open err.log to write:$!\n";
    }
    print "can't send mail,please check the err.log for detail\n";
    return -1;
}
}
#--------------------sendMail fun end--------------------------------------






先了解/proc/stat文件信息

    在Linux/Unix下，CPU利用率分为用户态，系统态和空闲态，分别表示CPU处于用户态执行的时间，系统内核执行的时间，和空闲系统进程执行的时间。平时所说的CPU利用率是指：CPU执行非系统空闲进程的时间 / CPU总的执行时间。

    此信息都存储在/proc/stat文件中，

    在Linux的内核中，有一个全局变量：Jiffies。 Jiffies代表时间。它的单位随硬件平台的不同而不同。系统里定义了一个常数HZ，代表每秒种最小时间间隔的数目。这样jiffies的单位就是1/HZ。Intel平台jiffies的单位是1/100秒，这就是系统所能分辨的最小时间间隔了。每个CPU时间片，Jiffies都要加1。 CPU的利用率就是用执行用户态+系统态的Jiffies除以总的Jifffies来表示。

    在Linux系统中，可以用/proc/stat文件来计算cpu的利用率。这个文件包含了所有CPU活动的信息，该文件中的所有值都是从系统启动开始累计到当前时刻。样例如下：

[root@bogon tmp]# cat /proc/stat 
cpu  2175 501 15724 1114163 7094 2153 1144 0
cpu0 2175 501 15724 1114163 7094 2153 1144 0
intr 11576005 11430258 11 0 3 3 0 5 0 1 0 0 0 107 0 0 111811 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5461 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 28345 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 530531
btime 1228361375
processes 6764
procs_running 1
procs_blocked 0

 

输出解释
CPU 以及CPU0、CPU1每行的每个参数意思（以第一行为例）为：

参数 解释
user (432661) 从系统启动开始累计到当前时刻，用户态的CPU时间（单位：jiffies） ，不包含 nice值为负进程。1jiffies=0.01秒
nice (13295) 从系统启动开始累计到当前时刻，nice值为负的进程所占用的CPU时间（单位：jiffies）
system (86656) 从系统启动开始累计到当前时刻，核心时间（单位：jiffies）
idle (422145968) 从系统启动开始累计到当前时刻，除硬盘IO等待时间以外其它等待时间（单位：jiffies）
iowait (171474) 从系统启动开始累计到当前时刻，硬盘IO等待时间（单位：jiffies） ，
irq (233) 从系统启动开始累计到当前时刻，硬中断时间（单位：jiffies）
softirq (5346) 从系统启动开始累计到当前时刻，软中断时间（单位：jiffies）

CPU时间=user+system+nice+idle+iowait+irq+softirq

“intr”这行给出中断的信息，第一个为自系统启动以来，发生的所有的中断的次数；然后每个数对应一个特定的中断自系统启动以来所发生的次数。
“ctxt”给出了自系统启动以来CPU发生的上下文交换的次数。
“btime”给出了从系统启动到现在为止的时间，单位为秒。
“processes (total_forks) 自系统启动以来所创建的任务的个数目。
“procs_running”：当前运行队列的任务的数目。
“procs_blocked”：当前被阻塞的任务的数目。

那么CPU利用率可以使用以下两个方法。先取两个采样点，然后计算其差值：


1、先了解/proc/stat文件信息

    在Linux/Unix下，CPU利用率分为用户态，系统态和空闲态，分别表示CPU处于用户态执行的时间，系统内核执行的时间，和空闲系统进程执行的时间。平时所说的CPU利用率是指：CPU执行非系统空闲进程的时间 / CPU总的执行时间。

    此信息都存储在/proc/stat文件中，

    在Linux的内核中，有一个全局变量：Jiffies。 Jiffies代表时间。它的单位随硬件平台的不同而不同。系统里定义了一个常数HZ，代表每秒种最小时间间隔的数目。这样jiffies的单位就是1/HZ。Intel平台jiffies的单位是1/100秒，这就是系统所能分辨的最小时间间隔了。每个CPU时间片，Jiffies都要加1。 CPU的利用率就是用执行用户态+系统态的Jiffies除以总的Jifffies来表示。

    在Linux系统中，可以用/proc/stat文件来计算cpu的利用率。这个文件包含了所有CPU活动的信息，该文件中的所有值都是从系统启动开始累计到当前时刻。样例如下：

[root@bogon tmp]# cat /proc/stat 
cpu  2175 501 15724 1114163 7094 2153 1144 0
cpu0 2175 501 15724 1114163 7094 2153 1144 0
intr 11576005 11430258 11 0 3 3 0 5 0 1 0 0 0 107 0 0 111811 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5461 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 28345 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ctxt 530531
btime 1228361375
processes 6764
procs_running 1
procs_blocked 0

 

输出解释
CPU 以及CPU0、CPU1每行的每个参数意思（以第一行为例）为：

参数 解释
user (432661) 从系统启动开始累计到当前时刻，用户态的CPU时间（单位：jiffies） ，不包含 nice值为负进程。1jiffies=0.01秒
nice (13295) 从系统启动开始累计到当前时刻，nice值为负的进程所占用的CPU时间（单位：jiffies）
system (86656) 从系统启动开始累计到当前时刻，核心时间（单位：jiffies）
idle (422145968) 从系统启动开始累计到当前时刻，除硬盘IO等待时间以外其它等待时间（单位：jiffies）
iowait (171474) 从系统启动开始累计到当前时刻，硬盘IO等待时间（单位：jiffies） ，
irq (233) 从系统启动开始累计到当前时刻，硬中断时间（单位：jiffies）
softirq (5346) 从系统启动开始累计到当前时刻，软中断时间（单位：jiffies）

CPU时间=user+system+nice+idle+iowait+irq+softirq

“intr”这行给出中断的信息，第一个为自系统启动以来，发生的所有的中断的次数；然后每个数对应一个特定的中断自系统启动以来所发生的次数。
“ctxt”给出了自系统启动以来CPU发生的上下文交换的次数。
“btime”给出了从系统启动到现在为止的时间，单位为秒。
“processes (total_forks) 自系统启动以来所创建的任务的个数目。
“procs_running”：当前运行队列的任务的数目。
“procs_blocked”：当前被阻塞的任务的数目。

那么CPU利用率可以使用以下两个方法。先取两个采样点，然后计算其差值：

 

 


2、实例代码

#!/usr/bin/perl
use warnings;
 
#################################################
# 统计cpu使用率,每5秒统一次
# parameter : nothing
# return    : $SYS_USAGE   # 系统cpu总使用率
#################################################
sub GETCPUPERCENTER
{
  $SLEEPTIME=5;
   
  if (-e "/tmp/stat") {
    unlink "/tmp/stat";
  }
  open (JIFF_TMP, ">>/tmp/stat") || die "Can't open /proc/stat file!/t$!/n";
  open (JIFF, "/proc/stat") || die "Can't open /proc/stat file!/t$!/n";
  @jiff_0=<JIFF>;
  print JIFF_TMP $jiff_0[0] ;
  close (JIFF);
   
  sleep $SLEEPTIME;
   
  open (JIFF, "/proc/stat") || die "Can't open /proc/stat file!/t$!/n";
  @jiff_1=<JIFF>;
  print JIFF_TMP $jiff_1[0];
  close (JIFF);
  close (JIFF_TMP);
   
  @USER    = `awk '{print /$2}' "/tmp/stat"`;
  @NICE    = `awk '{print /$3}' "/tmp/stat"`;
  @SYSTEM  = `awk '{print /$4}' "/tmp/stat"`;
  @IDLE    = `awk '{print /$5}' "/tmp/stat"`;
  @IOWAIT  = `awk '{print /$6}' "/tmp/stat"`;
  @IRQ     = `awk '{print /$7}' "/tmp/stat"`;
  @SOFTIRQ = `awk '{print /$8}' "/tmp/stat"`;
   
  $JIFF_0=$USER[0]+$NICE[0]+$SYSTEM[0]+$IDLE[0]+$IOWAIT[0]+$IRQ[0]+$SOFTIRQ[0];
  $JIFF_1=$USER[1]+$NICE[1]+$SYSTEM[1]+$IDLE[1]+$IOWAIT[1]+$IRQ[1]+$SOFTIRQ[1];
   
  $SYS_IDLE=($IDLE[0]-$IDLE[1]) / ($JIFF_0-$JIFF_1) * 100;
  $SYS_USAGE=100 - $SYS_IDLE;
  return $SYS_USAGE;
}

my $cpu_used=GETCPUPERCENTER();

print " $cpu_used: $cpu_used /n";


#disk space < 2G, send a waring email to a server

 #!/usr/bin/perl -w
use LWP::Simple;
use Sys::Statistics::Linux;
use Sys::Statistics::Linux::DiskUsage;
use Sys::HostIP;

my $ip_address = Sys::HostIP->ip;

$Sys::Statistics::Linux::DiskUsage::DF_CMD = 'df -kP';
my $sys  = Sys::Statistics::Linux->new(diskusage=>1);
my $stat = $sys->get;

foreach my $disk ( $stat->diskusage ) { # Gimme the disk names

    
    foreach my $key ( sort $stat->diskusage($disk) ) { 
        my $number= 0;  #########定义一个整数变量
        $dsk = $stat->diskusage($disk, $key);

        if ( $key eq "free"  || $key eq "mountpoint")
        {
         $home = "$dsk";
     
          if ( $dsk =~ /[0-9]/ )
          {
             $number = "$dsk";
             $dskspace = $home;
           }

         if ($home !~ /[0-9]/ && $dskspace =~ /[0-9]/ && $dskspace < 1024000 )
         {
            $dskspace = $dskspace/1024;
            my $smsurl="URL+参数既下发内容";
            my $content=get $smsurl;
            die "Couldn't get $smsurl" unless defined $content;
         }
       }

    }
}

