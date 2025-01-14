# Features

[x] Implémentation de l'algorithme de Ford Fulkerson

[x] Implémentation d'un algorithme de répartition des étudiants dans des écoles, les écoles ayant toutes une capacité maximale.

[x] Exportation du graphe de flot final aux formats dot, png et svg.

[x] Création d'un CLI pour une utilisation plus simple du programme.

[] Implémentation de tests unitaires à l'aide de OUnit2

# How to run

A [`Makefile`](Makefile) provides some useful commands:

 - `make build` to compile. This creates an `ftest.exe` executable
 - `make demo` to run the `ftest` program with some arguments
 - `make format` to indent the entire project
 - `make edit` to open the project in VSCode
 - `make clean` to remove build artifacts

In case of trouble with the VSCode extension (e.g. the project does not build, there are strange mistakes), a common workaround is to (1) close vscode, (2) `make clean`, (3) `make build` and (4) reopen vscode (`make edit`).

# Usage

```
✻ Usage: ./ftest.exe [OPTIONS]... [INFILE] -dot [OUTFILE]

🟄  INFILE   : input file containing a graph

🟄  OPTIONS:

  -v [DIRECTORY]
    Verbose mode, export all steps of the algorithm in DIRECTORY

  -dot [OUTFILE]
    Output file in which the result should be written in DOT format.

  -svg [OUTFILE]
    Output file in which the result should be written in SVG format.

  -png [OUTFILE]
    Output file in which the result should be written in PNG format.

  -d Debug mode, more information will be printed

  -f [SOURCE] [SINK]
    Launch ford fulkerson algorithm, SOURCE and SINK are the source and sink nodes.

  -b Launch students-to-school assignation algorithm
  -help  Display this list of options
  --help  Display this list of options
```

## Run Ford Fulkerson (-f option) 

Pour lancer l'algorithme de Ford Fulkerson l'INFILE doit être au format suivant:

```
%% Test graph #1

%% Nodes

n  20 300 0   % This is node #0, with its coordinates (which are not used by the algorithms).
n 200 300 1
n 200 200 2
n 200 400 3
n 380 300 4
n 380 200 5   % This is node #5.


%% Edges (arcs)

e 0 2 0 8     % An arc from 0 to 2, labeled "8". The second 0 is useless.
e 0 3 1 10
e 0 1 2 7
e 2 4 3 12
e 3 4 4 5
e 3 2 5 2
e 3 1 6 11
e 1 4 7 1
e 1 5 8 21
e 4 5 9 14    % An arc from 4 to 5 labeled 14. The 9 is useless.

% End of graph
```

## Run Students-to-Schools (-b option)

Pour lancer l'algorithme de répartition des élèves dans des écoles, l'INFILE doit être au format suivant :

La première ligne contient les écoles et leurs capacités. Chaque école est représentée par un ID, un nom et sa capacité maximale.

Exemple de format pour la première ligne de l'INFILE :

```
0 200 1 400 2 40 3 500
```

Ici, l'école 0 aura donc 200 places et l'école 2 en aura 40.

Les lignes suivantes doivent renseigner les vœux des élèves. Chaque ligne représente un élève et ses vœux. Un élève peut avoir un nombre de vœux différents des autres.

Chaque ligne commence par l'ID de l'élève (un nombre). Ensuite, on renseigne les écoles dans lesquelles il souhaite candidater. Un élève peut candidater plusieurs fois pour la même école.

Exemple de format pour les vœux des élèves :

```
0 0 0 1 1 1 3
```

Ici, l'élève 0 candidate 2 fois pour l'école 0, 3 fois pour l'école 1 et une fois pour l'école 3.

Exemple de fichier complet :

```
0 200 1 400 2 40 3 500
0 0 1 2
1 1 2 3
2 2 3
3 1 0 2 3
4 1 2 3
```