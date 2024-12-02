open Graph

type 'a path = 'a arc list 

val clone_nodes: 'a graph -> 'b graph
val gmap: 'a graph -> ('a -> 'b) -> 'b graph
val add_arc: int graph -> id -> id -> int -> int graph

exception Path_not_found

(* Find a path in graph from id1 to id2 
* @raise Path_not_found if no path found *)
val find_path: 'a graph -> id -> id -> 'a path
  
(* Check if a path exists in graph from id1 to id2 *)
val exists_path: 'a graph -> id -> id -> bool

(* Find the minimum capacity of a path *)
val find_minimum_path_capacity: id path -> id
    
(* Remove all arcs with negative or null capacity *)
val remove_negative_or_null_capacity: id graph -> id graph

(* Add and subtract capacity *)
val apply_capacity: id graph -> id path -> id -> id graph

(* Print a path *)
val print_path: 'a path -> unit

(* Biparti matching, students and schools *)

(* Create a new node, returns its id and the graph *)
val new_unique_node: 'a graph -> id * 'a graph

type school = int
type student = int
type wish = student * school list 

type node = School of school | Student of student | Source | Sink

val sink: int
val source: int

(* Biparti matching, students and schools *)

val in_arcs: 'a graph -> id -> 'a arc list

val create_graph_from_wishes: wish list -> school list -> (id graph * (id, node) Hashtbl.t)

val get_clusters: (id, node) Hashtbl.t -> id list list