scmake = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

llvm ?= https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.0-rc2/LLVM-19.1.0-rc2-macOS-ARM64.tar.xz
xwin ?= https://github.com/Jake-Shadle/xwin/releases/download/0.6.5/xwin-0.6.5-aarch64-apple-darwin.tar.gz
sc ?= https://download2.sierrachart.com//downloads/ZipFiles/SierraChart2600.zip

destdir ?= ~/.wine/drive_c/SierraChart/Data/ /Volumes/[C]%Windows%11/SierraChart/Data/
host ?= localhost windows-11

CXX = $(scmake)llvm/bin/clang++
CXXFLAGS += -target $(arch)-pc-windows-msvc -O3 -shared -fuse-ld=lld
CXXFLAGS += -Weverything -Wno-missing-prototypes
CXXFLAGS += $(addprefix -isystem, $(header))
LDFLAGS += $(addprefix -L, $(addsuffix /$(arch), $(library)))
LDLIBS += -lgdi32

header += $(scmake)xwin/splat/crt/include
header += $(shell find $(scmake)xwin/splat/sdk/include -maxdepth 1 -type d)
header += $(scmake)sc/ACS_Source
library += $(scmake)xwin/splat/crt/lib
library += $(shell find $(scmake)xwin/splat/sdk/lib -maxdepth 1 -type d)

src = $(wildcard *.cpp)
aarch64 = $(src:.cpp=_arm64.dll)
x86_64 = $(src:.cpp=_64.dll)

default: dependency aarch64 x86_64

aarch64: arch = aarch64
aarch64: $(aarch64)
%_arm64.dll: %.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	rm $*_arm64.lib

x86_64: arch = x86_64
x86_64: $(x86_64)
%_64.dll: %.cpp
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	rm $*_64.lib

clean:
	rm -f $(aarch64) $(aarch64:.dll=.lib) $(aarch64:.dll=.pdb) $(x86_64) $(x86_64:.dll=.lib) $(x86_64:.dll=.pdb)

install: $(aarch64) $(x86_64)
	$(foreach dir, $(destdir), $(foreach dll, $^, cp $(dll) $(subst %,\ , $(dir));))

uninstall: unload
	$(foreach dir, $(destdir), cd $(subst %,\ ,$(dir)) && rm -f $(aarch64) $(x86_64);)

unload:
	$(foreach h, $(host), scdll -a $(h) unload;)

load:
	$(foreach h, $(host), scdll -a $(h) load;)

reload: unload install load

dependency: $(scmake)llvm $(scmake)xwin $(scmake)sc

$(scmake)llvm:
	curl -Ls $(llvm) > $@.tar.xz
	mkdir $@
	tar -xf $@.tar.xz -C $@ --strip-components=1
	rm $@.tar.xz

$(scmake)xwin:
	curl -Ls $(xwin) > $@.tar.gz
	mkdir $@
	tar -zxf $@.tar.gz -C $@ --strip-components=1
	rm $@.tar.gz
	$@/xwin --accept-license --arch aarch64,x86_64 --cache-dir $@ --sdk-version 10.0.22621 splat --disable-symlinks --include-debug-libs --include-debug-symbols

$(scmake)sc:
	curl -Ls $(sc) > $@.zip
	mkdir $@
	unzip -q $@.zip -d $@
	rm $@.zip

purge:
	rm -rf $(scmake)llvm $(scmake)xwin $(scmake)sc $(scmake)llvm.tar.xz $(scmake)xwin.tar.gz $(scmake)sc.zip

.PHONY: default aarch64 x86_64 clean install uninstall unload load reload dependency purge
