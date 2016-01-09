"""
# Particle Swarm Optimization (PSO) package.

An impelementation of the Particle Swarm Optimization algorithm with support
for dissipative variations. PSO is a population based global stochastic optimization
technique inspired by social behavior of bird flocking or fish schooling.
"""
use "collections"

class SwarmParams
  """
  Swarm parameters.

  - c1: Cognitive factor. Usually c1 equals to c2 and ranges from [0, 4].
  - c2: Social factor.
  - cv: Chaos velocity factor, in the range [0, 1].
  - cl: Chaos location factor, in the range [0, 1].
  - inertia: Inertia function.
  - max: Maximum values of the search space.
  - min: Minimum values of the search space.
  - vmax: Maximum velocity.
  - particles: Number of particles. Typical range is [20, 40].
      Actually for most of the problems 10 particles is large enough to get good results.
      For some difficult or special problems, one can try 100 or 200 particles as well.
  - precision: Number of decimal figures per dimension. Set -1 for unbounded decimals.
  - stagnation: Maximum iterations without a global fit. Stop condition.
  - target: Target cost value for the optimization problem. Stop condition.
  - iterations: Maximum number of iterations. Stop condition.

  Example usage:
  ```
    let params = recover val
      let p = SwarmParams(2)
      p.max = [100, 100]
      p.stagnation = 100
      p.c1 = 1.5
      consume p
    end
  ```
  """
  var max: Array[F64]
  var min: Array[F64]
  var vmax: Array[F64]
  var target: F64 = 0
  var stagnation: U64 = 100
  var particles: U64 = 50
  var iterations: U64 = 1500
  var precision: F64 = -1
  var inertia: InertiaFunc = ConstantWeight
  var c1: F64 = 1.5
  var c2: F64 = 1.5
  var cv: F64 = -1
  var cl: F64 = -1
  let dims: U64

  new create(dims': U64) =>
    """
    Creates a new instance with the given number of particle dimensions.
    The number of dimensions is determined by the problem to be optimized.
    """
    dims = dims'
    max = Array[F64].init(200, dims)
    min = Array[F64].init(0, dims)
    vmax = Array[F64].init(-1, dims)

primitive Reason
  """
  Stop reasons.
  """
  fun target(): String => "Target"
  fun stagnation(): String => "Stagnation"
  fun iterations(): String => "Iterations"
  fun unknown(): String => "Unknown"

class _Particle
  """
  Represents a candidate solution.
  """
  var best: F64 = -1
  let swarm: Swarm ref
  let rand: Rand = Rand
  var hold_ctx: F64 = -1
  var _p: Array[F64]
  let _x: Array[F64]
  let _v: Array[F64]
  let _vmax: Array[F64]
  let _max: Array[F64]
  let _min: Array[F64]
  let _fitness: FitnessFunc
  let _wfunc: InertiaFunc
  let _c1: F64
  let _c2: F64
  let _cv: F64
  let _cl: F64
  let _precision: F64

  new create(s': Swarm ref, fitness: FitnessFunc) =>
    swarm = s'
    _c1 = swarm.params.c1
    _c2 = swarm.params.c2
    _cv = swarm.params.cv
    _cl = swarm.params.cl
    _wfunc = swarm.params.inertia
    _precision = swarm.params.precision
    _fitness = fitness
    let dims = swarm.params.dims
    _x = Array[F64].init(0, dims)
    _p = Array[F64].init(0, dims)
    _v = Array[F64].init(0, dims)
    _vmax = Array[F64].init(0, dims)
    _max = Array[F64].init(0, dims)
    _min = Array[F64].init(0, dims)
    _init_maxs()
    _randomize()

  fun ref epoch() =>
    """
    Runs an epoch for this particle.

    # PSO Algorithm

    1. Calculate particle velocity according:
       `v[] = (w * v[]) + c1 * rand() * (pbest[] - x[]) + c2 * rand() * (gbest[] - x[])`
    2. Update particle position according:
       `x[] = x[] + v[]`

    Where:

    - v[] is the particle velocity, x[] is the current particle (solution).
    - pbest[] and gbest[] are the particle best fitness and the global best fitness respectively.
    - rand () is a random number between (0,1).
    - c1, c2 are learning factors. usually c1 = c2 = 2.

    ## Dissipative Factors

    The chaos introduces the negative entropy from outer environment, which will keep the system
    in far-from-equilibrium state.

    3. Scatter velocity after (1) according to chaos factor:
       `IF rand() < cv THEN v[] = rand() * vmax[]`
    4. Scatter location after (2) according to chaos factor:
       `IF rand() < cl THEN x[] = rand(-max[], max[])`
    """
    for i in Range(0, _x.size()) do
      let rp = rand.next()
      let rg = rand.next()
      try
        let x = _x(i)
        let p = _p(i)
        let g = swarm.g(i)
        let vmax = _vmax(i)
        let max = _max(i)
        let w = _wfunc(this)

        var v' = (w *_v(i)) + (_c1 * rp * (p - x)) + (_c2 * rg * (g - x))
        v' = _clamp(v', vmax)

        if (_cv > -1) and (rand.next() < _cv) then
          v' = rand.next() * vmax
        end

        var x' = x + v'

        if (_cl > -1) and (rand.next() < _cl) then
          x' = rand.between(-max, max)
        end

        if _precision > -1 then
          x' = _round_to(x', _precision)
        end

        _x(i) = x'
        _v(i) = v'
      end
    end
    _adjust_fitness()

  fun ref _randomize() =>
    let siz = _x.size()
    for i in Range(0, siz) do
      try
        _x(i) = ((_max(i) - _min(i)) * rand.next())  + _min(i)
        _p(i) = _x(i)
        _v(i) = 2 * _vmax(i) * (rand.next() - 0.5)
      end
    end
    best = _eval_fitness(_p)
    swarm.update(_x, best)

  fun ref _adjust_fitness() =>
    let fx = _eval_fitness(_x)
    if fx <  best then
      _p = _x
      best = fx
      swarm.update(_x, fx)
    end

  fun _eval_fitness(n: Array[F64]) : F64 =>
    try
      _fitness(n)
    else
      // F64.max_value()
      U64.max_value().f64()
    end

  fun _clamp(a: F64, b: F64): F64 =>
    _signbit(a) * a.abs().min(b)

  fun ref _init_maxs() =>
    let siz = _vmax.size()
    swarm.params.vmax.copy_to(_vmax, 0, 0, siz)
    swarm.params.max.copy_to(_max, 0, 0, siz)
    swarm.params.min.copy_to(_min, 0, 0, siz)
    for i in Range(0, siz) do
      try
        if _vmax(i) < 0 then
          _vmax(i) = _max(i).abs() + _min(i).abs()
        end
      end
    end

  fun _signbit(n: F64): F64 =>
    if n < 0 then -1 elseif n > 0 then 1 else 0 end

  fun _round_to(n: F64, p: F64): F64 =>
    let m = F64(10).pow(p)
    let mn = m * n
    if (mn - mn.floor()) >= 0.5 then
        return mn.ceil() / m
    end
    mn.floor() / m

