ASSEMBLER = ../lib/asar

%.sfc: %.asm
	$(ASSEMBLER) --symbols=wla --define CODE_FILE=$< runtime.asm $@

%.asm: %.snm
	racket -t read-file.rkt -m $< > $@

clean:
	rm *.sfc *.sym
