
/**
 * Star Generator
 *      
 * Author: Jonas Frey  
 * Version: 0.1
 *
 * Description:
 * This OpenSCAD script generates a star-shaped 3D model with randomized 
 * decorative lines on each star corner.
 *
 * License:
 * This script licensed under a Standard Digital File License.
 *
 * Changelog:
 * [v1.0] Initial release
 */


star_radius = 100; // [10:400]
star_corners = 6;
max_rand_angle = 360/star_corners;
layerheight = 0.12;
//change this number to get a different random pattern

seed = 42;
center_translation = -20;
generate_hole = true;  // [true, false]

// base triangle points
// Control the third point position

/* [Advanced] */
angle1_max = 360/star_corners;  // Maximum angle for this star corner
p2_angle_factor = 0.5;
p2_angle = angle1_max / 2 * p2_angle_factor;       // Angle for the third point (half of max angle)
p2_radius_factor = 0.5;
p2_radius = star_radius * p2_radius_factor;   // Distance from origin (adjustable)

p2x = p2_radius * sin(p2_angle);  // x position (sin for angle from y-axis)
p2y = p2_radius * cos(p2_angle);  // y position (cos for angle from y-axis)

points = [[0,0], [0,star_radius], [p2x, p2y]];
faces = [[0,1,2]];
min_thick_lines = 0.5;
max_thick_lines = 3;
number_of_random_lines = 3;
number_of_random_diamonds = 2;

// small layerheight part1
module part1() {
    linear_extrude(height = layerheight)
        polygon(points = points, paths = faces);
}

// big layerheight part2 (used for intersections)
module part2() {
    linear_extrude(height = layerheight*20)
        polygon(points = points, paths = faces);
}

// Generate random line parameters
lines = [ for(i=[0:number_of_random_lines-1]) 
            let(
                w = rands(min_thick_lines, max_thick_lines, 1)[0], //rands(1,6,1,seed+i)[0],   // random width
                h = star_radius*2, // rands(2,6,1,seed+i+10)[0],// random height
                angle = rands(0,-max_rand_angle,1,seed+i+20)[0], // random rotation
                x_pos = 0,//rands(-5,5,1,seed+i+30)[0], // random X position
                y_pos = rands(0,star_radius/2,1,seed+i+40)[0], // random Y position
                layerheight = rands(layerheight, layerheight*10, 1)[0]
            )
            [w, h, angle, x_pos, y_pos, layerheight]  // store parameters as data
        ];

// Generate random rhombi parameters
min_rhombus_width = 5;
max_rhombus_width = 15;
min_rhombus_length = 20;
max_rhombus_length = 60;

rhombi = [ for(i=[0:number_of_random_diamonds-1])
            let(
                width = rands(min_rhombus_width, max_rhombus_width, 1, seed+i+100)[0],
                length = rands(min_rhombus_length, max_rhombus_length, 1, seed+i+110)[0],
                angle = rands(0, -max_rand_angle, 1, seed+i+120)[0],
                x_pos = 0,
                y_pos = rands(0, star_radius/2, 1, seed+i+130)[0],
                layerheight = rands(layerheight, layerheight*10, 1, seed+i+140)[0]
            )
            [width, length, angle, x_pos, y_pos, layerheight]  // store parameters as data
        ];

// Lines as objects
module lines() {
    for(r = lines)
        // Generate geometry from stored parameters
        translate([r[3], r[4], 0])       // x_pos, y_pos
            rotate([0,0,r[2]])           // angle
                translate([-r[0]/2,-r[1]/2,0])   // center using w, h
                    cube([r[0],r[1],r[5]]);         // w, h, height
}

// Random rhombi as objects
module random_rhombi() {
    for(d = rhombi) {
        // Create individual rhombus from parameters
        translate([d[3], d[4], 0])  // x_pos, y_pos
            rotate([0, 0, d[2]])    // angle
                linear_extrude(height = d[5]) {  // layerheight
                    polygon(points = [
                        [0, 0],                    // Bottom
                        [-d[0]/2, d[1]/2],         // Left (width/2, length/2)
                        [0, d[1]],                 // Top
                        [d[0]/2, d[1]/2]           // Right
                    ]);
                }
    }
}

