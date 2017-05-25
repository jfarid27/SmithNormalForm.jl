# Simplicial Complex

type SimplicialComplex{P} <: AbstractComplex
    cells::Dict{Int,Vector{Simplex{P}}} # cells per dimension
    # order::Dict{Pair{Int,Int},Int}      # order of cells
end
Base.show(io::IO, cplx::SimplicialComplex) = print(io, "SimplicialComplex($(size(cplx)))")
Base.copy(cplx::SimplicialComplex) = SimplicialComplex(deepcopy(cplx.cells))

# ---------------
# Private Methods
# ---------------
"""Add a simplex to the complex (as is) and return a complex size, a dimension of simplex and its index in it

This function **doesn't** add missing faces of the simplex to the complex. Use `addsimplex!` function for instead.
"""
function addsimplex{P}(cplx::SimplicialComplex{P}, splx::Simplex{P})
    d = dim(splx)
    d < 0 && return (0,d,0)
    !haskey(cplx.cells, d) && setindex!(cplx.cells, Simplex{P}[], d)
    i = length(cplx.cells[d])+1
    splx[:index] = i
    push!(cplx.cells[d], splx)
    # cplx.order[d=>i] = length(cplx.order)+1
    return sum(size(cplx)), d, i
end

"""Add a simplex to the complex and all of its faces recursivly and return a complex size, a dimension of simplex and its index in it"""
function addsimplex!{P}(cplx::SimplicialComplex{P}, splx::Simplex{P})
    # cache already
    added = Set{Simplex}()

    toprocess = Simplex[]
    addedidxs = NTuple{3,Int}[]

    # add simplex to complex
    t = addsimplex(cplx, splx)
    push!(addedidxs, t)
    for f in faces(splx) # add simplex faces for processing
        push!(toprocess, f)
    end

    # process simplex faces and add missing simplexes
    while(length(toprocess) > 0)
        tmp = pop!(toprocess) # processing simplex faces
        d = dim(tmp)

        cplx[tmp, d] <= size(cplx, d) && continue # skip if already in complex
        tmp in added && continue # skip if already processed

        t = addsimplex(cplx, tmp) # add simples to the complex
        push!(addedidxs, t)
        push!(added, tmp) # mark as processed

        dim(tmp) == 0 && continue # do not create faces for 0-simplexes
        for f in faces(tmp) # add simplex faces for processing
            push!(toprocess, f)
        end
    end

    # return addedidxs

    # reorder simplexes from low-dim to high-dim
    minidx = mapreduce(i->i[1], min, addedidxs)
    return [ (minidx+i-1, e[2], e[3]) for (i, e) in enumerate(sort(addedidxs,by=(s->s[2]))) ]
end

#
# Public Interface
#
celltype{P}(::SimplicialComplex{P}) = Simplex{P}

function cells(cplx::SimplicialComplex)
    CCT = valtype(cplx.cells)
    length(cplx.cells) == 0 && return CCT[] # no cell in complex
    dims = maximum(keys(cplx.cells))
    CCT[haskey(cplx.cells, d) ? cplx.cells[d] : CCT() for d in 0:dims]
end

cells(cplx::SimplicialComplex, d::Int) = haskey(cplx.cells, d) ? Nullable(cplx.cells[d]) : Nullable{valtype(cplx.cells)}()

dim(cplx::SimplicialComplex) = length(size(cplx))-1

function boundary{R}(cplx::SimplicialComplex, idx::Int, d::Int, ::Type{R})
    ch = Chain(d-1, R)
    if d == 0
        setdim!(ch, -1)
        return ch
    end
    pos = one(R)
    neg = -one(R)

    splx = cplx[idx, d]
    isnull(splx) && return ch

    sgn = true
    for face in faces(get(splx))
        fidx = cplx[face, d-1]
        push!(ch, (sgn ? pos : neg), fidx)
        sgn = !sgn
    end

    return ch
end

function coboundary{R}(cplx::SimplicialComplex, idx::Int, d::Int, ::Type{R})

    d == 0 && return Chain(d+1, R)

    cbd = Dict{Int,Chain{R}}()
    for i in 1:size(cplx,d-1)
        cbd[i] = Chain(d+1, R)
    end

    for i in 1:size(cplx,d)
        bd = boundary(cplx, i, d, R)
        for (c, el) in bd
            push!(cbd[el], c, i)
        end
    end

    return cbd[idx]
end

#
# Constructors
#
SimplicialComplex{P}(::Type{P}) = SimplicialComplex(Dict{Int,Vector{Simplex{P}}}())
function SimplicialComplex{P}(splxs::Simplex{P}...)
    cplx = SimplicialComplex(P)

    added = Set{Simplex}()
    toprocess = Vector{Simplex}()
    for splx in splxs
        push!(toprocess, splx) # add simplex to process its faces
        while(length(toprocess) > 0)
            tmp = pop!(toprocess) # processing simplex faces
            tmp in added && continue # skip if already processed
            addsimplex(cplx, tmp) # add simples to complex
            push!(added, tmp) # mark as processed
            for f in faces(tmp) # add simplex faces for processing
                push!(toprocess, f)
            end
        end
    end

    return cplx
end
SimplicialComplex(splxs::Vector{Simplex}) = SimplicialComplex(splxs...)

#
# Miscellaneous
#
function readsimcomplex(io::IO)
    splxs = Simplex[]
    while !eof(io)
        l = chomp(readline(io))
        si = map(e->parse(Int, e), split(l, ' '))
        push!(splxs, Simplex(si...))
    end
    return SimplicialComplex(splxs)
end

function writesimcomplex(io::IO, cplx::SimplicialComplex)
    zsplxs = Dict{Int,Int}()
    for s in cplx.cells[0]
        zsplxs[s.vs[]] = s.idx
        write(io, "$(s.idx)")
        write(io, 0x0A)
    end
    for d in 1:dim(cplx)
        for s in cplx.cells[d]
            for (j,i) in enumerate(s.vs)
                write(io, "$(zsplxs[i])")
                if j>d
                    write(io, 0x0A)
                else
                    write(io, ' ')
                end
            end
        end
    end
    return
end
