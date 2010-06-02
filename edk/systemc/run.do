do system_setup.do

#rm -fr work/_sc/linux_gcc-4.1.2

sccom -ggdb ../../systemc/lldma.cpp
sccom -link
#sccom ../../systemc/*.o -link

c
s
w

do ../../systemc/wave.do

run 10us
