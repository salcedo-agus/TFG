# ─────────────────────────────────────────────────────────────────────────────
# Rocket Staging - Makefile
# Targets:
#   make all       - compile Fortran and build the shared library
#   make fortran   - compile and run the Fortran standalone executable
#   make gui       - build the shared library and launch the Python GUI
#   make clean     - remove all compiled artefacts
# ─────────────────────────────────────────────────────────────────────────────

# -- Compiler ------------------------------------------------------------------
FC      := gfortran
FFLAGS  := -O2 -Wall

# -- Folder layout -------------------------------------------------------------
BUILD_DIR          := ../build
INOUT_DIR          := inout
STAGING_DIR        := staging
INTERFACE_DIR      := interface
GUI_DIR            := gui
PRE_STAGING_DIR    := pre-staging-calcs
PRE_SIMULATION_DIR := pre-simulation-calcs

# -- Object files (compiled individually in dependency order) -----------------
OBJS := \
    $(BUILD_DIR)/Rocket_Types.o   \
    $(BUILD_DIR)/Typical_Data.o   \
    $(BUILD_DIR)/Staging.o        \
    $(BUILD_DIR)/Root_Finding.o     \
    $(BUILD_DIR)/Payload_Mass_calc.o \
    $(BUILD_DIR)/Stage_Optimization_Loop.o \
    $(BUILD_DIR)/C_Interface.o    \
    $(BUILD_DIR)/Orbit_calc.o     \
    $(BUILD_DIR)/Thrust_calc.o        
    
# -- Module search/output flags -----------------------------------------------
MODFLAGS := -J$(BUILD_DIR) -I$(BUILD_DIR)

# -- Main program object -------------------------------------------------------
MAIN_OBJ := $(BUILD_DIR)/main.o

# -- Platform detection --------------------------------------------------------
ifeq ($(OS), Windows_NT)
    PLATFORM     := windows
    LIB          := $(BUILD_DIR)/librocket.dll
    EXE          := $(BUILD_DIR)/rocket.exe
    SHARED_FLAGS := -shared -m64
    PYTHON       := python
    MKDIR        := mkdir
    RM           := del /Q
    RMDIR        := rmdir /Q /S
    MINGW_BIN    := C:/TDM-GCC-64/bin
    RUNTIME_DLLS := \
        $(MINGW_BIN)/libgfortran_64-5.dll \
        $(MINGW_BIN)/libgcc_s_seh_64-1.dll \
        $(MINGW_BIN)/libquadmath_64-0.dll  \
        $(MINGW_BIN)/libwinpthread_64-1.dll
else
    UNAME := $(shell uname -s)
    ifeq ($(UNAME), Darwin)
        PLATFORM     := macos
        LIB          := $(BUILD_DIR)/librocket.dylib
        EXE          := $(BUILD_DIR)/rocket
        SHARED_FLAGS := -shared -fPIC
        PYTHON       := python3
        MKDIR        := mkdir -p
        RM           := rm -f
        RMDIR        := rm -rf
        RUNTIME_DLLS :=
    else
        PLATFORM     := linux
        LIB          := $(BUILD_DIR)/librocket.so
        EXE          := $(BUILD_DIR)/rocket
        SHARED_FLAGS := -shared -fPIC
        PYTHON       := python3
        MKDIR        := mkdir -p
        RM           := rm -f
        RMDIR        := rm -rf
        RUNTIME_DLLS :=
    endif
endif

# ─────────────────────────────────────────────────────────────────────────────
# Default target
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: all
all: $(BUILD_DIR) $(LIB)
	@echo ""
	@echo "  Build complete - $(LIB) is ready."
	@echo "  Run 'make fortran' to execute the Fortran program."
	@echo "  Run 'make gui'     to launch the Python GUI."
	@echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Create build directory
# ─────────────────────────────────────────────────────────────────────────────
$(BUILD_DIR):
ifeq ($(PLATFORM), windows)
	if not exist "$(BUILD_DIR)" $(MKDIR) "$(BUILD_DIR)"
else
	$(MKDIR) $(BUILD_DIR)
endif

# ─────────────────────────────────────────────────────────────────────────────
# Compile each source file individually (guaranteed dependency order)
# ─────────────────────────────────────────────────────────────────────────────

# 1. Rocket_Types — no dependencies
$(BUILD_DIR)/Rocket_Types.o: $(STAGING_DIR)/Rocket_Types.f90 | $(BUILD_DIR)
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 2. Typical_Data — depends on Rocket_Types (data_entry subroutine uses rocket_types)
$(BUILD_DIR)/Typical_Data.o: $(INOUT_DIR)/Typical_Data.f90 \
    $(BUILD_DIR)/Rocket_Types.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 3. Root_Finding.f90 — depends on Rocket_Types, Typical_Data and Staging
$(BUILD_DIR)/Root_Finding.o: $(STAGING_DIR)/Root_Finding.f90 \
    $(BUILD_DIR)/Typical_Data.o $(BUILD_DIR)/Rocket_Types.o $(BUILD_DIR)/Staging.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 4. Staging — depends on Typical_Data, Rocket_Types and Root_Finding
