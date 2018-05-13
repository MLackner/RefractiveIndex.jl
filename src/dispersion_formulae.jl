using Dierckx: Spline1D, evaluate

function splinefun(λ, n, name::Symbol)
    # Some of the tabulated data is not sorted
    p = sortperm(λ)
    λ = λ[p]
    n = n[p]
    range = [minimum(λ), maximum(λ)]
    if length(n) == 2
        k = 1
    elseif length(n) == 1
        # If there's only one data point return that value
        fun = quote 
            function (λ)
                rangecheck(λ, $range)
                n[1]
            end
        end
        return eval(fun)
    else
        k = 1
    end
    spl = Spline1D(λ, n; k=k)
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            evaluate($spl, λ)
        end
    end
    eval(fun)
end

function f1(range, coeffs)
    # Sellmeier
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n2 = coefficients[1]
            for i = 2:2:length(coefficients)
                n2 += coefficients[i] * λ.^2 ./ (λ.^2 - coefficients[i+1].^2)
            end
            return sqrt.(n2 + 1)
        end
    end
end

function f2(range, coeffs)
    # Sellmeier-2
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n2 = coefficients[1]
            for i = 2:2:length(coefficients)
                n2 += coefficients[i] * λ.^2 ./ (λ.^2 - coefficients[i+1])
            end
            return sqrt.(n2 + 1)
        end
    end
end

function f3(range, coeffs)
    # Polynominal
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n2 = coefficients[1]
            for i = 2:2:length(coefficients)
                n2 += coefficients[i] * λ.^coefficients[i+1]
            end
            return sqrt.(n2)
        end
    end
end

function f4(range, coeffs)
    # RefractiveIndex.INFO
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n2 = coefficients[1]
            for i = 2:4:9
                n2 += coefficients[i] * λ.^(coefficients[i+1]) ./ (λ.^2 - coefficients[i+2]^coefficients[i+3])
            end
            for i = 10:2:length(coefficients)
                n2 += coefficients[i] * λ.^coefficients[i+1]
            end
            return sqrt.(n2)
        end
    end
end

function f5(range, coeffs)
    # Cauchy
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n2 = coefficients[1]
            for i = 2:2:length(coefficients)
                n2 += coefficients[i] * λ.^coefficients[i+1]
            end
            return n2
        end
    end
end

function f6(range, coeffs)
    # Gases
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n = coefficients[1]
            for i = 2:2:length(coefficients)
                n += coefficients[i] ./ (coefficients[i+1] - λ.^-2)
            end
            return n + 1.0
        end
    end
end

function f7(range, coeffs)
    # Herzberger
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n = coefficients[1] + coefficients[2] ./ (λ.^2 - 0.028) + coefficients[3] * (1 ./ (λ.^2 - 0.028)).^2
            for i = 4:length(coefficients)
                n += coefficients[i] * λ.^((i-3)*2)
            end
            return n
        end
    end
end

function f8(range, coeffs)
    # Retro
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            x = coefficients[1] + coefficients[2] * λ.^2 ./ (λ.^2 - coefficients[3]) + coefficients[4] * λ.^2
            return sqrt.((2x + 1) ./ (1 - x))
        end
    end
end

function f9(range, coeffs)
    # Exotic
    fun = quote
        function (λ)
            rangecheck(λ, $range)
            coefficients = $coeffs
            n = coefficients[1] + coefficients[2] ./ (λ.^2 - coefficients[3]) + 
                coefficients[4] * (λ - coefficients[5]) ./ ((λ - coefficients[5]).^2 + coefficients[6])
            n = sqrt.(n)
        end
    end
end

function rangecheck(λ, range)
    lowerrange = range[1]
    upperrange = range[2]
    if any(λ .> upperrange) || any(λ .< lowerrange)
        warn("One or more values are out of range. ($lowerrange - $upperrange µm)")
    end
end