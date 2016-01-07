"""
# Particle swarm optimization (PSO) package.

A population based stochastic optimization technique 
developed by Dr. Eberhart and Dr. Kennedy  in 1995, 
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
  - c2:  Social factor.
  - w: Inertia weight. Typically ranges from [0, 1] , where 0 means no inertia.
  - max: Maximum values of the search space.
  - min: Minimum values of the search space.
  - particles: Number of particles.  The typical range is [20, 40].
     Actually for most of the problems 10 particles is large enough to get good results. 
     For some difficult or special problems, one can try 100 or 200 particles as well.
  - precision: Number of decimal figures per dimension. Set -1 for unbounded decimals.
  - max_stag:  Maximum iterations without a global fit.
    When reached some particles will be randomized.
  - target: Target cost value for the optimization problem. Stop condition.
  - max_iters: Maximum number of iterations. Stop condition.

  Example usage:
  ```
    let params = recover val
      let p = SwarmParams(2)
      p.max = [100, 100]
      p.max_stag = 100
      p.c1 = 1.5
      consume p
    end
  ```
  """
  var max: Array[F64]
  var min: Array[F64]
  var target: F64 = 0
  var max_stag: U64 = 30
  var particles: U64 = 50
  var max_iters: U64 = 1500
  var precision: F64 = -1
  var w: F64 = 0
  var c1: F64 = 0.5
  var c2: F64 = 0.5
  let dims: U64

  new create(dims': U64) =>
    """
    Creates a new instance with the given number of particle dimensions.
    The number of dimensions is determined by the problem to be optimized.
    """
    dims = dims'
    max = Array[F64].init(200, dims)
    min = Array[F64].init(0, dims)

primitive Reason
  """
  Stop reasons.
  """
  fun target(): String => "Target"
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


class _Particle
  """
  Represents a candidate solution.
  """
  var best: F64 = -1
  var _p: Array[F64]
  let _x: Array[F64]
  let _v: Array[F64]
  let _vmax: Array[F64]
  let _rand: Rand = Rand
  let _fitness: FitnessFunc
  let _s: Swarm ref
  let _c1: F64
  let _c2: F64
  let _w: F64
  let _precision: F64

  new create(s: Swarm ref, fitness: FitnessFunc) =>
    _c1 = s.params.c1
    _c2 = s.params.c2
    _w = s.params.w
    _precision = s.params.precision
    _fitness = fitness
    _s = s
    let dims = s.params.dims
    _x = Array[F64].init(0, dims)
    _p = Array[F64].init(0, dims)
    _v = Array[F64].init(0, dims)
    _vmax = Array[F64].init(0, dims)
    randomize()

  fun ref epoch() =>
    """
    Runs an epoch for this particle.

    1. Calculate particle velocity according:
       `v[] = (w * v[]) + c1 * rand() * (pbest[] - x[]) + c2 * rand() * (gbest[] - x[])`
    2. Update particle position according:
       `x[] = x[] + v[]`
    
    Where:

    - v[] is the particle velocity, x[] is the current particle (solution).
    - pbest[] and gbest[] are the particle best fitness and the global best fitness respectively.
    - rand () is a random number between (0,1).
    - c1, c2 are learning factors. usually c1 = c2 = 2.
    """
    for i in Range(0, _x.size()) do
      let rp = _rand.next()
      let rg = _rand.next()
      try
        let x = _x(i)
        let p = _p(i)
        let g = _s.g(i)
        var v' = (_w *_v(i)) + (_c1 * rp * (p - x)) + (_c2 * rg * (g - x))
        v' = _signbit(v') * (v'.abs().min(_vmax(i)))
        var x' = x + v'
        if _precision > -1 then 
          x' = _round_to(x', _precision) 
        end
        _x(i) = x'
        _v(i) = v'
      end
    end
    _adjust_fitness()

  fun ref randomize() =>
    """
    Randomizes the state of this particle.
    """
    let max = _s.params.max
    let min = _s.params.min
    let s = _x.size()
    for i in Range(0, s) do
      try
        _vmax(i) = max(i).abs() + min(i).abs()
        _x(i) = ((max(i) - min(i)) * _rand.next())  + min(i)
        _p(i) = _x(i)
        _v(i) = 2* _vmax(i) * (_rand.next() - 0.5)
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
        _update_stag()
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

    if _epoch >= params.max_iters then
      reason = Reason.iterations()
      return false
    end

    true

  fun ref _update_stag() =>
    if _stagnation >= params.max_stag then
      let r = Rand
      for p in _particles.values() do
        let th = _epoch.f64() / params.max_iters.f64()
        if  r.next() > th then
          p.randomize()
        end
      end
      _stagnation = 0
    end
