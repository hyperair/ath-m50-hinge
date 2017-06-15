use <MCAD/array/mirror.scad>
use <MCAD/array/along_curve.scad>
use <MCAD/shapes/2Dshapes.scad>
include <MCAD/units/metric.scad>

fork_od = 82;
fork_id = 69;
fork_thickness = 7.86;
wall_thickness = 2.3;

hinge_od = 8;

hinge_stub_d = 7;
hinge_stub_h = 1;

hinge_pin_d = 4.9;
hinge_pin_h = 10;

bar_size = [23.87, 28, 7.45];
bar_angle = 15;
center_gap = 14;

/* wedge dimensions on z=0 plane */
wedge_dimensions_z0 = [4, 2, 3];

/* wedge dimensions on y=0 plane */
wedge_dimensions_y0 = [4, 3, 3];


$fs = 0.4;
$fa = 1;

module linear_extrude_if (height, condition = true)
{
    if (condition) {
        linear_extrude (height = height)
        children ();
    } else {
        children ();
    }
}

module c_shape (od, id, h = -1)
{
    linear_extrude_if (height = h, condition = (h > 0))
    difference () {
        circle (d = od);
        circle (d = id);

        translate ([hinge_od / 2, -od / 2])
        square (od);
    }
}

module hinge_pin ()
{
    translate ([0, 0, fork_thickness / 2])
    render ()
    mcad_mirror_duplicate (Y)
    translate ([0, fork_id / 2 - hinge_stub_h + epsilon])
    rotate (90, X)
    difference () {
        cylinder (d = hinge_pin_d, h = hinge_pin_h);

        translate ([0, 0, hinge_pin_h - 1])
        difference () {
            ccube (hinge_pin_d + 1, center = X + Y);

            translate ([0, 0, -epsilon])
            cylinder (d1 = hinge_pin_d, d2 = hinge_pin_d - 2, h = 1);
        }
    }
}

module fork ()
{
    render ()
    difference () {
        /* main fork shape */
        union () {
            c_shape (fork_od, fork_id, fork_thickness);

            /* hinge stub */
            mcad_mirror_duplicate (Y)
            translate ([0, fork_id / 2 + epsilon, fork_thickness / 2])
            rotate (90, X)
            cylinder (d = hinge_stub_d, h = hinge_stub_h);

            /* hinge pin */
            hinge_pin ();

            bar ();
        }

        /* wire channel */
        difference () {
            translate ([0, 0, wall_thickness])
            c_shape (fork_od - wall_thickness * 2,
                     fork_id + wall_thickness * 2,
                     fork_thickness);

            translate ([hinge_od / 2, 0, -epsilon])
            mirror (X)
            ccube ([wall_thickness, fork_od, fork_thickness + epsilon * 2],
                   center = Y);
        }

        /* rounded edge */
        translate (
            [-fork_thickness / 2 + hinge_od / 2, 0, fork_thickness / 2])
        rotate (90, X)
        linear_extrude (height = fork_od + epsilon * 2, center = true)
        difference () {
            translate ([0, -(fork_thickness + epsilon) / 2])
            square (fork_thickness + epsilon * 2);

            circle (d = fork_thickness);
        }

        /* wire channel */
        translate ([0, fork_id / 2 - hinge_stub_h - 1])
        mirror (Y)
        ccube ([1.2, hinge_pin_h, 0.6 * fork_thickness], center = X);

        translate (
            [0, fork_id / 2 + wall_thickness + epsilon, 0.4 * fork_thickness]
        )
        mirror (Y)
        ccube (
            [
                1.2,
                0.4 * hinge_pin_h + wall_thickness + hinge_stub_h,
                0.6 * fork_thickness
            ],
            center = X
        );

        place_bar () {
            translate ([-1.2 / 2, 0.3 * bar_size[1], (bar_size[2] - 1.2) / 2])
            mirror (X) {
                ccube ([bar_size[0], 1.2, 10]);

                translate ([bar_size[0] - 1.2, 1.2, 1.2 / 2])
                mirror (Y)
                ccube ([1.2, 0.2 * bar_size[1], 10]);
            }

            translate ([-bar_size[0], 0, bar_size[2] / 2])
            mirror (Z)
            ccube ([1.2, 0.4 * center_gap, 10], center = X);

            translate ([-bar_size[0], -1, bar_size[2] / 2])
            rotate (-90, X)
            cylinder (d = 1.2, h = 0.3 * bar_size[1]);

            translate ([-bar_size[0], 0, bar_size[2] / 2])
            hull ()
            mcad_linear_multiply (no = 2, separation = 10, axis = Z)
            rotate (-30, Y)
            translate ([0, 0, 2 / 2])
            rotate (90, Y)
            cylinder (d = 2, h = 6, center = true);
        }
    }
}

module place_bar ()
{
    translate ([-fork_od / 2 + 3, 0])
    rotate (bar_angle, Y)
    children ();
}

module wedge_trapezoid (size)
{
    bottom = size[0];
    top = size[1];
    height = size[2];

    linear_extrude (height = 10, center = true)
    trapezoid (bottom = bottom, height = height, top = top);
}

module bar ()
{
    cylinder_h = 7.6;
    cylinder_d1 = 14.23;
    cylinder_d2 = 13;

    shaft_d = 5.5;

    place_bar () {
        render ()
        difference () {
            mirror (X)
            ccube (bar_size, center = Y);

            translate ([-(bar_size[0] - shaft_d / 2 - 5), 0, -epsilon])
            mirror (X)
            ccube ([bar_size[0], center_gap, bar_size[2] + epsilon * 2],
                   center = Y);
        }

        /* wedge */
        translate (
            [
                -(bar_size[0] - shaft_d / 2 - 5),
                0,
                bar_size[2] - wedge_dimensions_y0[0] / 2
            ]
        )
        intersection () {
            rotate (90, Z)
            wedge_trapezoid (wedge_dimensions_z0);

            rotate (90, X)
            rotate (90, Z)
            wedge_trapezoid (wedge_dimensions_y0);
        }

        /* hinge caps */
        translate ([-bar_size[0], 0, bar_size[2] / 2])
        rotate (90, X) {
            mcad_mirror_duplicate (Z)
            translate ([0, 0, center_gap / 2])
            cylinder (d1 = cylinder_d1,
                      d2 = cylinder_d2,
                      h = cylinder_h);

            cylinder (d = shaft_d, h = center_gap + epsilon * 2, center = true);
        }
    }
}


fork ();
