draft-keiichi-mobileip-kame-implementation-00.txt: draft.txt
	cp -p draft.txt draft-keiichi-mobileip-kame-implementation-00.txt

draft.txt: draft.ms fix.sh tmac.draft
	sh Make
	sh Make
	sh Make

clean:
	-rm -f draft.txt draft.toc draft.txt draft-keiichi-mobileip-kame-implementation-00.txt *~
