DESTDIR=/opt/neuralview

.PHONY: reference
reference:
	mkdir -p docs/reference
	luadoc --nofiles -i docs/indexr.html \
		view/*.lua core/*.lua *.lua addons/*.lua -d docs/reference

.PHONY: prepare
prepare: clean reference
	po/makepo.lua update all
	
.PHONY: install
install:
	mkdir -p $(DESTDIR)
	cp -r docs view core addons examples po $(DESTDIR)
	cp MainApp.lua Config.lua Globals.lua readme.md logo.png COPYING neuralview Makefile neuralview.desktop $(DESTDIR)
	chmod +x $(DESTDIR)/MainApp.lua
	chmod +x $(DESTDIR)/neuralview

.PHONY: clean
clean:
	lua po/makepo.lua clean all
	rm -rf docs/reference
