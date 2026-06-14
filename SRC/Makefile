# ─────────────────────────────────────────────────────────────────────────────
# Rocket Staging — Makefile
# Targets:
#   make all       — compile Fortran and build the shared library
#   make fortran   — compile and run the Fortran standalone executable
#   make gui       — build the shared library and launch the Python GUI
#   make clean     — remove all compiled artefacts
# ─────────────────────────────────────────────────────────────────────────────

# ── Compiler ──────────────────────────────────────────────────────────────────
FC      := gfortran
FFLAGS  := -O2 -Wall

# ── Source files (order matters: dependencies first) ─────────────────────────
SRCS    := Typical_Data.f90 \
           Rocket_Types.f90 \
           Staging.f90 \
           C_Interface.f90

# Main program source (for the standalone Fortran run)
MAIN    := main.f90

# ── Platform detection ────────────────────────────────────────────────────────
ifeq ($(OS), Windows_NT)
    # ── Windows ───────────────────────────────────────────────────────────────
    PLATFORM    := windows
    LIB         := librocket.dll
    EXE         := rocket.exe
    SHARED_FLAGS:= -shared -m64
    PYTHON      := python
    RM          := del /Q
    # Runtime DLLs to copy from TDM-GCC into the project folder
    MINGW_BIN   := C:/TDM-GCC-64/bin
    RUNTIME_DLLS := \
        $(MINGW_BIN)/libgfortran_64-5.dll \
        $(MINGW_BIN)/libgcc_s_seh_64-1.dll \
        $(MINGW_BIN)/libquadmath_64-0.dll  \
        $(MINGW_BIN)/libwinpthread_64-1.dll
else
    UNAME := $(shell uname -s)
    ifeq ($(UNAME), Darwin)
        # ── macOS ─────────────────────────────────────────────────────────────
        PLATFORM     := macos
        LIB          := librocket.dylib
        EXE          := rocket
        SHARED_FLAGS := -shared -fPIC
        PYTHON       := python3
        RM           := rm -f
        RUNTIME_DLLS :=
    else
        # ── Linux ─────────────────────────────────────────────────────────────
        PLATFORM     := linux
        LIB          := librocket.so
        EXE          := rocket
        SHARED_FLAGS := -shared -fPIC
        PYTHON       := python3
        RM           := rm -f
        RUNTIME_DLLS :=
    endif
endif

# ─────────────────────────────────────────────────────────────────────────────
# Default target
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: all
all: $(LIB)
	@echo ""
	@echo "  Build complete - $(LIB) is ready."
	@echo "  Run 'make fortran' to execute the Fortran program."
	@echo "  Run 'make gui'     to launch the Python GUI."
	@echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Build the shared library
# ─────────────────────────────────────────────────────────────────────────────
$(LIB): $(SRCS) C_Interface.f90
	@echo "[$(PLATFORM)] Compiling shared library: $(LIB)"
	$(FC) $(FFLAGS) $(SHARED_FLAGS) -o $(LIB) $(SRCS)
ifeq ($(PLATFORM), windows)
	@echo "[windows] Copying MinGW runtime DLLs..."
	@for %%D in ($(RUNTIME_DLLS)) do ( \
		if exist "%%D" ( copy /Y "%%D" . > nul ) \
		else ( echo   WARNING: %%D not found — skipping ) \
	)
endif
	@echo "[$(PLATFORM)] $(LIB) built successfully."

# ─────────────────────────────────────────────────────────────────────────────
# Compile and run the standalone Fortran executable
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: fortran
fortran: $(EXE)
	@echo "[$(PLATFORM)] Running Fortran executable: $(EXE)"
	@echo "─────────────────────────────────────────"
	./$(EXE)

$(EXE): $(SRCS) $(MAIN)
	@echo "[$(PLATFORM)] Compiling Fortran executable: $(EXE)"
	$(FC) $(FFLAGS) -o $(EXE) $(SRCS) $(MAIN)

# ─────────────────────────────────────────────────────────────────────────────
# Build the shared library and launch the Python GUI
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: gui
gui: $(LIB)
	@echo "[$(PLATFORM)] Launching Python GUI..."
	$(PYTHON) gui.py

# ─────────────────────────────────────────────────────────────────────────────
# Remove all compiled artefacts
# ─────────────────────────────────────────────────────────────────────────────
.PHONY: clean
ifeq ($(PLATFORM), windows)
clean:
	@echo "[windows] Cleaning compiled artefacts..."
	-$(RM) $(LIB) $(EXE) *.mod *.o 2>nul
	@echo "[windows] Clean complete."
else
clean:
	@echo "[$(PLATFORM)] Cleaning compiled artefacts..."
	$(RM) $(LIB) $(EXE) *.mod *.o
	@echo "[$(PLATFORM)] Clean complete."
endif
