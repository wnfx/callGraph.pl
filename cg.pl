#!/usr/bin/perl  
 
#use diagnostics;
 
my $fnasm = "asm.opencore.player";   
my $soname = "foo.so"; 
if(@ARGV[0])
{ 
   $fnasm = @ARGV[0]; 
}
if(@ARGV[1])
{ 
   $soname = @ARGV[1]; 
}
print $soname;

exit if(index(lc($soname), "webcore") >= 0);
$fnasm = "<" . $fnasm;
print "\n\n";

my $base = "/home/yk/work/ut6410-android2.1-v2.0/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-";
 
my $flt = $base . "c++filt"; 


my %relMap = {};
if(@ARGV[2])
{#readelf 
  
  open(fasm, @ARGV[2]) or die "open file fail $! readelf  \n" ;  
  while(my $line= <fasm>)
  {  
    #0000936c  00000616 R_ARM_JUMP_SLOT        00000000   _ZN7android22MediaMetadataRetriever15extractAlbumArtEv
    if($line =~ /^([0-9a-z]{8}).*R_ARM_JUMP_SLOT.*(\b[_0-9a-zA-Z]+)$/)
    {
      $t = `$flt $2`;
      chomp($t);
      $relMap{hex($1)} = $t;
      #print "$1 $2 ",  `$flt $2`;
    }
  }
  close(fasm);
}
 
open(fasm, $fnasm) or die "open file fail $! $fnasm \n" ;
my $linecount = 0;
my $current_fun = "";
my %map = {}; 
my %AddrMap = {};

#for plt
my $inplt = 0;
my $lineidx = 0;
my $at1 = "";
my $at2 = "";
my %relAddrMap = {};
#end
my $intext = 0;
 
while(my $line=<fasm>)
{
  chomp($line);
  $linecount = $linecount + 1;
   
  my $call_count = 0;
   
  if(index($line, "Disassembly of section") >= 0)
  {
     if(index($line, "Disassembly of section .plt:") >= 0)
     {
       $inplt = 1;
     }
     else
     {
       $inplt = 0; 
     }
     if(index($line, "Disassembly of section .text:") >= 0)  
     {
       $intext = 1;
     }
     else
     {
       $intext = 0; 
     } 
  }
  next unless ($intext || $inplt);

  if($inplt)
  {
#    39c8:	e28fc600 	add	ip, pc, #0	; 0x0
#    39cc:	e28cca05 	add	ip, ip, #20480	; 0x5000
#    39d0:	e5bcfb0c 	ldr	pc, [ip, #2828]!
     if(index($line, "add	ip, ip") >= 0)
     {
         $line =~ /([0-9a-f]+):.*#([0-9]+).*/;
         $at1 = $1;
         $at2 = $2;
     }
     elsif($line =~ /\[ip, #([0-9]+)\]\!/)
     {
         #print $at1, "\t$at2\t$1\n"; 
         $relAddrMap{hex($at1) - 4} = hex($at1) -4 + $at2 + $1 + 8;
     }
  }
  elsif($line =~ /^([0-9a-f]{8}).*<([_0-9a-zA-Z]*)>/) #函数 /^0.*<(_.*)[\-|\+]?.*>/
  {
    my $addr = $1;
    my $ret = `$flt $2`;
    chomp($ret); 
    $externalcall = 0;
    if(index($ret, "non-virtual thunk to ") >= 0) 
    { 
      $externalcall = 1;
      $ret =~ s/non-virtual thunk to //;
    } 
    elsif(index($ret,"virtual thunk to ") >= 0)
    { 
      $externalcall = 1;
      $ret =~ s/virtual thunk to //;
    } 
    if($externalcall)
    {
       $ret = "!" . $ret;
    }
    my $matched = $ret;
     
    if($current_fun ne $ret)
    {
      #push @arr, $current_fun;
      $map{$ret} = () if($ret ne "");#$callcount;
      $AddrMap{$ret} = $addr if($ret ne "");
    }
    $current_fun = $ret;
    $callcount = 0;
  }
  elsif($line =~ /([0-9a-f]+) <([_0-9a-zA-Z]+)\-.*>/) # to .plt section
  {
#    4194:	f7ff ea8c 	blx	36b0 <_ZN7_JNIEnv15DeleteGlobalRefEP8_jobject-0x3a8>
#     print "found rel.plt $1\n";
#     print $relAddrMap{hex($1)};
#     print $relMap{$relAddrMap{hex($1)}};
       $ret = $relMap{$relAddrMap{hex($1)}};
       my $matched = $ret;
       $callcount = $callcount + 1;  
       $flag = 0;
       foreach $tv (@{$map{$current_fun}})
       {
         if($tv eq $matched)
         {
           $flag = 1;
         }
       }  
       $flag = 1 if($current_fun eq ""); #there is no parent function       
       if($flag < 1)
       { 
         push @{$map{$current_fun}}, $matched;  
       } 
  }
  elsif($line =~ /<([_0-9a-zA-Z]+)[\+]*.*>/) # /<([0-9a-z]+)\b([_0-9a-zA-Z]+).*>/)  no asm code for external function
  { #print $1;
    my $ret = `$flt $1`;
    chomp($ret);

    $externalcall = 0;
    if(index($ret, "non-virtual thunk to ") >= 0) 
    { 
      $externalcall = 1;
      $ret =~ s/non-virtual thunk to //;
    } 
    elsif(index($ret,"virtual thunk to ") >= 0)
    { 
      $externalcall = 1;
      $ret =~ s/virtual thunk to //;
    } 
    if($externalcall)
    {
       $ret = "!" . $ret;
    }

    my $matched = $ret;
 
    if($matched ne $current_fun)
    { 
       $callcount = $callcount + 1;  
       $flag = 0;
       foreach $tv (@{$map{$current_fun}})
       {
         if($tv eq $matched)
         {
           $flag = 1;
         }
       }  
       $flag = 1 if($current_fun eq ""); #there is no parent function       
       if($flag < 1)
       { 
         push @{$map{$current_fun}}, $matched;  
       } 
    }
  }
  
}
#print "\ndumping====================================\n";
 

while(($key, @val) = each(%map))
{
  print  "[$AddrMap{$key}]$key" , "\n" ;
  foreach $tt (@{$map{$key}})#(@map{"e"})
  {
    #print join(",",  @$map{"e"}) , "\n";
    print "\t->" , $tt , "\n";
  }
}
 
close(fasm);

print "****************************\n";

 
__END__
  
