CXX=../../../../build/bin/clang++ 
INC=/Applications/Xcode.app/Contents//Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/
x64:test.cpp config.json
	DECLANG_HOME=. $(CXX) -Os -mmacosx-version-min=10.14.6 -std=c++03 -I$(INC) -lc++ -lstdc++ -lSystem -g test.cpp -mllvm -antihack=./config.json -o test
x64_ir:test.cpp config.json
	DECLANG_HOME=. $(CXX) -Os -mmacosx-version-min=10.14.6 -std=c++03 -I$(INC) -lc++ -lstdc++ -lSystem test.cpp -mllvm -antihack=./config.json -emit-llvm -S -o test.ll
aarch64:test.cpp config.json
	DECLANG_HOME=. $(CXX) -std=c++03 -I$(INC) -c -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/10.0.0/lib/darwin/ -lclang_rt.ios -Os -arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk test.cpp -mllvm -antihack=./config.json -mllvm --loop-unswitch-threshold=1 -o test
aarch64_ir:test.cpp config.json
	DECLANG_HOME=. $(CXX) -std=c++03 -I$(INC) -c -L/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/10.0.0/lib/darwin/ -lclang_rt.ios -Os -arch arm64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk test.cpp -mllvm -antihack=./config.json -mllvm --loop-unswitch-threshold=1 -emit-llvm -S -o test.ll

config.json:config.pre.json
	mkdir -p ./.DeClang/
	../../config/gen_config_mac -path .

clean:
	rm -f *.o
	rm -f test
	rm -f test.ll
	rm -f config.json
	rm -rf *.dSYM
	rm -rf ./.DeClang/
