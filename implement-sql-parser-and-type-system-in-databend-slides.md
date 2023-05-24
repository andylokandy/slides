---
theme: light
paginate: true
marp: true
title: Implement SQL parser and type system in Databend
author: Andy Lok
size: 16:9
---

<style>
@import url('https://unpkg.com/tailwindcss@2.2.19/dist/utilities.min.css');
</style>

<!-- mermaid.js -->
<script type="module">
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10.0.0/dist/mermaid.esm.min.mjs';
mermaid.initialize({theme:'neutral'});
</script>

# Implement SQL parser and type system in Databend

<div class="grid grid-cols-3 gap-20 items-start mt-20">
<div class= "col-span-2">

### [Databend Cloud](https://databend.com) is an affordable cloud **data warehouse** developed in Rust. In this exploration, we will dive into Databend's internal, specifically examining its SQL parser and type system that are meticulously crafted for Rust.

by **@AndyLok**

</div>
<div>

![](https://databend.rs/img/logo/logo-no-text.svg)

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Who am I


</div>
<div>

**骆迪安**

https://github.com/andylokandy
https://twitter.com/AndylokandyLok

**Databend** Planner Team
Distributed transaction

Rust contributor
Idris-lang contributor 

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Databend

https://databend.rs

</div>
<div>

- Feature-Rich
- Instant Elasticity
- Support for Semi-Structured Data
- MySQL/ClickHouse Compatible
- Low Cost
- Easy To Use
- Cloud Native (S3, Azure Blob, Google Cloud Storage, Alibaba Cloud OSS, etc)

</div>
</div>

---

![bg fit](https://databend.rs/assets/images/new-planner-6-2e48dcc34fcdc3aae0c02a847b4d93a3.png)

---

<div class="grid grid-cols-2 gap-20">
<div>

## SQL Parser

Check for syntax violation and construct **Abstract Syntax Tree (AST)**

</div>
<div>

Input

```sql
SELECT a + 1 FROM t
```

<hr/>

Output

<pre class='mermaid'>
flowchart
    SELECT --- | expr | plus["+"]
    plus --- a
    plus --- one["1"]
    SELECT --- | from | t
</pre>

</div>
</div>

--- 

<div class="grid grid-cols-2 gap-20">
<div>

## Tokenize

Convert **String** to **Token Stream**

</div>
<div>

## Parse

Convert **Token Stream** to **AST**

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Tokenize

Recognise **tokens** by regular expression

</div>
<div>

**Regular expression** for each token kind

```
Ident = [_a-zA-Z][_$a-zA-Z0-9]*
Number = [0-9]+
Plus = \+
SELECT = SELECT
FROM = FROM
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Tokenize

Recognise **tokens** by regular expression

</div>
<div>

Input

```sql
SELECT a + 1 FROM t
```

<hr/>

Output

```sql
[
    Keyword(SELECT),
    Ident(a),
    BinOp(+),
    Number(1),
    Keyword(FROM),
    Ident(t),
]
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Parse

Define **gramma rule** and construct **AST**

</div>
<div>

**Backus–Naur form (BNF)** grammars

```
<select_statement> ::= SELECT <expr> FROM <ident>
<expr> ::= <number>
         | <ident>
         | <expr> <op> <expr>
<op> ::= + | - | * | /
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Parse

Define **gramma rule** and construct **AST**

</div>
<div>

Input

```sql
[
    Keyword(SELECT),
    Ident(a),
    BinOp(+),
    Number(1),
    Keyword(FROM),
    Ident(t),
]
```

<hr/>

Output

```rust
SelectStatement {
    projection: Expr::BinaryOp {
        op: Op::Plus,
        args: [
            Expr::ColumnRef("a"),
            Expr::Constant(Scalar::Int(1))
        ]
    }
    from: "t",
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Choosing SQL Parser

</div>
<div>

- sqlparser-rs
- ANTLR4
- LALRPOP
- nom

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Tokenizer

https://github.com/maciejhirsz/logos

</div>
<div>

```rust
#[derive(Logos)]
pub enum TokenKind {
    #[regex(r"[ \t\r\n\f]+", logos::skip)]
    Whitespace,

    #[regex(r#"[_a-zA-Z][_$a-zA-Z0-9]*"#)]
    Ident,
    #[regex(r"[0-9]+")]
    Number,

    #[token("+")]
    Plus,

    #[token("SELECT", ignore(ascii_case))]
    SELECT,
    #[token("FROM", ignore(ascii_case))]
    FROM,
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Tokenizer

https://github.com/maciejhirsz/logos

</div>
<div>

Input

```sql
SELECT a + 1 FROM t
```

<hr/>

Output

```rust
[
    Token { kind: TokenKind::Select, text: "SELECT", span: 0..6 },
    Token { kind: TokenKind::Ident, text: "a", span: 7..8 },
    Token { kind: TokenKind::Plus, text: "+", span: 9..10 },
    Token { kind: TokenKind::Number, text: "1", span: 11..12 },
    Token { kind: TokenKind::From, text: "from", span: 13..17 },
    Token { kind: TokenKind::Ident, text: "t", span: 18..19 },
]
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Tokenizer

https://github.com/maciejhirsz/logos

</div>
<div>

Input

```sql
SELECT a + 1 FROM t
```

<hr/>

Output

```rust
[
    Token { kind: TokenKind::Select, text: "SELECT", span: 0..6 },
    Token { kind: TokenKind::Ident, text: "a", span: 7..8 },
    Token { kind: TokenKind::Plus, text: "+", span: 9..10 },
    Token { kind: TokenKind::Number, text: "1", span: 11..12 },
    Token { kind: TokenKind::From, text: "from", span: 13..17 },
    Token { kind: TokenKind::Ident, text: "t", span: 18..19 },
]
```

<hr/>

Span

```
SELECT  a     +      1       FROM    t
0..6    7..8  9..10  11..12  13..17  18..19
```

</div>
</div>

---

## Error Report

**Pretty print** the error report thanks to the **span** information

<div style='margin-top:140px;'>

```
error: 
  --> SQL:1:19
  |
1 | create table a (c varch)
  | ------          - ^^^^^ expected `BOOLEAN`, `BOOL`, `UINT8`, `TINYINT`, `UINT16`, `SMALLINT`, or 33 more ...
  | |               |  
  | |               while parsing `<column name> <type> [DEFAULT <default value>] [COMMENT '<comment>']`
  | while parsing `CREATE TABLE [IF NOT EXISTS] [<database>.]<table> [<source>] [<table_options>]`
```

</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Parser

https://github.com/rust-bakery/nom

</div>
<div>

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Terminal

Recognize only one **token** from **token stream**

</div>
<div>

## Combinator

Combine **terminals** and other small parsers into a larger parser

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Terminal

Recognize only one **token** from **token stream**

</div>
<div>

Recongnize a token that has the exactly **text**

```rust
fn match_text(text: &str) 
    -> impl FnMut(&[Token]) -> IResult<&[Token], Token> 
{
    satisfy(|token: &Token| token.text == text)(i)
}
```

<hr/>

Recongnize a token that is of the **token kind**

```rust
fn match_token(kind: TokenKind) 
    -> impl FnMut(&[Token]) -> IResult<&[Token], Token>
{
    satisfy(|token: &Token| token.kind == kind)(i)
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Combinator

Combine **terminals** and other small parsers into a larger parser

</div>
<div>

- tuple(a, b, c)
- alt(a, b, c)
- many0(a)
- many1(a)
- opt(a)

</div>
</div>

---

<div class="grid grid-cols-2 gap-20 items-start">
<div>

## BNF

Formally defined **gramma rule**

```
<select_statement> ::=
    SELECT <expr> FROM <ident>
```

</div>
<div>

## Code

Practical Rust code using **nom**

```rust
tuple((
    match_token(SELECT),
    expr,
    match_token(FROM),
    match_token(Ident),
))
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20 items-start">
<div>

## BNF

Formally defined **gramma rule**

```
<select_statement> ::=
    SELECT <expr> [FROM <ident>]
```

</div>
<div>

## Code

Practical Rust code using **nom**

```rust
tuple((
    match_token(SELECT),
    expr,
    opt(tuple((
        match_token(FROM),
        match_token(Ident),
    )))
))
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20 items-start">
<div>

## BNF

Formally defined **gramma rule**

```
<select_statement> ::=
    SELECT <expr>+ [FROM <ident>]
```

</div>
<div>

## Code

Practical Rust code using **nom**

```rust
tuple((
    match_token(SELECT),
    many1(expr),
    opt(tuple((
        match_token(FROM),
        match_token(Ident),
    )))
))
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20 items-start">
<div>

## BNF

Formally defined **gramma rule**

```
<select_statement> ::=
    SELECT (<expr> AS <ident> | <expr>)+ 
    [FROM <ident>]
```

</div>
<div>

## Code

Practical Rust code using **nom**

```rust
tuple((
    match_token(SELECT),
    many1(alt((
        tuple((
            expr,
            match_token(AS),
            expr,
        )),
        expr,
    ))),
    opt(tuple((
        match_token(FROM),
        match_token(Ident),
    )))
))
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20 items-start">
<div>

## Parse Tree

The **parse tree** of `SELECT a + 1`

<pre class='mermaid'>
flowchart LR
    SELECT["Token(SELECT)"] --- expr
    expr --- FROM
    FROM["Token(FROM)"] --- t["Token(t)"]
    subgraph expr
        direction BT
        a["Token(a)"] --> plus["Token(+)"]
        one["Token(1)"] --> plus
    end
</pre>

</div>
<div>

## AST

The **AST** of `SELECT a + 1`

```rust
SelectStatement {
    projection: Expr::BinaryOp {
        op: Op::Plus,
        args: [
            Expr::ColumnRef("a"),
            Expr::Constant(Scalar::Int(1))
        ]
    }
    from: "t",
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## map( )

</div>
<div>

Use **map( )** to convert **Parse Tree** into **AST**

```rust
fn select_statement(input: &[Token]) 
    -> IResult<&[Token], SelectStatement> 
{
    map(
        tuple((
            match_token(SELECT),
            many1(alt((
                tuple((
                    expr,
                    match_token(AS),
                    expr,
                )),
                expr,
            ))),
            opt(tuple((
                match_token(FROM),
                match_token(Ident),
            )))
        )),
        |(_, projections, _, opt_from)| SelectStatement {
            projections: projections
                .map(|(expr, _, alias)| {
                    Projection::Aliased(expr, alias)
                })
                .collect(),
            from: opt_from.map(|(_, from)| from),
        }
    )(input)
}

```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## nom-rule

https://github.com/andylokandy/nom-rule
Simplify nom parser using **BNF**-like gramma

</div>
<div>

Syntax definition using **nom-rule**

```rust
nom_rule! { 
    SELECT
    ~ (#expr ~ AS ~ Ident | #expr)+
    ~ (FROM ~ Ident)?
}
```

<hr/>

Generated **nom** parser

```rust
tuple((
    match_token(SELECT),
    many1(alt((
        tuple((
            expr,
            match_token(AS),
            expr,
        )),
        expr,
    ))),
    opt(tuple((
        match_token(FROM),
        match_token(Ident),
    )))
))
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## nom-rule

https://github.com/andylokandy/nom-rule
Simplify nom parser using **BNF**-like gramma

</div>
<div>

Update the example using **nom-rule**

```rust
fn select_statement(input: &[Token])
    -> IResult<&[Token], SelectStatement>
{
    map(
        nom_rule! { 
            SELECT 
            ~ (#expr ~ AS ~ Ident | #expr)+
            ~ (FROM ~ Ident)?
        },
        |(_, projections, _, opt_from)| SelectStatement {
            projections: projections
                .map(|(expr, _, alias)| {
                    Projection::Aliased(expr, alias)
                })
                .collect(),
            from: opt_from.map(|(_, from)| from),
        }
    )(input)
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## nom-rule

https://github.com/andylokandy/nom-rule
Simplify nom parser using **BNF**-like gramma

</div>
<div>

**nom-rule** cheatsheet

| nom-rule    | Translated         |
| ----------- | ------------------ |
| TOKEN       | match_token(TOKEN) |
| "+"         | match_text("+")    |
| a ~ b ~ c   | tuple((a, b, c))   |
| (...)*      | many0(...)         |
| (...)+      | many1(...)         |
| (...)?      | opt(...)           |
| a \| b \| c | alt((a, b, c))     |

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Left Recursion

A classical **problem** every parser will meet when parsing expression

</div>
<div>

Try to define the syntax for expression like `1 + 2`

```
<expr> ::= <number>
         | <expr> + <expr>
```

<hr/>

oops! The second rule will **never apply**

<pre class='mermaid'>
flowchart LR
    number -.- error
    subgraph number["number"]
        one["1"]
    end
    subgraph error["error!"]
        direction LR
        plus["+"] -.- two["2"]
    end
</pre>

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Left Recursion

A classical **problem** every parser will meet when parsing expression

</div>
<div>

Try again! **Reverse the order**!

```
<expr> ::= <expr> + <expr>
         | <number>
```

<hr/>

but not gonna work... it'll **never stop**

<pre class='mermaid'>
flowchart LR
    expr1["expr"] --- plus1["+"] --- expr2["expr"]
    expr3["expr"] --- plus2["+"] --- expr4["expr"]
    expr5["expr"] --- plus3["+"] --- expr6["expr"]
    expr1 -.- expr3
    expr3 -.- expr5
    expr5 -.- others["..."]
</pre>

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Pratt Parser

https://github.com/segeljakt/pratt/
A decent solution to the problem of **Left Recursioin**

</div>
<div>

Instead of parsing to a tree, parse the flatten elements

```
<expr_element> ::= + | <number>
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Pratt Parser

https://github.com/segeljakt/pratt/
A decent solution to the problem of **Left Recursioin**

</div>
<div>

Construct the AST using **Pratt Parser**

```rust
use pratt::PrattParser;

impl<I: Iterator<Item = ExprElement> PrattParser<I> for ExprParser {
    type Output = Expr;

    fn query(&mut self, elem: &ExprElement> -> Affix {
        match elem {
            ExprElement::Plus =>
                Affix::Infix(Precedence(20), Associativity::Left),
            ExprElement::Number(_) => Affix::Nilfix,
        }
    }

    fn primary(&mut self, elem: ExprElement) -> Expr {
        match elem {
            ExprElement::Number(n) => Expr::Number(n),
            _ => unreachable!(),
        }
    }

    fn infix(
        &mut self,
        lhs: Expr,
        elem: ExprElement,
        rhs: Expr,
    ) -> Expr {
        match elem {
            ExprElement::Plus(n) => Expr::Plus(lhs, rhs),
            _ => unreachable!(),
        }
    }
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Type Check

Validate the **sematic** of the SQL

</div>
<div>

1. Given an AST

```rust
1 + 'foo'
```

<hr/>

2. **Desugar** AST into function calls

```rust
plus(1, 'foo')
```

<hr/>

3. Infer type of **literals**

```rust
1 :: Int8
'foo' :: String
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Type Check

Validate the **sematic** of the SQL

</div>
<div>

4. So we desire to find a function overload tha matches

```rust
plus(Int8, String)
```

<hr/>

5. Query function overloads for `plus()`

```rust
plus(Int8, Int8) -> Int8
plus(Int16, Int16) -> Int16
plus(Timestamp, Timestamp) -> Timestamp
plus(Date, Date) -> Date
```

<hr/>

6. However, no matching overload is found, thus typechecker reports a **type error**

```rust
1 + 'foo'
  ^ function `plus` has no overload for parameters `(Int8, String)`

  available overloads:
    plus(Int8, Int8) -> Int8
    plus(Int16, Int16) -> Int16
    plus(Timestamp, Timestamp) -> Timestamp
    plus(Date, Date) -> Date
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Type Judgement

Formal rules to **prove type** of a expression

</div>
<div>

1. Rule to assume the type of **boolean** literal

```rust
⊢ TRUE : Boolean
```

<hr/>

2. Also, the same for **numbers** and **string**

```rust
⊢ 1 : Int8
⊢ "foo" : String
```

<hr/>

3. Rule to prove the type of **function call**
```rust
Γ ⊢ e1 : Int8     Γ ⊢ e2 : Int8
--------------------------------
    Γ ⊢ plus(e1, e2) : Int8


*Γ : Type Environment
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Type Environment

The meaning of the mystery `Γ`

</div>
<div>

What is the type of variable `a`?

```sql
SELECT 1 + a
```

<hr/>

a. determined by querying the **table metadata**

```sql
SELECT 1 + a from t
```

<hr/>

b. determined by type checking the **subquery**

```sql
SELECT 1 + a from (
    SELECT number as a from numbers(100)
)
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Subtype

</div>
<div>

1. Given an AST

```rust
1 + 256
```

<hr/>

2. **Desugar** AST to funtion call

```rust
plus(Int8, Int16)
```

<hr/>


3. oops! There is no matching overloads

```rust
plus(Int8, Int8) -> Int8
plus(Int16, Int16) -> Int16
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Subtype

</div>
<div>

4. Because `Int8` is subtype of `Int16`,  `Int8` can be cast to `Int16`

```rust
Int8 <: Int16
```

<hr/>


5. Update the type rule of function call to accept **subtype**

```rust
Γ ⊢ e1 : T1     Γ ⊢ e2 : T2     T1 <: In16     T2 <: Int16
-----------------------------------------------------------
                Γ ⊢ plus(e1, e2) : Int16
```

<hr/>


6. Finally we prove

```rust
⊢ plus(1, 256) : Int16
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Generic

</div>
<div>

1. Type of **array**

```rust
⊢ [1, 2, 3] : Array<Int8>
```

<hr/>

2. oops! It's impossible to enumerate all possible types

```rust
get(Array<Int8>, Int64) -> Int8
get(Array<Array<Int8>>, Int64) -> Array<Int8>
get(Array<Array<Array<Int8>>>, Int64) -> Array<Array<Int8>>
...
```

<hr/>

3. Use **generic** in the function signature

```rust
get<T>(Array<T>, Int64) -> T
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Generic

</div>
<div>

4. Assume we are checking this expression

```rust
get([1, 2, 3], 0)
```

<hr/>

5. Type check its arguments first

```rust
get(Array<Int8>, Int8)

```

<hr/>

6. We have got the **substitution** after **unification**, then apply the substitution to the signature

```rust
{T=Int8}
// then apply the substitution to the signature
get<Int8>(Array<Int8>, Int64) -> Int8
```

<hr/>

7. Finally we prove

```rust
⊢ get([1, 2, 3], 0) : Int8
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

Typechecker produces expression that is ready to be evaluated

```rust
pub enum Expr {
    Constant {
        scalar: Scalar,
        data_type: DataType,
    },
    ColumnRef {
        id: String,
        data_type: DataType,
    },
    Cast {
        is_try: bool,
        expr: Box<Expr>,
        dest_type: DataType,
    },
    FunctionCall {
        name: String,
        args: Vec<Expr>,
        return_type: DataType,
        eval: Box<Fn([Value]) -> Value>,
    },
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

Expression of `1 + a`

```rust
Expr::FunctionCall {
    name: "plus",
    args: [
        Expr::Constant {
            scalar: Scalar::Int8(1),
            data_type: DataType::int8,
        },
        Expr::ColumnRef {
            id: "a",
            data_type: DataType::Int8,
        },
    ],
    return_type: DataType::Int8,
    eval: Box<Fn([Value]) -> Value>,
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

The place where actual work takes place

```rust
fn plus_eval(args: &[Value]) -> Value {
    ...
}
```

<hr/>

Vectorized input which can either be a **column** or **scalar** (all values are same)

```rust
enum Value {
    Scalar(Scalar),
    Column(Column),
}

enum Scalar {
    Int8(i8),
    Int16(i16),
    Boolean(bool),
    ...
}

enum Column {
    Int8(Vec<i8>),
    Int16(Vec<i16>),
    Boolean(Vec<bool>),
    ...
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

A working example for `plus(Int8, Int8) -> Int8`

```rust
fn plus_eval(args: &[Value]) -> Value {
    match (&args[0], &args[1]) {
        (Value::Scalar(Scalar::Int8(lhs)), Value::Scalar(Scalar::Int8(rhs))) => {
            Value::Scalar(Scalar::Int8(lhs + rhs))
        },
        (Value::Column(Column::Int8(lhs)), Value::Scalar(Scalar::Int8(rhs))) => {
            let result: Vec<i8> = lhs
                .iter()
                .map(|lhs| *lhs + rhs)
                .collect();
            Value::Column(Column::Int8(result))
        },
        (Value::Scalar(Scalar::Int8(lhs)), Value::Column(Column::Int8(rhs))) => {
            let result: Vec<i8> = rhs
                .iter()
                .map(|rhs| lhs + *rhs)
                .collect();
            Value::Column(Column::Int8(result))
        },
        (Value::Column(Column::Int8(lhs)), Value::Column(Column::Int8(rhs))) => {
            let result: Vec<i8> = lhs
                .iter()
                .zip(rhs.iter())
                .map(|(lhs, rhs)| *lhs + *rhs)
                .collect();
            Value::Column(Column::Int8(result))
        },
        _ => unreachable!()
    }
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

Extract the pattern for **vectorization**

```rust
fn register_2_arg_int8(&mut self, name: String, eval: impl Fn(i8, i8) -> i8) {
    self.register_function(Function {
        signature: FunctionSignature {
            name: "plus",
            arg: [DataType::Int8, DataType::Int8],
            return_type: DataType::Int8,
        },
        eval: |args: &[Value]| -> Value {
            match (&args[0], &args[1]) {
                (Value::Scalar(Scalar::Int8(lhs)), Value::Scalar(Scalar::Int8(rhs))) => {
                    Value::Scalar(Scalar::Int8(eval(lhs, rhs)))
                },
                (Value::Column(Column::Int8(lhs)), Value::Scalar(Scalar::Int8(rhs))) => {
                    let result: Vec<i8> = lhs
                        .iter()
                        .map(eval(*lhs, rhs))
                        .collect();
                    Value::Column(Column::Int8(result))
                },
                (Value::Scalar(Scalar::Int8(lhs)), Value::Column(Column::Int8(rhs))) => {
                    let result: Vec<i8> = rhs
                        .iter()
                        .map(eval(lhs, *rhs))
                        .collect();
                    Value::Column(Column::Int8(result))
                },
                (Value::Column(Column::Int8(lhs)), Value::Column(Column::Int8(rhs))) => {
                    let result: Vec<i8> = lhs
                        .iter()
                        .zip(rhs.iter())
                        .map(|(lhs, rhs)| eval(*lhs, *rhs))
                        .collect();
                    Value::Column(Column::Int8(result))
                },
                _ => unreachable!()
            }
        }
    });
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

As a result, it's easy to register overload for any **vectorized** input

```rust
registry.register_2_arg_int8("plus", |lhs: i8, rhs: i8| lhs + rhs);
registry.register_2_arg_int8("minus", |lhs: i8, rhs: i8| lhs - rhs);
```

<hr/>

But still many **duplicated types** to register

```rust
registry.register_2_arg_int16("plus", |lhs: i16, rhs: i16| lhs + rhs);
registry.register_2_arg_int16("minus", |lhs: i16, rhs: i16| lhs - rhs);
registry.register_2_arg_int32("plus", |lhs: i32, rhs: i32| lhs + rhs);
registry.register_2_arg_int32("minus", |lhs: i32, rhs: i32| lhs - rhs);
registry.register_2_arg_int64("plus", |lhs: i64, rhs: i64| lhs + rhs);
registry.register_2_arg_int64("minus", |lhs: i64, rhs: i64| lhs - rhs);
```

</div>
</div>

---

## Evaluation

<div class="grid grid-cols-2 gap-20 items-start">
<div>


```rust
// Marker type for `Int8`
struct Int8Type;

// Define all methods needed to process data of the type
trait ValueType {
    type Scalar;
    
    fn data_type() -> DataType;
    fn downcast_scalar(Scalar) -> Self::Scalar;
    fn upcast_scalar(Self::Scalar) -> Scalar;
    fn iter_column(Column) -> impl Iterator<Item = Self::Scalar>;
    fn collect_iter(impl Iterator<Item = Self::Scalar>) -> Column;
}
```

</div>
<div>

```rust
impl ValueType for Int8Type {
    type Scalar = i8;

    fn data_type() -> DataType {
        DataType::Int8
    }
    fn downcast_scalar(scalar: Scalar) -> Self::Scalar {
        match scalar {
            Scalar::Int8(val) => val,
            _ => unreachable!(),
        }
    }
    fn upcast_scalar(scalar: Self::Scalar) -> Scalar {
        Scalar::Int8(scalar)
    }
    fn iter_column(col: Column) -> impl Iterator<Item = Self::Scalar> {
        match col {
            Column::Int8(col) => col.iter().cloned(),
            _ => unreachable!(),
        }
    }
    fn collect_iter(iter: impl Iterator<Item = Self::Scalar>) -> Column {
        let col = iter.collect();
        Column::Int8(col)
    }
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

Extract the data type using **marker type**

```rust
fn register_2_arg<I1: ValueType, I2: ValueType, Output: ValueType>(
    &mut self,
    name: String,
    eval: impl Fn(I1::Scalar, I2::Scalar) -> Output::Scalar
) {
    self.register_function(Function {
        signature: FunctionSignature {
            name: "plus",
            arg: [I1::data_type(), I2::data_type()],
            return_type: Output::data_type(),
        },
        eval: |args: &[Value]| -> Value {
            match (&args[0], &args[1]) {
                (Value::Scalar(lhs), Value::Scalar(rhs)) => {
                    let lhs: I1::Scalar = I1::downcast_scalar(lhs);
                    let rhs: I2::Scalar = I2::downcast_scalar(rhs);
                    let res: Output::Scalar = eval(lhs, rhs);
                    Output::upcast_scalar(O::upcast_scalar(res))
                },
                ...
            }
        }
    });
}
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Evaluation

</div>
<div>

As a result, its easy to register overload for input of **any data type**

```rust
registry.register_2_arg::<Int8Type, Int8Type, Int8Type>(
    "plus", |lhs: i8, rhs: i8| lhs + rhs
);
registry.register_2_arg::<Int8Type, Int8Type, Int8Type>(
    "minus", |lhs: i8, rhs: i8| lhs - rhs
);
```

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Conclusion

</div>
<div class='grid justify-items-center'>

<pre class='mermaid'>
flowchart
    Query -.- Parser:::notice -.- TypeChecker[Type Check]:::notice -.- Planner -.- Pipeline -.- Evaluation:::notice -.- Storage
</pre>

</div>
</div>

---

<div class="grid grid-cols-2 gap-20">
<div>

## Conclusion

</div>
<div>

![](https://m.media-amazon.com/images/I/41kqKqZhzpL._SX426_BO1,204,203,200_.jpg)
*Types and Programming Languages*

</div>
</div>
