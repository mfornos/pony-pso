use "../../pso"

actor Main

  new create(env: Env) =>
    env.out.print( "PSO - Artificial landscapes")

    booth(env)
    schwefel(env)

fun schwefel(env: Env) =>
     env.out.print(
      """
      Schwefel function:
      http://www.sfu.ca/~ssurjano/schwef.html
      """
      )

    let params = recover val
      let p = SwarmParams(2)
      p.max = Array[F64].init(500, 2)
      p.min = Array[F64].init(-500, 2)
      p.vmax = Array[F64].init(10, 2)
      // p.inertia = Chaotic(0.05, 0.07)
      p.precision = 4
      p.cv = 0.001
      p.cl = 0.002
      p.target = 0.000025459
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

  fun booth(env: Env) =>
     env.out.print(
      """
      Booth's function:
      f(x, y) = (x + 2y -7)^2 + (2x + y - 5)^2
      """
      )

    let params = recover val
      let p = SwarmParams(2)
      p.max = Array[F64].init(10, 2)
      p.min = Array[F64].init(-10, 2)
      p.precision = 0
      p.c1 = 2
      p.c2 = 2
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
