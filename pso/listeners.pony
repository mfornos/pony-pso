interface val SwarmListener
  """
  Receives notifications from the simulation.
  """
  fun results(i: USize, gbest: F64, g: Array[F64], r: String) =>
    """
    Invoked when a termination condition was reached.

    - i: iteration number
    - gbest: lower cost (gbest)
    - g: solution
    - r: termination reason
    """

  fun local_best(i: USize, pbest: F64, p: Array[F64]) =>
    """
    Invoked when a local best is found.
    """

  fun global_best(i: USize, gbest: F64, g: Array[F64]) =>
    """
    Invoked when a global best is found.
    """


class SwarmLog is SwarmListener
  """
  Listener that prints execution results to system out.
  """
  let _env: Env

  new val create(env: Env) =>
    _env = env

  fun results(i: USize, gbest: F64, g: Array[F64], r: String) =>
    _env.out.print("Execution Results")
    _env.out.print("-----------------")
    _env.out.print("Best:\t\t" + gbest.string())
    for (k, v) in g.pairs() do
      _env.out.print("X" + (k + 1).string() + ":\t\t" + v.string())
    end
    _env.out.print("Epoch:\t\t" + i.string())
    _env.out.print("Reason:\t\t" + r)
