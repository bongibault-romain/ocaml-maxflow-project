open Graph
open Tools

val ford_fulkerson: id graph -> id -> id -> (id graph -> int -> unit) -> int * id graph

val students_to_schools: wish list -> school list -> ((student * school option) list * (id graph) * (id graph) * (id list list))