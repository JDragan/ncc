## ncc is new language with python like syntax
## transpiles to ANSI C

import strutils
import os

type
    NodeKind = enum # the different node types
        nkInt,      # a leaf with an integer value
        nkFloat,    # a leaf with a float value
        nkString,   # a leaf with a string value
        nkBinOp,
        nkBoolOp,
        nkAdd,      # an addition
        nkSub,      # a subtraction
        nkIf,       # an if statement
        nkComment,
        nkPrintStmt,
        nkAssign,
        nkEndline
    Node = ref object
        case kind: NodeKind # the ``kind`` field is the discriminator
        of nkInt, nkFloat:
            numLiteral: string
        of nkString: strLiteral: string
        of nkAdd, nkSub, nkBinOp, nkBoolOp:
            leftOp, rightOp: Node
            operand: string
        of nkIf:
            condition: Node
            thenPart: seq[Node]
            elsePart: Node
        of nkComment: comment: string
        of nkPrintStmt: params: seq[Node]
        of nkAssign:
            identifier: string
            value: Node
        of nkEndline: isEndline: bool

const ENDL = ";" & "\n"
const QUOTE = "\""
const OPERANDS = ['+', '-']
const OPERANDS_BOOL = ["=="]
const KEYWORDS = ["int", "float"]
# const KEYWORDSOP = [nkInt, nkFloat]

proc newAssignNode(identifier: string = "", value: Node = nil): Node = Node(kind: nkAssign)

proc newAddNode(left, right: Node = nil): Node = Node(kind: nkAdd)

proc newBoolOpNode(left, right: Node = nil): Node = Node(kind: nkBoolOp)

proc newIfNode(cond, body: Node = nil): Node =
    Node(kind: nkIf, condition: cond, elsePart: body, thenPart: newSeq[Node](0))

proc newIntNode(val: string = ""): Node = Node(kind: nkInt, numLiteral: val)

proc newStringNode(val: string = ""): Node = Node(kind: nkString,
    strLiteral: val)

# proc newEndline(): Node = Node(kind: nkEndline, isEndline: true)

proc count_spaces(ln: string): int =
    var numspaces = 0
    for c in ln:
        if c == ' ': inc numspaces
        else: break
    return numspaces

proc isStringLiteral(line: string): bool =
    if line.strip.startsWith(QUOTE) and line.strip.endsWith(QUOTE): true
    else: false

proc isBinOp(str: string): bool =
    for c in str:
        if c in OPERANDS: return true
    return false

proc isBoolOp(str: string): bool =
    for c in str.split(" "):
        if c in OPERANDS_BOOL: return true
    return false

proc isStringDigit(str: string): bool =
    ## Reimplementation of isDigit for strings
    if str.len() == 0: return false
    for i in str:
        if not isDigit(i): return false
    return true

proc isComment(line: string): bool =
    line.strip.startsWith("#")

proc parseComment(i: string): string =
    return i.split("# ")[1].strip()

proc isPrintStmt(line: string): bool =
    line.strip.startsWith("print ")

proc parsePrintStmt(i: string): seq[Node] =
    var paramSeq: seq[Node]
    let lit = i.split("print ")[1].strip()
    if ", " in lit:
        var printParams = lit.split(", ")
        for p in printParams:
            var n = newStringNode(p)
            paramSeq.add(n)
    else:
        var n = newStringNode(lit)
        paramSeq.add(n)
    return paramSeq

proc isAssignStmt(i: string): bool =
    let spl = i.split
    for s in spl:
        if s.strip in KEYWORDS: return true
    return false

proc buildBinOp(binopExpression: string): Node =
    let arr = binopExpression.split("+")
    var mainBinop = newAddNode()
    # binop parse tree
    # echo "arr: ", arr
    for idx, v in arr:
        var tempnode = newAddNode()

        if idx == 0: continue
        if idx == 1:
            tempnode.leftOp = newIntNode(arr[0])
            tempnode.rightOp = newIntNode(arr[1])
        else:
            tempnode.leftOp = mainBinop
            tempnode.rightOp = newIntNode(v)

        mainBinop = tempnode

    return mainBinop

proc buildBoolOp(binopExpression: string): Node =
    var arr = binopExpression.split(" == ")
    if arr[1].strip().endsWith(":"): arr[1] = arr[1].split(":")[0]
    var mainBinop = newBoolOpNode()
    # binop parse tree
    for idx, v in arr:
        var tempnode = newBoolOpNode()

        if idx == 0: continue
        if idx == 1:
            tempnode.leftOp = newIntNode(arr[0])
            tempnode.rightOp = newIntNode(arr[1])
        else:
            tempnode.leftOp = mainBinop
            tempnode.rightOp = newIntNode(v)

        mainBinop = tempnode

    return mainBinop

