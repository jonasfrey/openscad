module rhombus(w, l) {
    // Create rhombus centered at origin
    rhombus_points = [
        [-w/2, 0],    // left
        [0, l/2],     // top  
        [w/2, 0],     // right
        [0, -l/2]     // bottom
    ];
    polygon(points = rhombus_points, paths = [[0,1,2,3]]);
}

// Now rotation works as expected around the center
rotate([0, 0, 45])
    translate([20, 40, 0])
        linear_extrude(2) {
            rhombus(10, 20);
        }