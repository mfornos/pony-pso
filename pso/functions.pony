interface FitnessFunc val
  """
  Contract for the cost function to be minimized.
  """
  fun apply(x: Array[F64]): F64 ?

interface InertiaFunc val
  """
  Contract for calculating the inertia weight.
  """
  fun apply(iterations: U64, epoch: U64, w: F64, pbest: F64, gbest: F64): F64

class ConstantWeight is InertiaFunc
  """
  Constant inertia weight.
  Typically ranges from [0, 1].
  """
  let _c: F64
  new val create(c: F64 = 0) => _c = c
  fun apply(i: U64, k: U64, w: F64, p: F64, g: F64): F64 => _c

class LinearWeight is InertiaFunc
  """
  """
  let _max: F64
  let _min: F64
  new val create(min: F64, max: F64) =>
    _min = min
    _max = max
  fun apply(iterations: U64, epoch: U64, w: F64, pbest: F64, gbest: F64): F64
  =>
    let n = (_max - _min) / iterations.f64()
    _max - (n * epoch.f64())

class SIF is InertiaFunc
  """
  """
  let _d1: F64
  let _d2: F64
  new val create(d1: F64, d2: F64) =>
    _d1 = d1
    _d2 = d2
  fun apply(iterations: U64, epoch: U64, w: F64, pbest: F64, gbest: F64): F64
  =>
    4.0 * (w * (1 - w))
