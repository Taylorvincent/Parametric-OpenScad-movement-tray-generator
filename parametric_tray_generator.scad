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

//Number of columns for this tray
cols = 6;
//Number of rows for this tray
rows = 7;
//heigh (thickness) of this tray
height = 5;//.1
//new base width 
new_base_width = 25;
//new base length 
new_base_length = 25;
// existing base width of adapted models
adapted_base_width = 21;//.1
// existing base length of adapted models
adapted_base_length = 21;//.1
//minimum bottom height (thickness) of the insets for the bases
height_offset = 2;
//Inset of the top of the tray: greater the value greater the slope of the tray
inset = 1;
//if base adapted are round (in this case adapted_base_width is considered as the diameter of the round base)
isRound_adapted = false;
//magnets height (if greater than 1 will generate the insets)
magnets_height = 0.0;//.1
//magnets radius
magnets_radius = 0.0;//.1
//if the tray is for lance formation, use only the number of rows to genrate the tray
is_lance_formation = false;
//Put a mark to show the new base widh/length on the adapter
markBases = false;
//Depth of the base-marker grooves, measured from the top surface
markBases_depth = 2.5;//.1
//Width of the base-marker grooves at the top surface
markBases_width = 1.0;//.1
//Creates a standard (not an adpater) movement tray for given Type for given new_base_length x new_base_width
create_Movement_Tray_Type="0"; // [0:None, 4:Four walls, 3:Three walls]
//Wall thickness at the top of the standalone movement tray
tray_wall_thickness = 1.5;//.1
//Extra room inside the standalone tray walls so the bases slide in freely (total, split evenly on both sides)
tray_tolerance = 1.0;//.1
//Radius to round the hard top edges of the tray walls, outer rim and cavity edge (0 = sharp)
tray_top_rounding = 0.0;//.1
//Creates holes under the tray for magnets
lower_Movement_tray_magnets="0"; // [0:None, 4:Four, 5:Five, 6:Six, 7:Seven, 9:Nine]
//Tray magnets height
lower_Movement_tray_magnets_height = 2.0;//.1
//Tray magnets radius
lower_Movement_tray_magnets_radius = 3.0;//.1

/* [Output] */
//What to generate
output_mode = "3D"; // [3D:3D model, 2D:2D outline - bottom]


module tray(cols, rows, height, new_base_width, new_base_length, adapted_base_width, adapted_base_length, inset, margin_for_empty_tray) {
    
        b_total_cols = (new_base_width * cols) + margin_for_empty_tray;
        b_total_rows = (new_base_length * rows)+ margin_for_empty_tray;
        
        t_total_cols = (new_base_width * cols - inset *2) + margin_for_empty_tray;
        t_total_rows = (new_base_length * rows - inset *2) + margin_for_empty_tray;
        
        if (tray_top_rounding > 0) {
            //same silhouette, but the top rim is traced by spheres tucked under
            //the corners so every top edge gets a radius
            r = min(tray_top_rounding, height/2);
            hull() {
                cube([b_total_cols, b_total_rows, slice_eps]);
                for (x = [inset + r, inset + t_total_cols - r])
                    for (y = [inset + r, inset + t_total_rows - r])
                        translate([x, y, height - r]) sphere(r = r, $fn = 32);
            }
        } else {
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
}

/* [Hidden] */
slice_eps = 0.01;

//this module will create the hole in the "empty" classic movement tray
module empty_tray_hole(cols, rows, height_offset, new_base_width,  new_base_length, adapted_base_width, adapted_base_length, inset, margin_for_empty_tray,create_Movement_Tray_Type) {
    
    t_total_cols = (new_base_width * cols) + tray_tolerance;
    t_total_rows = (new_base_length * rows) + tray_tolerance;


    translate(
                [(margin_for_empty_tray-tray_tolerance)/2, //row
               (margin_for_empty_tray-tray_tolerance)/2, //col
                height_offset]
    )

    if(toInt(create_Movement_Tray_Type) == 3){
        cube([t_total_cols,t_total_rows+margin_for_empty_tray, 30]);
    }else{
        cube([t_total_cols,t_total_rows, 30]);
    }

