open Graph
open Printf

type path = string

(* Format of text files:
   % This is a comment

   % A node with its coordinates (which are not used), and its id.
   n 88.8 209.7 0
   n 408.9 183.0 1

   % Edges: e source dest label id  (the edge id is not used).
   e 3 1 11 0 
   e 0 2 8 1

*)

(* Compute arbitrary position for a node. Center is 300,300 *)
let iof = int_of_float
let foi = float_of_int

let index_i id = iof (sqrt (foi id *. 1.1))

let compute_x id = 20 + 180 * index_i id

let compute_y id =
  let i0 = index_i id in
  let delta = id - (i0 * i0 * 10 / 11) in
  let sgn = if delta mod 2 = 0 then -1 else 1 in

  300 + sgn * (delta / 2) * 100


let write_file path graph =

  (* Open a write-file. *)
  let ff = open_out path in

  (* Write in this file. *)
  fprintf ff "%% This is a graph.\n\n" ;

  (* Write all nodes (with fake coordinates) *)
  n_iter_sorted graph (fun id -> fprintf ff "n %d %d %d\n" (compute_x id) (compute_y id) id) ;
  fprintf ff "\n" ;

  (* Write all arcs *)
  let _ = e_fold graph (fun count arc -> fprintf ff "e %d %d %d %s\n" arc.src arc.tgt count arc.lbl ; count + 1) 0 in

  fprintf ff "\n%% End of graph\n" ;

  close_out ff ;
  ()

let create_missing_directories path =
  let rec create_missing_directories_rec path =
    if not (Sys.file_exists path) then
      create_missing_directories_rec (Filename.dirname path);
    if not (Sys.file_exists path) then
      Sys.mkdir path 0o777
  in
  create_missing_directories_rec path

let export path graph =
  create_missing_directories (Filename.dirname path);

  (* Open a write-file *)
  let ff = open_out path in

  (* Write in this file. *)
  fprintf ff "digraph exported_graph {\n\tfontname=\"Helvetica,Arial,sans-serif\"\n\tnode [fontname=\"Helvetica,Arial,sans-serif\"]\n\tedge [fontname=\"Helvetica,Arial,sans-serif\"]\n\trankdir = BT;\n\tsplines = false;\n\tnode [shape = circle];";

  (* Write all nodes *)
  e_iter graph (fun arc -> fprintf ff "\n\t%d -> %d [label = \"%s\"]" (arc.src) (arc.tgt) (arc.lbl)) ;
  fprintf ff "\n}" ;

  close_out ff;
  ()

let export_with_clusters path graph clusters =
  create_missing_directories (Filename.dirname path);

  (* Open a write-file *)
  let ff = open_out path in

  (* Write in this file. *)
  fprintf ff "digraph exported_graph {\n\tfontname=\"Helvetica,Arial,sans-serif\"\n\tnode [fontname=\"Helvetica,Arial,sans-serif\"]\n\tedge [fontname=\"Helvetica,Arial,sans-serif\"];\n\trankdir = BT;\n\tsplines = false;\n\tnode [shape = circle];";

  (* Write all nodes *)
  e_iter graph (fun arc -> fprintf ff "\n\t%d -> %d [label = \"%s\"]" (arc.src) (arc.tgt) (arc.lbl)) ;

  (* Write all clusters *)
  List.iter (fun (cluster) -> 
      fprintf ff "\n\tsubgraph {\n\t\trank = same;\n\t\tcolor = transparent;\n";
      fprintf ff "\t\t" ;
      List.iter (fun node -> fprintf ff "%d; " node) cluster;  
      fprintf ff "\n\t}"
    ) clusters ;

  fprintf ff "\n}" ;

  close_out ff;
  ()

(* Reads a line with a node. *)
let read_node graph line =
  try Scanf.sscanf line "n %f %f %d" (fun _ _ id -> new_node graph id)
  with e ->
    Printf.printf "Cannot read node in line - %s:\n%s\n%!" (Printexc.to_string e) line ;
    failwith "from_file"

(* Ensure that the given node exists in the graph. If not, create it. 
 * (Necessary because the website we use to create online graphs does not generate correct files when some nodes have been deleted.) *)
let ensure graph id = if node_exists graph id then graph else new_node graph id

(* Reads a line with an arc. *)
let read_arc graph line =
  try Scanf.sscanf line "e %d %d %_d %s@%%"
        (fun src tgt lbl -> let lbl = String.trim lbl in new_arc (ensure (ensure graph src) tgt) { src ; tgt ; lbl } )
  with e ->
    Printf.printf "Cannot read arc in line - %s:\n%s\n%!" (Printexc.to_string e) line ;
    failwith "from_file"

(* Reads a comment or fail. *)
let read_comment graph line =
  try Scanf.sscanf line " %%" graph
  with _ ->
    Printf.printf "Unknown line:\n%s\n%!" line ;
    failwith "from_file"

let from_file path =

  let infile = open_in path in

  (* Read all lines until end of file. *)
  let rec loop graph =
    try
      let line = input_line infile in

      (* Remove leading and trailing spaces. *)
      let line = String.trim line in

      let graph2 =
        (* Ignore empty lines *)
        if line = "" then graph

        (* The first character of a line determines its content : n or e. *)
        else match line.[0] with
          | 'n' -> read_node graph line
          | 'e' -> read_arc graph line

          (* It should be a comment, otherwise we complain. *)
          | _ -> read_comment graph line
      in      
      loop graph2

    with End_of_file -> graph (* Done *)
  in

  let final_graph = loop empty_graph in

  close_in infile ;
  final_graph

let rec read_schools_by_two list = match list with
  | [] -> []
  | a::b::tl -> (a, b)::(read_schools_by_two tl)
  | _ -> failwith "read_schools_by_two: odd number of schools"

let read_schools line =
  let schools = String.split_on_char ' ' line in
  read_schools_by_two (List.map int_of_string schools)

let read_wishes line =
  let wishes = String.split_on_char ' ' line in
  let id = int_of_string (List.hd wishes) in
  let wishes = List.tl wishes in
  id, List.map int_of_string wishes 

let from_file_wishes path = 
  let infile = open_in path in 

  let line = input_line infile in
  let schools = read_schools line in

  let rec loop students =
    try 
      let line = input_line infile in
      (* read the first int of the line *)
      let student = read_wishes line in
      loop (student::students)
    with End_of_file -> students

  in let students = loop [] in

  close_in infile;
  students, schools

let from_dot_to_png infile outfile = 
  let command = "dot -Tpng " ^ infile ^ " > " ^ outfile in
  ignore (Sys.command command)

let from_dot_to_svg infile outfile = 
  let command = "dot -Tsvg " ^ infile ^ " > " ^ outfile in
  ignore (Sys.command command)

let remove_trailing_slash path = 
  let len = String.length path in
  if path.[len - 1] = '/' then String.sub path 0 (len - 1) else path