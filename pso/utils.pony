use "random"
use "time"

class Rand
  """
  Random helper.
  """
  let _rand: MT
  new create() =>
    _rand = MT(Time.nanos())
  fun ref next(): F64 =>
    _rand.next().f64() / U64.max_value().f64()
  fun ref between(min: F64, max: F64): F64 =>
    next() * ((max - min) + min)