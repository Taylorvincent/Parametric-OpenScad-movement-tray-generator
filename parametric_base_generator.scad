// Copyright 2023 Stefano Linguerri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.¢
// See the License for the specific language governing permissions and
// limitations under the License.

//height (thickness) of this tray
height = 4;//0.1
//base width 
base_width = 25;
//base length 
base_length = 25;
//thickness of the top and sides of the base
height_offset = 1.3;
//Inset of the top of the tray: greater the value greater the slope of the tray
inset = 1;
//magnets height (if greater than 0.1 will generate the magnet holders)
magnets_height = 0.1;
//magnets diameter
magnets_diameter = 0.1;

base_type = "0"; // [0:Hollow, 1:Solid]
//wall thickness of the pipe the magnet sits in (hollow bases only)
magnets_pipe_wall = 1.5;
//grainy texture on the top surface
texture_top = true;
//max grain size of the texture
texture_grain = 0.8;//0.1
//grains per square mm of top surface
texture_density = 3;//0.1
//random seed for the texture (same seed = same texture)
texture_seed = 42;
//X-shaped support ribs under the top (hollow bases only)
support_ribs = true;
//thickness of the support ribs
rib_width = 1.2;//0.1
//slotta hole width
slotta_width = 2;//0.1
//slotta hole length
slotta_length = 18;//0.1
//slotta type
slotta_type = "0"; // [0:None, 1:Parallel Center, 2:Parallel 3/4, 3:Diagonal]

module tray(offset, zOffset, height, base_width, base_length, inset) {
    
        
        b_total_cols = (base_width);
        b_total_rows = (base_length);
        
        t_total_cols = (base_width - inset *2);
        t_total_rows = (base_length - inset *2);
    
        translate(
            [offset,
            offset,
            zOffset]
        )

        polyhedron(
            points=[
                    [0,0,0],                        //base bottom left
                    [b_total_cols,0,0],             //base bottom right
                    [b_total_cols,b_total_rows,0],  //base top right
                    [0,b_total_rows,0],             //base top left


                    [inset,  inset,   height],                              //surface bottom left
                    [inset + t_total_cols, inset,  height],                 //surface bottom right
                    [inset + t_total_cols, inset + t_total_rows, height],   //surface top right
                    [inset,   inset + t_total_rows,  height]                //surface top left
                ],
            faces =[
                        [0,1,2,3],
                        [4,5,1,0],
                        [5,6,2,1],
                        [6,7,3,2],
                        [7,4,0,3],
                        [7,6,5,4]
                    ]
        ); 
           
}

module slotta (base_width, base_length,slotta_width,slotta_height, slotta_type, offset,inset) {   

    if(slotta_type == "1"){
        translate( 
            [(base_width - slotta_length)/2, base_width/2, -0.1]
        )
        cube(size = [slotta_length,slotta_width,slotta_height+0.2]);
    }
    
    if(slotta_type == "2"){
        translate( 
            [(base_width - slotta_length)/2, base_width/4, -0.1]
        )
        cube(size = [slotta_length,slotta_width,slotta_height+0.2]);
    }
    
    if(slotta_type == "3"){

        let(cathetus_slotta_width = slotta_width/sqrt(2),cathetus_slotta_lenght = slotta_length/sqrt(2)){
            echo(">>>>",cathetus_slotta_lenght)
            translate( 
                [(base_width/2)-(cathetus_slotta_lenght/2), (base_length/2) -(cathetus_slotta_lenght/2), -0.1]
            )

            rotate(45)

            cube(size = [slotta_length,slotta_width,slotta_height+0.2]);
                    
        }
    }    
}

module magnets_holes (base_width, base_length, magnets_height, magnets_diameter) {
    translate(
        [base_width/2,
        base_length/2,
        -0.1]
    )
    cylinder(d = magnets_diameter, h = magnets_height+0.01,$fn=30);
}

//tube hanging from the underside of the top wall for the magnet to press-fit into
module magnets_pipe (base_width, base_length, height, height_offset, magnets_diameter, pipe_wall) {
    translate([base_width/2, base_length/2, 0])
    cylinder(d = magnets_diameter + 2*pipe_wall, h = height - height_offset, $fn = 60);
}

//two thin walls running corner to corner (trimmed to the base outline elsewhere)
module support_ribs_geom (base_width, base_length, height, height_offset, rib_width) {
    rib_height = height - height_offset;
    diag = sqrt(base_width*base_width + base_length*base_length);
    angle = atan2(base_length, base_width);
    translate([base_width/2, base_length/2, 0])
    for (a = [angle, -angle])
        rotate([0, 0, a])
        translate([-diag/2, -rib_width/2, 0])
        cube([diag, rib_width, rib_height]);
}

//random rotated cubes scattered across the top face;
//protrude=true buries them so they poke up (bumps, to union),
//protrude=false floats them so they bite down (dimples, to subtract)
module top_texture (base_width, base_length, height, inset, grain, density, seed, protrude) {
    n = max(1, floor((base_width - 2*inset) * (base_length - 2*inset) * density));
    xs = rands(inset, base_width - inset, n, seed);
    ys = rands(inset, base_length - inset, n, seed + 1);
    ss = rands(grain*0.4, grain, n, seed + 2);
    rx = rands(0, 360, n, seed + 3);
    ry = rands(0, 360, n, seed + 4);
    rz = rands(0, 360, n, seed + 5);
    zs = rands(0.25, 0.5, n, seed + 6);
    dir = protrude ? -1 : 1;
    intersection() {
        //clip to the flat top footprint so no grain overhangs the bevel edge
        translate([inset, inset, height - 3*grain - 1])
            cube([base_width - 2*inset, base_length - 2*inset, 6*grain + 2]);
        for (i = [0:n-1])
            translate([xs[i], ys[i], height + dir * zs[i] * ss[i]])
            rotate([rx[i], ry[i], rz[i]])
            cube(ss[i], center = true);
    }
}

difference(){

    union(){

        difference(){

            color ([0.5, 0.5, 0.5]) {
                tray(0,0, height, base_width, base_length, inset);
            }

            if(base_type == "0"){
                color ([0.7, 0.7, 0.7]) {
                    tray(height_offset, -1.0, height - height_offset, base_width - (2*height_offset), base_length - (2 * height_offset), inset);
                }
            }
        }

        if(base_type == "0" && magnets_height > 0.1){
            magnets_pipe(base_width, base_length, height, height_offset, magnets_diameter, magnets_pipe_wall);
        }

        if(base_type == "0" && support_ribs){
            intersection(){
                support_ribs_geom(base_width, base_length, height, height_offset, rib_width);
                tray(0,0, height, base_width, base_length, inset);
            }
        }

        //render() collapses the grains to one mesh so F5 preview doesn't blow the CSG tree
        if(texture_top){
            render() top_texture(base_width, base_length, height, inset, texture_grain, texture_density, texture_seed, true);
        }
    }

    if (magnets_height > 0.1){
        magnets_holes (base_width, base_length, magnets_height, magnets_diameter);
    }

    slotta(base_width,base_length,slotta_width,height,slotta_type,height_offset,inset);

    if(texture_top){
        render() top_texture(base_width, base_length, height, inset, texture_grain, texture_density, texture_seed + 100, false);
    }

}

