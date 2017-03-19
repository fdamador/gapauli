(* ::Package:: *)

(* copy this module to a directory in $Path.  Then invoke with <<GA13` *)
BeginPackage[ "GA13`" ]
GA13::usage = "GA13: An implementation of a Minkowski (CL(1,3)) Geometric Algebra.

Dirac matrices are used to represent the algebraic elements.  This provides an fairly efficient and compact representation
of the entire algebraic space.  This representation unfortunately has a built in redundancy, since the complex
4x4 matrix has 32 degrees of freedom, while there are only 16 elements in the algebraic space.

Internally, a multivector is represented by a pair (grade, dirac-representation).  The grade portion will be
obliterated when adding objects that have different grade, or multiplying vectors or bivectors.  When
it is available, certain operations can be optimized.  Comparison ignores the cached grade if it exists.

Elements of the algebra can be constructed with one of

   Scalar[ v ]
   Vector[ v, n ]
   Bivector[ v, n, m ]
   Trivector[ v, n, m, o ]
   Quadvector[ v ]

Example:

   m = Scalar[ Sin[ x ] ] + Vector[ Log[ z ], 3 ] + Trivector[ 7, 0, 1, 3 ] ;
   m // StandardForm

> 7 e[ 123 ] + e[ 3 ] Log[ z ] + Sin[ x ]

A few operators are provided:
   ==         Compare two multivectors, ignoring the cached grade if any.
   m1 + m2
   m1 - m2
   - m
   st * vb    Scalars and trivectors can multiply vectors and bivectors in any order
   vb1 ** vb1 Vectors and bivectors when multiplied have to use the NonCommutativeMultiply operator, but any grade object may also.
   m1 . m2    Dot product.  The functional form Dot[ m1, m2 ] may also be used.
   m1 ^ m2   Wedgeproduct.  Enter with m1 [ Esc ]^[ Esc ] m2.  The functional form Wedge[ m1, m2 ]
   <m>        Scalar selection.  Enter with [ Esc ]<[ Esc ] m [ Esc ]>[ Esc ].  The functional form ScalarValue[ m ] may also be used.  This returns the numeric (or expression) value of the scalar grade of the multivector, and not a grade[ ] object.
   <m1,m2>    Scalar product.  Enter with [ Esc ]<[ Esc ] m1,m2 [ Esc ]>[ Esc ].  The functional form ScalarProduct[ m1, m2 ] may also be used.  This returns the numeric (or expression) value of the scalar product of the multivectors, and not a grade[ ] object.

   Functions provided:

   - GradeSelection
   - ScalarSelection
   - VectorSelection
   - BivectorSelection
   - TrivectorSelection
   - QuadvectorSelection
   - ScalarValue, < m >
   - ScalarProduct, < m1, m2 >

The following built-in methods are overridden:

   - TraditionalForm
   - DisplayForm
   - StandardForm

Internal functions:

   - scalarQ
   - vectorQ
   - bivectorQ
   - trivectorQ
   - quadvectorQ
   - bladeQ
   - gradeAnyQ
   - notGradeQ

TODO:

1) How to get better formatted output by default without using one of TraditionalForm, DisplayForm, StandardForm ?

2) Can a package have options (i.e. to define the name of the e[ ] operator used in StandardForm that represents a basis vector).

3) proper packaging stuff:  private for internals.
" ;

(*BEGIN: << altcomplex`;*)

(* copy this module to a directory in $Path.  Then invoke with <<GA13` *)
(*BeginPackage[ "complex`" ]*)

Unprotect[ complex, complexQ, notComplexQ, real, imag, conjugate, complexI, fMatrix, matrixreal, matriximag, matrixconj ] ;

complex::usage =
  "complex.  A limited use complex number implementation to use internally in \
a Dirac or Dirac matrix basis representation, independent of any Complex" ;
ClearAll[ complex, complexQ, notComplexQ, real, imag, conjugate ] ;

complex /: complex[ r1_, i1_ ] + complex[ r2_, i2_ ] := complex[ r1 + r2, i1 + i2 ] ;
complex /: r1_ + complex[ r2_, i2_ ] := complex[ r1 + r2, i2 ] ;

