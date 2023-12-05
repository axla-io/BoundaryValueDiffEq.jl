function Φ!(residual, cache::MIRKCache, y, u, p = cache.p)
    return Φ!(residual, cache.fᵢ_cache, cache.k_discrete, cache.f, cache.TU,
              y, u, p, cache.mesh, cache.mesh_dt, cache.stage)
end

function Φ!(residual, cache::FIRKCache, y, u, p = cache.p)
    return Φ!(residual, cache.fᵢ_cache, cache.k_discrete, cache.f, cache.TU,
              y, u, p, cache.mesh, cache.mesh_dt, cache.stage, cache)
end

@views function Φ!(residual, fᵢ_cache, k_discrete, f!, TU::MIRKTableau, y, u, p,
                   mesh, mesh_dt, stage::Int)
    @unpack c, v, x, b = TU

    tmp = get_tmp(fᵢ_cache, u)
    T = eltype(u)
    for i in eachindex(k_discrete)
        K = get_tmp(k_discrete[i], u)
        residᵢ = residual[i]
        h = mesh_dt[i]

        yᵢ = get_tmp(y[i], u)
        yᵢ₊₁ = get_tmp(y[i + 1], u)

        for r in 1:stage
            @. tmp = (1 - v[r]) * yᵢ + v[r] * yᵢ₊₁
            __maybe_matmul!(tmp, K[:, 1:(r - 1)], x[r, 1:(r - 1)], h, T(1))
            f!(K[:, r], tmp, p, mesh[i] + c[r] * h)
        end

        # Update residual
        @. residᵢ = yᵢ₊₁ - yᵢ
        __maybe_matmul!(residᵢ, K[:, 1:stage], b[1:stage], -h, T(1))
    end
end

@views function Φ!(residual, fᵢ_cache, k_discrete, f!, TU::FIRKTableau{false}, y, u, p,
                   mesh, mesh_dt, stage::Int, cache)
    @unpack c, a, b = TU
    tmp1 = get_tmp(fᵢ_cache, u)
    K = get_tmp(k_discrete[1], u) # Not optimal
    T = eltype(u)
    ctr = 1
    for i in eachindex(k_discrete)
        h = mesh_dt[i]
        yᵢ = get_tmp(y[ctr], u)
        yᵢ₊₁ = get_tmp(y[ctr + stage + 1], u)

        # Load interpolation residual
        for j in 1:stage
            K[:, j] = get_tmp(y[ctr + j], u)
        end

        # Update interpolation residual
        for r in 1:stage
            @. tmp1 = yᵢ
            __maybe_matmul!(tmp1, K, a[r, :], h, T(1))
            f!(residual[ctr + r], tmp1, p, mesh[i] + c[r] * h)
            residual[ctr + r] .-= K[:, r]
        end

        # Update mesh point residual
        residᵢ = residual[ctr]
        @. residᵢ = yᵢ₊₁ - yᵢ
        __maybe_matmul!(residᵢ, K, b, -h, T(1))
        ctr += stage + 1
    end
end

function FIRK_nlsolve!(res, K, p_nlsolve, f!, a, c, h, stage, p_f!)
    mesh_i = p_nlsolve[1]
    yᵢ = @view p_nlsolve[2:end]

    T = eltype(K)
    tmp1 = similar(K, size(K, 1)) # Optimize by removing this allocation

    for r in 1:stage
        @. tmp1 = yᵢ
        __maybe_matmul!(tmp1, @view(K[:, 1:stage]), @view(a[r, 1:stage]), h, T(1))
        f!(@view(res[:, r]), tmp1, p_f!, mesh_i + c[r] * h)
        @views res[:, r] .-= K[:, r]
    end
    return nothing
end

#= # Hacky way to initialize problem
@unpack c, a, b, = TU
K = get_tmp(k_discrete[1], u)
yᵢ = get_tmp(y[1], u)
y_i = eltype(yᵢ) == Float64 ? yᵢ : [y.value for y in yᵢ]
h = mesh_dt[1]
p_nestprob = vcat(promote(mesh[1], one(eltype(y_i)))[1], y_i)
K0 = fill(1.0, size(K))
nestprob = NonlinearProblem((res, K, p_nestprob) -> FIRK_nlsolve(res, K, p_nestprob, f!,
                                                                 a, c, h, stage, p),
                            K0, p_nestprob)

nest_cache = init(nestprob, NewtonRaphson(autodiff = false), abstol = 1e-4,
                  reltol = 1e-4,
                  maxiters = 10) =#

