#!/usr/bin/perl  
 
#use diagnostics; 
my $a2l = "/home/yk/work/ut6410-android2.1-v2.0/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-addr2line";
my $SoBase = "/home/yk/work/ut6410-android2.1-v2.0s/out/target/product/ut6410/symbols/system/lib/";
my $ext = "so";
my $fnasm = "<" . "callg.total";     
print $fnasm; 
open(fasm, $fnasm) or die "open file fail $! $fnasm \n" ;
my $linecount = 0;
my $curr_fun = ""; 
my $curr_so = "";
my %Map = {}; 
my %Rmap = {};
while(my $line=<fasm>)
{
#if(index($line, "PVMFMP4FFParserNode::playResumeNotification(bool)") >= 0)
#{
#  print $line;
#}

  chomp($line);
  $linecount = $linecount + 1; 
  if($line =~ /(.+\.${ext})/) 
  {
    $curr_so = $1; 
    $map{$curr_so} = {};
  }
  elsif($line =~ /^\[[0-9a-z]+\]\!{1}(.*)/)
  {
  }
  elsif($line =~ /^\[([0-9a-z]+)\]\!{0}(.*)/)
  {  
    #s/!//;
    $curr_fun = $2;
    ${$Map{$curr_so}}{$curr_fun} = (); 
    $Rmap{$curr_fun}{".so"} = $curr_so;
    $Rmap{$2}{".addr"} = $1; 
  }
  elsif($line =~ /\t->\!*(.*)/)
  {
    my $T = $1;
    push @{${Map{$curr_so}{$curr_fun}}}, $T;
    $Rmap{$T}{".so"} = $curr_so;
    if(!($Rmap{$T}{".par"}))
    {
      ${$Rmap{$T}}{".par"} = ();  
    }
    push @{$Rmap{$T}{".par"}}, $curr_fun;
  } 
}
close(fasm);
  

print "\n======================Loaded====================================\n"; 
print "输入函数名，或 q 退出\n"; 
my $flag = "";
my $input = ""; 
my @T = ();
while($_ = <>)
{
  chomp($_); 
  exit if $_ eq "q";
  
  if($flag eq "check")
  {
          if($_ =~ /^-(\d)$/)
	  {
	     $_ = @{$Rmap{$curr_fun}{".par"}}[$1]; 
	  }
	  if($_ =~ /^(\d)$/)
	  {
	     $_ = @{$Map{$curr_so}{$curr_fun}}[$1]; 
	  } 
          $flag = "";
  }

  if($flag eq "")
  {
          @T = ();
          my $tfun = $_;
	  my $count = 0;
	  while(($k, $v) = each(%Rmap))
	  {
	    if(index(lc($k), lc($_)) >= 0)
            {
              push @T, $k;
              #print "$count:", $Rmap{$k}{".addr"}, "\t$k  \n";
              print "$count:",  "\t$k  \n";  
              $count++;
            } 
	  } 
	  $len = scalar @T;
	  $input = 0;
	  if($len == 0)
	  {
	    print "啥都没找着啊，再次输入或者 q 退出\n";
	    next;
	  }
	  if($len > 1)
	  {
	    print "发现 $len 个函数, 输入编号选择一个, 或 r 重新输入函数名, 或 q 退出\n";
	    $input = <>;  
            chomp($input);
	    exit if($input eq "q");
	    if($input eq "r")
	    {
	      print "输入函数名，或 q 退出\n"; 
	      next;
	    }
	  }
	  $curr_fun = $T[$input];
          $curr_so = ${Rmap{$curr_fun}{".so"}};
	  print $curr_fun, "\n";
         
	  print "\t模块: ", $curr_so, "\n";
          $fso = $SoBase . $curr_so;
          print "\t源文件: " ,`$a2l -e $fso ${Rmap{$curr_fun}{".addr"}}`;
	  print "\t被如下函数调用:\n";
	  my $pidx = 0;
	  my $sidx = 0;
	  foreach $item (@{$Rmap{$curr_fun}{".par"}})
	  { 
	    print "\t\t-$pidx:\t$item\n";
	    $pidx++;
	  }
	  print "\t可能调用:\n";
	  foreach $item (@{$Map{$curr_so}{$curr_fun}})
	  { 
	    print "\t\t$sidx:\t$item\n";
	    $sidx++;
	  }	
          print "输入函数名，或索引编号查看上下级函数， 或 q 退出\n";
          $flag = "check"

  }  
}

 
__END__  
