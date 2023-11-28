using Dates


function maximum_time(max::Int)
  start::DateTime = Dates.now()
  max = convert(Dates.Millisecond, Dates.Second(max))
  @inline increment(time::DateTime, args...)::DateTime = time
  @inline check_stop(start::DateTime)::Bool =
    (Dates.now() - start <= max)

  return start, max, increment, check_stop
end


function maximum_iterations(max::Int)
  start::Int = 1
  @inline increment(i::Int, do_nothing::Bool)::Int =
    if !do_nothing i+1 else i end
  @inline check_stop(i::Int)::Bool = i <= max

  return start, max, increment, check_stop
end


function maximum_iterations_with_no_improvement(max::Int)
  start::Int = 0
  @inline increment(i::Int, restart::Bool)::Int =
    if !restart i+1 else 0 end
  @inline check_stop(i::Int)::Bool = i <= max

  return start, max, increment, check_stop
end
