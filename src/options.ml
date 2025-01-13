open Gfile

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
  "\n✻ Usage: " ^ Sys.argv.(0) ^ " [OPTIONS]... [INFILE] -o [OUTFILE]"
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