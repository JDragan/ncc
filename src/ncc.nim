## ncc is new language with python like syntax
## transpiles to ANSI C

import strutils
import os

import astnode
import astbuild


func quot(i: string): string = QUOTE & i & QUOTE
proc bracketize(i: string): string = "(" & i & ")"

var rawccode = ""
proc walkAST(node: Node) =

    if node.isNil: return


    case node.kind:

    of nkComment: rawccode.add node.parsed & "\n"

    of nkAdd:
        walkAST(node.leftOp)
        rawccode.add(" + ")
        walkAST(node.rightOp)

    of nkBoolOp:
        walkAST(node.leftOp)
        rawccode.add(" == ")
        walkAST(node.rightOp)

    of nkint: rawccode.add(node.value)

    of nkIdent: rawccode.add(node.name)

    of nkAssign:
        if node.isInit:
            rawccode.add("int ")
        rawccode.add(node.identifier)
        rawccode.add(" = ")
        walkAST(node.assigned)
        rawccode.add(ENDL)

    of nkString: rawccode.add(node.value)

    of nkPrintStmt:
        rawccode.add("printf")
        var paramArr: seq[string]
        var paramFormat: seq[string]
        for p in node.params:
            # if isStringLiteral(p.value):
            if p.kind == nkString:
                paramArr.add(p.value)
                paramFormat.add("%s")
            elif p.kind == nkInt:
                paramArr.add(p.value)
                paramFormat.add("%d")
            elif p.kind == nkIdent:
                paramArr.add(p.name)
                paramFormat.add("%d")
            else:
                paramFormat.add("%d")

        let f = quot(join(paramFormat, " ") & "\\n")
        let p = join(paramArr, ", ")
        rawccode.add(bracketize(f & ", " & p))
        rawccode.add(ENDL)

    of nkIf:
        rawccode.add("if (")
        walkAST(node.condition)
        rawccode.add(") {\n")
        for n in node.thenPart: walkAST(n)
        rawccode.add("}\n")

    of nkFloat, nkBinOp, nkSub:
        echo node.kind, " not implemented yet"



import json

proc emitCode(nodes: seq[Node]): string =

    discard execShellCmd "echo '" & $(%nodes) & "' > dump_ast.json"

    for n in nodes:
        n.walkAST()

    rawccode.add("}\n")
    rawccode


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