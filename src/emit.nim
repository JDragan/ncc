import astnode
import strutils


const ENDL = ";" & "\n"
const QUOTE = "\""
func quot(i: string): string = QUOTE & i & QUOTE
func bracketize(i: string): string = "(" & i & ")"

var rawccode: string
proc walkAST(node: Node)

func emitPrint*(node: Node): string =
    result.add("printf")
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
    result.add bracketize(f & ", " & p)
    result.add ENDL

proc emitIf(node: Node) =
    rawccode.add("if (")
    walkAST(node.condition)
    rawccode.add(") {\n")
    for n in node.thenPart: walkAST(n)
    rawccode.add("}\n")


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

        of nkPrintStmt: rawccode.add emitPrint(node)

        of nkIf: emitIf(node)

        of nkFloat, nkBinOp, nkSub:
            echo node.kind, " not implemented yet"


import os
import json

proc emitCode*(nodes: seq[Node]): string =

    discard execShellCmd "echo '" & $(%nodes) & "' > dump_ast.json"

    for n in nodes:
        n.walkAST()

    rawccode.add("}\n")
    rawccode