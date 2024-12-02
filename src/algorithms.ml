open Tools
open Graph

let ford_fulkerson graph source sink step =
  step graph 0;
  let rec ford_fulkerson_counter graph flow i =
    try 
      Printf.printf "FF: Finding path...\n%!";
      let path = find_path graph source sink in
      Printf.printf "FF: Path found\n%!";
      let capacity = find_minimum_path_capacity path in
      Printf.printf "FF: Capacity found: %d\n%!" capacity;
      let graph = apply_capacity graph path capacity in
      Printf.printf "FF: Capacity applied\n%!";
      let graph = remove_negative_or_null_capacity graph in
      Printf.printf "FF: Capacity removed\n%!";
      let flow = flow + capacity in

      step graph i;
      ford_fulkerson_counter graph flow (i + 1)
    with
      | Path_not_found -> flow, graph

  in ford_fulkerson_counter graph 0 1

let students_to_schools wishes schools = 
  Printf.printf "Creating graph...\n%!";
  let graph, hashtbl = create_graph_from_wishes wishes schools in
  let students_node_ids = Hashtbl.fold (fun id node acc -> match node with
    | Student(student) -> (id, student)::acc
    | _ -> acc
  ) hashtbl [] in

  Printf.printf "Running Ford Fulkerson...\n%!";

  let _, graph = ford_fulkerson graph source sink (fun _ i -> (
    Printf.printf "Step %d\n%!" i;
  )) in


  Printf.printf "Computing students to schools...\n%!";

  (* Get all in_arcs of students_nodes, should be one in_arc per students that is a School or less *)
  let students_in_arcs = List.fold_left (fun acc (id, student) -> 
    (id, student, in_arcs graph id)::acc
  ) [] students_node_ids in

  Printf.printf "Computing students to schools...\n%!";

  (* Get the unique school in the in_arcs *)
  let students_schools = List.fold_left (fun acc (_, student, arcs) ->
    let schools = List.fold_left (fun acc arc -> match Hashtbl.find hashtbl arc.src with
        | School(school) -> Some school
        | _ -> acc
    ) None arcs in
    (student, schools)::acc
  ) [] students_in_arcs in

  (* Get the unique schools *)
    students_schools