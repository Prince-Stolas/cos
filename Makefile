default:
	nasm -fbin src/bootloader.s -o build/bin/bootloader.bin
	nasm -fbin src/kernel.s -o build/bin/kernel.bin
	nasm -fbin src/storage.s -o build/bin/storage.bin
	cat build/bin/bootloader.bin build/bin/kernel.bin build/bin/storage.bin > build/os.bin
