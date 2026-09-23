// Assembly preview: Vincent-tray with 4x Vincent-converter strips slotted in,
// positioned as they would be assembled in real life.
//
// The placement values below must match the Vincent-* presets in
// parametric_tray_generator.json — rebuild the STLs with `make all` first.

//from Vincent-tray preset
tray_wall_thickness = 2;
inset = 1;
tray_tolerance = 1;
height_offset = 2;
new_base_length = 25;
converter_rows_in_tray = 4;

//outer margin added around the tray cavity by the generator
tray_margin = tray_wall_thickness*2 + inset*2 + tray_tolerance;

//tray, sitting on the ground
import("prints/tray-4x5.stl");

//converter strips: centered in the cavity (tolerance split evenly),
//resting on the tray floor, one strip per tray row
for (r = [0:converter_rows_in_tray-1]){
    translate([tray_margin/2, tray_margin/2 + r*new_base_length, height_offset])
        import("prints/convertor-1x5-square.stl");
}
