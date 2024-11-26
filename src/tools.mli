open Graph

type 'a path = 'a arc list 

val clone_nodes: 'a graph -> 'b graph
val gmap: 'a graph -> ('a -> 'b) -> 'b graph
val add_arc: int graph -> id -> id -> int -> int graph

exception Path_not_found

val find_path: 'a graph -> id -> id -> 'a path
val exists_path: 'a graph -> id -> id -> bool
val print_path: 'a path -> unit