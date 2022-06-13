.PHONY: all

NAME := gen_config

ALL: $(NAME)_mac_intel $(NAME)_mac_applesilicon $(NAME)_linux $(NAME)_windows.exe

clean:
	rm -f $(NAME)_mac_intel
	rm -f $(NAME)_mac_applesilicon
	rm -f $(NAME)_windows.exe
	rm -f $(NAME)_linux
	rm -f $(NAME)_android
	rm -f config.json

SRCS := GenConfig.go

$(NAME)_mac_intel:
	GOOS=darwin GOARCH=amd64 go build -o $@ $(SRCS)
$(NAME)_mac_applesilicon:
	GOOS=darwin GOARCH=arm64 go build -o $@ $(SRCS)
$(NAME)_windows.exe:
	GOOS=windows GOARCH=386 go build -o $@ $(SRCS)
$(NAME)_linux:
	GOOS=linux GOARCH=amd64 go build -o $@ $(SRCS)
$(NAME)_android:
	GOOS=linux GOARCH=arm go build -o $@ $(SRCS)

