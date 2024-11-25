open Graph

let clone_nodes g = 
  n_fold g (fun g id -> new_node g id) empty_graph
;;

let gmap g f = 
  e_fold g (fun g arc -> new_arc g { src = arc.src; tgt = arc.tgt; lbl = f arc.lbl }) (clone_nodes g)
;;

let add_arc g id1 id2 n = match (find_arc id1 id2) with
  | None -> new_arc g { src = id1; tgt = id2; lbl = n }
  | Some arc -> new_arc g { src = id1; tgt = id2; lbl = n + arc.lbl }
;;
  