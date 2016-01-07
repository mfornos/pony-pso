use "../../pso"

actor Main

  new create(env: Env) =>

    env.out.print(
      """
      PSO - Sphere function:
      f(x) = Sum(x[]^2)
      """
      )

    let params = recover val
      let p = SwarmParams(4)
      p.max = Array[F64].init(500, 4)
      p.precision = 0
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
