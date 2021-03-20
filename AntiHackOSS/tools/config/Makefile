.PHONY: all

NAME := gen_config

ALL: $(NAME)_mac $(NAME)_linux $(NAME)_windows.exe

clean:
	rm -f $(NAME)_mac
	rm -f $(NAME)_windows.exe
	rm -f $(NAME)_linux
	rm -f $(NAME)_android
	rm -f config.json

SRCS := GenConfig.go

$(NAME)_mac: $(SRCS)
	GOOS=darwin GOARCH=amd64 go build -o $@ 
$(NAME)_windows.exe: $(SRCS)
	GOOS=windows GOARCH=386 go build -o $@
$(NAME)_linux: $(SRCS)
	GOOS=linux GOARCH=amd64 go build -o $@
$(NAME)_android: $(SRCS)
	GOOS=linux GOARCH=arm go build -o $@

