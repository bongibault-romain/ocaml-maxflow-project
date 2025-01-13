open Gfile
open Tools
open Algorithms

let verbose = ref None
let outfile = ref None
let svg_outfile = ref None
let png_outfile = ref None
let infile = ref None
let ford_fulkerson_source = ref None
let ford_fulkerson_sink = ref None
let debug = ref false
let biparti = ref false

let usage = 
  "\n✻ Usage: %s [OPTIONS]... [INFILE] -o [OUTFILE]" ^ Sys.argv.(0)
  ^ ("\n\n🟄  INFILE   : input file containing a graph\n\n")
  ^ ("🟄  OPTIONS:\n")
;;

let anonymous filename =
  infile := Some filename

let speclist = [
  ("-v", Arg.String (fun s -> verbose := Some (remove_trailing_slash s)), "[DIRECTORY]\n    Verbose mode, export all steps of the algorithm in DIRECTORY\n");
  ("-dot", Arg.String (fun s -> outfile := Some (remove_trailing_slash s)), "[OUTFILE]\n    Output file in which the result should be written in DOT format.\n");
  ("-svg", Arg.String (fun s -> svg_outfile := Some (remove_trailing_slash s)), "[OUTFILE]\n    Output file in which the result should be written in SVG format.\n");
  ("-png", Arg.String (fun s -> png_outfile := Some (remove_trailing_slash s)), "[OUTFILE]\n    Output file in which the result should be written in PNG format.\n");
  ("-d", Arg.Unit (fun _ -> debug := true), "Debug mode, more information will be printed\n");
  ("-f", Arg.Tuple [Arg.Int (fun i -> ford_fulkerson_source := Some i); Arg.Int (fun i -> ford_fulkerson_sink := Some i)],  "[SOURCE] [SINK]\n    Launch ford fulkerson algorithm, SOURCE and SINK are the source and sink nodes.\n");
  ("-b", Arg.Unit (fun _ -> biparti := true), "Launch students-to-school assignation algorithm");
]

let validate_args () =
  match !infile with
  | None -> Printf.printf "Error: no input file specified\n"; exit 1
  | Some _ -> ();
    (* ensure not -f and -b at the same time *)
    match (!ford_fulkerson_sink, !ford_fulkerson_source, !biparti) with
    | (Some _, Some _, true) -> Printf.printf "Error: -f and -b cannot be used at the same time\n"; exit 1
    | _ -> ();
      (* -svg or -png needs -dot to be executed *)
      match (!svg_outfile, !png_outfile, !outfile) with
      | (Some _, _, None) 
      | (_, Some _, None) -> Printf.printf "Error: -svg or -png options need -dot option to be executed\n"; exit 1
      | _ -> ()

