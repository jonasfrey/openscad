
/**
 * Star Generator
 *      
 * Author: Jonas Frey  
 * Version: 1.2
 *
 * Description:
 * This OpenSCAD script generates a star-shaped 3D model with randomized 
 * decorative lines on each star corner.
 *
 * License:
 * This script licensed under a Standard Digital File License.
 *
 * Opensource credits:
 * - openscad 'language': https://openscad.org/ 
 * - online openscad playground: https://ochafik.com/openscad2
 * 
 * Changelog:
 * [v1.0] Initial release
 * [v1.1] 
 *      - improved layout and labeling of input variables
 *      - added some minor code improvements
 * [v1.2]
 *      - improved UI inputs
 */

//change this number to get a different random pattern
model_variation = 72.4; // [0:0.1:100]
/* [Size] */
// in mm
diameter = 220; // [10:400]
star_radius = diameter/2;
corners = 6; // [3:12]
star_corners = corners;
max_rand_angle = 360/star_corners;
// first layer
layerheight = 0.12; // [0.08,0.12,0.16,0.2];
seed = model_variation;

random_lines = 4; // [0:20]
random_rhombi = 5; // [0:20]


// base triangle points
// Control the third point position

/* [Advanced] */
// distance from center to a 'leaf' of the star, makes sense when using a uneven number of corners
center_translation = -15; // [-100:0]


angle1_max = 360/star_corners;  // Maximum angle for this star corner
// normalized distance from origin to third point of triangle which makes up the half 'leaf' of the star
anglefactor = 0.7;// [0:0.1:2]
p2_angle_factor = anglefactor;
p2_angle = angle1_max / 2 * p2_angle_factor;       // Angle for the third point (half of max angle)
// normalized radial distance from star 'crest' to 'through' 
radiusfactor = 0.5;// [0:0.1:2]
p2_radius_factor = radiusfactor;
p2_radius = star_radius * p2_radius_factor;   // Distance from origin (adjustable)

p2x = p2_radius * sin(p2_angle);  // x position (sin for angle from y-axis)
p2y = p2_radius * cos(p2_angle);  // y position (cos for angle from y-axis)

points = [[0,0], [0,star_radius], [p2x, p2y]];
faces = [[0,1,2]];


max_thickness = layerheight*12;

/* [line sizes] */
min_thick_lines = 0.5;
max_thick_lines = 2;
/* [rhombi sizes] */
min_rhombus_width = 1;
max_rhombus_width = star_radius/4;
min_rhombus_length = 2;
max_rhombus_length = star_radius/2;



// generate_hole = false;  // [true, false] 
// Cylinder hole parameters
// hole_outer_radius = 5;
// hole_inner_radius = 3;
// hole_length = 2;


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
lines = [ for(i=[0:random_lines - 1]) 
            let(
                w = rands(min_thick_lines, max_thick_lines, 1)[0], //rands(1,6,1,seed+i)[0],   // random width
                h = star_radius*2, // rands(2,6,1,seed+i+10)[0],// random height
                angle = rands(0,-max_rand_angle,1,seed+i+20)[0], // random rotation
                x_pos = 0,//rands(-5,5,1,seed+i+30)[0], // random X position
                y_pos = rands(0,star_radius/2,1,seed+i+40)[0], // random Y position
                layerheight = rands(layerheight*2, max_thickness, 1)[0]
            )
            [w, h, angle, x_pos, y_pos, layerheight]  // store parameters as data
        ];


rhombi = [ for(i=[0:random_rhombi-1])
            let(
                width = rands(min_rhombus_width, max_rhombus_width, 1, seed+i+100)[0],
                length = rands(min_rhombus_length, max_rhombus_length, 1, seed+i+110)[0],
                angle = rands(0, -360/corners/2/2, 1, seed+i+44)[0],
                x_pos = rands(0, 0, 1)[0],
                y_pos = rands(0, star_radius, 1, seed+i+22)[0],
                layerheight = rands(layerheight*2, max_thickness, 1, seed+i+140)[0]
            )
            [width, length, angle, x_pos, y_pos, layerheight]  // store parameters as data
        ];





// Module to create a rhombus pointing from origin along Y axis
module rhombus(w, l) {
    rhombus_points = [
        [0, 0],
        [-w/2, l/2],
        [0, l],
        [w/2, l/2]
    ];
    polygon(points = rhombus_points, paths = [[0,1,2,3]]);
}

// Single star corner module
module star_corner() {
    union() {
        part1();
        
        if(random_lines > 0 ){

            for(i = [0:random_lines - 1]) {
                let(
                    r = lines[i],
                    // Generate colors based on index
                    hue = (i * 360 / random_lines) % 360,
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
        }
        if(random_rhombi > 0 ){
            // Each rhombus intersection gets a different color
            for(i = [0:random_rhombi-1]) {
                let(
                    d = rhombi[i],
                    hue = (i * 360 / random_rhombi) % 360,
                    color_rgb = [hue/360, 0.7, 0.9]  // HSV-like color generation
                )
                color(color_rgb)
                    intersection() {
                        part2();
                        rotate([0, 0, d[2]])
                            translate([d[3], d[4], 0])
                                linear_extrude(height = d[5]) {
                                    rhombus(d[0], d[1]);
                                }
                    }
                
            }
        }

    }
}


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


// // Add the cylinder hole at the top peak of the first leaf (if enabled)
// if (generate_hole) {
//     translate([0, star_radius + center_translation-hole_outer_radius*4, 0])  // Position at top of first leaf
//         rotate([0, 90, 0])  // Rotate 90 degrees around Y axis to align with X axis
//             cylinder_hole();
// }