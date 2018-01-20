test: shiori_charset_convert.nim
	nim c -r shiori_charset_convert

doc/index.html: shiori_charset_convert.nim
	mkdir -p doc
	nim doc -o:doc/index.html shiori_charset_convert.nim

clean:
	rm -rf nimcache *.exe *.lib *.exp *.ilk *.pdb *.dll
