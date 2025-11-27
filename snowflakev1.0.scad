
/**
 * Snowflake Generator OPENSCAD opensource script
 *      
 * Author: Jonas Frey  
 * Version: 1.0
 *
 * Description:
 * This OpenSCAD script generates a snow flake shaped 3d model
 * with decorative lines on each snowflake branch.
 *
 * License:
 * This script licensed under a Standard Digital File License.
 *
 * Changelog:   
 * [v1.0] Initial release
 */

//change to get another random
randomseed = 71.70; // [0:0.05:100]
// number
branch_lines = 6; // [0:20]
// in mm
diameter = 85; // [10:400]
star_radius = diameter/2;
// factor
branch_rotation_randomness = 0.16; // [0:0.01:1]
branch_location_randomness = 0.47; // [0:0.01:1]
// in mm
branch_thickness = 2.2; // [0.3:0.1:10]
branch_thickness_randomness = 0.26; // [0:0.01:1]

// i know snowflakes have 6 sides, but why not get diverse
corners = 6; // [3:12]
star_corners = corners;
max_rand_angle = 360/star_corners;
layerheight = 0.12; // [0.08,0.12,0.16,0.2];
seed = randomseed;

/* [Advanced] */


angle1_max = 360/star_corners;  // Maximum angle for this star corner
anglefactor = 0.65;// [0:0.05:2]
p2_angle_factor = anglefactor;
p2_angle = angle1_max / 2 * p2_angle_factor;       // Angle for the third point (half of max angle)
radiusfactor = 0.9;// [0:0.05:2]
p2_radius_factor = radiusfactor;
p2_radius = star_radius * p2_radius_factor;   // Distance from origin (adjustable)

p2x = p2_radius * sin(p2_angle);  // x position (sin for angle from y-axis)
p2y = p2_radius * cos(p2_angle);  // y position (cos for angle from y-axis)

points = [[0,0], [0,star_radius], [p2x, p2y]];
faces = [[0,1,2]];
max_thickness = layerheight*12;
/* [line sizes] */
min_thick_lines = 0.5;
max_thick_lines = 3;
extrusion_h1 = layerheight*10;
firstlayerheight = 0.4;
// 0.0 45 degrees rotation 1.0 0-90 degrees rotated

// cube lines
center_line_width = 4;
center_line_length = star_radius+1;
center_line_height = layerheight*10;


// Axis helper lines (X=red, Y=green, Z=blue)
module axis_helper(len = 200, thickness = 0.5) {

    color([1,0,0,0.5])  // X axis
        cube([len, thickness, thickness]);

    color([0,1,0,0.5])  // Y axis
        cube([thickness, len, thickness]);

    color([0,0,1,0.5])  // Z axis
        cube([thickness, thickness, len]);
}


module c_cube(size = [1,1,1], center = false, col = [1.0,0.7,0.7,0.5]) {
    color(col)
        cube(size = size, center = center);
}

module c_linear_extrude(height = 1, center = false, convexity = 10, twist = 0, slices = 1, scale = 1, col = [0.7,0.7,1,0.5]) {
    color(col)
        linear_extrude(height = height, center = center, convexity = convexity, twist = twist, slices = slices, scale = scale)
            children();
}

module rhomboid(
    width = 5,
    length = 15,
){
    rhomboid_points = [
        [0, 0],
        [-width/2, length/2],
        [0, length],
        [width/2, length/2]
    ];
    polygon(points = rhomboid_points, paths = [[0,1,2,3]]);
}





module branch_profile(scl_x=1,scl_y=10,scl_z=1, trn_y_offset = 0){
    let(
        scl_x_a = scl_x/3, 
        scl_x_b = scl_x, 
        scl_z_a = scl_z, 
        scl_z_b = scl_z*0.4
    ){
        translate([-scl_x_a/2,trn_y_offset, 0])
            c_cube([scl_x_a, scl_y, scl_z_a]);

        translate([-(scl_x_b/2),trn_y_offset, 0])
            c_cube([scl_x_b, scl_y, firstlayerheight]);
    }
}


module branch_with_rhomoid_at_ends(scl_x=1,scl_y=10,scl_z=1, trn_y_offset = 0){
    branch_profile(scl_x, scl_y, scl_z, trn_y_offset);
    // i want to put rhomboids on the end of the branch
    let(
        scl_x_rhomb = scl_x*2,
        scl_y_rhomb = scl_x*3
    ){

        translate([0, trn_y_offset + scl_y -scl_y_rhomb*0.3, 0])
            c_linear_extrude(height = scl_z) {
                color([1,1,1,0.5])
                rhomboid(scl_x_rhomb, scl_y_rhomb);
            }
        translate([0, trn_y_offset-scl_y_rhomb*(1.-0.3), 0])
            c_linear_extrude(height = scl_z) {
                color([1,1,1,0.5])
                rhomboid(scl_x_rhomb, scl_y_rhomb);
            }

    }


}

