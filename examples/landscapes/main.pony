use "../../pso"
use "collections"

actor Main

  new create(env: Env) =>
    env.out.print( "PSO - Artificial landscapes")

    booth(env)
    schwefel(env)
    rosenbrock(env)

fun rosenbrock(env: Env, dims: U64 = 2) =>
  env.out.print(
      """
      Rosenbrock function:
      f(x,y) = (a-x)^2+b(y-x^2)^2
      """
      )

    let params = recover val
      let p = SwarmParams(dims)
      p.max = Array[F64].init(2.048, dims)
      p.min = Array[F64].init(-2.048, dims)
      p.inertia = ChaoticWeight(0.05, 0.07)
      p.target = 1e-5
      consume p
    end

    let sw = Swarm(params,
      SwarmLog(env),
      object is FitnessFunc
        fun apply(a: Array[F64]): F64 ? =>
          var sum: F64 = 0
          for i in Range(0, a.size() - 1) do
            let x = a(i)
            sum = sum + ((100 * (a(i+1) - x.pow(2)).pow(2)) + (1 - x).pow(2))
          end
          sum
      end)

    sw.solve()

fun schwefel(env: Env, dims: U64 = 2) =>
     env.out.print(
      """
      Schwefel function:
      http://www.sfu.ca/~ssurjano/schwef.html
      """
      )

    let params = recover val
      let p = SwarmParams(dims)
      p.max = Array[F64].init(500, dims)
      p.min = Array[F64].init(-500, dims)
      p.vmax = Array[F64].init(10, dims)
      p.precision = 4
      p.cv = 0.001
      p.cl = 0.002
      p.target = 2.5459e-5
      p.particles = 50
      p.stagnation = 500
      consume p
    end

    let sw = Swarm(params,
      SwarmLog(env),
      object is FitnessFunc
        fun apply(a: Array[F64]): F64 =>
          var r: F64 = 0
          var n: F64 = 418.9829 * a.size().f64()
          for x in a.values() do
            r = r + (x * x.abs().sqrt().sin())
          end
          (n - r).abs()
      end)

    sw.solve()

  fun booth(env: Env, dims: U64 = 2) =>
     env.out.print(
      """
      Booth's function:
      f(x,y) = (x+2y-7)^2 + (2x+y-5)^2
      """
      )

    let params = recover val
      let p = SwarmParams(dims)
      p.max = Array[F64].init(10, dims)
      p.min = Array[F64].init(-10, dims)
      p.inertia = ConstantWeight(0.2)
      p.precision = 2
      consume p
    end

    let sw = Swarm(params,
      SwarmLog(env),
      object is FitnessFunc
        fun apply(a: Array[F64]): F64 ? =>
          let x = a(0)
          let y = a(1)
          ((x + (2*y)) - 7).pow(2) + ((2*x) + (y - 5)).pow(2)
      end)

    sw.solve()
