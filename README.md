# Pony package for Particle Swarm Optimization

An impelementation of the Particle Swarm Optimization algorithm[1] in Pony, with support for dissipative variations[2].
PSO is a population based global stochastic optimization technique inspired by social behavior of bird flocking or fish schooling.

# Building

This software depends on [ponyc](http://www.ponylang.org/) version 0.2.1, the Pony language compiler.

Execute `./build.sh -e` to compile all the examples.
You will find the executables in the `bin/` folder.

# Usage

```pony
use "pso"

actor Main
  new create(env: Env) =>

    let params = recover val
        let p = SwarmParams(2)
        p.max = [5000, 5000]
        p.min = [-5000, -5000]
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

## Supported Parameters

`c1` : Cognitive factor. Usually c1 equals to c2 and ranges from [0, 4].

`c2` : Social factor.

`cv` : Chaos velocity factor, in the range [0, 1].

`cl` : Chaos location factor, in the range [0, 1].

`w` : Inertia weight. Typically ranges from [0, 1].

`max` : Maximum values of the search space.

`min` : Minimum values of the search space.

`vmax` : Maximum velocity.

`particles` : Number of particles. Typical range is [20, 40].
Actually for most of the problems 10 particles is large enough to get good results.
For some difficult or special problems, one can try 100 or 200 particles as well.

`precision` : Number of decimal figures per dimension. Set -1 for unbounded decimals.

`stagnation` : Maximum iterations without a global fit. Stop condition.

`target` : Target cost value for the optimization problem. Stop condition.

`iterations` : Maximum number of iterations. Stop condition.

# Example

Running `bin/simple` will print an output close to this:

```
PSO Sphere function
f(x) = Sum(x[]^2)

Execution Results
----------------
Best            0
X1:             0
X2:             0
X3:             0
X4:             0
Epoch:          9
Reason:         Target
```

# References

[1] J. Kennedy and R. C. Eberhart. “Particle swarm optimization,” Proc. IEEE Int. Conf. on Neural Networks, pp. 1942-1948, 1995.

[2] Xiao-Feng Xie, Wen-Jun Zhang and Zhi-Lian Yang. “Dissipative particle swarm optimization,” in Evolutionary Computation, 2002. CEC '02. Proceedings of the 2002 Congress on , vol.2, no., pp.1456-1461, 2002

