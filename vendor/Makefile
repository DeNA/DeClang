.PHONY: install clean

all: sqlite-autoconf-3420000/sqlite3

install: bin/sqlite3

sqlite-autoconf-3420000.tar.gz:
	curl -OL https://www.sqlite.org/2023/sqlite-autoconf-3420000.tar.gz

sqlite-autoconf-3420000/sqlite3: sqlite-autoconf-3420000.tar.gz
	rm -rf sqlite-autoconf-3420000 && \
	tar xzvf $^ && \
	cd sqlite-autoconf-3420000 && \
	./configure --prefix=$(shell pwd) && \
	make

bin/sqlite3: sqlite-autoconf-3420000/sqlite3
	cd sqlite-autoconf-3420000 && \
	make install

clean:
	rm -rf sqlite-autoconf-3420000.tar.gz
	rm -rf sqlite-autoconf-3420000
	rm -rf include
	rm -rf lib
	rm -rf bin
	rm -rf share

