# Pony package for particle swarm optimization

Particle swarm optimization (PSO) is a population based stochastic optimization technique developed by Dr. Eberhart and Dr. Kennedy  in 1995, inspired by social behavior of bird flocking or fish schooling.

Supported parameters:

<dl>
  <dt>c1</dt><dd>Cognitive factor. Usually c1 equals to c2 and ranges from [0, 4].</dd>
  <dt>c2</dt><dd>Social factor.</dd>
  <dt>cv</dt><dd>Chaos velocity factor, in the range [0, 1].</dd>
  <dt>cl</dt><dd>Chaos location factor, in the range [0, 1].</dd>
  <dt>w</dt><dd>Inertia weight. Typically ranges from [0, 1].</dd>
  <dt>max</dt><dd>Maximum values of the search space.</dd>
  <dt>min</dt><dd>Minimum values of the search space.</dd>
  <dt>vmax</dt><dd>Maximum velocity.</dd>
  <dt>particles</dt>
  <dd>
      Number of particles. Typical range is [20, 40].
      Actually for most of the problems 10 particles is large enough to get good results.
      For some difficult or special problems, one can try 100 or 200 particles as well.
  </dd>
  <dt>precision</dt><dd>Number of decimal figures per dimension. Set -1 for unbounded decimals.</dd>
  <dt>stagnation</dt><dd>Maximum iterations without a global fit. Stop condition.</dd>
  <dt>target</dt><dd>Target cost value for the optimization problem. Stop condition.</dd>
  <dt>iterations</dt><dd>Maximum number of iterations. Stop condition.</dd>
</dl>

# Building

This software depends on [ponyc](http://www.ponylang.org/) version 0.2.1, the Pony language compiler.

Execute `./build.sh -e` to compile all the examples.
You will find the executables in the `bin/` folder.

# Example

Running `bin/simple` will print an output close to this:

```
PSO <dt>Sphere function</dt><dd>f(x) = Sum(x[]^2)</dd>

Execution Results
----------------<dt>Best</dt><dd>          0</dd>
X1:             0
X2:             0
X3:             0
X4:             0
Epoch:          9
Reason:         Target
```

# References

- [Particle Swarm Central](http://www.particleswarm.info/)

