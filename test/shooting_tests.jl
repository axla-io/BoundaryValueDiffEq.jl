using BoundaryValueDiffEq, LinearAlgebra, OrdinaryDiffEq, Test

@info "Shooting method"

SOLVERS = [Shooting(Tsit5()), MultipleShooting(10, Tsit5())]

@info "Multi-Point BVProblem" # Not really but using that API

tspan = (0.0, 100.0)
u0 = [0.0, 1.0]

# Inplace
function f1!(du, u, p, t)
    du[1] = u[2]
    du[2] = -u[1]
    return nothing
end

function bc1!(resid, sol, p, t)
    t₀, t₁ = first(t), last(t)
    resid[1] = sol(t₀)[1]
    resid[2] = sol(t₁)[1] - 1
    return nothing
end

bvp1 = BVProblem(f1!, bc1!, u0, tspan)
@test SciMLBase.isinplace(bvp1)
for solver in SOLVERS
    resid_f = Array{Float64}(undef, 2)
    sol = solve(bvp1, solver; abstol = 1e-13, reltol = 1e-13)
    @test SciMLBase.successful_retcode(sol)
    bc1!(resid_f, sol, nothing, sol.t)
    @test norm(resid_f) < 1e-12
end

# Out of Place
f1(u, p, t) = [u[2], -u[1]]

function bc1(sol, p, t)
    t₀, t₁ = first(t), last(t)
    return [sol(t₀)[1], sol(t₁)[1] - 1]
end

@test_throws SciMLBase.NonconformingFunctionsError BVProblem(f1!, bc1, u0, tspan)
@test_throws SciMLBase.NonconformingFunctionsError BVProblem(f1, bc1!, u0, tspan)

bvp2 = BVProblem(f1, bc1, u0, tspan)
@test !SciMLBase.isinplace(bvp2)
for solver in SOLVERS
    sol = solve(bvp2, solver; abstol = 1e-13, reltol = 1e-13)
    @test SciMLBase.successful_retcode(sol)
    resid_f = bc1(sol, nothing, sol.t)
    @test norm(resid_f) < 1e-12
end

@info "Two Point BVProblem" # Not really but using that API

# Inplace
function bc2a!(resid, ua, p)
    resid[1] = ua[1]
    return nothing
end

function bc2b!(resid, ub, p)
    resid[1] = ub[1] - 1
    return nothing
end

bvp3 = TwoPointBVProblem(f1!, (bc2a!, bc2b!), u0, tspan;
    bcresid_prototype = (Array{Float64}(undef, 1), Array{Float64}(undef, 1)))
@test SciMLBase.isinplace(bvp3)
for solver in SOLVERS
    sol = solve(bvp3, solver)
    @test SciMLBase.successful_retcode(sol; abstol = 1e-13, reltol = 1e-13)
    @test SciMLBase.successful_retcode(sol)
    resid_f = (Array{Float64, 1}(undef, 1), Array{Float64, 1}(undef, 1))
    bc2a!(resid_f[1], sol(tspan[1]), nothing)
    bc2b!(resid_f[2], sol(tspan[2]), nothing)
    @test norm(reduce(vcat, resid_f)) < 1e-11
end

# Out of Place
bc2a(ua, p) = [ua[1]]
bc2b(ub, p) = [ub[1] - 1]

bvp4 = TwoPointBVProblem(f1, (bc2a, bc2b), u0, tspan)
@test !SciMLBase.isinplace(bvp4)
for solver in SOLVERS
    sol = solve(bvp4, solver; abstol = 1e-13, reltol = 1e-13)
    @test SciMLBase.successful_retcode(sol)
    resid_f = reduce(vcat, (bc2a(sol(tspan[1]), nothing), bc2b(sol(tspan[2]), nothing)))
    @test norm(resid_f) < 1e-12
end

#Test for complex values
u0 = [0.0, 1.0] .+ 1im
bvp = BVProblem(f1!, bc1!, u0, tspan)
resid_f = Array{ComplexF64}(undef, 2)

nlsolve = NewtonRaphson(; autodiff = AutoFiniteDiff())
for solver in [Shooting(Tsit5(); nlsolve), MultipleShooting(10, Tsit5(); nlsolve)]
    sol = solve(bvp, solver; abstol = 1e-13, reltol = 1e-13)
    @test SciMLBase.successful_retcode(sol)
    bc1!(resid_f, sol, nothing, sol.t)
    @test norm(resid_f) < 1e-12
end