// small layerheight part1
module part1() {
    c_linear_extrude(height = layerheight)
        polygon(points = points, paths = faces);
}
extrusion_subtractor = layerheight*40;
// big layerheight part2 (used for intersections)
module part2() {
    c_linear_extrude(height = layerheight*20)
        polygon(points = points, paths = faces);
}
module part_subtractor_positive(){
    c_linear_extrude(height = extrusion_subtractor)
        polygon(points = points, paths = faces);
}
// the outer 'negative' of part2
module part_subtractor() {
    difference() {
        // large cube
        w = star_radius*3;
        l = star_radius*3;
        h = extrusion_subtractor;
        translate([0, 0, h/2])
        c_cube([w, w, h], center = true);
        // subtract part2 to create the negative space
        part_subtractor_positive();

    }
}
module random_branches(seed_offset = 0) {
    // Generate random line parameters
    s = seed_offset + seed;
    branchesinfo = [ for(i=[0:branch_lines - 1]) 
                let(
                    rotation_randomness_normalized = rands(-1, 1, 1, s+i+14)[0],
                    location_randomness_normalized =  rands(-1, 1, 1, s+i+18)[0],
                    thickness_randomness_normalized =  rands(-1, 1, 1, s+i+53)[0],
                    scl_y = rands(0, star_radius/4, 1, s+i+23)[0],
                    scl_z = rands(0, layerheight*40, 1, s+i+12)[0], 
                )
                [rotation_randomness_normalized, location_randomness_normalized, thickness_randomness_normalized, scl_x, scl_y, scl_z]  // store parameters as data
            ];
            
    for(i = [0:branch_lines-1]) {
        let(
            a = branchesinfo[i],
            rotation_randomness_normalized = a[0],
            location_randomness_normalized = a[1],
            thickness_randomness_normalized = a[2],
            scl_y = a[4],
            scl_z = a[5],

            it_nor = i/branch_lines,
            trn_y_per_branch = star_radius/branch_lines,
            // Generate colors based on index
            hue = (i * 360 / random_lines) % 360,
            color_rgb = [hue/360, 0.7, 0.9],  // HSV-like color generation
            trn_y = trn_y_per_branch*i+(location_randomness_normalized*trn_y_per_branch*branch_location_randomness),
            rotation = -45 + rotation_randomness_normalized*90*branch_rotation_randomness,
            scl_x_calc = branch_thickness + (branch_thickness*thickness_randomness_normalized*branch_thickness_randomness),
            scl_x_calc2 = max(scl_x_calc,1.0) 
        )
        translate([0, trn_y, 0])  // translate leaf outward from center
        rotate([0, 0, rotation])
        branch_with_rhomoid_at_ends(scl_x_calc2, scl_y*2, extrusion_h1, -scl_y/2);
    }

}
module flake_leaf_half_withoutsubtractor(seed_offset = 0) {

    union(){
        translate([0,0,0])
        branch_profile(center_line_width, center_line_length, extrusion_h1);
        random_branches(seed_offset );
    }
    //part_subtractor();
}

module flake_leaf_half(seed_offset = 0) {
    s = seed + seed_offset;
    difference(){
        flake_leaf_half_withoutsubtractor(seed_offset);
        part_subtractor();
    }

    let(
        a = center_line_width*2,
        scl_x = a,
        scl_y = rands(a, a*2, 1, s)[0],
    ){
        // add a rhomboid at the end of the leaf
        translate([0, star_radius-scl_y*0.5, 0])
            rotate([0,0,0])
                c_linear_extrude(height = layerheight*10) {
                    rhomboid(scl_x, scl_y);
                }
    }
}


module flake_leaf(seed_offset = 0) {
    union() {
        flake_leaf_half(seed_offset);
        mirror([1, 0, 0])
            flake_leaf_half(seed_offset);

    }
}

module flake(seed_offset = 0){
    // Complete star: circular pattern of mirrored corners
    for(i = [0:star_corners-1]) {
        rotate([0, 0, i * 360/star_corners])
            translate([0, -10, 0])  // translate leaf inward to center to create overlap
            flake_leaf(seed_offset);
    }
}

module flakes(){
    // in a grid make multiple flakes
    spacing = diameter*1.01;
    rows = 2;
    cols = 2;
    
    translate([-spacing*(cols-1)/2, -spacing*(rows-1)/2, 0])
    for(x = [0:cols-1]){
        for(y = [0:rows-1]){
            translate([x*spacing, y*spacing, 0])
                let(
                    seed_offset_unique = (x*rows + y)*10
                )
                flake(seed_offset_unique);
        }
    }
}
// call it
// axis_helper(10, 0.01);

//flake_leaf_half_withoutsubtractor();
//flake_leaf_half();
//flake_leaf();
// flake();
flakes();
//branch_profile(1,10,1);
//branch_with_rhomoid_at_ends(4,33,5,0);
//flake_leaf_half_withoutsubtractor();
//branch_with_rhomoid_at_ends(4,33,5,0);




