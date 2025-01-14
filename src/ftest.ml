open Gfile
open Tools
open Algorithms
open Options

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
        List.iter (fun (school, places) -> Printf.printf "id: %d places: %d\n" school places) schools;
        Printf.printf "\n\n";

        Printf.printf "Students: \n";
        List.iter (fun (student, wishes) -> Printf.printf "id: %d, wishes: " student; List.iter (fun wish -> Printf.printf "%d " wish) wishes; Printf.printf "\n") students;
      end;

      let assignations, original, bgraph, clusters = students_to_schools students schools in
      let end_graph = convert_to_flow_graph original bgraph in
      
      if (Option.is_some !outfile) then begin
        Printf.printf "✻ Graph exported at %s\n" (Option.get !outfile);
        export_with_clusters (Option.get !outfile) end_graph clusters;
  
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

      (* Show assignations *)
      List.iter (fun (student, school) -> (match school with
      | Some s -> Printf.printf "✻ Student %d goes to school %d\n" student s
      | _ -> Printf.printf "✻ Student %d has no assignation\n" student)) assignations;
    end;
