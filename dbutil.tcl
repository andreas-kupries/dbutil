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
	lappend tinfo $entry
    }
    return $tinfo
}

# # ## ### ##### ######## ############# #####################
package provide dbutil 0
return
