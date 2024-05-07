ASM_FILES := src/init.asm src/main.asm

OBJ_DIR := bin/obj
OUTPUT_DIR := bin

# Convert .asm files to .o files
OBJ_FILES := $(patsubst src/%.asm, $(OBJ_DIR)/%.o, $(ASM_FILES))
LST_FILES := $(patsubst src/%.asm, $(OBJ_DIR)/%.lst, $(ASM_FILES))

# Name of the output NES file
OUTPUT_NES := $(OUTPUT_DIR)/output.nes

$(shell mkdir -p $(OBJ_DIR) $(OUTPUT_DIR))

# Rule to generate .o files from .asm files
$(OBJ_DIR)/%.o: src/%.asm
	@echo "Assembling $<..."
	@ca65 -t nes -g -l $(patsubst %.o, %.lst, $@) $< -o $@

# Rule to link .o files into a .nes file
$(OUTPUT_NES): $(OBJ_FILES)
	@echo "Linking $@..."
	@ld65 --dbgfile $(OUTPUT_DIR)/output.dbg -o $@ -C nes.cfg $(OBJ_FILES)

# Rule to build all
all: $(OUTPUT_NES)

# Clean rule
clean:
	@echo "Cleaning up..."
	@rm -f $(OBJ_FILES) $(LST_FILES) $(OUTPUT_NES) $(OUTPUT_DIR)/output.dbg

.PHONY: all clean