    //round the cavity's top edges into a convex shoulder so each wall top reads as a reverse U:
    //each edge tool removes a bar minus a quarter-cylinder, leaving a quarter-round of wall
    //material; at the closed corners the crown sweeps around as a quarter-torus instead
    if (tray_top_rounding > 0) {
        r = min(tray_top_rounding, height/2);
        open_front = toInt(create_Movement_Tray_Type) == 3;
        hx0 = (margin_for_empty_tray-tray_tolerance)/2;
        hy0 = (margin_for_empty_tray-tray_tolerance)/2;
        hx1 = hx0 + t_total_cols;
        hy1 = hy0 + t_total_rows;
        y_end = open_front ? hy0 + t_total_rows + margin_for_empty_tray : hy1;

        translate([hx0, hy0, height])   top_edge_roundover(t_total_cols, r);                  //back wall
        translate([hx0, y_end, height]) rotate([0,0,-90]) top_edge_roundover(y_end - hy0, r); //left wall
        translate([hx1, hy0, height])   rotate([0,0,90])  top_edge_roundover(y_end - hy0, r); //right wall
        translate([hx0, hy0, height])   top_corner_roundover(r);                              //back-left
        translate([hx1, hy0, height])   rotate([0,0,90])  top_corner_roundover(r);            //back-right
        if (!open_front) {
            translate([hx1, hy1, height]) rotate([0,0,180]) top_edge_roundover(t_total_cols, r); //front wall
            translate([hx1, hy1, height]) rotate([0,0,180]) top_corner_roundover(r);             //front-right
            translate([hx0, hy1, height]) rotate([0,0,-90]) top_corner_roundover(r);             //front-left
        }
    }
}

//cutting block for a cavity top corner: cavity toward +x/+y, tray top at z=0.
//removes the corner column down to a quarter-torus, so the wall crown sweeps around
//the inside corner tangent to both edge roundovers and to the flat top
module top_corner_roundover(r) {
    difference() {
        intersection() {
            translate([-r, -r, -r]) cube([r + slice_eps, r + slice_eps, r + slice_eps*2]);
            translate([0, 0, -r]) cylinder(h = r + slice_eps*3, r = r, $fn = 32);
        }
        rotate([0, 0, 180]) rotate_extrude(angle = 90, $fn = 32)
            translate([r, -r]) circle(r = r, $fn = 32);
    }
}

//cutting bar for one cavity top edge: edge along +x at the origin, cavity toward +y, tray top at z=0.
//subtracting it leaves a convex quarter-round on the wall's inner shoulder
module top_edge_roundover(len, r) {
    difference() {
        translate([-slice_eps, -r, -r]) cube([len + slice_eps*2, r + slice_eps, r + slice_eps]);
        translate([-slice_eps*2, -r, -r]) rotate([0,90,0]) cylinder(h = len + slice_eps*4, r = r, $fn = 32);
    }
}


module adapted_base_holes(cols, rows, height_offset, new_base_width,  new_base_length, adapted_base_width, adapted_base_length) {
    
    gap_w = new_base_width - adapted_base_width;
    gap_l = new_base_length - adapted_base_length;

    for (c = [0:cols-1]){
        for (r = [0:rows-1]){
           translate( 
                        [gap_w/2 + (c*adapted_base_width) + (c*gap_w), //row
                        gap_l/2 + (r*adapted_base_length) + (r*gap_l), //col
                        height_offset]
            )                       
            cube([adapted_base_width,adapted_base_length, 30]);
            
        }
    }
}

module adapted_base_holes_round(cols, rows, height_offset, new_base_width, new_base_length, adapted_base_width, adapted_base_length) {
    
    for (c = [0:cols-1]){
        for (r = [0:rows-1]){
            translate( 
                        [new_base_width/2 + new_base_width * c , //row
                        new_base_length/2 + new_base_length * r, //col
                        height_offset]
            )
            //resize([adapted_base_width,adapted_base_length]) 
            cylinder(r = adapted_base_width/2, h = height);
           
        }
    }
}

module magnets_holes (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset) {
    
