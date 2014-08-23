---
layout: post
title: "Notes on Lambda Calculus"
date:   2013-07-27 17:14:41
---

What a pity that I haven't been taught lambda calculus in university, accompany with my Scheme and Haskell study, the lambda calculi has been exposed so many times that I decided to master it to a certain degree.

This post will be constantly updated to track my understanding on lambda calculus, and help me to remember those concepts. Its another intention is to test the $\text{MathJax}\ \LaTeX$ support in my blog engine, $\heartsuit$ those beautiful symbols!


Basic definition
----------------

Lambda calculus (λ-calculus) is a formal system in mathematical logic and computer science for expressing computation by way of variable binding and substitution.

The system consists of a language of lambda expressions, and a set of transformation rules, which allow manipulation of lambda expressions.

For example, $(x,y) \mapsto x^3 + x \times y$ in lambda expression: $\lambda x.\lambda y.x^3 + x \times y$.


###Lambda expressions###

According to Wikipedia and most materials,  lambda expressions are composed of:

1. variables **v~1~, v~2~ ...**
2. abstraction symbols **λ** and **.**
3. parentheses **( )**

The set of lambda expressions, $\Lambda$, can be defined inductively:

1. $\text{If x is a variable, then } x \in \Lambda$
2. $\text{If x is a variable and } M \in \Lambda\text{, then } \lambda x.M \in \Lambda$
3. $\text{If } M, N \in \Lambda\text{, then } (M\ N) \in \Lambda$ 

Instances of rule 2 are known as **abstractions** and instances of rule 3 are known as **applications**.

Some people (in the references) may use different symbols for the identical meaning, but I will insist on the wikipedia manner.


###Free variables###

The abstraction operator, $\lambda$, is said to bind its variable wherever it occurs in the abstraction body. For example, in $\lambda x.x\ x\ y$, $x$ is bound, and $y$ is free.

Also note that a variable is bound by its **nearest abstraction**. In the following example the single occurrence of $x$ in the expression is bound by the second lambda: $\lambda x.y\ (\lambda x.z\ x)$.

The set of free variables of a lambda expression, $M$, is denoted by $FV(M)$ and defined by recursion:

1. $FV(x) = \{x\}, \text{where x is a variable}$
2. $FV(\lambda x.M) = FV(M) \setminus \{x\}$
3. $FV(M\ N) = FV(M) \cup FV(N)$

An expression that contains no free variables is said to be closed. Closed lambda expressions are also known as **combinators** and are equivalent to terms in combinatory logic.


###Substitutions###

Substitution, written $E[v := R]$, is the process of replacing all the **free occurrences** of the variable $v$ in the expression $E$ with expression $R$.

