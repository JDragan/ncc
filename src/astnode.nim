

type
    NodeKind* = enum # the different node types
        nkIdent
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
    Node* = ref object
        case kind*: NodeKind # the ``kind`` field is the discriminator
        of nkIdent: identName*: string
        of nkInt, nkFloat:
            numLiteral*: string
        of nkString: strLiteral*: string
        of nkAdd, nkSub, nkBinOp, nkBoolOp:
            leftOp*, rightOp*: Node
            operand*: string
        of nkIf:
            condition*: Node
            thenPart*: seq[Node]
            elsePart*: Node
        of nkComment: comment*: string
        of nkPrintStmt: params*: seq[Node]
        of nkAssign:
            identifier*: string
            value*: Node
            isInit*: bool
        of nkEndline: isEndline*: bool

        parsed*: string

var Globals*: seq[string]

func newCommentNode*(comment_str: string = ""): Node =
    var parsed = "// " & comment_str
    Node(kind: nkComment, comment: comment_str, parsed: parsed)

proc newAssignNode*(identifier: string = "", value: Node = nil): Node =
    var isInit = false
    if Globals.find(identifier) < 0:
        isInit = true
        Globals.add identifier
    Node(kind: nkAssign, identifier: identifier, isInit: isInit)

proc newAddNode*(left, right: Node = nil): Node = Node(kind: nkAdd)

proc newBoolOpNode*(left, right: Node = nil): Node = Node(kind: nkBoolOp)

proc newIfNode*(cond, body: Node = nil): Node =
    Node(kind: nkIf, condition: cond, elsePart: body, thenPart: newSeq[Node](0))

proc newIntNode*(val: string = ""): Node = Node(kind: nkInt, numLiteral: val)

proc newStringNode*(val: string = ""): Node = Node(kind: nkString,
    strLiteral: val)

proc newIdentNode*(val: string = ""): Node = Node(kind: nkIdent, identName: val)