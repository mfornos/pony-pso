interface FitnessFunc val
  """
  Contract for the cost function to be minimized.
  """
  fun apply(x: Array[F64]): F64 ?

interface InertiaFunc val
  """
  Contract for calculating the inertia weight.
  """
  fun apply(p: _Particle): F64

class ConstantWeight is InertiaFunc
  """
  Constant inertia weight.
  Typically ranges from [0, 1].
  """
  let _c: F64
  new val create(c: F64 = 0) => _c = c
  fun apply(p: _Particle): F64 => _c

class LinearWeight is InertiaFunc
  """
  Linear decreasing strategy.
  """
  let _max: F64
  let _min: F64
  new val create(min: F64, max: F64) =>
    _min = min
    _max = max
  fun apply(p: _Particle): F64 =>
    let iterations = p.swarm.params.iterations.f64()
    let epoch = p.swarm.epoch.f64()
    let n = (_max - _min) / iterations
    _max - (n * epoch)

class ChaoticWeight is InertiaFunc
  """
  Chaotic inertia weight.
  """
  let _max: F64
  let _min: F64
  new val create(min: F64, max: F64) =>
    _min = min
    _max = max
  fun apply(p: _Particle): F64 =>
    let iters = p.swarm.params.iterations.f64()
    let iter = p.swarm.epoch.f64()
    let k = if p.hold_ctx == -1 then p.rand.next() else p.hold_ctx end
    let k' = 4.0 * (k * (1 - k))
    p.hold_ctx = k'
    ((_max - _min) * ((iters - iter) / iters)) + (_min * k')
