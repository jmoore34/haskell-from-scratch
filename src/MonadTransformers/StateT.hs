module MonadTransformers.StateT () where
import Control.Monad.Trans.Class (MonadTrans (lift))
import Control.Monad.IO.Class (MonadIO (liftIO))
import Control.Monad.State (MonadState (..), put)

-- StateT :: * -> (* -> *) -> * -> *
newtype StateT s m a = StateT { runStateT :: s -> m (a, s)}

instance Monad m => Functor (StateT s m) where
    fmap :: (a -> b) -> StateT s m a -> StateT s m b
    fmap f state = StateT $ \s0 ->
        let m0 = runStateT state $ s0
        in  m0 >>= \(a,s) ->
            return (f a, s)

instance Monad m => Applicative (StateT s m) where
    pure :: a -> StateT s m a
    pure a = StateT $ \s -> return (a,s)
    (<*>) :: StateT s m (a -> b) -> StateT s m a -> StateT s m b
    sf <*> sa = StateT $ \s0 ->
        let mf = runStateT sf $ s0
        in  mf >>= \(f,s1) ->
            let ma = runStateT sa $ s1
            in  ma >>= \(a,s2) ->
                return (f a, s2)

instance Monad m => Monad (StateT s m) where
    (>>=) :: StateT s m a -> (a -> StateT s m b) -> StateT s m b
    state >>= f = StateT $ \s0 ->
        let m = runStateT state $ s0
        in  m >>= \(a, s1) ->
            runStateT (f a) $ s1

get :: Monad m => StateT s m s
get = StateT $ \s -> return (s,s)

put :: Monad m => s -> StateT s m ()
put s = StateT $ \_ -> return ((),s)

-- MonadTrans :: ((* -> *) -> * -> *) -> Constraint
-- StateT :: * -> (* -> *) -> * -> *
-- (StateT s) ::  (* -> *) -> * -> *
instance MonadTrans (StateT s) where
    lift :: (Monad m) => m a -> StateT s m a
    lift ma = StateT $ \s ->
        ma >>= \a ->
            pure (a, s)

-- MonadIO      ::                  (* -> *) -> Constraint
-- StateT       :: * -> (* -> *) -> * -> *
-- (StateT s m) ::                  * -> *
instance (MonadIO m) => MonadIO (StateT s m) where
    liftIO :: IO a -> StateT s m a
    liftIO = lift . liftIO
    -- liftIO ioA =
    --     let mA = liftIO ioA
    --     in lift mA

-- MonadState has two parameters
-- MonadState :: * -> (* -> *) -> Constraint
instance (Monad m) => MonadState s (StateT s m) where
    get :: StateT s m s
    get = MonadTransformers.StateT.get

    put ::s -> StateT s m ()
    put = MonadTransformers.StateT.put

    state :: (s -> (a,s)) -> StateT s m a
    state f = StateT $ \s0 ->
        let (a1, s1) = f s0
        in pure (a1, s1)