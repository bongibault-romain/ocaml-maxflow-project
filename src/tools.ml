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
  
let find_path graph id1 id2 = 
  let rec find_path_acc graph id1 id2 marked =
    (* todo: marked node do not persists when a tested path fail *)
    let rec loop arcs = match arcs with
    | [] -> raise Path_not_found
    | arc::_ when arc.tgt = id2 -> [arc]
    | arc::t when List.mem arc.tgt marked -> loop t;
    | arc::t -> try arc::(find_path_acc graph (arc.tgt) id2 ((arc.src)::marked)) 
                with Path_not_found -> (loop t)
    in loop (out_arcs graph id1)
  in find_path_acc graph id1 id2 [id1]
;;

let exists_path graph id1 id2 = 
  try ignore (find_path graph id1 id2); true 
  with Path_not_found -> false

let find_minimum_path_capacity path = 
  List.fold_left (fun acc arc -> if arc.lbl < acc then arc.lbl else acc) max_int path

let remove_negative_or_null_capacity graph = 
  e_fold graph (fun g arc -> if arc.lbl <= 0 then g else new_arc g arc) (clone_nodes graph)

let apply_capacity graph path capacity = 
  let create_arcs g arc = add_arc (new_arc g { src = arc.src; tgt = arc.tgt; lbl = arc.lbl - capacity }) arc.tgt arc.src capacity in
  List.fold_left create_arcs graph path

let rec print_path arcs = match arcs with
  | [] -> Printf.printf "\n";
  | [h] -> Printf.printf " (%d,%d)\n" (h.src) (h.tgt);
  | h::t -> Printf.printf " (%d,%d) ->" (h.src) (h.tgt);
    print_path t;
;;


(* Biparti matching, students and schools *)

let new_unique_node g = 
  let id = n_fold g (fun acc _ -> acc + 1) 0 in
  id, new_node g id

type school = int
type student = int
type wish = student * school list 

type node = School of school | Student of student | Source | Sink

let source = -1
let sink = -2

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
  List.fold_left (fun g (id, _) -> new_arc g { src = -1; tgt = id; lbl = 1 }) graph wish_node_ids

let create_schools_to_sink_arcs graph school_nodes =
  List.fold_left (fun g (id, _) -> new_arc g { src = id; tgt = -2; lbl = 1 }) graph school_nodes

let create_students_to_schools_arcs (graph: 'a graph) wish_node_ids = 
  List.fold_left (fun g (student_node_id, (_, schools_node_ids)) -> 
    List.fold_left (fun g school_node_id -> 
      new_arc g { src = student_node_id; tgt = school_node_id; lbl = 1 }
    ) g schools_node_ids
  ) graph wish_node_ids

let create_graph_from_wishes (wishes: wish list) (schools: school list) =
  let hashtbl = Hashtbl.create (List.length wishes) in

  let graph = empty_graph in

  let graph = new_node graph source in
  Hashtbl.add hashtbl source Source;

  let graph = new_node graph sink in
  Hashtbl.add hashtbl sink Sink;

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