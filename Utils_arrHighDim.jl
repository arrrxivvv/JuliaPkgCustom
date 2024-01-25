#Utils funcs
#higher dimensional array manipulation
using ShiftedArrays

function arrShAdvRetLstFunc( arr::AbstractArray, nDim::Int64 )
	arrShDimLst = [ ShiftedArrays.circshift( arr, ntuple( id -> id == dim ? (-1)^iSh : 0, nDim ) ) for dim = 1 : nDim, iSh = 1:2 ];
end