// Rhombus (diamond) parameters
rhombus_length = star_radius + center_translation;  // Length from origin to star corner
rhombus_width = 10;  // Width of the rhombus at its widest point
rhombus_height = layerheight * 5;  // Height (z-axis extrusion)

// Module to create a rhombus pointing from origin along Y axis
module rhombus() {
    // Define rhombus points: bottom, left, top, right
    rhombus_points = [
        [0, 0],                           // Bottom point (at origin)
        [-rhombus_width/2, rhombus_length/2],  // Left point (middle)
        [0, rhombus_length],              // Top point (at star corner)
        [rhombus_width/2, rhombus_length/2]    // Right point (middle)
    ];
    
    linear_extrude(height = rhombus_height)
        polygon(points = rhombus_points);
}

// Single star corner module
module star_corner() {
    union() {
        part1();
        
        // Each line intersection gets a different color
        for(i = [0:len(lines)-1]) {
            let(
                r = lines[i],
                // Generate colors based on index
                hue = (i * 360 / len(lines)) % 360,
                color_rgb = [hue/360, 0.7, 0.9]  // HSV-like color generation
            )
            color(color_rgb)
                intersection() {
                    part2();
                    // Individual line
                    translate([r[3], r[4], 0])
                        rotate([0,0,r[2]])
                            translate([-r[0]/2,-r[1]/2,0])
                                cube([r[0],r[1],r[5]]);
                }
        }
        
        // Each rhombus intersection gets a different color
        for(i = [0:len(rhombi)-1]) {
            let(
                d = rhombi[i],
                // Generate colors based on index (offset from lines)
                hue = ((i + len(lines)) * 360 / (len(lines) + len(rhombi))) % 360,
                color_rgb = [hue/360, 0.7, 0.9]
            )
            color(color_rgb)
                intersection() {
                    part2();
                    // Individual rhombus
                    translate([d[3], d[4], 0])
                        rotate([0, 0, d[2]])
                            linear_extrude(height = d[5]) {
                                polygon(points = [
                                    [0, 0],
                                    [-d[0]/2, d[1]/2],
                                    [0, d[1]],
                                    [d[0]/2, d[1]/2]
                                ]);
                            }
                }
        }
        
        // Uncomment the line below to show full cubes (and comment out intersection above)
        //for(i = [0:len(lines)-1]) {
        //    let(r = lines[i], hue = (i * 360 / len(lines)) % 360)
        //    color([hue/360, 0.7, 0.9])
        //        translate([r[3], r[4], 0])
        //            rotate([0,0,r[2]])
        //                translate([-r[0]/2,-r[1]/2,0])
        //                    cube([r[0],r[1],r[5]]);
        //}
    }
}

// Cylinder hole parameters
hole_outer_radius = 2;
hole_inner_radius = 1;
hole_length = 2;

// Module for the cylinder with a hole (tube)
module cylinder_hole() {
    difference() {
        // Create the tube
        difference() {
            cylinder(h = hole_length, r = hole_outer_radius, center = true);
            cylinder(h = hole_length + 1, r = hole_inner_radius, center = true);
        }
        // Cut away everything below the XY plane (Z < 0)
        tempvar = hole_outer_radius*5;
        translate([tempvar/2, 0, 0])
            cube([tempvar, tempvar, tempvar], center = true);
    }

}

// Complete star: circular pattern of mirrored corners
for(i = [0:star_corners-1]) {
    rotate([0, 0, i * 360/star_corners])
        translate([0, center_translation, 0])  // translate leaf outward from center
            union() {
                star_corner();
                mirror([1, 0, 0])
                    star_corner();
            }
}

// Add rhombus pointing from origin to each star corner
for(i = [0:star_corners-1]) {
    rotate([0, 0, i * 360/star_corners])
        color("gold")
            rhombus();
}

// Add the cylinder hole at the top peak of the first leaf (if enabled)
if (generate_hole) {
    translate([0, star_radius + center_translation-hole_outer_radius*4, 0])  // Position at top of first leaf
        rotate([0, 90, 0])  // Rotate 90 degrees around Y axis to align with X axis
            cylinder_hole();
}