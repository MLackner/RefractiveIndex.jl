using RefractiveIndex
using Base.Test

# write your own tests here
materials = RefractiveIndex.Material[]
push!(materials, getdata("main", "au", "babar")) # tabulated nk
push!(materials, getdata("glass", "ami", "amtir-2")) # formula 1 / tabulated k
push!(materials, getdata("glass", "schott", "k7")) # formula 2 / tabulated k
push!(materials, getdata("glass", "hoya", "bac4")) # formula 3 / tabulated k
push!(materials, getdata("main", "Ag3AsS3", "Hulme-e.yml")) # formula 4
push!(materials, getdata("glass", "misc", "soda-lime/Rubin-bronze.yml")) # formula 5
push!(materials, getdata("main", "Ar", "Bideau-Mehu.yml")) # formula 6
push!(materials, getdata("main", "Si", "Edwards.yml")) # formula 7
push!(materials, getdata("main", "AgBr", "Schroter.yml")) # formula 8
push!(materials, getdata("organic", "CH4N2O - urea", "Rosker-e.yml")) # formula 9


λ =     [1.937,   1.937,     1.937,        1.0,       1.3,     1.3,         0.5677,     5.3,     0.5,     0.5]
nvals = [0.25991, 2.8104,    1.4909,       1.5578,    2.5608,  1.5100,      1.00028201, 3.4254,  2.3095,  1.6167]
kvals = [13.099,  0.00000023, 0.00000137, 0.00000002, nothing, 0.00001430, nothing,    nothing, nothing, nothing]
num_dec_k = [3, 8, 8, 8, nothing, 8, nothing, nothing, nothing, nothing]

function getalldata()
    print("|")
    for (i, shelf) in enumerate(getshelves())
        for book in getbooks(shelf), page in getpages(shelf,book)
            # println("\"$shelf\", \"$book\", \"$page\"")
            @test typeof(getdata(shelf, book, page)) == RefractiveIndex.Material
        end
    end
end

function check_refractiveindices(materials, λ, nvals, kvals)
    for i = 1:length(materials)
        num_dec_n = length(split(string(nvals[i]), ".")[2])
        @test round(materials[i].nfun(λ[i]), num_dec_n) ≈ nvals[i]
        kvals[i] == nothing || @test round(materials[i].kfun(λ[i]), num_dec_k[i]) ≈ kvals[i]
    end
end

@testset "Data Reachability Test" begin getalldata() end
@testset "Refractive Index Tests" begin check_refractiveindices(materials, λ, nvals, kvals) end