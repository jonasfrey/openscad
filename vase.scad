// Function to generate polygon points
function generate_points(num_points = 33, radius = 10) = 
    [ for (n = [0:num_points-1]) 
        [radius * sin(n * 360/num_points), radius * cos(n * 360/num_points)] 
    ];



// Extrude the polygon
linear_extrude(height = 20, twist = 180, slices = 50) {
    polygon(points);
}


for (i = [0:20]){
    polygon_points = generate_points(33, 14+i*2);
    translate([0, 0, i])
    rotate([0,0,i*2])
    // Extrude the polygon to create a 3D object
    // Generate the points

    linear_extrude(height = 1) {
        polygon(points = polygon_points, paths = polygon_path);
    }
}
