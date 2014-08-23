---
layout: post
title: "GCC and Clang Vector Extensions"
date:   2013-07-23 08:25:59
---

Recently, I've been picking up some old OpenGL stuffs (e.g. [Valo](https://github.com/vecio/Valo)), with so little experiences in this domain, didn't find a reasonable C solution for matrices manipulation, so I made a decision to craft my own one, [3DM](https://github.com/vecio/3DM).

Then I began my journey of pursuing the 'better' solution, and came across the vector extensions from the two most popular C compilers, which were designed to be fast and cross-platform.


GCC Vector Extensions
---------------------

From [GCC's docs](http://gcc.gnu.org/onlinedocs/gcc/Vector-Extensions.html), I think the vector extensions are easily usable since version 4.7, it gives out the actual identical result to what I thought should be.

```c
typedef double vec4d __attribute__ ((vector_size(32)));

vec4d v1 = {1, 2, 3, 4};
vec4d v2 = {7, 8, 9, 10};

vec4d v3 = v1 * v2; // {7, 16, 27, 40}
vec4d v4 = 7 * v1; // {7, 14, 21, 28}
vec4d v5 = v1 + (vec4d){0,1}; // {1, 3, 3, 4}

double a = v1[0] + v2[3]; // 1 + 10
```

Yes, it just works! And the vector type can also be used as function parameters and return values, just like the normal double value.

The `vector_size` attribute can also be used directly without `typedef`.

```c
#define vector(type,size) type __attribute__ ((vector_size(sizeof(type)*(size))))

vector(float, 3) v1 = {1, 2, 3};
vector(float, 3) v2 = v1 - (vector(float, 3)){1}; // {0, 2, 3}
```

Besides these obvious vector algebra, GCC also provides a shuffling feature through `__builtin_shuffle`, we can use it to do some fast vector permutations, for example, to transpose a matrix.

```c
typedef double mat4d __attribute__ ((vector_size(128)));

mat4d mat4d_transpose(mat4d m)
{
  vector(long, 16) mask = {0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15};
  return __builtin_shuffle(m, mask);
}
```

Just remember all parameters of `__builtin_shuffle` should have the same count and same length, and `mask` should be a **integral** type (e.g. short, int, long).


Clang Vectors and Extended Vectors
----------------------------------

Only in recent days, I found Clang much better than GCC, it produces smaller and faster binary by default, the log is colorful and readable, even the online documents are not in GCC's old days.

In supporting vectors, Clang is compatible with GCC, [accompany with three additional extensions: OpenCL, AltiVec and NEON](http://clang.llvm.org/docs/LanguageExtensions.html#vectors-and-extended-vectors).

The `vector_size` in Clang is mostly the same as GCC's, with only one exception I found, you can't do scalar operation to vectors.

```c
typedef double vec4d __attribute__ ((vector_size(32)));

vec4d v1 = {1, 2, 3, 4};
vec4d v2 = 3 * {1, 2, 3, 4}; // error: can't convert between vector values of different size ('vec4d' and 'double')
```

But the OpenCL style vectors with the `ext_vector_type` attribute can support all the (and more) operations provided by `vector_size` from GCC.

```c
typedef double vec4d __attribute__ ((ext_vector_type(4)));

vec4d v1 = {1, 2, 3, 4};
vec4d v2 = 3 * {1, 2, 3, 4}; // {3, 6, 9, 12}

v1.w = -7; // v1 = {1, 2, 3, -7}
v1.xyz = 8; // v1 = {8, 8, 8, -7}
v2.xy = {1, 2}; // v2 = {1, 2, 9, 12}
```

It's interesting that the types with the two attributes can work with each other, seamlessly.

```c
typedef double vec4d __attribute__ ((vector_size(32)));
typedef double vec4de __attribute__ ((ext_vector_type(4)));

vec4d v1 = {1, 2, 3, 4};
vec4de v2 = {7, 8, 9, 10};
vec4d v3 = v1 + v2; // {8, 10, 12, 14}
```

But `ext_vector_type` is not capable of everything, it can only be used in the `typedef`, you just can't use it like the `vector(type,size)` macro we defined for `vector_size`.


Troubleshooting
---------------

Until now, just one big problem occurred, the program would crash in some situations, but when I tried to trace the problem with valgrind, the problem just disappeared! For details, check the GitHub issue [General Protection Fault ](https://github.com/vecio/3DM/issues/1).

I haven't done any optimizations and benchmarks yet, and haven't tried it in other platforms either. So I don't know if these extensions deserve.
