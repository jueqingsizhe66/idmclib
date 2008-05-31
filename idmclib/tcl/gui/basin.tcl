#!/bin/sh
#\
exec wish "$0" ${1+"$@"}
source "init.tcl"

set fin [open $argv r]
set ::buffer [read $fin]
close $fin

set model [model_alloc $::buffer]
wm title . "Basins of attraction - [idmc_model_name_get $model]"

##Init input variables
array set ::vEntry [list]
array set ::pEntry [list]
set ::nit 1
set ::ntr 0
set ::xvar 0
set ::yvar 1
set ::xrange(0) 0
set ::xrange(1) 1
set ::xrange(2) 100
set ::yrange(0) 0
set ::yrange(1) 1
set ::yrange(2) 100
##

#root: root pane
#m: loaded model object
proc make_input_pane {root m} {
	set tmp root
	set r [ttk::frame $root$tmp]
	grid $r -row 0 -column 0 -sticky nsew
	grid columnconfigure $root 1 -weight 1; grid rowconfigure $root 0 -weight 1
	set sv "$r.sv"
	set c "$r.c"
	set fr "$r.fr"
	set $sv [ttk::scrollbar $sv -orient vertical -command [list $c yview] ]
	set $c [canvas $c -yscrollcommand [list $sv set]]
	grid $c -column 0 -row 0 -sticky nsew
	grid columnconfigure $r 0 -weight 1; grid rowconfigure $r 0 -weight 1
	grid $sv -column 999 -row 0 -sticky ns

	ttk::frame $fr

	grid [ttk::labelframe "$fr.varfr" -text "variables"] -padx 5 -pady 5 -column 0 -row 0 -sticky nsew
	set ::nvar [idmc_model_var_len_get $m]
	set varnames [idmc_model_var_get $m]
	set vnlist [list]
	array set vids [list]
	for {set i 0} {$i < $::nvar} {incr i} {
		lappend vnlist [stringArray_getitem  $varnames $i]
		set vids([stringArray_getitem  $varnames $i]) i
	}

	for {set i 0} {$i < $::nvar} {incr i} {
		grid [ttk::label "$fr.varfr.lb$i" -text [lindex $vnlist $i]] \
			-column 0 -row $i -sticky ew -padx 5 -pady 5
		grid [ttk::entry "$fr.varfr.entry$i" -textvariable ::vEntry($i)] \
			-column 1 -row $i -sticky e -padx 5 -pady 5
	}

	grid [ttk::labelframe $fr.parfr -text "parameters"] -padx 5 -pady 5 -column 0 -row 1 -sticky nsew
	set ::npar [idmc_model_par_len_get $m]
	set parnames [idmc_model_par_get $m]
	for {set i 0} {$i < $::npar} {incr i} {
		grid [ttk::label "$fr.parfr.lb$i" -text [stringArray_getitem  $parnames $i]] \
			-column 0 -row $i -sticky ew -padx 5 -pady 5
		grid [ttk::entry "$fr.parfr.entry$i" -textvariable ::pEntry($i)] \
			-column 1 -row $i -sticky e -padx 5 -pady 5
	}
	
	grid [ttk::labelframe "$fr.nitfr" -text "algorithm"] -padx 5 -pady 5 -column 0 -row 2 -sticky nsew
	grid [ttk::label "$fr.nitfr.lbNit" -text "iterations"] \
		-column 0 -row 0 -sticky ew -padx 5 -pady 5
	grid [ttk::entry "$fr.nitfr.entryNit" -textvariable ::nit] \
		-column 1 -row 0 -sticky e -padx 5 -pady 5
	grid [ttk::label "$fr.nitfr.lbTr" -text "transient"] \
		-column 0 -row 1 -sticky ew -padx 5 -pady 5
	grid [ttk::entry "$fr.nitfr.entryTr" -textvariable ::ntr] \
		-column 1 -row 1 -sticky e -padx 5 -pady 5

	set ::xvar-display [lindex $vnlist 0]
	grid [ttk::label "$fr.nitfr.lbxv" -text "x axis"] \
		-column 0 -row 2 -sticky ew -padx 5 -pady 5
	grid [ttk::combobox "$fr.nitfr.entryXv" -state readonly -textvariable ::xvar-display] \
		-column 1 -row 2 -sticky e -padx 5 -pady 5
	"$fr.nitfr.entryXv" configure -values $vnlist
	set ::yvar-display [lindex $vnlist 1]
	grid [ttk::label "$fr.nitfr.lbyv" -text "x axis"] \
		-column 0 -row 3 -sticky ew -padx 5 -pady 5
	grid [ttk::combobox "$fr.nitfr.entryYv" -state readonly -textvariable ::yvar-display] \
		-column 1 -row 3 -sticky e -padx 5 -pady 5
	"$fr.nitfr.entryYv" configure -values $vnlist

	$c create window 10 10 -window $fr -anchor nw

	update
	$c configure -scrollregion [$c bbox all]
	set tmp [$c bbox all]
	$c configure -width [expr [lindex $tmp 2] - [lindex $tmp 0] ]
}

make_input_pane . $model
grid [ttk::frame .frmBttns] -row 1 -column 0 -sticky sew
grid [ttk::button .frmBttns.bttnDraw -text Draw -command onDraw] -row 0 -column 0 -padx 5 -pady 5 -sticky w
grid columnconfigure .frmBttns 0 -weight 1; grid columnconfigure .frmBttns 1 -weight 1
grid rowconfigure .frmBttns 0 -weight 1

grid [canvas .c] -row 0 -column 1 -sticky nsew -rowspan 2
set argv0 ""
source gnuplot.tcl
set ::canvas .c

proc onDraw {} {
	set ::worker [open "|tclsh traj.tcl $::argv" r+]
	for {set i 0} {$i < $::nvar} {incr i} {
		eval "puts $::worker $[lindex $::vEntry $i]"
	}
	for {set i 0} {$i < $::npar} {incr i} {
		eval "puts $::worker $[lindex $::pEntry $i]"
	}
	puts $::worker $::niter
	flush $::worker
	gpcmd "plot '-' with lines"
	fileevent $::worker readable {
		set tmp [gets $::worker]
		if [eof $::worker] {
			gpcmd "e"
			#fix this!
			after 100
			gpdraw
			close $::worker
		} else {
			gpcmd $tmp
		}
	}
}
