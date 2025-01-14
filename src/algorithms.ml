open Tools
open Graph
open Gfile
open Options

let ford_fulkerson graph source sink step = step graph 0;
  let rec ford_fulkerson_counter graph flow i =
    try 
      let path = find_path graph source sink in
      if !debug then (print_string "Path:"; print_path path;);

      let capacity = find_minimum_path_capacity path in
      if !debug then Printf.printf "Capacity: %d\n" capacity;

      let graph = apply_capacity graph path capacity in

      let flow = flow + capacity in
      if !debug then Printf.printf "Flow: %d\n" flow;

      step graph i;
      ford_fulkerson_counter graph flow (i + 1)
    with
    | Path_not_found -> flow, remove_negative_or_null_capacity graph

  in ford_fulkerson_counter graph 0 1

let students_to_schools wishes schools = 
  let graph, hashtbl = create_graph_from_wishes wishes schools in
  let students_node_ids = Hashtbl.fold (fun id node acc -> match node with
      | Student(student) -> (id, student)::acc
      | _ -> acc
    ) hashtbl [] in
  let clusters = get_clusters hashtbl in

  if !debug then begin
    Printf.printf "\nGraph created, here is nodes association:\n";
    Hashtbl.iter (fun id node -> Printf.printf "Node %d: %s\n" id (match node with
        | School(school) -> "School " ^ string_of_int school
        | Student(student) -> "Student " ^ string_of_int student
        | Source -> "Source"
        | Sink -> "Sink"
      )) hashtbl;

    Printf.printf "\nClusters:\n";
    List.iter (fun cluster -> List.iter (fun id -> Printf.printf "%d " id) cluster; Printf.printf "\n") clusters;
  end;

  if !debug then Printf.printf "Computing students to schools (applying ford fulkerson)...\n%!";

  let _, egraph = ford_fulkerson graph sts_source sts_sink (fun current_graph i -> (
        print_if !debug ("\nRunning Ford Fulkerson algorithm (step " ^ (string_of_int i) ^ ")...");

        if (Option.is_some !verbose) then begin
          print_if !debug ("✻ Intermediate graph exported at step " ^ (Option.get !verbose) ^ "/" ^  string_of_int i ^ ".dot\n");
          let end_graph = convert_to_flow_graph graph current_graph in
          export_with_clusters ((Option.get (!verbose)) ^ "/" ^ string_of_int i ^ ".dot") end_graph clusters;

          if (Option.is_some !svg_outfile) then begin
            print_if !debug ("✻ Intermediate graph exported at step " ^ (Option.get !verbose) ^ "/" ^  string_of_int i ^ ".svg\n");
            from_dot_to_svg ((Option.get (!verbose)) ^ "/" ^ string_of_int i ^ ".dot") ((Option.get (!verbose)) ^ "/" ^ string_of_int i ^ ".svg");
          end;

          if (Option.is_some !png_outfile) then begin
            print_if !debug ("✻ Intermediate graph exported at step " ^ (Option.get !verbose) ^ "/" ^  string_of_int i ^ ".png\n");
            from_dot_to_png ((Option.get (!verbose)) ^ "/" ^ string_of_int i ^ ".dot") ((Option.get (!verbose)) ^ "/" ^ string_of_int i ^ ".png");
          end;
        end;

      )) in

  if !debug then Printf.printf "Computing students to schools...\n%!";

  (* Get all in_arcs of students_nodes, should be one in_arc per students that is a School or less *)
  let students_in_arcs = List.fold_left (fun acc (id, student) -> 
      (id, student, in_arcs egraph id)::acc
    ) [] students_node_ids in

  if !debug then Printf.printf "Computing students to schools...\n%!";

  (* Get the unique school in the in_arcs *)
  let students_schools = List.fold_left (fun acc (_, student, arcs) ->
      let schools = List.fold_left (fun acc arc -> match Hashtbl.find hashtbl arc.src with
          | School(school) -> Some school
          | _ -> acc
        ) None arcs in
      (student, schools)::acc
    ) [] students_in_arcs in

  (* Get the unique schools *)
  students_schools, graph, egraph, clusters