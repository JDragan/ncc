## Builds Abstract Syntax Tree from provided file

import strutils
import astnode


const ENDL* = ";" & "\n"
const QUOTE* = "\""
const OPERANDS = ['+', '-']
const OPERANDS_BOOL = ["=="]
const KEYWORDS = ["int", "float"]
# const KEYWORDSOP = [nkInt, nkFloat]

proc count_spaces(ln: string): int =
    var numspaces = 0
    for c in ln:
        if c == ' ': inc numspaces
        else: break
    return numspaces

proc tabPos(tabsz: int32 = 0): string =
    var spaces = ""
    for space in 0..tabsz-1:
        spaces.add(" ")
    return spaces

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
            if p.isStringLiteral():
                paramSeq.add newStringNode(p)
            elif p.isStringDigit():
                paramSeq.add newIntNode(p)
            else:
                paramSeq.add newIdentNode(p)

    else:
        if lit.isStringLiteral():
            paramSeq.add(newStringNode(lit))
        elif lit.isStringDigit():
            paramSeq.add(newIntNode(lit))
        else:
            paramSeq.add(newIdentNode(lit))
            

    return paramSeq

proc isAssignStmt(line: string): int =
    # echo i.split
    if line.strip.startsWith("if"): return 0
    for c in line.split:
        if c.strip in KEYWORDS: return 1
        if c.strip in Globals : return 2
    return 0

proc isIfStmt(line: string): bool =
    line.strip.startsWith("if ")

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

var numspaces: int32 = 0 # space tracker
proc buildAST*(input: string): seq[Node] =

    var astnodes: seq[Node]
    var lines = input.split("\n")

    var idx = 0
    while idx < lines.len - 1:

        var line = lines[idx]
        inc idx
        echo idx, ": ", line

        if line.strip == "":
            continue

        if line.isComment():
            astnodes.add newCommentNode(parseComment(line))
            continue

        if line.isPrintStmt():
            astnodes.add Node(kind: nkPrintStmt, params: parsePrintStmt(line))
            continue

        let assignType = line.isAssignStmt()

        if assignType > 0:

            var splitter = ""

            if assignType == 1: splitter = " = "
            if assignType == 2: splitter = " = "

            let lit = line.split(splitter)

            echo lit, " ", splitter

            # echo Globals
            if lit.len < 2:
                echo "Error parsing : ", line, " ---"
                return

            let left = lit[0].strip()
            let right = lit[1].strip()
            let leftname = left.split()[0].strip().split(":")[0]

            var anode = newAssignNode(leftname)

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