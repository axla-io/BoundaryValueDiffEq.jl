const DEFAULT_NLSOLVE_SHOOTING = TrustRegion(; autodiff = Val(true))
const DEFAULT_NLSOLVE_MIRK = NewtonRaphson(; autodiff = Val(true))
const DEFAULT_JACOBIAN_ALGORITHM_MIRK = AutoMultiModeDifferentiation(AutoFiniteDiff(),
    AutoSparseFiniteDiff())

# Algorithms
abstract type BoundaryValueDiffEqAlgorithm <: SciMLBase.AbstractBVPAlgorithm end
abstract type AbstractMIRK <: BoundaryValueDiffEqAlgorithm end

struct Shooting{O, N} <: BoundaryValueDiffEqAlgorithm
    ode_alg::O
    nlsolve::N
end

Shooting(ode_alg; nlsolve = DEFAULT_NLSOLVE_SHOOTING) = Shooting(ode_alg, nlsolve)

"""
@article{Enright1996RungeKuttaSW,
  title={Runge-Kutta Software with Defect Control for Boundary Value ODEs},
  author={Wayne H. Enright and Paul H. Muir},
  journal={SIAM J. Sci. Comput.},
  year={1996},
  volume={17},
  pages={479-497}
}
"""
Base.@kwdef struct MIRK3{N, J} <: AbstractMIRK
    nlsolve::N = DEFAULT_NLSOLVE_MIRK
    jac_alg::J = DEFAULT_JACOBIAN_ALGORITHM_MIRK
end

"""
@article{Enright1996RungeKuttaSW,
  title={Runge-Kutta Software with Defect Control for Boundary Value ODEs},
  author={Wayne H. Enright and Paul H. Muir},
  journal={SIAM J. Sci. Comput.},
  year={1996},
  volume={17},
  pages={479-497}
}
"""
Base.@kwdef struct MIRK4{N, J} <: AbstractMIRK
    nlsolve::N = DEFAULT_NLSOLVE_MIRK
    jac_alg::J = DEFAULT_JACOBIAN_ALGORITHM_MIRK
end

"""
@article{Enright1996RungeKuttaSW,
  title={Runge-Kutta Software with Defect Control for Boundary Value ODEs},
  author={Wayne H. Enright and Paul H. Muir},
  journal={SIAM J. Sci. Comput.},
  year={1996},
  volume={17},
  pages={479-497}
}
"""
Base.@kwdef struct MIRK5{N, J} <: AbstractMIRK
    nlsolve::N = DEFAULT_NLSOLVE_MIRK
    jac_alg::J = DEFAULT_JACOBIAN_ALGORITHM_MIRK
end

"""
@article{Enright1996RungeKuttaSW,
  title={Runge-Kutta Software with Defect Control for Boundary Value ODEs},
  author={Wayne H. Enright and Paul H. Muir},
  journal={SIAM J. Sci. Comput.},
  year={1996},
  volume={17},
  pages={479-497}
}
"""
Base.@kwdef struct MIRK6{N, J} <: AbstractMIRK
    nlsolve::N = DEFAULT_NLSOLVE_MIRK
    jac_alg::J = DEFAULT_JACOBIAN_ALGORITHM_MIRK
end
