__precompile__(true)

module RefractiveIndex

using YAML, DataDeps

# package code goes here

struct Material
    λ::Array{Float64,1}
    n::Array{Float64,1}
    k::Array{Float64,1}
    nfun::Function
    kfun::Function
    reference::AbstractString
    comment::AbstractString
    specs::Dict{String,Any}
end


include("dispersion_formulae.jl")



export Material, getdata, getshelves, getbooks, getpages


function __init__()
    DATABASEURL = "https://github.com/polyanskiy/refractiveindex.info-database/archive/master.zip"
    
    RegisterDataDep("RefractiveIndexInfoDB", 
        """
        RefractiveIndex.INFO website: © 2008-2018 Mikhail Polyanskiy
        refractiveindex.info database: public domain via CC0 1.0
        NO GUARANTEE OF ACCURACY - Use on your own risk
        """, 
        [DATABASEURL],
        post_fetch_method=unpack)
    
    const global DATAROOT = joinpath(datadep"RefractiveIndexInfoDB", 
                              "refractiveindex.info-database-master/database/data/")
end

getshelves() = shelves = readdir(DATAROOT)
getbooks(shelf) = readdir(joinpath(DATAROOT, shelf))

function getpages(shelf, book)
    contents = readdir(joinpath(DATAROOT, shelf, book))
    # Since some pages are located in a subdirectory we need to extract those
    for (i, content) in enumerate(contents)
        if isdir(joinpath(DATAROOT, shelf, book, content))
            dircontents = readdir(joinpath(DATAROOT, shelf, book, content))
            splice!(contents, i, joinpath.(content, dircontents))
        end
    end
    contents
end

parsearray(datastr) = "[" * datastr * "]" |> parse |> eval

function getdata(shelf, book, page)
    isempty(splitext(page)[2]) ? page *= ".yml" : nothing
    path = joinpath(DATAROOT, shelf, book, page)
    yaml = YAML.load(open(path))
    haskey(yaml, "REFERENCES") ? reference = yaml["REFERENCES"] : reference = ""
    haskey(yaml, "COMMENTS") ? comment = yaml["COMMENTS"] : comment = ""
    haskey(yaml, "SPECS") ? specs = yaml["SPECS"] : specs = Dict{String,Any}()

    # Default field contents for material
    λ = Float64[]
    n = Float64[]
    k = Float64[]
    nfun() = nothing
    kfun() = nothing
    
        
    for i in 1:length(yaml["DATA"])
        # Possible datatypes:
        #   -tablulated nk
        #   -tablulated k
        #   -formula 1-9
        datatype = yaml["DATA"][i]["type"]

        if any(datatype .== ["tabulated nk", "tabulated n", "tabulated k"])
            datastr = yaml["DATA"][i]["data"]
            data = parsearray(datastr)
        elseif any(datatype .== ["formula 1", 
                                 "formula 2", 
                                 "formula 3", 
                                 "formula 4",
                                 "formula 5",
                                 "formula 6",
                                 "formula 7",
                                 "formula 8",
                                 "formula 9"])
            rangestr = yaml["DATA"][i]["range"]
            coeffstr = yaml["DATA"][i]["coefficients"]
            range = parsearray(rangestr)
            coeffs = parsearray(coeffstr)
        else
            error("Datatype $datatype unknown")
        end

        if datatype == "tabulated nk"
            λ = data[:,1]
            n = data[:,2]
            k = data[:,3]
            nfun = splinefun(λ, n, :n)
            kfun = splinefun(λ, k, :k)
            range = [maximum(λ), minimum(λ)]
        elseif datatype == "tabulated n"
            λ = data[:,1]
            n = data[:,2]
            nfun = splinefun(λ, n, :n)
            range = [minimum(λ), maximum(λ)]
        elseif datatype == "tabulated k"
            λ = data[:,1]
            k = data[:,2]
            kfun = splinefun(λ, k, :k)
            range = [minimum(λ), maximum(λ)]
        elseif datatype == "formula 1"
            nfun = eval(f1(range, coeffs))
        elseif datatype == "formula 2"
            nfun = eval(f2(range, coeffs))
        elseif datatype == "formula 3"
            nfun = eval(f3(range, coeffs))
        elseif datatype == "formula 4"
            nfun = eval(f4(range, coeffs))
        elseif datatype == "formula 5"
            nfun = eval(f5(range, coeffs))
        elseif datatype == "formula 6"
            nfun = eval(f6(range, coeffs))
        elseif datatype == "formula 7"
            nfun = eval(f7(range, coeffs))
        elseif datatype == "formula 8"
            nfun = eval(f8(range, coeffs))
        elseif datatype == "formula 9"
            nfun = eval(f9(range, coeffs))
        else
            error("Datatype \"$(datatype)\" not defined.")
        end
    end
    return Material(λ, n, k, nfun, kfun, reference, comment, specs)
end



end # module