@views function Φ!(residual, fᵢ_cache, k_discrete, f!, TU::FIRKTableau{true}, y, u, p,
                   mesh, mesh_dt, stage::Int, cache)
    @unpack c, a, b, = TU
    @unpack nest_cache, p_nestprob = cache
    T = eltype(u)

    for i in eachindex(k_discrete)
        residᵢ = residual[i]
        h = mesh_dt[i]

        K = get_tmp(k_discrete[i], u)
        if minimum(abs.(K)) < 1e-2
            K = fill(1.0, size(K))
        end

        yᵢ = get_tmp(y[i], u)
        yᵢ₊₁ = get_tmp(y[i + 1], u)
        y_i = eltype(yᵢ) == Float64 ? yᵢ : [y.value for y in yᵢ]

        p_nestprob[1] = promote(mesh[i], one(eltype(y_i)))[1]
        p_nestprob[2:end] = y_i
        reinit!(nest_cache, K, p = p_nestprob)
        solve!(nest_cache) #pass kwargs in initialization # Doesn't work with forwarddiff atm

        # Update residual
        @. residᵢ = yᵢ₊₁ - yᵢ
        __maybe_matmul!(residᵢ, nest_cache.u[:, 1:stage], b[1:stage], -h, T(1))
    end
end

function Φ(cache::AbstractRKCache, y, u, p = cache.p) # TODO: fix this
    return Φ(cache.fᵢ_cache, cache.k_discrete, cache.f, cache.TU, y, u, p, cache.mesh,
             cache.mesh_dt, cache.stage)
end

@views function Φ(fᵢ_cache, k_discrete, f, TU::MIRKTableau, y, u, p, mesh, mesh_dt,
                  stage::Int)
    @unpack c, v, x, b = TU
    residuals = [similar(yᵢ) for yᵢ in y[1:(end - 1)]]
    tmp = get_tmp(fᵢ_cache, u)
    T = eltype(u)
    for i in eachindex(k_discrete)
        K = get_tmp(k_discrete[i], u)
        residᵢ = residuals[i]
        h = mesh_dt[i]

        yᵢ = get_tmp(y[i], u)
        yᵢ₊₁ = get_tmp(y[i + 1], u)

        for r in 1:stage
            @. tmp = (1 - v[r]) * yᵢ + v[r] * yᵢ₊₁
            __maybe_matmul!(tmp, K[:, 1:(r - 1)], x[r, 1:(r - 1)], h, T(1))
            K[:, r] .= f(tmp, p, mesh[i] + c[r] * h)
        end

        # Update residual
        @. residᵢ = yᵢ₊₁ - yᵢ
        __maybe_matmul!(residᵢ, K[:, 1:stage], b[1:stage], -h, T(1))
    end

    return residuals
end

@views function Φ(fᵢ_cache, k_discrete, f!, TU::FIRKTableau{false}, y, u, p,
                  mesh, mesh_dt, stage::Int)
    @unpack c, a, b = TU
    residuals = [similar(yᵢ) for yᵢ in y[1:(end - 1)]]
    tmp1 = get_tmp(fᵢ_cache, u)
    K = get_tmp(k_discrete[1], u) # Not optimal
    T = eltype(u)
    ctr = 1
    for i in eachindex(k_discrete)
        h = mesh_dt[i]
        yᵢ = get_tmp(y[ctr], u)
        yᵢ₊₁ = get_tmp(y[ctr + stage + 1], u)

        # Load interpolation residual
        for j in 1:stage
            K[:, j] = get_tmp(y[ctr + j], u)
        end

        # Update interpolation residual
        for r in 1:stage
            @. tmp1 = yᵢ
            __maybe_matmul!(tmp1, K[:, 1:stage], a[r, 1:stage], h, T(1))
            f!(residuals[ctr + r], tmp1, p, mesh[i] + c[r] * h)
            residuals[ctr + r] .-= K[:, r]
        end

        # Update mesh point residual
        residᵢ = residuals[ctr]
        @. residᵢ = yᵢ₊₁ - yᵢ
        __maybe_matmul!(residᵢ, K[:, 1:stage], b[1:stage], -h, T(1))
        ctr += stage + 1
    end
    return residuals
end

# TODO: Make this work
@views function Φ(residual, fᵢ_cache, k_discrete, f!, TU::FIRKTableau{true}, y, u, p,
                  mesh, mesh_dt, stage::Int)
    @unpack c, a, b = TU
    residuals = [similar(yᵢ) for yᵢ in y[1:(end - 1)]]
    tmp1 = get_tmp(fᵢ_cache, u)
    T = eltype(u)
    K = get_tmp(k_discrete[1], u)

    for i in eachindex(k_discrete)
        residᵢ = residual[i]
        h = mesh_dt[i]

        yᵢ = get_tmp(y[i], u)
        yᵢ₊₁ = get_tmp(y[i + 1], u)
        FIRK_nlsolve!(res, K, p) = FIRK_nlsolve!(res, K, a, c, tmp1, yᵢ, h, T, mesh[i], p)
        prob = NonlinearProblem(FIRK_nlsolve!, K, p)
        sol = solve(prob, NewtonRaphson(), reltol = 1e-4, maxiters = 10)
        K = sol.u

        # Update residual
        @. residᵢ = yᵢ₊₁ - yᵢ
        __maybe_matmul!(residᵢ, K[:, 1:stage], b[1:stage], -h, T(1))
    end
    return residuals
end
