kame-mip6-implementation.txt: draft.txt
	cp -p draft.txt kame-mip6-implementation.txt

draft.txt: draft.ms fix.sh tmac.draft
	sh Make
	sh Make
	sh Make

clean:
	-rm -f draft.txt draft.toc draft.txt kame-mip6-implementation.txt