complex /: -complex[ re_, im_ ] := complex[ -re, -im ] ;

complex /: complex[ re_ ] := re ;
complex /: complex[ re_, 0 ] := re ;

complex /: complex[ r1_, i1_ ] complex[ r2_, i2_ ] := complex[ r1 r2 - i1 i2, r1 i2 + r2 i1 ] ;

norm::usage = "norm[ z ].  A Norm like function for complex[ ]" ;
norm[ z_complex ] := ((z // First)^2 + (z // Last)^2) ;

(*special case this one to deal with the sort of products that are \
generated multiplying dirac matrices*)

complex /: Power[ z_complex, 2 ] := complex[ z ] complex[ z ] ;
complex /: Power[ z_complex, n_ ] :=
  Module[ {r = norm[ z ]^(n/2), theta = n ArcTan[ z // First, z // Last ]},
    r complex[ Cos[ theta ], Sin[ theta ] ] ] ;

complexQ::usage = "complexQ[ z ].  predicate pattern match for complex[ ]" ;
complexQ[ z_complex ] := True ;
complexQ[ _ ] := False ;
notComplexQ::usage = "notComplexQ[ z ].  predicate pattern match for !complex[ ]" ;
notComplexQ[ v_ ] := Not[ complexQ[ v ] ] ;

complex /: (v_?notComplexQ) complex[ re_, im_ ] := complex[ v re, v im ] ;

real::usage = "real[ z ].  Re[ z ] like function for complex[ ]" ;
real[ z_complex ] := (z // First) ;
imag::usage = "imag[ z ].  Im[ z ] like function for complex[ ]" ;
imag[ z_complex ] := (z // Last) ;
real[ ex_ ] := ex ;
imag[ ex_ ] := 0 ;
conjugate::usage = "conjugate[ z ].  Conjugate[ z ] like function for complex[ ]" ;
conjugate[ z_complex ] := complex[ z // First, -z // Last ] ;
conjugate[ ex_ ] := ex ;

ClearAll[ complexI, fMatrix, matrixreal, matriximag, matrixconj ]
complexI::usage = "complexI.  I like unit imaginary for complex[ ]" ;
complexI := complex[ 0, 1 ] ;

fMatrix::usage = "thread a function f over all the elements p in a list." ;
fMatrix[ p_, f_ ] := (Function[ a, f@a, Listable ]@p)

matrixreal::usage =
  "matrixreal.  method to apply real to all elements in matrix.  This is a hack.  \
Can probably set an attribute on the real function to do this." ;
matrixreal[ m_ ] := fMatrix[ m, real ] ;

matriximag::usage =
  "matriximag.  method to apply imag to all elements in matrix.  This is a hack.  \
Can probably set an attribute on the imag function to do this." ;
matriximag[ m_ ] := fMatrix[ m, imag ] ;

matrixconj::usage =
  "matrixconj.  method to apply conjugate to all elements in matrix.  This is a \
hack.  Can probably set an attribute on the conj function to do this." ;
matrixconj[ m_ ] := fMatrix[ m, conjugate ] ;

Protect[ complex, complexQ, notComplexQ, real, imag, conjugate, complexI, fMatrix, matrixreal, matriximag, matrixconj ] ;

(*EndPackage[ ]*)
(*END: << altcomplex`;*)

Unprotect[ Scalar, Vector, Bivector, Trivector,
GradeSelection, ScalarSelection, VectorSelection, BivectorSelection, TrivectorSelection, e,
ScalarValue, ScalarProduct
] ;

ClearAll[ diracGammaMatrix, conjugateTranspose ]
diracGammaMatrix::usage =
  "diracGammaMatrix[ n ], n = 1,2,3,4.  This is like the DiracGammaMatrix[ ] mentioned in mathpages implemented with complex[ ], instead of Complex[ ]." ;
diracGammaMatrix[1] = ArrayFlatten[{{DiagonalMatrix[{0, 0}],  PauliMatrix[1]}, {-PauliMatrix[1], DiagonalMatrix[{0, 0}]}}];
diracGammaMatrix[2] = ArrayFlatten[{{DiagonalMatrix[{0, 0}],  PauliMatrix[2]}, {-PauliMatrix[2], DiagonalMatrix[{0, 0}]}}];
diracGammaMatrix[3] = ArrayFlatten[{{DiagonalMatrix[{0, 0}],  PauliMatrix[3]}, {-PauliMatrix[3], DiagonalMatrix[{0, 0}]}}];
diracGammaMatrix[4] = DiagonalMatrix[{1, 1, -1, -1}];
conjugateTranspose::usage =
  "conjugateTranspose[ ].  ConjugateTranspose[ ] like operation for diracGammaMatrix." ;
conjugateTranspose[ m_List ] := Transpose[ matrixconj[ m ] ] ;
(*End[ "`Private`" ]*)

Unprotect[ TraditionalForm, DisplayForm, StandardForm ] ;
TraditionalForm[ z_complex ] := (((z // real) + I (z // imag)) // TraditionalForm)
DisplayForm[ z_complex ] := (((z // real) + I (z // imag)) // DisplayForm)
StandardForm[ z_complex ] := (((z // real) + I (z // imag)) // StandardForm)
Protect[ TraditionalForm, DisplayForm, StandardForm ] ;

(* End of complex, and diracGammaMatrix section.  Define the basic CL(3,0) operations. *)

Unprotect[ Scalar, Vector, Bivector, Trivector,
GradeSelection, ScalarSelection, VectorSelection, BivectorSelection, TrivectorSelection, e,
ScalarValue, ScalarProduct, Pseudoscalar
] ;

Pseudoscalar = diracGammaMatrix[0].diracGammaMatrix[1].diracGammaMatrix[2].diracGammaMatrix[3];

grade::usage = "grade.  (internal) An upvalue type that represents a CL(3,0) algebraic element as a pair {grade, v}, where v is a sum of products of Dirac matrices.  These matrices may be scaled by arbitrary numeric or symbolic factors." ;
ClearAll[ Vector, Scalar, Bivector, Trivector, grade ]
Scalar::usage = "Scalar[ v ] constructs a scalar grade quantity with value v." ;
Scalar[ v_ ] := grade[ 0, v IdentityMatrix[ 2 ] ] ;
Vector::usage = "Vector[ v, n ], where n = {1,2,3} constructs a vector grade quantity with value v in direction n." ;
Vector[ v_, k_Integer /; k >= 1 && k <= 3 ] := grade[ 1, v diracGammaMatrix[ k ] ] ;
Bivector::usage = "Bivector[ v, n1, n2 ], where n1,n2 = {1,2,3} constructs a bivector grade quantity with value v in the plane n1,n2." ;
Bivector[ v_, k_Integer /; k >= 1 && k <= 3, j_Integer /; j >= 1 && j <= 3 ] := grade[ 2, v diracGammaMatrix[ k ].diracGammaMatrix[ j ] ] ;
Trivector::usage = "Trivector[ v, k, l, m ] constructs a trivector (pseudoscalar) grade quantity scaled by v." ;
Trivector[ v_, k_, l_, m_ ] := grade[ 3, v diracGammaMatrix[k].diracGammaMatrix[l].diracGammaMatrix[m] ] ;
Quadvector::usage = "Quadvector[ v ] constructs a quadvector (pseudoscalar) grade quantity scaled by v." ;
Quadvector[ v_ ] := grade[ 4, v Pseudoscalar ];

(*Begin[ "`Private`" ]*)
ClearAll[ scalarQ, vectorQ, bivectorQ, trivectorQ, bladeQ ]
gradeQ::usage = "gradeQ[ m, n ] tests if the multivector m is of grade n.  n = -1 is used internally to represent values of more than one grade." ;
gradeQ[ m_grade, n_Integer ] := ((m // First) == n)
scalarQ::usage = "scalarQ[ m ] tests if the multivector m is of grade 0 (scalar)" ;
scalarQ[ m_grade ] := gradeQ[ m, 0 ]
vectorQ::usage = "vectorQ[ m ] tests if the multivector m is of grade 1 (vector)" ;
vectorQ[ m_grade ] := gradeQ[ m, 1 ]
bivectorQ::usage = "bivectorQ[ m ] tests if the multivector m is of grade 2 (bivector)" ;
bivectorQ[ m_grade ] := gradeQ[ m, 2 ]
trivectorQ::usage = "trivectorQ[ m ] tests if the multivector m is of grade 3 (trivector)" ;
trivectorQ[ m_grade ] := gradeQ[ m, 3 ]
quadvectorQ::usage = "quadvectorQ[ m ] tests if the multivector m is of grade 4 (quadvector)" ;
quadvectorQ[ m_grade ] := gradeQ[ m, 4 ]
bladeQ::usage = "bladeQ[ m ] tests if the multivector is of a single grade." ;
bladeQ[ m_grade ] := ((m // First) >= 0)
gradeAnyQ::usage = "gradeAnyQ[ ].  predicate pattern match for grade[ _ ]" ;
gradeAnyQ[ m_grade ] := True
gradeAnyQ[ _ ] := False
notGradeQ::usage = "notGradeQ[ ].  predicate pattern match for !grade[ ]" ;
notGradeQ[ v_ ] := Not[ gradeAnyQ[ v ] ]

ClearAll[ directProduct, signedSymmetric, symmetric, antisymmetric ]

directProduct[ t_, v1_, v2_ ] := grade[ t, (v1 // Last).(v2 // Last) ] ;
signedSymmetric[ t_, v1_, v2_, s_ ] :=
  Module[ {a = (v1 // Last), b = (v2 // Last)},
   grade[ t, (a.b + s b.a)/2 ] ] ;
symmetric[ t_, v1_, v2_ ] := signedSymmetric[ t, v1, v2, 1 ] ;
antisymmetric[ t_, v1_, v2_ ] := signedSymmetric[ t, v1, v2, -1 ] ;

(*These operator on just the Dirac matrix portions x of \
diracGradeSelect[ ,x ]*)
ClearAll[ diracGradeSelect ]
(*
diracGradeSelect[ m_, 0 ] := IdentityMatrix[ 2 ] (m/2 // Tr // real // Simplify) ;
diracGradeSelect[ m_, 1 ] := ((diracGradeSelect01[ m ] - diracGradeSelect[ m, 0 ]) // Simplify) ;
diracGradeSelect[ m_, 2 ] := ((diracGradeSelect23[ m ] - diracGradeSelect[ m, 3 ]) // Simplify) ;
diracGradeSelect[ m_, 3 ] := complexI IdentityMatrix[ 2 ] (m/2 // Tr // imag // Simplify) ;
*)

ClearAll[ diracGradeSelect0, diracGradeSelect1, diracGradeSelect2, diracGradeSelect3 ]
diracGradeSelect0 := diracGradeSelect[ #, 0 ] & ;
diracGradeSelect1 := diracGradeSelect[ #, 1 ] & ;
diracGradeSelect2 := diracGradeSelect[ #, 2 ] & ;
diracGradeSelect3 := diracGradeSelect[ #, 3 ] & ;
(*End[ "`Private`" ]*)

ClearAll[ GradeSelection, ScalarSelection, VectorSelection, BivectorSelection, TrivectorSelection ]

GradeSelection::usage = "GradeSelection[ m, k ] selects the grade k elements from the multivector m.  The selected result is represented internally as a grade[ ] type (so scalar selection is not just a number)." ;
GradeSelection[ m_?scalarQ, 0 ] := m ;
GradeSelection[ m_?vectorQ, 1 ] := m ;
GradeSelection[ m_?bivectorQ, 2 ] := m ;
GradeSelection[ m_?trivectorQ, 3 ] := m ;
GradeSelection[ m_?quadvectorQ, 4 ] := m ;
GradeSelection[ m_, k_Integer /; k >= 0 && k <= 4 ] := grade[ k, diracGradeSelect[ m // Last, k ] ] ;
ScalarSelection::usage = "ScalarSelection[ m ] selects the grade 0 (scalar) elements from the multivector m.  The selected result is represented internally as a grade[ ] type (not just a number or an expression)." ;
ScalarSelection := GradeSelection[ #, 0 ] & ;
VectorSelection::usage = "VectorSelection[ m ] selects the grade 1 (vector) elements from the multivector m.  The selected result is represented internally as a grade[ ] type." ;
VectorSelection := GradeSelection[ #, 1 ] & ;
BivectorSelection::usage = "BivectorSelection[ m ] selects the grade 2 (bivector) elements from the multivector m.  The selected result is represented internally as a grade[ ] type." ;
BivectorSelection := GradeSelection[ #, 2 ] & ;
TrivectorSelection::usage = "TrivectorSelection[ m ] selects the grade 3 (trivector) element from the multivector m if it exists.  The selected result is represented internally as a grade[ ] type (not just an number or expression)." ;
TrivectorSelection := GradeSelection[ #, 3 ] & ;
QuadvectorSelection::usage = "QuadvectorSelection[ m ] selects the grade 4 (trivector) element from the multivector m if it exists.  The selected result is represented internally as a grade[ ] type (not just an number or expression)." ;
QuadvectorSelection := GradeSelection[ #, 3 ] & ;


ClearAll[ binaryOperator ]
binaryOperator[ f_, b_?bladeQ, m_grade ] := Total[ f[ b, # ] & /@ (GradeSelection[ m, # ] & /@ (Range[ 4+1 ] - 1)) ]
binaryOperator[ f_, m_grade, b_?bladeQ ] := Total[ f[ #, b ] & /@ (GradeSelection[ m, # ] & /@ (Range[ 4+1 ] - 1)) ]
binaryOperator[ f_, m1_grade, m2_grade ] := Total[ f[ # // First, # // Last ] & /@ (
    {GradeSelection[ m1, # ] & /@ (Range[ 4+1 ] - 1),
     GradeSelection[ m2, # ] & /@ (Range[ 4+1 ] - 1)} // Transpose) ]

(* Plus *)
grade /: (v1_?notGradeQ) + grade[ k_, v2_ ] := Scalar[ v1 ] + grade[ k, v2 ] ;
grade /: grade[ 0, v1_ ] + grade[ 0, v2_ ] := grade[ 0, v1 + v2 ] ;
grade /: grade[ 1, v1_ ] + grade[ 1, v2_ ] := grade[ 1, v1 + v2 ] ;
grade /: grade[ 2, v1_ ] + grade[ 2, v2_ ] := grade[ 2, v1 + v2 ] ;
grade /: grade[ 3, v1_ ] + grade[ 3, v2_ ] := grade[ 3, v1 + v2 ] ;
grade /: grade[ _, v1_ ] + grade[ _, v2_ ] := grade[ -1, v1 + v2 ] ;

(* Times[ -1, _ ] *)
grade /: -grade[ k_, v_ ] := grade[ k, -v ] ;

(* Times *)
grade /: (v_?notGradeQ) grade[ k_, m_ ] := grade[ k, v m ] ;
grade /: grade[ 0, s_ ] grade[ k_, m_ ] := grade[ k, s.m ] ;
grade /: grade[ 3, p_ ] grade[ 1, m_ ] := grade[ 2, p.m ] ;
grade /: grade[ 3, p_ ] grade[ 2, m_ ] := grade[ 1, p.m ] ;
grade /: grade[ 3, p_ ] grade[ 3, m_ ] := grade[ 0, p.m ] ;
grade /: grade[ 3, p_ ] grade[ _, m_ ] := grade[ -1, p.m ] ;

(* NonCommutativeMultiply *)
grade /: grade[ 0, s_ ] ** grade[ k_, m_ ] := grade[ k, s.m ] ;
grade /: grade[ k_, m_ ] ** grade[ 0, s_ ] := grade[ k, s.m ] ;
grade /: grade[ 3, s_ ] ** grade[ k_, m_ ] := grade[ 3, s ] grade[ k, m ] ;
grade /: grade[ k_, m_ ] ** grade[ 3, s_ ] := grade[ 3, s ] grade[ k, m ] ;
grade /: grade[ _, m1_ ] ** grade[ _, m2_ ] := grade[ -1, m1.m2 ] ;

(* Dot *)
grade /: (s_?notGradeQ).grade[ k_, m_ ] := grade[ k, s m ] ;
grade /: grade[ k_, m_ ].(s_?notGradeQ) := grade[ k, s m ] ;
grade /: grade[ 0, s_ ].grade[ k_, m_ ] := grade[ k, s m ] ;
grade /: grade[ k_, m_ ].grade[ 0, s_ ] := grade[ k, s m ] ;

grade /: (t_?trivectorQ).m_grade := t m ;
grade /: m_grade.(t_?trivectorQ) := t m ;

grade /: (v1_?vectorQ).grade[ 1, v2_ ] := symmetric[ 0, v1, grade[ 1, v2 ] ] ;
grade /: (v_?vectorQ).grade[ 2, b_ ] := antisymmetric[ 1, v, grade[ 2, b ] ] ;
grade /: (b_?bivectorQ).grade[ 1, v_ ] := antisymmetric[ 1, b, grade[ 1, v ] ] ;
grade /: (b1_?bivectorQ).grade[ 2, b2_ ] := symmetric[ 0, b1, grade[ 2, b2 ] ] ;

(* == comparison operator *)
grade /: grade[ _, m1_ ] == grade[ _, m2_ ] := (m1 == m2) ;

(* Dot ; handle dot products where one or more factors is a multivector.  *)
grade /: grade[ g1_, m1_ ] . grade[ g2_, m2_ ]:= binaryOperator[ Dot, grade[ g1, m1 ], grade[ g2, m2 ] ] ;

grade[ _, {{0, 0}, {0, 0}} ] := 0

(*Define a custom wedge operator*)

grade /: grade[ 0, s_ ] \[Wedge] grade[ k_, v_ ] := grade[ k, s.v ] ;
grade /: grade[ k_, v_ ] \[Wedge] grade[ 0_, s_ ] := grade[ k, s.v ] ;
grade /: grade[ 1, v1_ ] \[Wedge] (v2_?vectorQ) := antisymmetric[ 2, grade[ 1, v1 ], v2 ] ;

grade /: grade[ 1, v1_ ] \[Wedge] (v2_?bivectorQ) := symmetric[ 3, grade[ 1, v1 ], v2 ] ;
grade /: grade[ 2, v1_ ] \[Wedge] (v2_?vectorQ) := symmetric[ 3, grade[ 2, v1 ], v2 ] ;
grade /: grade[ 2, _ ] \[Wedge] (v2_?bivectorQ) := 0 ;

(* Only e123 ^ scalar is none zero, and that is handled above *)
grade /: grade[ 3, _ ] \[Wedge] b_?bladeQ := 0 ;
grade /: b_?bladeQ \[Wedge] grade[ 3, _ ] := 0 ;

grade /: grade[ g1_, m1_ ] \[Wedge] grade[ g2_, m2_ ]:= binaryOperator[ Wedge, grade[ g1, m1 ], grade[ g2, m2 ] ] ;

ClearAll[ pmagnitude ]

(*Begin[ "`Private`" ]*)
pmagnitude::usage =
  "pmagnitude[ ].  select the 1,1 element from a dirac matrix assuming it represents \
either a Scalar, or a Trivector (i.e. scaled diagonal matrix)." ;
pmagnitude[ m_ ] := m[ [1, 1 ] ] ;
(*End[ "`Private`" ]*)

(* AngleBracket,single operand forms, enter with[ Esc ]<[ Esc ] \
v[ Esc ]>[ Esc ] *)
grade /: AngleBracket[ grade[ 0, s_ ] ] := pmagnitude[ s ]
grade /: AngleBracket[ grade[ 1, _ ] ] := 0
grade /: AngleBracket[ grade[ 2, _ ] ] := 0
grade /: AngleBracket[ grade[ 3, _ ] ] := 0
grade /: AngleBracket[ grade[ _, m_ ] ] := ((diracGradeSelect[ m, 0 ]) // pmagnitude)

ClearAll[ ScalarValue ] ;
ScalarValue::usage = "ScalarValue[ m ].  Same as AngleBracket[ m ], aka [ Esc ]<[ Esc ] m1 [ Esc ]>[ Esc ]." ;
ScalarValue[ m_grade ] := AngleBracket[ m ] ;

(* AngleBracket,two operand forms. *)

grade /: AngleBracket[ grade[ 0, s1_ ], grade[ 0, s2_ ] ] := (pmagnitude[ s1 ] pmagnitude[ s2 ]) ;
grade /: AngleBracket[ grade[ 0, s1_ ], grade[ -1, m_ ] ] := (pmagnitude[ s1 ] ((diracGradeSelect[ m, 0 ]) // pmagnitude)) ;
grade /: AngleBracket[ grade[ 0, s1_ ], grade[ _, _ ] ] := 0 ;
grade /: AngleBracket[ grade[ -1, m_ ], grade[ 0, s1_ ] ] := (pmagnitude[ s1 ] ((diracGradeSelect[ m, 0 ]) // pmagnitude)) ;
grade /: AngleBracket[ grade[ _, _ ], grade[ 0, s1_ ] ] := 0 ;

grade /: AngleBracket[ grade[ 3, t1_ ], grade[ 3, t2_ ] ] := (pmagnitude[ t1 ] pmagnitude[ t2 ])
grade /: AngleBracket[ grade[ 3, t1_ ], grade[ -1, m_ ] ] := (pmagnitude[ t1 ] ((diracGradeSelect[ m, 3 ]) // pmagnitude)) ;
grade /: AngleBracket[ grade[ 3, t1_ ], grade[ _, _ ] ] := 0 ;
grade /: AngleBracket[ grade[ -1, m_ ], grade[ 3, t1_ ] ] := (pmagnitude[ t1 ] ((diracGradeSelect[ m, 3 ]) // pmagnitude)) ;
grade /: AngleBracket[ grade[ _, _ ], grade[ 3, t1_ ] ] := 0 ;

grade /: AngleBracket[ grade[ k1_, m1_ ], grade[ k2_, m2_ ] ] := (diracGradeSelect[ m1.m2, 0 ] // pmagnitude) ;

ClearAll[ ScalarProduct ] ;
ScalarProduct::usage = "ScalarProduct[ ].  Same as AngleBracket[ m1, m2 ], aka [ Esc ]<[ Esc ] m1, m2 [ Esc ]>[ Esc ]." ;
ScalarProduct[ m1_grade, m2_grade ] := AngleBracket[ m1, m2 ] ;

(*Begin[ "`Private`" ]*)
ClearAll[ displayMapping, bold, esub, GAdisplay ]
bold = Style[ #, Bold ] & ;
esub = Subscript[ bold[ "e" ], # ] & ;
displayMapping = {
   {Scalar[ 1 ], 1, 1},
   {Vector[ 1, 1 ], esub[ 1 ], e[ 1 ]},
   {Vector[ 1, 2 ], esub[ 2 ], e[ 2 ]},
   {Vector[ 1, 3 ], esub[ 3 ], e[ 3 ]},
   {Vector[ 1, 4 ], esub[ 3 ], e[ 0 ]},
   {Bivector[ 1, 1, 2 ], esub[ "12" ], e[ 1 ]e[ 2 ]},
   {Bivector[ 1, 1, 3 ], esub[ "13" ], e[ 1 ]e[ 3 ]},
   {Bivector[ 1, 2, 3 ], esub[ "23" ], e[ 2 ]e[ 3 ]},
   {Bivector[ 1, 1, 4 ], esub[ "10" ], e[ 1 ]e[ 0 ]},
   {Bivector[ 1, 2, 4 ], esub[ "20" ], e[ 2 ]e[ 0 ]},
   {Bivector[ 1, 3, 4 ], esub[ "30" ], e[ 3 ]e[ 0 ]},
   {Trivector[ 1, 1, 2, 3 ], esub[ "123" ], e[ 1 ]e[ 2 ]e[ 3 ]}
   {Trivector[ 1, 1, 2, 4 ], esub[ "120" ], e[ 1 ]e[ 2 ]e[ 0 ]}
   {Trivector[ 1, 1, 3, 4 ], esub[ "130" ], e[ 1 ]e[ 3 ]e[ 0 ]}
   {Trivector[ 1, 2, 3, 4 ], esub[ "230" ], e[ 2 ]e[ 3 ]e[ 0 ]}
   {Quadvector[ 1 ], esub[ "0123" ], e[ 0 ]e[ 1 ]e[ 2 ]e[ 3] }
} ;

GAdisplay[ v_grade, how_ ] :=
  Total[ (Times[ (AngleBracket[ # // First, v ] (*// Simplify*)), #[ [how ] ] ]) & /@
    displayMapping ] ;
(*End[ "`Private`" ]*)

(* Must reference any global symbol (or some of them) before Unprotecting it, since it may not have
   been loaded:

   http://mathematica.stackexchange.com/a/137007/10
 *)
{D, TraditionalForm, DisplayForm, StandardForm, Grad, Div, Curl};


Unprotect[ TraditionalForm, DisplayForm, StandardForm ] ;
TraditionalForm[ m_grade ] := ((GAdisplay[ m, 2 ]) // TraditionalForm) ;
DisplayForm[ m_grade ] := GAdisplay[ m, 2 ] ;
StandardForm[ m_grade ] := GAdisplay[ m, 3 ] ;
Protect[ TraditionalForm, DisplayForm, StandardForm, D ] ;

Unprotect[ D, Grad, Div, Curl, Vcurl ];
D[ m_grade, u_ ] := grade[ m // First, 
   Map[
     complex[
         D[# // real // Simplify, u],
         D[# // imag // Simplify, u]
     ] &,
     m // Last,
     {2}
   ]
] ;

(*Grad::usage = "grad[m,{x,y,z}] computes the vector product of the gradient with multivector m with respect to cartesian coordinates x,y,z..";*)
grade /: Grad[ grade[ k_, m_ ], u_List ] := ( ( Vector[1, #] ** D[ grade[k, m], u[[#]] ] ) & /@ Range[3] ) // Total ;

(*Div::usage = "div[m,{x,y,z}] of a grade k+1 blade m, computes < \[Del] m >_k, where the gradient is evaluated with respect to cartesian coordinates x,y,z." ;*)
grade /: Div[ grade[ 1, m_], u_List ] := Grad[ grade[1, m], u ] // ScalarSelection ;
grade /: Div[ grade[ 2, m_], u_List ] := Grad[ grade[2, m], u ] // VectorSelection ;
grade /: Div[ grade[ 3, m_], u_List ] := Grad[ grade[3, m], u ] // BivectorSelection ;

(*Curl::usage = "Given a grade (k-1) blade m, curl[ m, {x, y, z} ] = < \[Del] m >_k, where the gradient is evaluated with respect to cartesian coordinates x,y,z." ;*)
grade /: Curl[ grade[ 1, m_], u_List ] := Grad[ grade[1, m], u ] // BivectorSelection ;
grade /: Curl[ grade[ 2, m_], u_List ] := Grad[ grade[2, m], u ] // TrivectorSelection ;
grade /: Curl[ grade[ 3, m_], u_List ] := 0

Vcurl::usage = "Given a vector m, vcurl[m,{x,y,z}] computes the traditional vector valued curl of that vector with respect to cartesian coordinates x,y,z." ;
Vcurl[ m_?vectorQ, u_List ] := -Trivector[1] Curl[ m, u ] ;
Protect[ D, Grad, Div, Curl, Vcurl ];

Protect[ Scalar, Vector, Bivector, Trivector,
GradeSelection, ScalarSelection, VectorSelection, BivectorSelection, TrivectorSelection, e,
ScalarValue, ScalarProduct, Pseudoscalar
] ;

EndPackage[ ]