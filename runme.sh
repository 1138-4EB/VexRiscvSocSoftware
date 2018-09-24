#!/bin/sh

set -e

cd $(dirname $0)
rootDir=$(pwd)

cd soft/murax/demo/
make clean all

cd "$rootDir/VexRiscv"
sbt "run-main vexriscv.demo.MuraxWithRamInit"
cp Murax.vhd ../vhdl/srcs/

cd ../vhdl/test/py
python3 sim.py -v
#python3 sim.py -v -g --gtkwave-fmt=vcd

exit 0

mkdir -p bin

#echo "|> Build 'buffer_main'"
#gcc app/main.c -o bin/buffer_main

mkdir -p obj
cd obj

ghdl_args="--std=08 -fPIC"

ghdl -a $ghdl_args ../vhdl/srcs/Murax.vhd
ghdl -a $ghdl_args ../vhdl/test/c/tb_c_murax.vhd
ghdl -e $ghdl_args tb_murax

set +e

#./tb_murax --wave=murax.ghw
./tb_murax --vcd=murax.vcd

set -e

#gtkwave murax.ghw ../murax.gtkw
gtkwave murax.vcd ../murax.gtkw

#ghdl_args="--std=08 -fPIC -P../vhdl/test/py/vunit_out/ghdl/libraries/vunit_lib"
#
#echo "|> Analyze VHDL sources"
#for f in srcs/fifo srcs/axis_buffer test/c/pkg_c test/c/tb_c_axisbuffer; do
#  ghdl -a $ghdl_args "../vhdl/$f.vhdl"
#done
#
#echo "|> Bind simulation unit"
#ghdl --bind $ghdl_args test_buffer
#
#echo "|> Build wrapper for 'buffer_ghdl'"
#gcc -fPIC -c ../vhdl/test/c/wrapper.c -o wrapper.o
#
#echo "|> Build 'buffer_ghdl'"
#gcc -DGHDL ../app/main.c -o ../bin/buffer_ghdl -Wl,wrapper.o -Wl,`ghdl --list-link test_buffer`

cd ..

#echo "|> Run 'buffer_main' (raw)..."
#./bin/buffer_main
#
#echo "|> Run 'buffer_ghdl' (raw)..."
#./bin/buffer_ghdl
