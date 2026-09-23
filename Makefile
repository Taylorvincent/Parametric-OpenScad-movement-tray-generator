SCAD := parametric_tray_generator.scad
JSON := parametric_tray_generator.json
OUT  := prints
# presets whose name starts with this (case-insensitive) are built by `make`
MINE := vincent

.PHONY: all everything list clean curated

# build all "vincent*" presets plus the curated list to prints/
all: curated
	@$(MAKE) --no-print-directory _build FILTER='$(MINE)'

# ---- curated builds: preset + -D overrides ----
CURATED := \
	$(OUT)/convertor-1x5-angled.stl \
	$(OUT)/convertor-1x5-angled+marked.stl \
	$(OUT)/convertor-1x5-square.stl \
	$(OUT)/convertor-2x5-angled+marked.stl \
	$(OUT)/tray-4x5.stl \
	$(OUT)/assembly-tray+converters.stl

$(OUT)/convertor-1x5-angled.stl:        PRESET := Vincent-converter
$(OUT)/convertor-1x5-angled+marked.stl: PRESET := Vincent-converter
$(OUT)/convertor-1x5-angled+marked.stl: DEFS   := -D 'markBases=true'
$(OUT)/convertor-1x5-square.stl:        PRESET := Vincent-converter
$(OUT)/convertor-1x5-square.stl:        DEFS   := -D 'inset=0'
$(OUT)/convertor-2x5-angled+marked.stl: PRESET := Vincent-converter
$(OUT)/convertor-2x5-angled+marked.stl: DEFS   := -D 'rows=2' -D 'markBases=true'
$(OUT)/tray-4x5.stl:                    PRESET := Vincent-tray

curated: $(CURATED)

# assembly preview: tray with converter strips slotted in
$(OUT)/assembly-tray+converters.stl: assembly_vincent.scad $(OUT)/tray-4x5.stl $(OUT)/convertor-1x5-angled+marked.stl FORCE
	@echo "==> assembly -> $@"
	@openscad -o $@ assembly_vincent.scad 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

# generic rule: FORCE makes every stl rebuild unconditionally
$(OUT)/%.stl: $(SCAD) $(JSON) FORCE
	@mkdir -p $(OUT)
	@echo "==> $(PRESET) $(DEFS) -> $@"
	@openscad -o $@ -p $(JSON) -P '$(PRESET)' $(DEFS) $(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

.PHONY: FORCE
FORCE:


# render one preset by exact name: make one P="Vincent - tray"
one:
	@mkdir -p $(OUT)
	@out="$(OUT)/$$(printf '%s' '$(P)' | tr ' ' '_').stl"; \
	echo "==> $(P) -> $$out"; \
	openscad -o "$$out" -p $(JSON) -P '$(P)' $(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

list:
	@python3 -c 'import json; [print(k) for k in json.load(open("$(JSON)"))["parameterSets"]]'


.PHONY: _build one
_build:
	@mkdir -p $(OUT)
	@python3 -c 'import json; [print(k) for k in json.load(open("$(JSON)"))["parameterSets"] if k.lower().startswith("$(FILTER)".lower())]' | \
	while IFS= read -r p; do \
		out="$(OUT)/$$(printf '%s' "$$p" | tr ' ' '_').stl"; \
		echo "==> $$p -> $$out"; \
		openscad -o "$$out" -p $(JSON) -P "$$p" $(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; \
	done; true

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