proc isIfStmt(line: string): bool =
    line.strip.startsWith("if ")

proc buildIfStmt(line: string, body: var string, pasredbody: seq[Node]): Node =

    let cond = line[3..line.find(":") - 1]

    if body == "":
        body = line[line.find(":") + 1 .. line.high].strip()

    var node = newIfNode()
    if cond.isBoolOp():
        node.condition = buildBoolOp(cond)
    if body.isPrintStmt():
        node.thenPart = @[Node(kind: nkPrintStmt, params: parsePrintStmt(body))]
    else:
        node.thenPart = pasredbody
        # result.thenPart = buildAST(body)

    return node


proc quot(i: string): string = QUOTE & i & QUOTE
proc bracketize(i: string): string = "(" & i & ")"

var rawccode = ""
proc walkAST(node: Node) =

    if node != nil:
        case node.kind:

        of nkComment:
            rawccode.add("// " & node.comment & "\n")

        of nkAdd:
            walkAST(node.leftOp)
            rawccode.add(" + ")
            walkAST(node.rightOp)

        of nkBoolOp:
            walkAST(node.leftOp)
            rawccode.add(" == ")
            walkAST(node.rightOp)

        of nkint:
            rawccode.add(node.numLiteral)

        of nkAssign:
            rawccode.add("int ")
            rawccode.add(node.identifier)
            rawccode.add(" = ")
            walkAST(node.value)
            rawccode.add(ENDL)

        of nkString:
            rawccode.add(node.strLiteral)

        of nkPrintStmt:
            rawccode.add("printf")
            var paramArr: seq[string]
            var paramFormat: seq[string]
            for p in node.params:
                paramArr.add(p.strLiteral)
                if isStringLiteral(p.strLiteral):
                    paramFormat.add("%s")
                else:
                    paramFormat.add("%d")

            let f = quot(join(paramFormat, " ") & "\\n")
            let p = join(paramArr, ", ")
            rawccode.add(bracketize(f & ", " & p))
            rawccode.add(ENDL)

        of nkEndline:
            rawccode.add("")

        of nkIf:
            rawccode.add("if (")
            walkAST(node.condition)
            rawccode.add(") {\n")
            for n in node.thenPart: walkAST(n)
            rawccode.add("}\n")

        of nkFloat, nkBinOp, nkSub:
            echo node.kind, " not implemented yet"

proc tabPos(tabsz: int32 = 0): string =
    var spaces = ""
    for space in 0..tabsz-1:
        spaces.add(" ")
    return spaces



var numspaces: int32 = 0 # space tracker
proc buildAST*(input: string): seq[Node] =

    var astnodes: seq[Node]
    var lines = input.split("\n")

    var idx = 0
    while idx < lines.len - 1:

        var line = lines[idx]
        inc idx
        # echo idx, ": ", line

        if line.isComment():
            astnodes.add(Node(kind: nkComment, comment: parseComment(line)))
            continue

        if line.isPrintStmt():
            let printnode = Node(kind: nkPrintStmt, params: parsePrintStmt(line))
            astnodes.add(printnode)
            # astnodes.add(newEndline())
            continue

        if line.isAssignStmt():
            let lit = line.split(" = ")
            let left = lit[0].strip()
            let right = lit[1].strip()
            let leftname = left.split()[0].strip().split(":")[0]

            var anode = newAssignNode()

            anode.identifier = leftname

            if right.isStringDigit(): anode.value = newIntNode(right)
            elif right.isBinOp(): anode.value = buildBinOp(right)
            elif right.isBoolOp(): anode.value = buildBoolOp(right)
            else: anode.value = newStringNode(right)

            astnodes.add(anode)
            continue

        if line.isIfStmt():

            var node = newIfNode()
            var cond = line.split("if ")[^1]
            node.condition = buildBoolOp(cond)

            var thenPart: string = ""
            numspaces += 2

            while lines[idx].count_spaces >= tabPos(numspaces).len:
                thenPart.add(lines[idx] & "\n")
                inc idx
            node.thenPart = thenPart.buildAST()

            astnodes.add(node)
            numspaces -= 2

            continue

    return astnodes

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

let input = "test.ncc"
let myFile = readFile(input)

var ccode = header & emitCode(buildAST(myFile))

echo "rawccode:\n", rawccode

let output_c = input.changeFileExt("c")
let output_exe = output_c.changeFileExt("exe")

writeFile(output_c, ccode)
echo "Compiling: " & input    & " -> "   & output_c
echo "Compiling: " & output_c & " ---> " & output_exe
discard execShellCmd("gcc " & output_c & " -o " & output_exe)
discard execShellCmd("strip " & output_exe)
echo "DONE"