let () =
  Arg.parse speclist anonymous usage;

  validate_args ();

  match (!ford_fulkerson_sink, !ford_fulkerson_source) with
  | (Some sink, Some source) -> 
    print_if !debug ("Reading input file (" ^ (Option.get (!infile)) ^ ")...\n");

    let sgraph = from_file (Option.get !infile) in
    let graph = gmap sgraph int_of_string in

    print_if !debug ("Running Ford Fulkerson algorithm...");
    let flow, end_graph = ford_fulkerson graph source sink (fun current_graph i -> (
          print_if !debug ("\nRunning Ford Fulkerson algorithm (step " ^ (string_of_int i) ^ ")...");

          if (Option.is_some !verbose) then begin
            print_if !debug ("✻ Intermediate graph exported at step " ^ (Option.get !verbose) ^ "/" ^  string_of_int i ^ ".dot\n");
            let end_graph = convert_to_flow_graph graph current_graph in
            export ((Option.get (!verbose)) ^ "/" ^ string_of_int i ^ ".dot") end_graph;

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
    let end_graph = convert_to_flow_graph graph end_graph in

    (* Beautiful print result *)
    Printf.printf "\n✻ Max flow: %d\n" flow;

    if (Option.is_some !outfile) then begin
      Printf.printf "✻ Graph exported at %s\n" (Option.get !outfile);
      export (Option.get !outfile) end_graph;

      if (Option.is_some !svg_outfile) then begin
        Printf.printf "✻ Graph exported at %s\n" (Option.get !svg_outfile);
        from_dot_to_svg (Option.get !outfile) (Option.get !svg_outfile);
      end;

      if (Option.is_some !png_outfile) then begin
        Printf.printf "✻ Graph exported at %s\n" (Option.get !png_outfile);
        from_dot_to_png (Option.get !outfile) (Option.get !png_outfile);
      end;
    end;

    Printf.printf "\n";

  | _ -> ();

    if !biparti then begin
      print_if !debug ("Running students-to-school assignation algorithm...");
      print_if !debug ("Reading wishes file (" ^ (Option.get (!infile)) ^ ")...\n");
      let students, schools = from_file_wishes (Option.get !infile) in

      print_if !debug ("Creating biparti graph...\n");

      if !debug then begin
        Printf.printf "Schools: \n";
        List.iter (fun school -> Printf.printf "%d " school) schools;
        Printf.printf "\n\n";

        Printf.printf "Students: \n";
        List.iter (fun (student, wishes) -> Printf.printf "id: %d, wishes: " student; List.iter (fun wish -> Printf.printf "%d " wish) wishes; Printf.printf "\n") students;
      end;

      let _graph, hashtbl = create_graph_from_wishes students schools in
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

      (* let flow, graph = ford_fulkerson graph sts_source sts_sink step in

         () *)


    end;

    (* 
  (* Arguments are : infile(1) source-id(2) sink-id(3) outfile(4) *)

  let _infile = Sys.argv.(1)
  and outfile = Sys.argv.(4)

  (* These command-line arguments are not used for the moment. *)
  and _source = int_of_string Sys.argv.(2)
  and _sink = int_of_string Sys.argv.(3)
  in

  (* Open file *)
  (* let sgraph = from_file infile in *)
  (* let graph = gmap sgraph int_of_string in *)


  (* let schools = [0;1;2;3;4;5;6;7;8;9;10] in *)
  (* let students = [(0, [0;7;4]);(1,[0;2;4]);(2,[4;6;5;9]);(3,[0;5;3;4]);(4,[1;3;5;6]);(5,[2;0]);(6,[1;2;3;4;5]);(7,[1;8;9;3]);(8,[9;10;6;1;0]);(9,[1;0;5;10]);(10, [2;4;7;3])] in *)

  Printf.printf "Reading file...\n%!";

  let students, schools = from_file_wishes "./wishes/wish_0.txt" in

  (* print schools *)
  (* List.iter (fun school -> Printf.printf "School %d\n" school) schools; *)

  (* print students *)
  (* List.iter (fun (student, wishes) -> Printf.printf "Student %d: " student; List.iter (fun wish -> Printf.printf "%d " wish) wishes; Printf.printf "\n") students; *)

  (* Create the graph *)

  Printf.printf "Creating graph...\n%!";


  let graph, hashtbl = create_graph_from_wishes students schools in
  (* Hashtbl.iter (fun id node -> Printf.printf "Node %d: %s\n" id (match node with
    | School(school) -> "School " ^ string_of_int school
    | Student(student) -> "Student " ^ string_of_int student
    | Source -> "Source"
    | Sink -> "Sink"
  )) hashtbl; *)

  let clusters = get_clusters hashtbl in

  let _step graph i = 
    let sgraph = gmap graph string_of_int in
    let filename = "example/graph" ^ (string_of_int i) ^ ".dot" in
    export_with_clusters filename sgraph clusters;
  in
(* 
  (* Run the algorithm *)
  let flow, graph = ford_fulkerson graph source sink step in

  (* Print the result *)
  Printf.printf "Max flow: %d\n" flow ; *)

  Printf.printf "Computing students to schools...\n%!";

  (* Compute students to schools *)

  let students_schools = students_to_schools students schools in

  (* Print *)
  List.iter (fun (student, school) -> Printf.printf "Student %d -> School %s\n" student (match school with
    | Some school -> string_of_int school
    | None -> "None"
  )) students_schools;

  (* let () = write_file outfile graph in *)

  Printf.printf "Exporting graph...\n%!";

  (* Export the graph *)

  let sgraph = gmap graph string_of_int in

  (* Rewrite the graph that has been read. *)
  let () = export_with_clusters outfile sgraph clusters in *)

    ()