    //punch through the floor when the magnet is at least as tall as it, otherwise leave a skin below
    hole_bottom = magnets_height >= height_offset ? -0.01 : height_offset-magnets_height;

    for (c = [0:cols-1]){
        for (r = [0:rows-1]){
            translate(
                        [new_base_width/2 + new_base_width * c , //row
                        new_base_length/2 + new_base_length * r, //col
                        hole_bottom]
            )
            cylinder(r = magnets_radius/2, h = height_offset-hole_bottom+0.01,$fn=20);

        }
    }
}

/// BASE MARKER
module mark_new_bases (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset) {
    color ([0.9, 0.4, 0.4])
                    {
        //v-groove cross-section: markBases_width wide at the top surface, apex markBases_depth below it
        for (c = [1:cols-1]){
            translate(
                [new_base_width * c - markBases_width/2 , //col
                 new_base_length * 0, //row
                 height+0.01]
            )

            rotate([-90,0,0]) {
                linear_extrude(new_base_length*rows) {
                     polygon(points=[[0,0],[markBases_width,0],[markBases_width/2,markBases_depth+0.01]], paths=[[0,1,2]]);
                }
            }
        }


        for (r = [1:rows-1]){
            translate(
                    [new_base_width * 0 , //col
                     new_base_length * r - markBases_width/2, //row
                     height+0.01]
            )
            rotate([0,90,0]) {
                linear_extrude(new_base_width*cols) {
                    polygon(points=[[0,0],[0,markBases_width],[markBases_depth+0.01,markBases_width/2]], paths=[[0,1,2]]);
                }
            }
        }
    }
}

module lance_formation (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset,  inset, margin_for_empty_tray) {
    
    
    for (thisRow = [0:rows-1]){    

        translate( [0,thisRow*new_base_length,0]){
            for (thisCol = [0:thisRow]){    
                translate( [(new_base_width/2)*thisRow-(new_base_width*thisCol),0,0]){
                    //color([0.4, rands(0.01, 1,1)[0],rands(0.01, 1,1)[0] ])
                    color ([0.5, 0.5, 0.5])
                    {
                        lance_sloped_slot(thisCol+1, thisRow+1 == rows, height, new_base_width, new_base_length, adapted_base_width, adapted_base_length, inset, margin_for_empty_tray);
                    }    
                }
            }
        }
    }     
}

////////////////////////////////
// LANCE FORMATION            //
////////////////////////////////
module lance_sloped_slot(cols, isLastRow, height, new_base_width, new_base_length, adapted_base_width, adapted_base_length, inset, margin_for_empty_tray) {
    
        rows = 1;
    
        b_total_cols = (new_base_width * cols) + margin_for_empty_tray;
        b_total_rows = (new_base_length * rows)+ margin_for_empty_tray;
        
        t_total_cols = (new_base_width * cols - inset *2) + margin_for_empty_tray;
        t_total_rows = (new_base_length * rows - inset *2) + margin_for_empty_tray;

    

