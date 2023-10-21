CXX :=../../../../build/bin/clang++ 

all: mac mac.ll ios ios.ll

mac:test.cpp .DeClang/config.json
	DECLANG_HOME=. $(CXX) -w -Os -std=c++11 --sysroot=$$(xcrun --show-sdk-path) -o $@ test.cpp 

mac.ll:test.cpp .DeClang/config.json
	DECLANG_HOME=. $(CXX) -w -Os -std=c++11 --sysroot=$$(xcrun --show-sdk-path) -emit-llvm -S -o $@ test.cpp

ios:test.cpp .DeClang/config.json
	DECLANG_HOME=. $(CXX) -target arm64-apple-ios12.4 -w -Os -std=c++11 --sysroot=$$(xcrun --sdk iphoneos --show-sdk-path) -o $@ test.cpp

ios.ll:test.cpp .DeClang/config.json
	DECLANG_HOME=. $(CXX) -w -Os -std=c++11 --sysroot=$$(xcrun --sdk iphoneos --show-sdk-path) -emit-llvm -S -o $@ test.cpp

.DeClang/config.json: config.pre.json
	mkdir -p ./.DeClang/
	cp config.pre.json ./.DeClang
	mkdir -p ./.DeClang/gen_config/bin/macOS/Intel
	mkdir -p ./.DeClang/gen_config/bin/macOS/AppleSilicon
	mkdir -p ./.DeClang/gen_config/bin/Windows
	mkdir -p ./.DeClang/gen_config/bin/Linux
	cp -v ../../../tools/config/gen_config_mac_intel ./.DeClang/gen_config/bin/macOS/Intel/gen_config
	cp -v ../../../tools/config/gen_config_mac_applesilicon ./.DeClang/gen_config/bin/macOS/AppleSilicon/gen_config
	cp -v ../../../tools/config/gen_config_linux ./.DeClang/gen_config/bin/Linux/gen_config
	cp -v ../../../tools/config/gen_config_windows.exe ./.DeClang/gen_config/bin/Windows/gen_config.exe
	cp -v ../../../tools/config/gen_config.sh ./.DeClang/gen_config.sh
	DECLANG_HOME=. .DeClang/gen_config.sh

clean:
	rm -f mac
	rm -f mac.ll
	rm -f ios
	rm -f ios.ll
	rm -rf ./.DeClang/
