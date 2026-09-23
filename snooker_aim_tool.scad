// Snooker / pool ghost-ball aiming tool  --  parametric rebuild
//
// The hoop is a spherical socket that drops onto the OBJECT ball and self-centres on it.
// The arrow points where the object ball has to travel. The small ball on the opposite
// arm sits exactly one ball-diameter from the object ball centre, at ball-centre height:
// that is where the centre of the cue ball must be at the moment of impact (ghost ball).
//
// Printed flat: z=0 is the print bed and is the UPPER face of the plate when the tool is
// in use (the tool is flipped over to hang on the ball).
//
// Reverse-engineered from prints/testrpintjes2/billiard.stl, which was built for a
// 57.15 mm US pool ball. Every functional dimension there is driven by the ball diameter:
//   socket sphere R  = ball radius exactly (28.575), zero clearance
//   plate faces      = 22.000 / 24.000 mm from the ball centre  (= 0.76990 / 0.83990 * R)
//   ring outer       = socket radius + 1 mm (lower face) / + 3 mm (upper face)
//   aim ball         = O4 sphere at 2R from the hoop axis, at ball-centre height
//   strut            = 20 mm run / 22 mm drop  (47.726 deg)
// This file reproduces all of that, with the ball diameter as the single driving parameter.
//
// Ball sizes:
//   52.50  snooker, WPBSA regulation (+/-0.05) -- full-size tables and snooker halls
//   50.80  snooker 2"     -- common on 7-10 ft home tables
//   47.60  snooker 1-7/8" -- compact 6-7 ft tables
//   57.15  US pool 2-1/4" -- the original billiard.stl
//   56.00  carom / English pool 2-3/16"

/* [Ball] */
//ball diameter in mm (52.5 = official snooker, 57.15 = US pool)
ball_d = 52.5;//0.01
//extra radius added to the socket; 0 = conformal seat (self-centring, tolerant of print error)
socket_clearance = 0;//0.05

/* [Plate and hoop] */
//thickness of the flat plate
plate_t = 2;//0.1
//how high the hoop seats on the ball, as a fraction of the ball radius (0.76990376 = same seat latitude as the original)
seat_frac = 0.76990376;//0.00000001
//ring wall at the wide (in-use lower) face
ring_wall_thin = 1;//0.1
//ring wall at the narrow (in-use upper / print bed) face
ring_wall_thick = 3;//0.1

/* [Arrow] */
//width of the arrow shaft
shaft_w = 4;//0.1
//distance from the hoop axis to the base of the arrow head
arrow_base_y = 60;//0.5
//full width of the arrow head base
arrow_base_w = 8;//0.1
//length of the arrow head, base to tip
arrow_len = 5.7446;//0.01

/* [Aim ball] */
//diameter of the aim point ball (centre of the cue ball at impact)
aim_ball_d = 4;//0.1
//diameter of the neck behind the aim ball; must be < aim_ball_d or the strut
//swallows the ball and it stops reading as a distinct aim point
aim_neck_d = 2.4;//0.1
//angle of the strut that carries the aim ball, degrees from horizontal
strut_angle = 47.7263;//0.0001

/* [Quality] */
//facets per full circle
$fn = 128;

// ---- derived geometry -------------------------------------------------------
r      = ball_d / 2;                    // ball radius
d_in   = seat_frac * r;                 // ball centre -> in-use LOWER plate face
d_out  = d_in + plate_t;                // ball centre -> in-use UPPER face (= print bed)
ri_in  = sqrt(r*r - d_in*d_in);         // socket opening at the lower face (z = plate_t)
ri_out = sqrt(r*r - d_out*d_out);       // socket opening at the upper face (z = 0)
ro_in  = ri_in  + ring_wall_thin;       // ring outer radius at z = plate_t
ro_out = ri_out + ring_wall_thick;      // ring outer radius at z = 0
ghost  = 2 * r;                         // hoop axis -> aim ball centre (one ball diameter)
strut_run   = d_in / tan(strut_angle);  // horizontal run of the strut
strut_start = ghost - strut_run;        // where the strut leaves the plate

echo(str("ball_d=", ball_d, "  socket R=", r + socket_clearance,
         "  plate faces at ", d_in, "/", d_out, " from ball centre"));
echo(str("socket opening ", ri_in, " (lower) / ", ri_out, " (upper)",
         "  ring outer O", 2*ro_in, " max"));
echo(str("ghost offset=", ghost, "  aim ball centre ", r, " mm above the cloth",
         "  plate rides ", r + d_in, " mm above the cloth"));

// ---- modules ----------------------------------------------------------------

// flat shaft + arrow head, in the z = 0 plane
module plate_2d() {
    union() {
        // shaft: runs from the arrow head base, under the hoop, out to the strut
        translate([-shaft_w/2, -arrow_base_y])
            square([shaft_w, arrow_base_y + strut_start]);
        // arrow head
        polygon([[-arrow_base_w/2, -arrow_base_y],
                 [ arrow_base_w/2, -arrow_base_y],
                 [ 0, -(arrow_base_y + arrow_len)]]);
    }
}

// solid tapered disc; the socket sphere carves the actual hoop out of it
module ring_blank() {
    rotate_extrude()
        polygon([[0, 0], [ro_out, 0], [ro_in, plate_t], [0, plate_t]]);
}

// Arm carrying the aim point ball.
// The hull runs only as far as a NECK one ball-radius short of the aim centre, and
// the ball is unioned on top. Hulling straight to the ball would absorb it into the
// strut (the ball is wider than the strut is thick) and leave a rounded stub instead
// of a visible aim point. The neck sphere straddles the ball's rear surface, so the
// two always overlap into one solid.
// The hull seed is a cylinder laid across the shaft, not a box -- a box's corners give
// the hull a vertex fan that OpenSCAD exports as zero-area sliver facets. It is sunk
// clear of the shaft's end wall: if the seed is tangent to that wall, the wall's corner
// edge collapses into duplicate degenerate facets.
assert(aim_neck_d < aim_ball_d, "aim_neck_d must be smaller than aim_ball_d");
strut_len  = norm([ghost - strut_start, d_out - plate_t/2]);
neck_y = ghost - (ghost - strut_start)  / strut_len * aim_ball_d/2;
neck_z = d_out - (d_out - plate_t/2)    / strut_len * aim_ball_d/2;
module strut() {
    union() {
        hull() {
            translate([0, strut_start - 1.5*plate_t, plate_t/2]) rotate([0, 90, 0])
                cylinder(h = shaft_w, d = plate_t, center = true);
            translate([0, neck_y, neck_z]) sphere(d = aim_neck_d);
        }
        translate([0, ghost, d_out]) sphere(d = aim_ball_d);
    }
}

// ---- assembly ---------------------------------------------------------------
difference() {
    union() {
        linear_extrude(height = plate_t) plate_2d();
        ring_blank();
        strut();
    }
    // the object ball itself: centred on the hoop axis, d_out above the print bed
    translate([0, 0, d_out]) sphere(r = r + socket_clearance);
}
