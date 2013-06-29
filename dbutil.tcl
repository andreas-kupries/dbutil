# -*- tcl -*-
## (c) 2013 Andreas Kupries
# # ## ### ##### ######## ############# #####################

## sqlite3 specific database utilities to query and manipulate a
## database schema.

# @@ Meta Begin
# Package dbutil 0
# Meta author   {Andreas Kupries}
# Meta location https://core.tcl.tk/akupries/dbutil
# Meta platform tcl
# Meta summary Sqlite3 database utility commands.
# Meta description Utilities to quickly initialize and
# Meta description check schemata in sqlite3 databases.
# Meta subject sqlite database relation table index
# Meta require {Tcl 8.5-}
# Meta require sqlite3
# Meta category Database
# @@ Meta End

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require sqlite3

namespace eval dbutil {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################

proc dbutil::has {db table} {
    $db exists {
	SELECT name
	FROM  sqlite_master 
	WHERE type = 'table'
	AND   name = :table
    }
}

proc dbutil::table_info {db table} {
    set tinfo {}
    $db eval "PRAGMA table_info($table)" ti {
	set entry [array get ti]
	dict unset entry *
	# fields:
	# cid
	# name
	# type
	# notnull
	# dflt_value
	# pk
	dict with entry {} ; # => fields as variables.
	lappend tinfo [list $name $type $notnull $dflt_value $pk]
    }
    return $tinfo
}

proc dbutil::check {db table spec evar} {
    upvar 1 $evar reason
    set ti [table_info $db $table]
    set nex [llength $spec]
    set nis [llength $ti]
    if {$nis != $nex} {
	set reason "Expected $nex columns, got $nis"
	return 0
    }
    foreach entry $ti sentry $spec {
	if {![Match $table $entry $sentry reason]} { return 0 }
    }
    return 1
}

proc dbutil::setup {db table sql {indices {}}} {
    $db transaction {
	$db eval "CREATE TABLE \"$table\" ( $sql )"
	set counter 0
	foreach columnlist $indices {
	    $db eval "CREATE INDEX \"${table}$counter\" ON \"$table\" ( [join $columnlist ,] )"
	    incr counter
	}
    }
    return
}

proc dbutil::initialize-schema {db evar args} {
    upvar 1 $evar reason
    # args = schema = dict (table -> def)
    # where def = list (sql, table-info-spec)

    # args = dict (table-name --> table-definition)
    # table-definition = list (sql-for-create
    #                          table-info-for-check
    #                          indices)

    dict for {table def} $args {
	lassign $def sql info indices
	if {[has $db $table]} {
	    return [check $db $table $info reason]
	}
	setup $db $table $sql $indices
    }
    return 1
}

# # ## ### ##### ######## ############# #####################

proc dbutil::Match {table entry spec evar} {
    upvar 1 $evar reason

    foreach e $entry s $spec l {name type notnull dflt_value pk} {
	set $l $e
	if {![string match $s $e]} {
	    if {[info exists name]} {
		set reason "$table.$name: $l mismatch. Expected \"$s\", got \"$e\""
	    } else {
		set reason "$table: $l mismatch. Expected \"$s\", got \"$e\""
	    }
	    return 0
	}
    }
    return 1
}

# # ## ### ##### ######## ############# #####################
package provide dbutil 0
return
