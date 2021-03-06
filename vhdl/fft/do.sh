#!/bin/bash -


for last in $@; do :; done
tbfile=$(basename "$last" .vhdl)

ghdl -s $@
if  [ $? != 0 ]
then
echo "Syntax-Check Failed"
exit
else
echo "Syntax-Check OK"
fi
ghdl -a $@
if [ $? != 0 ]
then
echo "Analysis Failed"
exit
else
echo "Analysis OK"
fi
ghdl -e $tbfile
if [ $? != 0 ]
then
echo "Build Failed"
exit
else
echo "Build OK"
fi
ghdl -r $tbfile --vcd=testbench.vcd
if [ $? != 0 ];
then
echo "Run Failed"
exit
else
echo "Run OK"
fi
echo "Starting GTKWave"
gtkwave testbench.vcd
