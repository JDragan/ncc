## ncc is new language with python like syntax
## transpiles to ANSI C

import os
import astbuild
import emit


const header = """
#include <stdio.h>

typedef enum { false, true } bool;

int main() {
"""

proc main() =
    
    let input = "tests/condition.ncc"
    let myFile = readFile(input)

    var ccode = header & treeWalker(buildAST(myFile))

    let output_c = input.changeFileExt("c")
    let output_exe = output_c.changeFileExt("exe")

    writeFile(output_c, ccode)
    echo "Compiling: " & input    & " -> "   & output_c
    echo "Compiling: " & output_c & " ---> " & output_exe
    discard execShellCmd("gcc " & output_c & " -o " & output_exe)
    discard execShellCmd("strip " & output_exe)
    discard execShellCmd("./" & output_exe)
    echo "DONE"

if isMainModule:
    main()