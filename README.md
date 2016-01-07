# Pony package for particle swarm optimization

Particle swarm optimization (PSO) is a population based stochastic optimization technique developed by Dr. Eberhart and Dr. Kennedy  in 1995, inspired by social behavior of bird flocking or fish schooling.

# Building

Execute `./build.sh` to compile all the examples. 
You will find the executables in the `bin/` folder.

## Dependencies

- [ponyc](http://www.ponylang.org/) 0.2.1

# Example

Running `bin/simple` will print an output close to this:

```
PSO - Sphere function:
f(x) = Sum(x[]^2)

Execution Results
-----------------
Best:           0
X1:             0
X2:             0
X3:             0
X4:             0
Epoch:          9
Reason:         Target
```

# References

- [Particle Swarm Central](http://www.particleswarm.info/)

