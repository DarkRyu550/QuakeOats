CXX=clang++
CXXFLAGS=-std=c++2a -stdlib=libc++ -fimplicit-modules -fimplicit-module-maps \
	-fprebuilt-module-path=src/ -Wall -Wextra -pedantic   \
   	-O2 -g -DGLM_SWIZZLE

LD=clang++
LFLAGS=-O2 -g

LIBS=`pkg-config --libs sfml-all` -lpthread -lc++
OBJS=src/main.o src/game.pcm src/map.pcm src/gfx.pcm src/str.pcm
ASST=assets/cube.map assets/map0.map

QuakeOats: Makefile $(OBJS) $(ASST)
	$(LD) $(LFLAGS) -o $@ $(OBJS) $(LIBS)
src/main.o: src/main.cc src/game.pcm src/map.pcm src/gfx.pcm src/str.pcm
	$(CXX) $(CXXFLAGS) -c -o $@ $<
src/game.pcm: src/game.cc src/map.pcm src/gfx.pcm
	$(CXX) $(CXXFLAGS) -c $< -Xclang -emit-module-interface -o $@
src/map.pcm: src/map.cc src/gfx.pcm
	$(CXX) $(CXXFLAGS) -c $< -Xclang -emit-module-interface -o $@
src/gfx.pcm: src/gfx.cc src/str.pcm
	$(CXX) $(CXXFLAGS) -c $< -Xclang -emit-module-interface -o $@
src/str.pcm: src/str.cc
	$(CXX) $(CXXFLAGS) -c $< -Xclang -emit-module-interface -o $@

# Asset generation functions
assets/cube.map: assets/cube.json tools/map assets/grass.png assets/cube.obj assets/cube.mtl
	tools/map $< || { rm -rf $@; exit 1; }
assets/map0.map: assets/map0.json tools/map assets/arena.png assets/arena.obj assets/arena.mtl
	tools/map $< || { rm -rf $@; exit 1; }

.PHONY: clean all docker
clean:
	rm -rf QuakeOats $(ASST)
	find src/    -type f -name "*.o"   -exec rm -rf {} \+
	find src/    -type f -name "*.pcm" -exec rm -rf {} \+
all: QuakeOats

docker: clean
	docker build --no-cache -t quakeoats .
