import strutils
import os

type
  NodeKind = enum   # the different node types
    nkInt,          # a leaf with an integer value
    nkFloat,        # a leaf with a float value
    nkString,       # a leaf with a string value
    nkBinOp,
    nkBoolOp,
    nkAdd,          # an addition
    nkSub,          # a subtraction
    nkIf,           # an if statement
    nkComment,
    nkPrintStmt,
    nkAssign,
    nkEndline
  Node = ref object
    case kind: NodeKind  # the ``kind`` field is the discriminator
    of nkInt, nkFloat:
      intName, val: string
    of nkString: strVal: string
    of nkAdd, nkSub, nkBinOp, nkBoolOp:
      leftOp, rightOp: Node
      operand: string
    of nkIf: condition, thenPart, elsePart: Node
    of nkComment: comment: string
    of nkPrintStmt: params: seq[Node]
    of nkAssign: target, value: Node
    of nkEndline: isEndline: bool

const ENDL = ";" & "\n"
const QUOTE = "\""
const OPERANDS = ['+', '-']
const OPERANDS_BOOL = ["=="]
const KEYWORDS = ["int", "float"]
# const KEYWORDSOP = [nkInt, nkFloat]

proc newAssignNode(t, v: Node = nil): Node = Node(kind: nkAssign, target: t, value: v)

proc newAddNode(left, right: Node = nil): Node = Node(kind: nkAdd, leftOp: left, rightOp: right)

proc newBoolOpNode(left, right: Node = nil): Node = Node(kind: nkBoolOp, leftOp: left, rightOp: right)

proc newIfNode(cond, body: Node = nil): Node = Node(kind: nkIf, condition: cond, thenPart: body)

proc newIntNode(val: string = ""): Node = Node(kind: nkInt, val: val)

proc newStringNode(val: string = ""): Node = Node(kind: nkString, strVal: val)

proc newEndline(): Node = Node(kind: nkEndline, isEndline: true)

proc isStringLiteral(line: string): bool =
  if line.strip.startsWith(QUOTE) and line.strip.endsWith(QUOTE): true
  else: false

proc isBinOp(str: string): bool =
  for c in str:
    if c in OPERANDS: return true
  return false

proc isBoolOp(str: string): bool =
  var a = str.split(" ")
  for c in a:
    if c in OPERANDS_BOOL: return true
  return false

proc isStringDigit(str: string): bool =
  ## Reimplementation of isDigit for strings
  if str.len() == 0: return false
  for i in str:
    if not isDigit(i): return false
  return true

proc isComment(line: string): bool =
  if line.strip.startsWith("#"): true
  else: false

proc parseComment(i: string): string =
  return i.split("# ")[1].strip()

proc isPrintStmt(line: string): bool =
  if line.strip.startsWith("print "): true
  else: false

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
  let arr = binopExpression.split(" == ")
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
  if line.strip.startsWith("if "): true
  else: false

proc buildIfStmt(line: string): Node =

  let cond = line[3..line.find(":") - 1]
  let body = line[line.find(":") + 1 .. line.high].strip()

  var ifNode = newIfNode()

  if cond.isBoolOp():
    ifNode.condition = buildBoolOp(cond)
  if body.isPrintStmt():
    ifNode.thenPart = Node(kind: nkPrintStmt, params: parsePrintStmt(body))

  return ifNode


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
      rawccode.add(node.val)

    of nkAssign:
      rawccode.add("int ")
      walkAST(node.target)
      rawccode.add(" = ")
      walkAST(node.value)

    of nkString:
      rawccode.add(node.strVal)

    of nkPrintStmt:
      rawccode.add("printf")
      var paramArr:    seq[string]
      var paramFormat: seq[string]
      for p in node.params:
        paramArr.add(p.strVal)
        if isStringLiteral(p.strVal):
          paramFormat.add("%s")
        else:
          paramFormat.add("%d")

      let f = quot(join(paramFormat, " ") & "\\n")
      let p = join(paramArr, ", ")
      rawccode.add(bracketize(f & ", " & p))

    of nkEndline:
      rawccode.add(ENDL)

    of nkIf:
      rawccode.add("if (")
      walkAST(node.condition)
      rawccode.add(") ")
      walkAST(node.thenPart)

    of nkFloat, nkBinOp, nkSub:
      echo node.kind, " not implemented yet"


proc buildAST(input: FILE): seq[Node] =

  var astnodes: seq[Node]

  for line in lines input:

    if line.isComment():
      astnodes.add(Node(kind: nkComment, comment: parseComment(line) ))
      continue

    if line.isPrintStmt():
      let printnode = Node(kind: nkPrintStmt, params: parsePrintStmt(line))
      astnodes.add(printnode)
      astnodes.add(newEndline())
      continue

    if line.isAssignStmt():
      let lit = line.split(" = ")
      let left = lit[0].strip()
      let right = lit[1].strip()
      let leftname = left.split()[0].strip().split(":")[0]

      var anode = newAssignNode()

      anode.target = newStringNode(leftname)

      if right.isStringDigit(): anode.value = newIntNode(right)
      elif right.isBinOp():     anode.value = buildBinOp(right)
      elif right.isBoolOp():    anode.value = buildBoolOp(right)
      else: anode.value = newStringNode(right)

      astnodes.add(anode)
      astnodes.add(newEndline())
      continue

    if line.isIfStmt():
      astnodes.add(buildIfStmt(line))
      astnodes.add(newEndline())
      continue

  return astnodes


proc emitCode(nodes: seq[Node]): string =

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
let myFile = open(input)

var ccode = header & emitCode(buildAST(myFile))

echo "rawccode:\n", rawccode

let output_c   = input.changeFileExt("c")
let output_exe = output_c.changeFileExt("exe")

writeFile(output_c, ccode)
echo "Compiling: " & input & " -> " & output_c
echo "Compiling: " & output_c & " ---> " & output_exe
discard execShellCmd("tcc " & output_c & " -o " & output_exe)
discard execShellCmd("strip " & output_exe)
echo "DONE"
