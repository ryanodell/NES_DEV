ASM_FILES := src/reset.asm src/controllers.asm src/backgrounds.asm src/hello_world.asm

OBJ_DIR := bin/obj
OUTPUT_DIR := bin

# Convert .asm files to .o files
OBJ_FILES := $(patsubst src/%.asm, $(OBJ_DIR)/%.o, $(ASM_FILES))

# Name of the output NES file
OUTPUT_NES := $(OUTPUT_DIR)/output.nes

$(shell mkdir -p $(OBJ_DIR) $(OUTPUT_DIR))

# Rule to generate .o files from .asm files
$(OBJ_DIR)/%.o: src/%.asm
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
