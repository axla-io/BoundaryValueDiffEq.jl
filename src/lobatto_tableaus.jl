for order in (2, 3, 4, 5)
    alg = Symbol("LobattoIIIb$(order)")
    f = Symbol("constructLobattoIIIb$(order)")
    @eval constructRK(::$(alg), ::Type{T}) where {T} = $(f)(T)
end

function constructLobattoIIIb2(::Type{T}) where {T}
    # RK coefficients tableau
    s = 2
    a = [1//2 0
         1//2 0]
    c = [0, 1]
    b = [1 // 2, 1 // 2]

    # TODO: Interpolant tableau, no adaptivity for now

    TU = ITU = RKTableau(Int64(s), T.(a), T.(c), T.(b))
    # ITU = RKInterpTableau(Int64(s_star), T.(a_star), T.(c_star), T(τ_star))
    return TU, ITU
end

function constructLobattoIIIb3(::Type{T}) where {T}
    # RK coefficients tableau
    s = 3
    a = [1//6 -1//6 0
    1//6 1//3 0
    1//6 5//6 0]
    c = [0, 1 // 2, 1]
    b = [1 // 6, 2 // 3, 1 // 6]
    
    # TODO: Interpolant tableau, no adaptivity for now

    TU = ITU = RKTableau(Int64(s), T.(a), T.(c), T.(b))
    # ITU = RKInterpTableau(Int64(s_star), T.(a_star), T.(c_star), T(τ_star))
    return TU, ITU
end

function constructLobattoIIIb4(::Type{T}) where {T}
    # RK coefficients tableau
    s = 4
    a = [1 // 12 (-1 - Rational(√5))//24 (-1 + Rational(√5))//24 0
    1 // 12 (25 + Rational(√5))//120 (25 - 13*Rational(√5))//120 0
    1 // 12 (25 + 13*Rational(√5))//120 (25 - Rational(√5))//120 0
    1 // 12 (11 - Rational(√5))//24 (11 + Rational(√5))//24 0]
    c = [0, 1 // 2 - Rational(√5)//10, 1 // 2 + Rational(√5)//10, 1]
    b = [1 // 12, 5 // 12, 5 // 12, 1 // 12]
    
    # TODO: Interpolant tableau, no adaptivity for now

    TU = ITU = RKTableau(Int64(s), T.(a), T.(c), T.(b))
    # ITU = RKInterpTableau(Int64(s_star), T.(a_star), T.(c_star), T(τ_star))
    return TU, ITU
end

function constructLobattoIIIb5(::Type{T}) where {T}
    # RK coefficients tableau
    s = 5
    a = [1 // 20 (-7 - Rational(√21))//120 1 // 15 (-7 + Rational(√21))//120 0
    1 // 20 (343 + 9*Rational(√21))//2520 (56 - 15*Rational(√21))//315 (343 - 69*Rational(√21))//2520 0
    1 // 20 (49 + 12*Rational(√21))//360 8//45 (49 - 12*Rational(√21))//360 0
    1 // 20 (343 + 69*Rational(√21))//2520 (56 + 15*Rational(√21))//315 (343 - 9*Rational(√21))//2520 0
    1 // 20 (119 - 3*Rational(√21))//360 13//45 (119 + 3*Rational(√21))//360 0]
    c = [0, 1 // 2 - Rational(√21)//14, 1 // 2, 1 // 2 + Rational(√21)//14, 1]
    b = [1 // 20, 49 // 180, 16 // 45, 49 // 180, 1 // 20]
    
    # TODO: Interpolant tableau, no adaptivity for now

    TU = ITU = RKTableau(Int64(s), T.(a), T.(c), T.(b))
    # ITU = RKInterpTableau(Int64(s_star), T.(a_star), T.(c_star), T(τ_star))
    return TU, ITU
end
