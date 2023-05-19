ASSEMBLER = ../lib/asar

%.sfc: %.asm
	$(ASSEMBLER) --symbols=wla --define CODE_FILE=$< runtime.asm $@

%.asm: %.rkt
	racket -t read-file.rkt -m $< > $@

clean:
	rm *.sfc *.sym
