#!/bin/sh

#clear past stuff
rm -f bin/*

#compile assembly
cd src
cd boot
echo "ASSEMBLY :: Bootloader"
nasm -O0 -fbin -Wall bootloader.asm -o ../../bin/bootloader.boot
cd ..
cd kernel
echo "ASSEMBLY :: Kernel"
nasm -O0 -fbin -Wall kernel.asm -o ../../bin/kernel.sys
cd ..
cd ..

for i in src/programs/*.asm
do
	echo "ASSEMBLY :: $i"
	nasm -O0 -fbin -Isrc/common -Wall $i -o bin/`basename $i .asm`.prg || exit
done

for i in src/common/*.asm
do
	echo "ASSEMBLY :: $i"
	nasm -O0 -fbin -Isrc/common -Wall $i -o bin/`basename $i .asm`.lib || exit
done

if [ ! -e disk/ldos.flp ]
then
	mkdosfs -C disk/ldos.flp 1440 || exit
fi

#use dd to paste bootloader into disk
dd conv=notrunc if=bin/bootloader.boot of=disk/ldos.flp || exit

rm -rf tmp-loop
mkdir tmp-loop && mount -o loop -t vfat disk/ldos.flp tmp-loop

#do not put bootloader in floppy image (double boot??? what?)
rm -f bin/bootloader.boot
for i in bin/*
do
	echo "COPYING :: $i"
	cp $i tmp-loop || exit
done
for i in src/programs/*.lss
do
	echo "COPYING :: $i"
	cp $i tmp-loop || exit
done
sleep 0.2
umount tmp-loop || exit

rm -rf tmp-loop

echo ":: End"
