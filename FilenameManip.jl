module FilenameManip

export fNameFunc
export pdfType, jldType, jld2Type, npyType

const pdfType = ".pdf";
const jldType = ".jld";
const jld2Type = ".jld2";
const npyType = ".npy";

function fNameFunc( fNameMain, attrLst, valLst, fExt; fMod = "" )
	fName = fNameMain;
	for ii = 1 : length(attrLst)
		if isa(valLst[ii], Array)
			valStr = "[";
			for iA = 1 : length(valLst[ii])
				valStr *= string(valLst[ii][iA]);
				if iA < length(valLst[ii])
					valStr *= ", ";
				end
			end
			valStr *= "]";
		else
			valStr = string(valLst[ii]);
		end
		fName = fName * "_" * attrLst[ii] * "_" * valStr;
		# fName = fName * "_" * attrLst[ii] * "_" * string( valLst[ii] );
	end
	
	if isa( fMod, Vector{String} )
		fModStr = fMod[1];
		for ii = 2 : length(fMod)
			if fMod[ii] != ""
				fModStr = fModStr * "_" * fMod[ii];
			end
		end
	else
		fModStr = fMod;
	end
	if fModStr != ""
		fName = fName * "_" * fModStr;
	end
	fName = fName * fExt;
	return fName;
end

end
