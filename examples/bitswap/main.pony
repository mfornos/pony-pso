use "collections"
use "../../pso"

actor Main

  new create(env: Env) =>
    let t = "God bless you, sir."

    env.out.print("PSO - String adaptive permutation.")
    env.out.print("Target: " + t + "\n")

    let params = recover val
      let siz = t.size()
      let p = SwarmParams(siz)
      p.max = Array[F64].init(255, siz)
      p.particles = 200
      p.precision = 0
      p.c1 = 2
      p.c2 = 2
      p.cl = 0.002
      p.cv = 0.001
      consume p
    end

    let sw = Swarm(params, _L(env), _F(t))

    sw.solve()

class _F is FitnessFunc
    let _t: String
    new val create(t: String) => _t = t
    fun apply(x: Array[F64]): F64 ? =>
      var fit: F64 = 0
      for i in Range(0, x.size()) do
        let x' = (x(i) - _t(i).f64())
        fit = fit + x'.abs()
      end
      fit

class _L is SwarmListener
  let _env: Env
  new val create(env: Env) =>
    _env = env
  fun global_best(i: USize, gbest: F64, g: Array[F64]) =>
    _env.out.print(_to_str(g))
  fun _to_str(t: Array[F64]): String =>
    let siz = t.size()
    var str = String(siz)
    for i in Range(0, siz) do
      try
        str.push(t(i).u8())
      end
    end
    str.string()