        polyhedron(
            points=[
                    [0,0,0],                        //base bottom left
                    [b_total_cols,0,0],             //base bottom right
                    [b_total_cols,b_total_rows,0],  //base top right
                    [0,b_total_rows,0],             //base top left
        
                    [inset,  inset,   height],                              //surface bottom left
                    [inset + t_total_cols, inset,  height],                 //surface bottom right
                    [inset + t_total_cols,  
                        isLastRow ? inset + t_total_rows : inset*3 + t_total_rows, //if last row we set the slope otherwise we move the y of the point to reach the next row
                        height],   //surface top right
                    [inset, 
                        isLastRow ? inset + t_total_rows : inset*3 + t_total_rows,//if last row we set the slope otherwise we move the y of the point to reach the next row
                        height]//surface top left
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


module lance_formation_hole (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset) {
    
    gap_w = new_base_width - adapted_base_width;
    gap_l = new_base_length - adapted_base_length;
    
    for (thisRow = [0:rows-1]){    

        translate( [0,thisRow*new_base_length+gap_l/2,height_offset]){
            for (thisCol = [0:thisRow]){                    
                translate( [(new_base_width/2)*thisRow-(new_base_width*thisCol)+gap_w/2,0,0]){
                    color([0.7, 0.7,0.7 ]){
                        cube([adapted_base_width, adapted_base_length,height+2 ]);
                    }    
                }
            }
        }
    }     
}

//Standard movement tray
module lance_formation_tray_hole (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset, inset, margin_for_empty_tray, create_Movement_Tray_Type) {
    
    gap_w = new_base_width - adapted_base_width;
    gap_l = new_base_length - adapted_base_length;
    
    for (thisRow = [0:rows-1]){    

        translate( [0,thisRow*new_base_length+(margin_for_empty_tray-tray_tolerance)/2,height_offset]){
            for (thisCol = [0:thisRow]){
                translate( [(new_base_width/2)*thisRow-(new_base_width*thisCol)+(margin_for_empty_tray-tray_tolerance)/2,0,0]){
                    color([0.7, 0.7,0.7 ]){

                        if(toInt(create_Movement_Tray_Type) == 3){
                            cube([new_base_width+tray_tolerance, new_base_length+margin_for_empty_tray,height+2 ]);
                        }else{
                            cube([new_base_width+tray_tolerance+0.05, new_base_length+tray_tolerance+0.05,height+2 ]);
                        }
                    }    
                }
            }
        }
    }     
}

module lance_formation_magnets_hole (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset) {
    
    gap_w = new_base_width - adapted_base_width;
    gap_l = new_base_length - adapted_base_length;

    //punch through the floor when the magnet is at least as tall as it, otherwise leave a skin below
    hole_bottom = magnets_height >= height_offset ? -0.01 : height_offset-magnets_height;

    for (thisRow = [0:rows-1]){

        translate( [0,(thisRow+1)*new_base_length-new_base_length/2,hole_bottom]){
            for (thisCol = [0:thisRow]){
                translate( [(new_base_width/2)*thisRow-(new_base_width*thisCol)+gap_w/2+new_base_width/2,0,0]){
                    color([0.7, 0.7,0.7 ]){
                        cylinder(r = magnets_radius/2, h = height_offset-hole_bottom+0.01,$fn=20);
                    }
                }
            }
        }
    }
}


module tray_model() {

    tray_type = toInt(create_Movement_Tray_Type);
    //extra space added around the grid when a movement tray type is selected,
    //widened by the inset so the sloped outer walls keep their thickness at the top
    tray_margin = tray_type == 0 ? 0 : tray_wall_thickness*2 + inset*2 + tray_tolerance;

    //Ranked movement tray
    if(!is_lance_formation){
        difference(){
                color ([0.5, 0.5, 0.5]) {
                    if(tray_type == 0){
                        tray(cols, rows, height, new_base_width, new_base_length, adapted_base_width, adapted_base_length, inset, 0);
                    }else{
                        tray(cols, rows, height, new_base_width, new_base_length, adapted_base_width, adapted_base_length, inset, tray_margin);
                    }
                }
                color ([0.7, 0.7, 0.7]) {
                    if (magnets_height > 0){
                        translate([tray_margin/2, tray_margin/2, 0])
                        magnets_holes (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius,height, height_offset);
                    }
                    if(tray_type == 0){
                        if(!isRound_adapted){
                            adapted_base_holes(cols, rows, height_offset, new_base_width, new_base_length, adapted_base_width, adapted_base_length);
                        }else{
                            adapted_base_holes_round(cols, rows, height_offset, new_base_width, new_base_length, adapted_base_width, adapted_base_length);
                        }
                    }else{//Add here the logic for the 4th back wall
                        empty_tray_hole(cols, rows, height_offset, new_base_width,  new_base_length, adapted_base_width, adapted_base_length, inset, tray_margin,create_Movement_Tray_Type);
                    }
                }
                
                if(markBases){
                    echo("mark it");
                    mark_new_bases (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset);
                }
                
                
                if(toInt(lower_Movement_tray_magnets) > 0){
                    translate([tray_margin/2, tray_margin/2, 0])
                    tray_magnets_holes(cols,rows,new_base_width,new_base_length, lower_Movement_tray_magnets_height, lower_Movement_tray_magnets_radius ,toInt(lower_Movement_tray_magnets),false);
                }

                
            
        }
    }

    //Lance formation movment tray
    if(is_lance_formation){    
        difference(){      
            if(tray_type == 0){
                union() {
                    lance_formation (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset, inset, 0);
                }
            }else{
                union() {
                    lance_formation (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset, inset, tray_margin);
                }
            }
            
            if(tray_type == 0){
                lance_formation_hole (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset);
            }else{
                lance_formation_tray_hole(cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, height, height_offset, inset, tray_margin, create_Movement_Tray_Type);
            }
            
            if (magnets_height > 0){
                echo ("magnets lance");
                lance_formation_magnets_hole (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius,height, height_offset);
            }
        /*
         if(toInt(lower_Movement_tray_magnets) > 0){
                tray_magnets_holes(cols,rows,new_base_width,new_base_length, lower_Movement_tray_magnets_height, lower_Movement_tray_magnets_radius ,toInt(lower_Movement_tray_magnets),true);
        }
*/
        }
    }
}

//Movement tray lower magnets
module tray_magnets_holes (cols, rows,  new_base_width, new_base_length, magnets_height, magnets_radius, numbers, isLanceFormation) {


    if(isLanceFormation){
        echo("LAAAAANCEEE", cavalryShift(isLanceFormation, rows,new_base_width ));

    }
    //Bottom left
    translate( 
        [new_base_width/3 + new_base_width * 0 , 
        new_base_length/3 + new_base_length * 0, 
       -0.1]
    )
    cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);

    //Bottom right
    translate( 
        [(new_base_width/3*2) + new_base_width * (cols-1) ,  
        new_base_length/3 + new_base_length * 0, 
       -0.1]
    )    
    cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);

    //Top left
    translate( 
        [new_base_width/3 + new_base_width * 0 ,  
        (new_base_length/3*2)+ new_base_length * (rows-1),  
       -0.1]
    )
    cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);
    