actor Swarm
  """
  A particle swarm optimization solver.

  Example of usage:
  ```
    let params = recover val
      let p = SwarmParams(2)
      p.max = [5000, 5000]
      p.min = [-5000, -5000]
      p.particles = 30
      consume p
    end

    let sw = Swarm(params,
      SwarmLog(env),
      object is FitnessFunc
        fun apply(x: Array[F64]): F64 ? =>
            (x(0) - 200).abs() + (x(1) - 200).abs()
      end)

    sw.solve()
  ```
  """
  let g: Array[F64]
  let params: SwarmParams val
  var reason: String = Reason.unknown()
  var epoch: U64 = 0
  var gbest: F64 = U64.max_value().f64()
  let _listener: SwarmListener
  let _particles: Array[_Particle]
  var _updated: Bool = false
  var _stagnation: U64 = 0

  new create(params': SwarmParams val, listener: SwarmListener,
    fitness: FitnessFunc)
  =>
    params = params'
    _listener = listener
    var pnum = params.particles
    g = Array[F64].init(0, params.dims)
    _particles = Array[_Particle](pnum)
    while pnum > 0 do
      _particles.push(_Particle(this, fitness))
      pnum = pnum - 1
    end

  be solve() =>
    """
    Solves the optimization problem.
    """
    epoch = 0

    while _running() do
      for p in _particles.values() do
        p.epoch()
      end

      if not _updated then
        _stagnation = _stagnation + 1
      end

      epoch = epoch + 1
      _updated = false
    end

    _listener.results(epoch, gbest, g, reason)

  fun ref update(x: Array[F64], best: F64) =>
    """
    Invoked when a local fit is found.
    """
    _listener.local_best(epoch, best, x)

    if best < gbest then
      x.copy_to(g, 0, 0, x.size())
      gbest = best
      _updated = true
      _listener.global_best(epoch, best, x)
    end

  fun ref _running(): Bool =>
    """
    Returns false if a stop condition was reached.
    """
    if gbest <= params.target then
      reason = Reason.target()
      return false
    end

    if epoch >= params.iterations then
      reason = Reason.iterations()
      return false
    end

    if _stagnation >= params.stagnation then
      reason = Reason.stagnation()
      return false
    end

    true
