open Graph

type 'a path = 'a arc list 

let clone_nodes g = 
  n_fold g (fun g id -> new_node g id) empty_graph
;;

let gmap g f = 
  e_fold g (fun g arc -> new_arc g { src = arc.src; tgt = arc.tgt; lbl = f arc.lbl }) (clone_nodes g)
;;

let add_arc g id1 id2 n = match (find_arc g id1 id2) with
  | None -> new_arc g { src = id1; tgt = id2; lbl = n }
  | Some arc -> new_arc g { src = id1; tgt = id2; lbl = n + arc.lbl }
;;

exception Path_not_found
(* find a path using parcours en largeur *)
let find_path graph source target = 
  let rec aux queue visited = 
    match queue with
    | [] -> raise Path_not_found
    | (id, path)::queue -> 
      if id = target then List.rev path
      else if List.mem id visited then aux queue visited
      else 
        let new_visited = id::visited in
        let out_arcs = List.filter (fun a -> a.lbl > 0) (out_arcs graph id) in
        let new_queue = List.fold_left (fun acc arc -> (arc.tgt, arc::path)::acc) queue out_arcs in
        (* let new_queue = e_fold graph (fun acc arc -> if arc.src = id then (arc.tgt, arc::path)::acc else acc) queue in *)
        aux new_queue new_visited
  in
  aux [(source, [])] []


let exists_path graph id1 id2 = 
  try ignore (find_path graph id1 id2); true 
  with Path_not_found -> false

let find_minimum_path_capacity path = 
  List.fold_left (fun acc arc -> if arc.lbl < acc then arc.lbl else acc) max_int path

let remove_negative_or_null_capacity graph = 
  e_fold graph (fun g arc -> if arc.lbl <= 0 then g else new_arc g arc) (clone_nodes graph)

let apply_capacity graph path capacity = 
  let create_arcs g arc = 
    let g = add_arc g arc.tgt arc.src capacity in
    let g = new_arc g { src = arc.src; tgt = arc.tgt; lbl = arc.lbl - capacity } in
    g in
  List.fold_left create_arcs graph path

let rec print_path arcs = match arcs with
  | [] -> Printf.printf "\n";
  | [h] -> Printf.printf " (%d,%d)\n" (h.src) (h.tgt);
  | h::t -> Printf.printf " (%d,%d) ->" (h.src) (h.tgt);
    print_path t;
;;

let convert_to_flow_graph original graph = 
  let g = clone_nodes graph in
  e_fold original (fun g max_value -> 
    let flow_value = (find_arc graph max_value.tgt max_value.src) in

    let current_value = match flow_value with
      | None -> 0
      | Some arc -> arc.lbl in

    let opposite_arc = find_arc original max_value.tgt max_value.src in
    let opposite_max_value = match opposite_arc with
      | None -> 0
      | Some arc -> arc.lbl in

    let arc = { src = max_value.src; tgt = max_value.tgt; lbl = (string_of_int (max (current_value-opposite_max_value) 0)) ^ "/" ^ (string_of_int (max_value.lbl)) } in

    let g = new_arc g arc in
    g
  ) (gmap g string_of_int)

(* Biparti matching, students and schools *)

let new_unique_node g = 
  let id = n_fold g (fun acc _ -> acc + 1) 0 in
  id, new_node g id

type school = int
type student = int
type wish = student * school list 

type node = School of school | Student of student | Source | Sink

let sts_source = 0
let sts_sink = 1

(* let get_school = function
  | School(school) -> school
  | _ -> raise (Graph_error "Expected a school node")

let get_student = function
  | Student(student) -> student
  | _ -> raise (Graph_error "Expected a student node") *)

let rec find_school_node_id school_node_ids school = match school_node_ids with
  | [] -> failwith ("School not found " ^ string_of_int school)
  | (id, s)::_ when school = s -> id
  | _::t -> find_school_node_id t school

(* Returns the graph and (id * wish) list *)
let create_students_nodes graph hashtbl wishes school_node_ids =
  List.fold_left (fun (g, acc) (student, schools) -> (
    let id, g = new_unique_node g in
    Hashtbl.add hashtbl id (Student(student));
    g, (id, (student, List.map (find_school_node_id school_node_ids) schools))::acc
  )) (graph, []) wishes

let create_schools_nodes graph hashtbl schools =
  List.fold_left (fun (g, acc) school -> (
    let id, g = new_unique_node g in
    Hashtbl.add hashtbl id (School(school));
    g, (id, school)::acc
  )) (graph, []) schools

let create_students_to_source_arcs graph wish_node_ids =
  List.fold_left (fun g (id, _) -> new_arc g { src = sts_source; tgt = id; lbl = 1 }) graph wish_node_ids

let create_schools_to_sink_arcs graph school_nodes =
  List.fold_left (fun g (id, _) -> new_arc g { src = id; tgt = sts_sink; lbl = 1 }) graph school_nodes

let create_students_to_schools_arcs (graph: 'a graph) wish_node_ids = 
  List.fold_left (fun g (student_node_id, (_, schools_node_ids)) -> 
    List.fold_left (fun g school_node_id -> 
      new_arc g { src = student_node_id; tgt = school_node_id; lbl = 1 }
    ) g schools_node_ids
  ) graph wish_node_ids

let create_graph_from_wishes (wishes: wish list) (schools: school list) =
  let hashtbl = Hashtbl.create (List.length wishes) in

  let graph = empty_graph in

  let graph = new_node graph sts_source in
  Hashtbl.add hashtbl sts_source Source;

  let graph = new_node graph sts_sink in
  Hashtbl.add hashtbl sts_sink Sink;

  (* Create the node of schools *)  
  let graph, school_node_ids = create_schools_nodes graph hashtbl schools in

  (* Create the node of students *)
  let graph, wish_node_ids = create_students_nodes graph hashtbl wishes school_node_ids in

  let graph = create_schools_to_sink_arcs graph school_node_ids in
  let graph = create_students_to_source_arcs graph wish_node_ids in
  let graph = create_students_to_schools_arcs graph wish_node_ids in
  graph, hashtbl

(* Returns id list list, the node are all in the hashtbl (Student, School, Sink or Source) *)
let get_clusters hashtbl = 
  let source,students,schools,sink = Hashtbl.fold (fun id node (source, students, schools, sink) -> match node with
    | Source -> id::source, students, schools, sink
    | Student(_) -> source, id::students, schools, sink
    | School(_) -> source, students, id::schools, sink
    | Sink -> source, students, schools, id::sink
  ) hashtbl ([],[],[],[]) in

  [source;students;schools;sink]

let in_arcs graph id = e_fold graph (fun acc arc -> if arc.tgt = id then arc::acc else acc) []

let print_if b s = if b then Printf.printf "%s\n" s;;