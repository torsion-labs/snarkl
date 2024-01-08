module Snarkl.Language
  ( compileTExpToProgram,
    -- | Snarkl.Language.TExpr,
    booleanVarsOfTexp,
    TExp,
    -- | Snarkl.Language.Core,
    Variable (..),
    Program (..),
    Assignment (..),
    Exp (..),
    -- types
    module Snarkl.Language.Type,
    -- | SyntaxMonad and Syntax
    Comp,
    runState,
    return,
    (>>=),
    (>>),
    Env (..),
    -- | Return a fresh input variable.
    fresh_input,
    -- | Classes
    Zippable,
    Derive,
    -- | Basic values
    unit,
    false,
    true,
    fromField,
    -- | Sums, products, recursive types
    inl,
    inr,
    case_sum,
    pair,
    fst_pair,
    snd_pair,
    roll,
    unroll,
    fixN,
    fix,
    -- | Arithmetic and boolean operations
    (+),
    (-),
    (*),
    (/),
    (&&),
    zeq,
    not,
    xor,
    eq,
    beq,
    exp_of_int,
    inc,
    dec,
    ifThenElse,
    negate,
    -- | Arrays
    arr,
    arr2,
    arr3,
    input_arr,
    input_arr2,
    input_arr3,
    set,
    set2,
    set3,
    set4,
    get,
    get2,
    get3,
    get4,
    -- | Iteration
    iter,
    iterM,
    bigsum,
    times,
    forall,
    forall2,
    forall3,
    -- | Function combinators
    lambda,
    curry,
    uncurry,
    apply,
  )
where

import Data.Field.Galois (GaloisField)
import Snarkl.Errors (ErrMsg (ErrMsg), failWith)
import Snarkl.Language.Core
  ( Assignment (..),
    Exp (..),
    Program (..),
    Variable (..),
  )
import Snarkl.Language.Expr (mkProgram)
import Snarkl.Language.LambdaExpr (expOfLambdaExp)
import Snarkl.Language.Syntax
  ( Derive,
    Zippable,
    apply,
    arr,
    arr2,
    arr3,
    beq,
    bigsum,
    case_sum,
    curry,
    dec,
    eq,
    exp_of_int,
    fix,
    fixN,
    forall,
    forall2,
    forall3,
    fromField,
    fst_pair,
    get,
    get2,
    get3,
    get4,
    ifThenElse,
    inc,
    inl,
    input_arr,
    input_arr2,
    input_arr3,
    inr,
    iter,
    iterM,
    lambda,
    negate,
    not,
    pair,
    roll,
    set,
    set2,
    set3,
    set4,
    snd_pair,
    times,
    uncurry,
    unroll,
    xor,
    zeq,
    (&&),
    (*),
    (+),
    (-),
    (/),
  )
import Snarkl.Language.SyntaxMonad
  ( Comp,
    Env (..),
    false,
    fresh_input,
    return,
    runState,
    true,
    unit,
    (>>),
    (>>=),
  )
import Snarkl.Language.TExpr (TExp, booleanVarsOfTexp, tExpToLambdaExp)
import Snarkl.Language.Type
import Prelude (Either (..), error, ($), (.), (<>))

compileTExpToProgram :: (GaloisField k) => TExp ty k -> Program k
compileTExpToProgram te =
  let eprog = mkProgram . expOfLambdaExp . tExpToLambdaExp $ te
   in case eprog of
        Right p -> p
        Left err -> failWith $ ErrMsg $ "compileTExpToProgram: failed to convert TExp to Program: " <> err
