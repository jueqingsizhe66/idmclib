#!/usr/bin/tclsh
source "./init.tcl"
source "./misc_util.tcl"

set bs [allocBasin basin_test1.lua "1 1 5 5 1 5 4" "-4 9 100" "-4 9 100"\
	1e-4 2 2 20 "0 1" "0 0 0 0"]
llength [set attr_list [find_attractors $bs]]
stopifnot "![string compare $attr_list\
	{{{1.0 5.0 0.0 0.0}} {{1.0 1.0 0.0 0.0}} {{5.0 5.0 0.0 0.0}}}]"
idmc_basin_multi_free $bs

#TEST CASE 2: sensible variables are the 3rd and 4th ones
set bs [allocBasin basin_test2.lua "1 1 5 5 1 5 4" "-4 9 100" "-4 9 100"\
	1e-4 2 2 20 "1 3" "0 0 0 0"]
llength [set attr_list [find_attractors $bs]]
stopifnot "![string compare $attr_list\
	{{{0.0 1.0 0.0 5.0}} {{0.0 1.0 0.0 1.0}} {{0.0 5.0 0.0 5.0}}}]"
idmc_basin_multi_free $bs

#TEST CASE 3: VERIFY BASINS FILLING
set bs [allocBasin basin_test1.lua "1 1 2 2 3 1 0.499" "0 4 8" "0 2 4"\
	1e-4 2 2 40 "0 1" "0 0 0 0"]
stopifnot "![string compare [basin2stringmatrix $bs] {0 0 0 0
0 0 0 0
0 0 0 0
0 0 0 0
0 0 0 0
0 0 0 0
0 0 0 0
0 0 0 0}]"
llength [set attr_list [find_attractors $bs]]
stopifnot "![string compare $attr_list\
	{{{1.0 1.0 0.0 0.0}} {{2.0 2.0 0.0 0.0}} {{3.0 1.0 0.0 0.0}}}]"

set i 0
while {![idmc_basin_multi_finished $bs]} {
	idmc_basin_multi_step $bs
	stopifnot "($i < 32)"
	incr i
}

set r [idmc_basin_multi_raster_get $bs]
stopifnot "[idmc_raster_getxy $r 1.0 1.0] == 3"
stopifnot "[idmc_raster_getxy $r 2.0 1.999] == 5"
stopifnot "[idmc_raster_getxy $r 3.0 1.0] == 7"
stopifnot "[idmc_raster_getxy $r 1.0 1.4999] == 3"
stopifnot "[idmc_raster_getxy $r 1.0 1.5] == 1"
stopifnot "[idmc_raster_getxy $r 2.501 1.0] == 7"
stopifnot "[idmc_raster_getxy $r 0.499 0.499] == 1"
stopifnot "[idmc_raster_getxy $r 0.501 0.501] == 3"

idmc_basin_multi_free $bs

#TEST CASE 4: VERIFY BASINS FILLING (with invariant curves)
set bs [allocBasin basin_test3.lua "1 0.49" "-2 2 8" "-2 2 8"\
	1e-3 10 10 20 "0 1" "0 0 0 0"]
llength [set attr_list [find_attractors $bs]]

set i 0
while {![idmc_basin_multi_finished $bs]} {
	idmc_basin_multi_step $bs
	stopifnot "$i < 65"
	incr i
}
set r [idmc_basin_multi_raster_get $bs]

stopifnot "![string compare [lindex $attr_list 3] {{0.0 0.0 0.0 0.0}}]"
stopifnot "![string compare [basin2stringmatrix $bs]\
{1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 9 9 1 1 1
1 1 1 9 9 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1}]"

idmc_basin_multi_free $bs
