module ComputationalHomology

import SmithNormalForm
import Distances

import Base: ==, -, +, *

export AbstractCell,
       dim, faces, volume,
       Simplex, Cube,

       AbstractChain,
       setdim!, simplify,
       Chain,

       AbstractComplex,
       boundary, coboundary, celltype, cells, boundary_matrix,
       SimplicialComplex,
       vietorisrips, witness,

       AbstractHomology, grouptype, group,
       Homology, homology, withgenerators, generators,

       Filtration, filtration,

       AbstractPersistenceReduction,
       StandardReduction, TwistReduction,
       pairs, intervals,
       PersistentHomology, persistenthomology

global SNF = SmithNormalForm.snf

include("cells.jl")
include("chain.jl")
include("complex.jl")
include("simplicial.jl")
include("constructions.jl")
include("filtration.jl")
include("homology.jl")
include("persistence.jl")

function setsnf!(f::Function)
    global SNF
    SNF = f
end

end # module