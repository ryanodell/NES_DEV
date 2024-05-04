ASM_FILES := src/reset.asm src/controllers.asm src/backgrounds.asm src/hello_world.asm

# Convert .asm files to .o files
OBJ_FILES := $(ASM_FILES:.asm=.o)

# Name of the output NES file
OUTPUT_NES := output.nes

# Rule to generate .o files from .asm files
%.o: %.asm
	@echo "Assembling $<..."
	@ca65 $< -o $@

# Rule to link .o files into a .nes file
$(OUTPUT_NES): $(OBJ_FILES)
	@echo "Linking $@..."
	@ld65 -o $@ -C nes.cfg $(OBJ_FILES)

# Rule to build all
all: $(OUTPUT_NES)

# Clean rule
clean:
	@echo "Cleaning up..."
	@rm -f $(OBJ_FILES) $(OUTPUT_NES)

.PHONY: all clean
