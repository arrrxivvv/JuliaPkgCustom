using JLD2

function saveJld2Lst( fName::String, varNameLst::Vector{String}, varLst::Vector )
	if length(varNameLst) != length(varLst)
		error( "saveJld2Lst: length mismatch" );
	end
	
	jldVarLst = Vector{Any}(undef, 2*length(varNameLst));
	
	for ii = 1 : length(varNameLst)
		jldVarLst[2*ii-1] = varNameLst[ii];
		jldVarLst[2*ii] = varLst[ii];
	end
	
	save( fName, jldVarLst... );
end
