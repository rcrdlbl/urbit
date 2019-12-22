module Deppy.CST where

import ClassyPrelude
import Prelude (foldl1, foldr1)

import Bound
import Bound.Name
import Data.Function ((&))
import Numeric.Natural

import qualified Deppy.Hoon as H
import qualified Noun as N

type Atom = Natural

data CST
  = Var Text
  -- irregular forms
  | Hax
  | Fun [Binder] CST
  | Cel [Binder] CST
  | Wut (Set Atom)
  --
  | Lam [Binder] CST
  | Cns [CST]
  | Tag Atom
  --
  | App [CST]
  | Hed CST
  | Tal CST
  --
  | The CST CST
  | Fas CST CST
  | Obj (Map Atom CST)
  | Cls (Map Atom CST)
  | Col Atom CST
  -- Runes
  | HaxBuc (Map Atom CST)
  | HaxCen (Map Atom CST)
  | HaxCol [Binder] CST
  | HaxHep [Binder] CST
  --
  | BarCen (Map Atom CST)
  | BarTis [Binder] CST
  | CenDot CST CST
  | CenHep CST CST
  | ColHep CST CST
  | ColTar [CST]
  | TisFas Text CST CST
  | DotDot Binder CST
  | KetFas CST CST
  | KetHep CST CST
  | WutCen CST (Map Atom CST)
  deriving (Read, Eq, Ord)

type Binder = (Maybe Text, CST)

abstractify :: CST -> H.Hoon Text
abstractify = go
  where
    go = \case
      Var v -> H.Var v
      --
      Hax -> H.Hax
      Fun bs c -> bindMany H.Fun bs (go c)
      Cel bs c -> bindMany H.Cel bs (go c)
      Wut s -> H.Wut s
      --
      Lam bs c -> bindMany H.Lam bs (go c)
      Cns cs -> foldr1 H.Cns $ go <$> cs
      Tag a -> H.Tag a
      App cs -> foldl1 H.App $ go <$> cs
      Hed c -> H.Hed (go c)
      Tal c -> H.Tal (go c)
      --
      The c d -> H.The (go c) (go d)
      Fas c d -> H.Fas (go c) (go d)
      Obj cs  -> H.Obj (go <$> cs)
      Cls tcs -> H.Cls (go <$> tcs)
      Col a c -> H.Col a (go c)
      --
      HaxBuc tcs -> H.HaxBuc (go <$> tcs)
      HaxCen tcs -> H.HaxCen (go <$> tcs)
      HaxCol bs c -> bindMany H.HaxCol bs (go c)
      HaxHep bs c -> bindMany H.HaxHep bs (go c)
      --
      BarCen cs -> H.BarCen (go <$> cs)
      BarTis bs c -> bindMany H.BarTis bs (go c)
      CenDot c d -> H.CenDot (go c) (go d)
      CenHep c d -> H.CenHep (go c) (go d)
      ColHep c d -> H.ColHep (go c) (go d)
      ColTar cs -> H.ColTar (go <$> cs)
      TisFas v c d -> H.TisFas (go c) (abstract1 v $ go d)
      DotDot b c -> bind H.DotDot b (go c)
      KetFas c d -> H.KetFas (go c) (go d)
      KetHep c d -> H.KetHep (go c) (go d)
      WutCen c cs -> H.WutCen (go c) (go <$> cs)
    bind ctor (Just v,  c) h = ctor (go c) (abstract1 v h)
    bind ctor (Nothing, c) h = ctor (go c) (abstract (const Nothing) h)
    bindMany ctor bs h = foldr (bind ctor) h bs

concretize :: H.Hoon (Name Text a) -> CST
concretize = go
  where
    go = \case
      H.Var v -> Var (name v)

instance Show CST where
  show = \case
      Var t -> unpack t
      Hax -> "$"
      Fun bs x -> "$<" <> showBound bs x <> ">"
      Cel bs x -> "$[" <> showBound bs x <> "]"
      Wut (setToList -> [x]) -> showTag "$" "$" x
      Wut (setToList -> xs) -> "?(" <> intercalate " " (showTag "$" "$" <$> xs) <> ")"
      Lam bs x -> "<" <> showBound bs x <> ">"
      Cns xs -> "[" <> showGroup xs <> "]"
      Tag a -> showTag "%" "" a
      App xs -> "(" <> showGroup xs <> ")"
      Hed x -> "-." <> show x
      Tal x -> "+." <> show x
      The x y -> "`" <> show x <> "`" <> show y
      Fas x y -> show x <> "/" <> show y
      Obj (mapToList -> cs) -> "{" <> showEnts cs <> "}"
      Cls (mapToList -> tcs) -> "${" <> showEnts tcs <> "}"
      Col a x -> showTag "" "" a <> ":" <> show x
      HaxBuc (mapToList -> cs) -> "$%(" <> showEnts cs <> ")"
      HaxCen (mapToList -> cs) -> "$`(" <> showEnts cs <> ")"
      HaxCol bs x -> "$:(" <> showBound bs x <> ")"
      HaxHep bs x -> "$-(" <> showBound bs x <> ")"
      BarCen (mapToList -> cs) -> "|%(" <> showEnts cs <> ")"
      BarTis bs x -> "|=(" <> showBound bs x <> ")"
      CenDot x y -> "%.(" <> show x <> " " <> show y <> ")"
      CenHep x y -> "%-(" <> show x <> " " <> show y <> ")"
      ColHep x y -> ":-(" <> show x <> " " <> show y <> ")"
      ColTar xs -> ":*(" <> showGroup xs <> ")"
      TisFas t x y -> "=/(" <> unpack t <> show x <> " " <> show y <> ")"
      DotDot x y -> "..(" <> showBinder x <> " " <> show y <> ")"
      KetFas x y -> "^/(" <> show x <> " " <> show y <> ")"
      KetHep x y -> "^-(" <> show x <> " " <> show y <> ")"
      WutCen x (mapToList -> cs) -> "?%(" <> show x <> "; " <> showEnts' cs <> ")"
    where
      showEnts  xs = intercalate ", " (showEnt "" <$> xs)
      showEnts' xs = intercalate ", " (showEnt "%" <$> xs)
      showEnt s (x, y) = showTag s "" x <> " " <> show y
      showGroup xs = intercalate " " (show <$> xs)
      showTag p1 p2 x = N.fromNoun (N.A x) &
        \case
          Just (N.Cord x) | okay x -> p1 <> unpack x
          _ -> p2 <> show x
      okay = all (flip elem ['a'..'z'])
      showBound bs x =  showBinders bs <> " " <> show x
      showBinders bs = intercalate " " (showBinder <$> bs)
      showBinder (Nothing, x) = show x
      showBinder (Just t, x) = unpack t <> "/" <> show x
   