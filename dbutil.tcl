# -*- tcl -*-
## (c) 2013 Andreas Kupries
# # ## ### ##### ######## ############# #####################

## sqlite3 specific database utilities to query and manipulate a
## database schema.

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

proc dbutil::initialize-schema {db evar args} {
    upvar 1 $evar reason
    # args = schema = dict (table -> def)
    # where def = list (sql, table-info-spec)

    dict for {table def} $args {
	lassign $def sql info
	if {[has $db $table]} {
	    return [check $db $table $info reason]
	}
	$db transaction {
	    $db eval "CREATE TABLE \"$table\" ( $sql )"
	}
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
