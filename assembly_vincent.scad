// Assembly preview: Vincent-tray with 4x Vincent-converter strips slotted in,
// positioned as they would be assembled in real life.
//
// The values below are only fallbacks: the Makefile renders this file with
// `-p parametric_tray_generator.json -P Vincent-tray`, so OpenSCAD overrides
// every variable whose name matches a key in the Vincent-tray preset.
// Keep the names identical to the preset keys. Run `make all` to rebuild.

//from Vincent-tray preset (overridden by the JSON)
tray_wall_thickness = 1;
inset = 1;
tray_tolerance = 1;
height_offset = 2;
new_base_length = 25;
rows = 4;

//outer margin added around the tray cavity by the generator
tray_margin = tray_wall_thickness*2 + inset*2 + tray_tolerance;

//tray, sitting on the ground
import("prints/tray-4x5.stl");

//converter strips: centered in the cavity (tolerance split evenly),
//resting on the tray floor, one strip per tray row
for (r = [0:rows-1]){
    translate([tray_margin/2, tray_margin/2 + r*new_base_length, height_offset])
        import("prints/convertor-1x5-angled+marked.stl");
}
