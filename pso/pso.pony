"""
# Particle swarm optimization (PSO) package.

A population based stochastic optimization technique
developed by Dr. Eberhart and Dr. Kennedy in 1995,
inspired by social behavior of bird flocking or fish schooling.
"""
use "time"
use "random"
use "collections"

interface FitnessFunc val
  """
  Contract for the cost function to be minimized.
  """
  fun apply(x: Array[F64]): F64 ?

interface SwarmListener val
  """
  Receives notifications from the simulation.
  """
  fun results(i: U64, gbest: F64, g: Array[F64], r: String) =>
    """
    Invoked when a stop condition was triggered.

    - i: iteration number
    - gbest: lower cost (gbest)
    - g: solution
    - r: stop reason
    """
    None
  fun local_best(i: U64, pbest: F64, p: Array[F64]) =>
    """
    Invoked when a local best is found.
    """
    None
  fun global_best(i: U64, gbest: F64, g: Array[F64]) =>
    """
    Invoked when a global best is found.
    """
    None

class SwarmLog is SwarmListener
  """
  Listener that prints execution results to system out.
  """
  let _env: Env
  new val create(env: Env) => _env = env
  fun results(i: U64, gbest: F64, g: Array[F64], r: String) =>
    _env.out.print("Execution Results")
    _env.out.print("-----------------")
    _env.out.print("Best:\t\t" + gbest.string())
    for (k, v) in g.pairs() do
      _env.out.print("X" + (k + 1).string() + ":\t\t" + v.string())
    end
    _env.out.print("Epoch:\t\t" + i.string())
    _env.out.print("Reason:\t\t" + r)

class SwarmParams
  """
  Swarm parameters.

  - c1: Cognitive factor. Usually c1 equals to c2 and ranges from [0, 4].
  - c2: Social factor.
  - cv: Chaos velocity factor, in the range [0, 1].
  - cl: Chaos location factor, in the range [0, 1].
  - w: Inertia weight. Typically ranges from [0, 1], where 0 means no inertia.
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
  var w: F64 = 0
  var c1: F64 = 0.5
  var c2: F64 = 0.5
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

class Rand
  """
  Random helper.
  """
  let _rand: MT
  new create() =>
    _rand = MT(Time.nanos())
  fun ref next(): F64 =>
    _rand.next().f64() / U64.max_value().f64()
  fun ref between(min: F64, max: F64): F64 =>
    next() * ((max - min) + min)

class _Particle
  """
  Represents a candidate solution.
  """
  var best: F64 = -1
  var _p: Array[F64]
  let _x: Array[F64]
  let _v: Array[F64]
  let _vmax: Array[F64]
  let _max: Array[F64]
  let _min: Array[F64]
  let _rand: Rand = Rand
  let _fitness: FitnessFunc
  let _s: Swarm ref
  let _c1: F64
  let _c2: F64
  let _cv: F64
  let _cl: F64
  let _w: F64
  let _precision: F64

  new create(s: Swarm ref, fitness: FitnessFunc) =>
    _c1 = s.params.c1
    _c2 = s.params.c2
    _cv = s.params.cv
    _cl = s.params.cl
    _w = s.params.w
    _precision = s.params.precision
    _fitness = fitness
    _s = s
    let dims = s.params.dims
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
      let rp = _rand.next()
      let rg = _rand.next()
      try
        let x = _x(i)
        let p = _p(i)
        let g = _s.g(i)
        let vmax = _vmax(i)
        let max = _max(i)

        var v' = (_w *_v(i)) + (_c1 * rp * (p - x)) + (_c2 * rg * (g - x))
        v' = _clamp(v', vmax)

        if (_cv > -1) and (_rand.next() < _cv) then
          v' = _rand.next() * vmax
        end

        var x' = x + v'

        if (_cl > -1) and (_rand.next() < _cl) then
          x' = _rand.between(-max, max)
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
    let s = _x.size()
    for i in Range(0, s) do
      try
        _x(i) = ((_max(i) - _min(i)) * _rand.next())  + _min(i)
        _p(i) = _x(i)
        _v(i) = 2 * _vmax(i) * (_rand.next() - 0.5)
      end
    end
    best = _eval_fitness(_p)
    _s.update(_x, best)

  fun ref _adjust_fitness() =>
    let fx = _eval_fitness(_x)
    if fx <  best then
      _p = _x
      best = fx
      _s.update(_x, fx)
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
    let s = _vmax.size()
    _s.params.vmax.copy_to(_vmax, 0, 0, s)
    _s.params.max.copy_to(_max, 0, 0, s)
    _s.params.min.copy_to(_min, 0, 0, s)
    for i in Range(0, s) do
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
  let _listener: SwarmListener
  let _particles: Array[_Particle]
  var _gbest: F64 = U64.max_value().f64()
  var _updated: Bool = false
  var _stagnation: U64 = 0
  var _epoch: U64 = 0

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
    _epoch = 0

    while _running() do
      for p in _particles.values() do
        p.epoch()
      end

      if not _updated then
        _stagnation = _stagnation + 1
      end

      _epoch = _epoch + 1
      _updated = false
    end

    _listener.results(_epoch, _gbest, g, reason)

  fun ref update(x: Array[F64], best: F64) =>
    """
    Invoked when a local fit is found.
    """
    _listener.local_best(_epoch, best, x)

    if best < _gbest then
      x.copy_to(g, 0, 0, x.size())
      _gbest = best
      _updated = true
      _listener.global_best(_epoch, best, x)
    end

  fun ref _running(): Bool =>
    """
    Returns false if a stop condition was reached.
    """
    if _gbest <= params.target then
      reason = Reason.target()
      return false
    end

    if _epoch >= params.iterations then
      reason = Reason.iterations()
      return false
    end

    if _stagnation >= params.stagnation then
      reason = Reason.stagnation()
      return false
    end

    true
