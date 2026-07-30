SCAD := parametric_tray_generator.scad
JSON := parametric_tray_generator.json
OUT  := prints
# presets whose name starts with this (case-insensitive) are built by `make`
MINE := vincent

.PHONY: all everything list clean

# build all "vincent*" presets to prints/<name>.stl
all:
	@$(MAKE) --no-print-directory _build FILTER='$(MINE)'

# build every preset in the json
everything:
	@$(MAKE) --no-print-directory _build FILTER=''

# render one preset by exact name: make one P="Vincent - tray"
one:
	@mkdir -p $(OUT)
	@out="$(OUT)/$$(printf '%s' '$(P)' | tr ' ' '_').stl"; \
	echo "==> $(P) -> $$out"; \
	openscad -o "$$out" -p $(JSON) -P '$(P)' $(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; true

list:
	@python3 -c 'import json; [print(k) for k in json.load(open("$(JSON)"))["parameterSets"]]'

# only removes STLs this Makefile generated (named after presets), never other files in prints/
clean:
	@python3 -c 'import json; [print(k) for k in json.load(open("$(JSON)"))["parameterSets"]]' | \
	while IFS= read -r p; do \
		f="$(OUT)/$$(printf '%s' "$$p" | tr ' ' '_').stl"; \
		[ -f "$$f" ] && echo "rm $$f" && rm "$$f"; \
	done; true

.PHONY: _build one
_build:
	@mkdir -p $(OUT)
	@python3 -c 'import json; [print(k) for k in json.load(open("$(JSON)"))["parameterSets"] if k.lower().startswith("$(FILTER)".lower())]' | \
	while IFS= read -r p; do \
		out="$(OUT)/$$(printf '%s' "$$p" | tr ' ' '_').stl"; \
		echo "==> $$p -> $$out"; \
		openscad -o "$$out" -p $(JSON) -P "$$p" $(SCAD) 2>&1 | grep -iE 'warning|error' | grep -v 'NoError'; \
	done; true
