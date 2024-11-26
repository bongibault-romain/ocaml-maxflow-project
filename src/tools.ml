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
  
let rec find_path graph id1 id2 =
  let rec loop arcs = match arcs with
    | [] -> raise Path_not_found
    | arc::_ when arc.tgt = id2 -> [arc]
    | arc::t -> try arc::(find_path graph (arc.tgt) id2) with Path_not_found -> (loop t)
  in
  loop (out_arcs graph id1)
;;

let exists_path graph id1 id2 = try ignore (find_path graph id1 id2); true with Path_not_found -> false

let rec print_path arcs = match arcs with
  | [] -> Printf.printf "\n";
  | [h] -> Printf.printf " (%d,%d)\n" (h.src) (h.tgt);
  | h::t -> Printf.printf " (%d,%d) ->" (h.src) (h.tgt);
    print_path t;
;;