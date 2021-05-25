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
    
    let input = "tests/test.ncc"
    let myFile = readFile(input)

    var ccode = header & emitCode(buildAST(myFile))

    # echo "rawccode:\n", rawccode

    let output_c = input.changeFileExt("c")
    let output_exe = output_c.changeFileExt("exe")

    writeFile(output_c, ccode)
    echo "Compiling: " & input    & " -> "   & output_c
    echo "Compiling: " & output_c & " ---> " & output_exe
    discard execShellCmd("gcc " & output_c & " -o " & output_exe)
    discard execShellCmd("strip " & output_exe)
    echo "DONE"

if isMainModule:
    main()