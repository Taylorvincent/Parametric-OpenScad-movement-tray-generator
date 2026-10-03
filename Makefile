SCAD := parametric_tray_generator.scad
JSON := parametric_tray_generator.json
OUT  := prints

# tray size as ROWSxCOLS, override on the command line: make TRAY=4x6
# the converter is always a single row strip matching the tray width (4x6 -> 1x6)
TRAY ?= 4x5

# split "RxC" into its parts
rows_of = $(word 1,$(subst x, ,$(1)))
cols_of = $(word 2,$(subst x, ,$(1)))

CONV := 1x$(call cols_of,$(TRAY))

TRAY_STL := $(OUT)/tray-$(TRAY).stl
CONV_STL := $(OUT)/convertor-$(CONV)-angled+marked.stl
ASSEMBLY := $(OUT)/assembly-tray-$(TRAY)+convertor-$(CONV).stl
BUILDS   := $(TRAY_STL) $(CONV_STL) $(ASSEMBLY)

.PHONY: all build list one preview _preview FORCE

# build tray + converter + assembly to prints/, then PNG previews
all: build
	@$(MAKE) --no-print-directory _preview TRAY=$(TRAY)

build: $(BUILDS)

# tray: Vincent-tray preset with rows/cols from the name, e.g. prints/tray-4x6.stl
$(OUT)/tray-%.stl: $(SCAD) $(JSON) FORCE
	@mkdir -p $(OUT)
	@echo "==> Vincent-tray $* -> $@"
	@openscad -o $@ -p $(JSON) -P 'Vincent-tray' \
		-D 'rows=$(call rows_of,$*)' -D 'cols=$(call cols_of,$*)' \
		$(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

# converter: Vincent-converter preset, angled + marked, always 1 row, e.g. prints/convertor-1x6-angled+marked.stl
$(OUT)/convertor-1x%-angled+marked.stl: $(SCAD) $(JSON) FORCE
	@mkdir -p $(OUT)
	@echo "==> Vincent-converter 1x$* (marked) -> $@"
	@openscad -o $@ -p $(JSON) -P 'Vincent-converter' \
		-D 'rows=1' -D 'cols=$*' -D 'markBases=true' \
		$(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

# assembly preview: tray with converter strips slotted in
# placement params are read from the Vincent-tray preset, sizes/files passed via -D
$(ASSEMBLY): assembly_vincent.scad $(JSON) $(TRAY_STL) $(CONV_STL) FORCE
	@echo "==> assembly $(TRAY) + $(CONV) -> $@"
	@openscad -o $@ -p $(JSON) -P 'Vincent-tray' \
		-D 'rows=$(call rows_of,$(TRAY))' \
		-D 'tray_stl="$(TRAY_STL)"' -D 'conv_stl="$(CONV_STL)"' \
		assembly_vincent.scad 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

# PNG snapshots of the built STLs, rendered straight from disk (no viewer cache)
# fixed camera angle so successive builds compare 1:1; output in prints/preview/
PREVIEW := $(OUT)/preview
preview: build
	@$(MAKE) --no-print-directory _preview TRAY=$(TRAY)

# render only, no rebuild: `all` calls this after it has built the STLs
_preview:
	@mkdir -p $(PREVIEW)
	@for stl in $(BUILDS); do \
		png="$(PREVIEW)/$$(basename "$$stl" .stl).png"; \
		echo "==> preview $$stl -> $$png"; \
		printf 'import("%s");\n' "$(CURDIR)/$$stl" > $(PREVIEW)/.view.scad; \
		openscad -o "$$png" --render --imgsize=2400,1800 --viewall --autocenter \
			--camera=0,0,0,55,0,25,0 --colorscheme=Tomorrow $(PREVIEW)/.view.scad 2>&1 | grep -iE 'warning|error'; \
	done; rm -f $(PREVIEW)/.view.scad; true

FORCE:

# render one preset by exact name: make one P="Vincent - tray"
one:
	@mkdir -p $(OUT)
	@out="$(OUT)/$$(printf '%s' '$(P)' | tr ' ' '_').stl"; \
	echo "==> $(P) -> $$out"; \
	openscad -o "$$out" -p $(JSON) -P '$(P)' $(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

list:
	@python3 -c 'import json; [print(k) for k in json.load(open("$(JSON)"))["parameterSets"]]'

# ---- billiard / snooker ghost-ball aiming tool -------------------------------
# Independent of the tray generator: no preset JSON, ball diameter drives everything.
# Explicit targets, not a pattern rule: prints/%.stl above would otherwise claim these.
AIMSCAD := snooker_aim_tool.scad
AIMOUT  := prints/testrpintjes2
AIMSTLS := $(AIMOUT)/snooker-aim-tool.stl \
           $(AIMOUT)/snooker-aim-tool-2in.stl \
           $(AIMOUT)/snooker-aim-tool-178in.stl \
           $(AIMOUT)/pool-aim-tool.stl

# 52.5 = snooker, WPBSA regulation (full-size tables and snooker halls)
# 50.8 = snooker 2" (7-10 ft tables), 47.6 = snooker 1-7/8" (6-7 ft tables)
# 57.15 = US pool 2-1/4" -- what the original billiard.stl was built for
$(AIMOUT)/snooker-aim-tool.stl:       BALL := 52.5
$(AIMOUT)/snooker-aim-tool-2in.stl:   BALL := 50.8
$(AIMOUT)/snooker-aim-tool-178in.stl: BALL := 47.6
$(AIMOUT)/pool-aim-tool.stl:          BALL := 57.15

.PHONY: aimtools aimtools-all
aimtools: $(AIMOUT)/snooker-aim-tool.stl
aimtools-all: $(AIMSTLS)

$(AIMSTLS): $(AIMSCAD) FORCE
	@mkdir -p $(AIMOUT)
	@echo "==> aim tool ball_d=$(BALL) -> $@"
	@openscad -o $@ --export-format binstl -D 'ball_d=$(BALL)' $(AIMSCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true
