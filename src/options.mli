val verbose: string option ref
val outfile: string option ref
val svg_outfile: string option ref
val png_outfile: string option ref
val infile: string option ref
val ford_fulkerson_source: int option ref
val ford_fulkerson_sink: int option ref
val debug: bool ref
val biparti: bool ref

val usage: string

val anonymous: string -> unit

val speclist: (string * Arg.spec * string) list