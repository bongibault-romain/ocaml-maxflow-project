open Gfile
open Tools
open Algorithms

let () =

  (* Check the number of command-line arguments *)
  if Array.length Sys.argv <> 5 then
    begin
      Printf.printf
        "\n ✻  Usage: %s infile source sink outfile\n\n%s%!" Sys.argv.(0)
        ("    🟄  infile  : input file containing a graph\n" ^
         "    🟄  source  : identifier of the source vertex (used by the ford-fulkerson algorithm)\n" ^
         "    🟄  sink    : identifier of the sink vertex (ditto)\n" ^
         "    🟄  outfile : output file in which the result should be written.\n\n") ;
      exit 0
    end ;


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

  let students, schools = from_file_wishes "./wishes/wish_4.txt" in

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

  let _students_schools = students_to_schools students schools in

  (* Print *)
  (* List.iter (fun (student, school) -> Printf.printf "Student %d -> School %s\n" student (match school with
    | Some school -> string_of_int school
    | None -> "None"
  )) students_schools; *)

  (* let () = write_file outfile graph in *)

  Printf.printf "Exporting graph...\n%!";

  (* Export the graph *)

  let sgraph = gmap graph string_of_int in

  (* Rewrite the graph that has been read. *)
  let () = export_with_clusters outfile sgraph clusters in

  ()
