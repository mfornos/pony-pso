use "../../pso"

actor Main

  new create(env: Env) =>
    let dims: USize = 60

    env.out.print(
      """
      PSO - Sphere:
      f(x) = sum(x[]^2)
      """
      )

    let params = recover val
      let p = SwarmParams(dims)
      p.max = Array[F64].init(500, dims)
      p.min = Array[F64].init(-500, dims)
      p.precision = 0
      p.stagnation = 1000
      p.cv = 0.001
      p.cl = 0.002
      p.c1 = 2
      p.c2 = 2
      consume p
    end

    let sw = Swarm(params,
      SwarmLog(env),
      object is FitnessFunc
        fun apply(a: Array[F64]): F64 =>
          var sum: F64 = 0
          for x in a.values() do
            sum = sum + (x * x)
          end
          sum
      end)

    sw.solve()
