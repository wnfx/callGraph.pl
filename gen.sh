#!/bin/bash  
declare objd="/home/yk/work/ut6410-android2.1-v2.0/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-objdump" 
declare SoBase="/home/yk/work/ut6410-android2.1-v2.0s/out/target/product/ut6410/symbols/system/lib/" 
declare readelf="/home/yk/work/ut6410-android2.1-v2.0/prebuilt/linux-x86/toolchain/arm-eabi-4.4.0/bin/arm-eabi-readelf" 
for f in `ls $SoBase `
do 
  echo "disassembling $f and dumping rel information"
  $objd -d $SoBase$f > asm.tmp #-d disassemble
  $readelf -r -W $SoBase$f > elf.tmp # -r 
  echo "parsing ................ "
  
  ./cg.pl asm.tmp  $f elf.tmp | tee -a callg.total 
done
