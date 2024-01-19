{-# LANGUAGE RebindableSyntax #-}

module Snarkl.Modules.Vector where

import Data.Fin (Fin, universe)
import Data.Nat (Nat)
import Data.Type.Nat (Mult, SNatI, reflectToNum)
import Data.Typeable (Proxy (Proxy), Typeable)
import Snarkl.AST.TExpr (TExp (TEApp))
import Snarkl.Syntax
  ( Comp,
    Ty (TArr, TBool, TFun, TUnit, TVec),
    apply,
    arr,
    arr2,
    dec,
    false,
    forall,
    forall2,
    lambda,
    return,
    true,
    unsafe_cast,
    (&&),
    (>>=),
    (||),
  )
import qualified Snarkl.Syntax as Snarkl
import Prelude hiding (foldl, return, traverse, (&&), (*), (>>=), (||))
import qualified Prelude as P

vec ::
  forall (n :: Nat) proxy ty k.
  (SNatI n) =>
  (Typeable ty) =>
  proxy n ->
  Comp ('TVec n ty) k
vec _ = do
  let n = reflectToNum (Proxy @n)
  a :: TExp ('TArr ty) k <- arr n
  return $ unsafe_cast a

get ::
  (Typeable ty) =>
  (SNatI n) =>
  (TExp ('TVec n ty) k, Fin n) ->
  Comp ty k
get (a, i) =
  Snarkl.get (unsafe_cast a, fromIntegral i)

get2 ::
  (Typeable ty) =>
  (SNatI n) =>
  (SNatI m) =>
  (TExp ('TVec n ('TVec m ty)) k, Fin n, Fin m) ->
  Comp ty k
get2 (a, i, j) =
  Snarkl.get2 (unsafe_cast a, fromIntegral i, fromIntegral j)

set ::
  (Typeable ty) =>
  (SNatI n) =>
  (TExp ('TVec n ty) k, Fin n) ->
  TExp ty k ->
  Comp 'TUnit k
set (a, i) e =
  Snarkl.set (unsafe_cast a, fromIntegral i) e

set2 ::
  (Typeable ty) =>
  (SNatI n) =>
  (SNatI m) =>
  (TExp ('TVec n ('TVec m ty)) k, Fin n, Fin m) ->
  TExp ty k ->
  Comp 'TUnit k
set2 (a, i, j) e =
  Snarkl.set2 (unsafe_cast a, fromIntegral i, fromIntegral j) e

map ::
  forall a b (n :: Nat) k.
  (SNatI n) =>
  (Typeable a) =>
  (Typeable b) =>
  (Typeable n) =>
  TExp ('TFun a b) k ->
  TExp ('TVec n a) k ->
  Comp ('TVec n b) k
map f a = do
  b <- vec (Proxy @n)
  _ <- forall (universe @n) $ \i -> do
    ai <- get (a, i)
    bi <- apply f ai
    set (b, i) bi
  return b

foldl ::
  forall a b (n :: Nat) k.
  (SNatI n) =>
  (Typeable a) =>
  (Typeable b) =>
  TExp ('TFun b ('TFun a b)) k ->
  TExp b k ->
  TExp ('TVec n a) k ->
  Comp b k
foldl f b0 as = do
  go (universe @n) b0
  where
    go ns acc = case ns of
      [] -> return acc
      (n : rest) -> do
        ai <- get (as, n)
        let acc' = TEApp (TEApp f acc) ai
        go rest acc'

traverse ::
  forall a b (n :: Nat) k.
  (SNatI n) =>
  (Typeable a) =>
  (Typeable b) =>
  (Typeable n) =>
  (TExp a k -> Comp b k) ->
  TExp ('TVec n a) k ->
  Comp ('TVec n b) k
traverse f as = do
  bs <- vec (Proxy @n)
  _ <- forall (universe @n) $ \i -> do
    ai <- get (as, i)
    bi <- f ai
    set (bs, i) bi
  return bs

traverse_ ::
  forall a (n :: Nat) k.
  (SNatI n) =>
  (Typeable a) =>
  (TExp a k -> Comp 'TUnit k) ->
  TExp ('TVec n a) k ->
  Comp 'TUnit k
traverse_ f as = do
  forall (universe @n) $ \i -> do
    ai <- get (as, i)
    f ai

concat ::
  forall (n :: Nat) (m :: Nat) a k.
  (SNatI n) =>
  (SNatI m) =>
  (Typeable a) =>
  TExp ('TVec n ('TVec m a)) k ->
  Comp ('TVec (Mult n m) a) k
concat asV = do
  let n = reflectToNum (Proxy @n)
      m = reflectToNum (Proxy @m)
      as = unsafe_cast asV
  bs :: TExp ('TArr a) k <- arr (n P.* m)
  _ <- forall2 ([0 .. dec n], [0 .. dec m]) $ \i j -> do
    ai <- Snarkl.get2 (as, i, j)
    let idx = (n P.* i) P.+ j
    Snarkl.set (bs, idx) ai
  return $ unsafe_cast bs

chunk ::
  forall (n :: Nat) (m :: Nat) k ty.
  (Typeable ty) =>
  (SNatI n) =>
  (SNatI m) =>
  TExp ('TVec (Mult n m) ty) k ->
  Comp ('TVec n ('TVec m ty)) k
chunk asV = do
  let n = reflectToNum (Proxy @n)
      m = reflectToNum (Proxy @m)
      as = unsafe_cast asV
      is = fromIntegral <$> universe @n
      js = fromIntegral <$> universe @n
  bs <- arr2 @ty n m
  _ <- forall2 (is, js) $ \i j -> do
    let idx = n P.* i P.+ j
    ai <- Snarkl.get (as, idx)
    Snarkl.set2 (bs, i, j) ai
  return $ unsafe_cast bs

transpose ::
  forall (n :: Nat) (m :: Nat) k ty.
  (Typeable ty) =>
  (SNatI n) =>
  (SNatI m) =>
  TExp ('TVec n ('TVec m ty)) k ->
  Comp ('TVec m ('TVec n ty)) k
transpose asV = do
  let n = reflectToNum (Proxy @n)
      m = reflectToNum (Proxy @m)
      as = unsafe_cast asV
      is = fromIntegral <$> universe @n
      js = fromIntegral <$> universe @n
  bs <- arr2 @ty m n
  _ <- forall2 (is, js) $ \i j -> do
    ai <- Snarkl.get2 (as, i, j)
    Snarkl.set2 (bs, j, i) ai
  return $ unsafe_cast bs

all ::
  (SNatI n) =>
  TExp ('TVec n 'TBool) k ->
  Comp 'TBool k
all as = do
  f <- lambda $ \acc ->
    lambda $ \x ->
      return $ acc && x
  foldl f true as

any ::
  (SNatI n) =>
  TExp ('TVec n 'TBool) k ->
  Comp 'TBool k
any as = do
  f <- lambda $ \acc ->
    lambda $ \x ->
      return $ acc || x
  foldl f false as
