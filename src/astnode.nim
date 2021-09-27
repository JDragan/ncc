

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
        nkAssign

    Node* = ref object of RootObj
        name*:   string
        value*:  string
        parsed*: string
        case kind*: NodeKind # the ``kind`` field is the discriminator
            of nkComment: nil
            of nkIdent: nil
            of nkInt, nkFloat: nil
            of nkString: nil
            of nkAdd, nkSub, nkBinOp, nkBoolOp:
                leftOp*, rightOp*: Node
                operand*: string
            of nkIf:
                condition*: Node
                thenPart*: Tree
                elsePart*: Node
            of nkPrintStmt: params*: seq[Node]
            of nkAssign:
                identifier*: string
                assigned*: Node
                isInit*: bool

    Tree* = object of RootObj
        nodes*: seq[Node]

var Globals*: seq[string]

func newCommentNode*(comment_str: string = ""): Node =
    let parsed = "// " & comment_str
    Node(kind: nkComment, value: comment_str, parsed: parsed)

proc newAssignNode*(identifier: string = "", assigned: Node = nil): Node =
    var isInit = false
    if Globals.find(identifier) < 0:
        isInit = true
        Globals.add identifier
    Node(kind: nkAssign, identifier: identifier, isInit: isInit)

func newAddNode*(left, right: Node = nil): Node = Node(kind: nkAdd)

func newBoolOpNode*(left, right: Node = nil): Node = Node(kind: nkBoolOp)

func newIfNode*(cond, body: Node = nil): Node =
    Node(kind: nkIf, condition: cond, elsePart: body, thenPart: Tree())

func newIntNode*(val: string = ""): Node = Node(kind: nkInt, value: val)

func newStringNode*(val: string = ""): Node = Node(kind: nkString, value: val)

func newIdentNode*(val: string = ""): Node = Node(kind: nkIdent, name: val)
