# a simple sql querier with database aliases
# $env.sql_aliases_path - path to an empty file to which alias data is to be written

module "sql" {    
    def aliases [] { open $env.sql_aliases_path | from json | columns }

    def from_json_maybe_empty [] {
        if $in == "" {
            "{}"
        } else {
            $in
        } | from json
    }

    # Add database dsn alias to alias list
    export def-env "add" [
        alias: string
        dsn: string # database dsn (format: `pg://user:pass@host/dbname`)
    ] {
        open $env.sql_aliases_path | from_json_maybe_empty | upsert $alias $dsn | to text | save -f $env.sql_aliases_path
    }

    # Remove database dsn alias from alias list
    export def-env "remove" [alias: string@aliases] {
        open $env.sql_aliases_path | from_json_maybe_empty | reject $alias | to text | save -f $env.sql_aliases_path
    }

    # List database dsn aliases
    export def-env "list" [] {
        open $env.sql_aliases_path | from_json_maybe_empty 
    }    
    
    # Query database by alias
    export def-env "q" [alias: string@aliases, query: string] {
        open $env.sql_aliases_path | from_json_maybe_empty | get $alias | usql $"($in)?sslmode=disable" -c $query -J -q | from json
    }
}