$\begin{aligned}
x[x := N] & \equiv N \\
y[x := N] & \equiv y, \text{ if } x \neq y \\
(M_1\ M_2)[x := N] & \equiv (M_1[x := N])(M_2[x := N) \\
(\lambda x.M)[x := N] & \equiv \lambda x.M \\
(\lambda y.M)[x := N] & \equiv \lambda y.(M[x := N]), \text{ if } x \neq y, \text{ provided } y \notin FV(N)
\end{aligned}$

To understand the substitution, should adhere with the restriction of **free** variable in the definition. So $x[x := N] \equiv N$, cause $FV(x) = \{x\}$. And because $x \notin FV(\lambda x.M)$ (i.e. $x$ isn't free), so no need to replace $x$ in $\lambda x.M$, i.e. $(\lambda x.M)[x := N] \equiv \lambda x.M$.

The freshness condition (requiring $y \notin FV(N)$) is crucial to ensure the substitution doesn't change the meaning of the expression. For example, in $(\lambda y.x)[x := y]$, $FV(N) = \{y\}$ (i.e. $y$ is a free variable of $N$), if we ignore this and substitute $x$ with $y$, then the expression would be $\lambda y.(x[x := y]) \equiv \lambda y.y$, the function $f(y) = x$ is turned into $f(y) = y$. 

To overcome this, we can do an **α-conversion** at first, $\lambda y.x \equiv \lambda z.x$, then the substitution should be $(\lambda z.x)[x := y] \equiv \lambda z.y$.


Transformations
---------------

The meaning of lambda expressions is defined by how expressions can be transformed or reduced. There are three kinds of transformations.


###α-conversion###

Alpha-conversion, sometimes known as alpha-renaming, allows **bound variable** names to be changed. For example, alpha-conversion of $\lambda x.x$ might yield $\lambda y.y$. Terms that differ only by alpha-conversion are called **α-equivalent**. Frequently in uses of lambda calculus, α-equivalent terms are considered to be equivalent.


###β-reduction###

Beta-reduction is just function application (also called a function call), to substitute the formal parameter with the actual parameter expression: $((\lambda v.E)\ E′) \rightarrow E[v := E′]$.

For example, $((\lambda n.n \times 2)\ 7) \rightarrow (n \times 2)[n := 7] \rightarrow 7 \times 2$.


###η-conversion###

Eta-conversion converts between $F$ and $\lambda x.(F\ x)$ whenever $x \notin FV(F)$. In other words, η-conversion is adding or dropping of abstraction over a function. We can prove that they give the same result for all arguments: $(\lambda x.(F\ x))\ v \rightarrow (F[x := v])(x[x := v]) \rightarrow F\ v$.

Eta-conversion expresses the idea of extensionality, which in this context is that two functions are the same if and only if they give the same result for all arguments. If we have $F\ x \equiv G\ x$, then $F \equiv \lambda x.(F\ x) \equiv \lambda x.(G\ x) \equiv G$.


###Redex and reduct###

The term redex, short for **reducible expression**, refers to subterms that can be reduced by one of the transformation rules. The expression to which a redex reduces is called its reduct.

For example, $(\lambda x.M)\ N$ is a **β-redex**, if $x$ is not free in $M$, $\lambda x.M\ x$ is an **η-redex**. The reducts of these expressions are respectively $M[x:=N]$ and $M$.


###Normalizing###

An expression is said to be in **β-normal form** if it has no β-redexes (i.e. no β-reduction is possible), e.g. $F := (\lambda x.x)((\lambda x.x)(\lambda x.y)) \rightarrow (\lambda x.x)(\lambda x.y) \rightarrow \lambda x.y$, in two β-reductions,  $F$ is evaluated to its β-normal form $\lambda x.y$.

For expression, $E := \lambda x_1 \ldots \lambda x_m.H_1 \ldots H_n, m \geq 0, n \geq 1$, if $H_1$ is a redex, it's common called head redex, the reduction is called head reduction. Once reduced to $H_i$, which is not a redex, then $E$ is said in **HNF (head normal form)**. Any β-normal form expression is in HNF, not vice versa, e.g. $\lambda x.(x\ (\lambda y.y\ z))$.

Following the above definition of $E$, if $m = 1$, we get expression $\lambda x.H_1 \ldots H_n$, then $E$ is said in **WHNF (weak head normal form)**, despite $H_1$ is a redex. Any HNF expression is in WHNF, not vice versa, e.g. $\lambda x.(\lambda y.y\ z)$.


References
----------

Most of the texts are quoted from resources below, with some modifications according to my understanding, some mistakes may occur, I will keep improving.

1. [Wikipedia: Lambda Calculus](http://en.wikipedia.org/wiki/Untyped_lambda_calculus), so many links to follow from this page.
2. [SEP: The Lambda Calculus](http://plato.stanford.edu/entries/lambda-calculus/index.html), a quick, brief and precise reference to this topic.
3. [The Little Schemer](http://www.ccs.neu.edu/home/matthias/BTLS/), there is a good derivation of Y Combinator in chapter 9.
4. [Lecture Notes on the Lambda Calculus](http://www.mathstat.dal.ca/~selinger/papers/lambdanotes.pdf), a set of great lecture notes developed out of courses on lambda calculus by Peter Selinger.
5. [mvanier: The Y Combinator (Slight Return)](http://mvanier.livejournal.com/2897.html), using Scheme to understand the Y Combinator.
6. [HaskellWiki](http://www.haskell.org/haskellwiki/Haskell), there're many useful articles combining the programming language design and lambda calculus.
7. [SoftOption: Normal Forms and Termination](http://softoption.us/content/node/37), with detailed introduction to different normal forms.
8. [Head Linear Reduction - Institut de Mathématiques de Luminy](http://iml.univ-mrs.fr/~regnier/articles/pam.ps.gz).