    //Top right
    translate( 
        [(new_base_width/3*2) + new_base_width * (cols-1)  ,  
        (new_base_length/3*2)+ new_base_length * (rows-1),  
       -0.1]
    )
    cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);
    
    //middle/center
    if(numbers == 5 || numbers == 7 || numbers == 9 ){        
        translate( 
            [ new_base_width * (cols/2)  , //row
            new_base_length * (rows/2), //col
           -0.1]
        ) 
        cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);
    }
    
    //middle left/right
    if(numbers == 7 || numbers == 6 || numbers == 9){        
        translate( 
            [new_base_width/3 + new_base_width * 0 , 
            new_base_length * (rows/2), 
            -0.1]
        )
        cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);
        
        translate( 
            [(new_base_width/3*2) + new_base_width * (cols-1) ,  
            new_base_length * (rows/2), 
            -0.1]
        )   

        cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);
    }
    
    //middle top/bottom
    if(numbers == 9){        
        translate( 
            [ new_base_width * (cols/2)  ,  
            new_base_length/3 + new_base_length * 0,  
           -0.1]
        ) 
        cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);      
      
        translate( 
            [ new_base_width * (cols/2)  , 
            (new_base_length/3*2)+ new_base_length * (rows-1), 
           -0.1]
        ) 
        cylinder(r = magnets_radius/2, h = magnets_height+0.01,$fn=20);  
    }
    
}


// ---- output dispatcher ----
if (output_mode == "2D") {
    projection(cut = true) translate([0, 0, -slice_eps]) tray_model();
} else {
    tray_model();
}


function cavalryShift(isLanceFormation, cols, base_width) =
    isLanceFormation
    ? cols* base_width
    : 0;

function toInt(s, ret=0, i=0) =
    is_num(s) ? s
    : i >= len(s)
    ? ret
    : toInt(s, ret*10 + ord(s[i]) - ord("0"), i+1);
