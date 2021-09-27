import astnode
import strutils


const ENDL = ";" & "\n"
const QUOTE = "\""
func quot(i: string): string = QUOTE & i & QUOTE
func bracketize(i: string): string = "(" & i & ")"

var rawccode: string
proc walkNode(node: Node)

func emitPrint*(node: Node): string =
    result.add("printf")
    var paramArr: seq[string]
    var paramFormat: seq[string]
    
    for p in node.params:
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
    walkNode(node.condition)
    rawccode.add(") {\n")
    for n in node.thenPart.nodes: walkNode(n)
    rawccode.add("}\n")


proc walkNode(node: Node) =

    if node.isNil: return

    case node.kind:
        of nkComment: rawccode.add node.parsed & "\n"

        of nkAdd:
            walkNode(node.leftOp)
            rawccode.add(" + ")
            walkNode(node.rightOp)

        of nkBoolOp:
            walkNode(node.leftOp)
            rawccode.add(" == ")
            walkNode(node.rightOp)

        of nkint: rawccode.add(node.value)

        of nkIdent: rawccode.add(node.name)

        of nkAssign:
            if node.isInit:
                rawccode.add("int ")
            rawccode.add(node.identifier)
            rawccode.add(" = ")
            walkNode(node.assigned)
            rawccode.add(ENDL)

        of nkString: rawccode.add(node.value)

        of nkPrintStmt: rawccode.add emitPrint(node)

        of nkIf: emitIf(node)

        of nkFloat, nkBinOp, nkSub:
            echo node.kind, " not implemented yet"


import os
import json

proc treeWalker*(tree: Tree): string =

    discard execShellCmd "echo '" & $(%tree.nodes) & "' > dump_ast.json"

    for n in tree.nodes:
        n.walkNode()

    rawccode.add("}\n")
    rawccode