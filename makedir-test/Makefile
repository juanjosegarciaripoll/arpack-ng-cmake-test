prefix=../local

all: icb_arpack_c.log icb_arpack_cpp.log

icb_arpack_cpp.log: icb_arpack_c.exe
	LD_LIBRARY_PATH=$(prefix)/lib ./icb_arpack_c.exe 2>&1 >$@ || rm $@

icb_arpack_cpp.exe: icb_arpack_cpp.cpp Makefile
	$(CXX) -o $@ $< -I$(prefix)/include/arpack-ng -L$(prefix)/lib -larpack

icb_arpack_cpp.cpp: ../arpack-ng/TESTS/icb_arpack_cpp.cpp
	cp $< $@

icb_arpack_c.log: icb_arpack_c.exe
	LD_LIBRARY_PATH=$(prefix)/lib ./icb_arpack_c.exe 2>&1 >$@ || rm $@

icb_arpack_c.exe: icb_arpack_c.c Makefile
	$(CC) -o $@ $< -I$(prefix)/include/arpack-ng -L$(prefix)/lib -larpack

icb_arpack_c.c: ../arpack-ng/TESTS/icb_arpack_c.c
	cp $< $@

clean:
	rm -f *.exe *.log