$(BUILD_DIR)/Staging.o: $(STAGING_DIR)/Staging.f90 \
    $(BUILD_DIR)/Typical_Data.o $(BUILD_DIR)/Rocket_Types.o $(BUILD_DIR)/Root_Finding.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 5. C_Interface — depends on Typical_Data and Rocket_Types
$(BUILD_DIR)/C_Interface.o: $(INTERFACE_DIR)/C_Interface.f90 \
    $(BUILD_DIR)/Typical_Data.o $(BUILD_DIR)/Rocket_Types.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 6. Stage_Optimization_Loop.f90 — depends on Typical_Data and Rocket_Types
$(BUILD_DIR)/Stage_Optimization_Loop.o: $(STAGING_DIR)/Stage_Optimization_Loop.f90 \
    $(BUILD_DIR)/Typical_Data.o $(BUILD_DIR)/Rocket_Types.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 7. Orbit_calc.f90 — depends on Typical_Data
$(BUILD_DIR)/Orbit_calc.o: $(PRE_STAGING_DIR)/Orbit_calc.f90 \
    $(BUILD_DIR)/Typical_Data.o 
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 8. Payload_Mass_calc.f90 — depends on Typical_Data and Rocket_Types
$(BUILD_DIR)/Payload_Mass_calc.o: $(PRE_STAGING_DIR)/Payload_Mass_calc.f90 \
    $(BUILD_DIR)/Typical_Data.o $(BUILD_DIR)/Rocket_Types.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 9. Thrust_calc.f90 — depends on Typical_Data and Rocket_Types
$(BUILD_DIR)/Thrust_calc.o: $(PRE_SIMULATION_DIR)/Thrust_calc.f90 \
    $(BUILD_DIR)/Typical_Data.o $(BUILD_DIR)/Rocket_Types.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# 10. main — depends on Rocket_Types and Typical_Data
$(BUILD_DIR)/main.o: main.f90 \
    $(BUILD_DIR)/Typical_Data.o $(BUILD_DIR)/Rocket_Types.o
	$(FC) $(FFLAGS) $(MODFLAGS) -c $< -o $@

# ─────────────────────────────────────────────────────────────────────────────
# Link shared library
# ─────────────────────────────────────────────────────────────────────────────
$(LIB): $(OBJS)
	@echo "[$(PLATFORM)] Linking shared library: $(LIB)"
	$(FC) $(FFLAGS) $(SHARED_FLAGS) -o $(LIB) $(OBJS)
ifeq ($(PLATFORM), windows)
	@echo "[windows] Copying MinGW runtime DLLs into $(BUILD_DIR)..."
	-@if exist "$(MINGW_BIN)\libgfortran_64-5.dll"  copy /Y "$(MINGW_BIN)\libgfortran_64-5.dll"  "$(BUILD_DIR)\" > nul
	-@if exist "$(MINGW_BIN)\libgcc_s_seh_64-1.dll" copy /Y "$(MINGW_BIN)\libgcc_s_seh_64-1.dll" "$(BUILD_DIR)\" > nul
	-@if exist "$(MINGW_BIN)\libquadmath_64-0.dll"  copy /Y "$(MINGW_BIN)\libquadmath_64-0.dll"  "$(BUILD_DIR)\" > nul
	-@if exist "$(MINGW_BIN)\libwinpthread_64-1.dll" copy /Y "$(MINGW_BIN)\libwinpthread_64-1.dll" "$(BUILD_DIR)\" > nul
endif
	@echo "[$(PLATFORM)] $(LIB) built successfully."

# ─────────────────────────────────────────────────────────────────────────────
# Compile and run the standalone Fortran executable
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: fortran
fortran: $(BUILD_DIR) $(EXE)
	@echo "[$(PLATFORM)] Running Fortran executable: $(EXE)"
	@echo "-----------------------------------------"
	./$(EXE)

$(EXE): $(OBJS) $(MAIN_OBJ)
	@echo "[$(PLATFORM)] Linking Fortran executable: $(EXE)"
	$(FC) $(FFLAGS) -o $(EXE) $(OBJS) $(MAIN_OBJ)

# ─────────────────────────────────────────────────────────────────────────────
# Parse Typical_Data.f90 and regenerate typical_data_ranges.py
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: parse
parse:
	@echo "[$(PLATFORM)] Parsing Typical_Data.f90 -> gui/typical_data_ranges.py"
	$(PYTHON) $(INOUT_DIR)/parse_typical_data.py

# ─────────────────────────────────────────────────────────────────────────────
# Build the shared library and launch the Python GUI
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: gui
gui: $(LIB)
	@echo "[$(PLATFORM)] Launching Python GUI..."
	$(PYTHON) $(GUI_DIR)/gui.py

# ─────────────────────────────────────────────────────────────────────────────
# Remove all compiled artefacts
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: clean
ifeq ($(PLATFORM), windows)
clean:
	@echo "[windows] Cleaning build folder..."
	if exist "$(BUILD_DIR)" $(RMDIR) "$(BUILD_DIR)"
	@echo "[windows] Clean complete."
else
clean:
	@echo "[$(PLATFORM)] Cleaning build folder..."
	$(RMDIR) $(BUILD_DIR)
	@echo "[$(PLATFORM)] Clean complete."
endif
