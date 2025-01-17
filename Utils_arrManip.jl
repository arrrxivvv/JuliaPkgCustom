function arrSlcLst( arr, iDim, sz )
	return [ selectdim( arr, iDim, iZ )
		for iZ = 1 : sz ];
end

function arrShAllLst( arr, nDim )
	return [ ShiftedArrays.circshift( arr, 
		ntuple( ( x -> (x == iDim ? -1 : 0) ), nDim ) ) 
		for iDim = 1 : nDim];
end 

function assignArrOfArrs!( arrLst1, arrLst2 )
	( (a,b) -> (a .= b) ).( arrLst1, arrLst2 );
end

function genLevCivita3rdId()
	nDim3 = 3;
	idMat = @MMatrix zeros(Int64, nDim3, nDim3);
	idLst = @SVector [3,2,1];
	
	i1d = 1;
	for ii = 1 : nDim3 - 1, jj = ii+1 : nDim3
		idMat[ii,jj] = idLst[i1d];
		idMat[jj,ii] = idMat[ii,jj];
		i1d += 1;
	end
	
	return idMat;
end

function genLevCivita3rdSgn()
	nDim3 = 3;
	sgnLst = @SVector [1,-1,1];
	
	sgnMat = @MMatrix zeros(Int64, nDim3, nDim3);
	
	i1d = 1;
	for ii = 1 : nDim3-1, jj = ii+1 : nDim3
		sgnMat[ii,jj] = sgnLst[i1d];
		sgnMat[jj,ii] = -sgnMat[ii,jj];
		i1d += 1;
	end
	
	return sgnMat;
end

const leviCivita3rdIdMat = genLevCivita3rdId();
const leviCivita3rdSgnMat = genLevCivita3rdSgn( );

function genStaticIdentityMat( sz::Int64, type::Type = Int64 )
	mat = @MMatrix zeros(type, sz, sz);
	
	for ii = 1 : sz
		mat[ii,ii] = 1;
	end
	
	return mat;
end

macro MVectorCompr( ex )
	ln = esc(ex.args[1].args[2].args[2].args[3]);
	ii = ex.args[1].args[2].args[1];
	elem = esc(ex.args[1].args[1]);
	expr = :( MVector( ntuple( $ii ->　$elem, $ln ) ) );
	
	return expr;
end

macro MMatrixCompr( ex )
	elem = esc(ex.args[1].args[1]);
	i1 = ex.args[1].args[2].args[1];
	i2 = ex.args[1].args[3].args[1];
	rng1 = esc( ex.args[1].args[2].args[2] );
	rng2 = esc( ex.args[1].args[3].args[2] );
	l1 = esc( ex.args[1].args[2].args[2].args[3] );
	l2 = esc( ex.args[1].args[3].args[2].args[3] );
	
	expr = :( MMatrix{ $l1, $l2 }( tuple( ( $elem for $i1 in $rng1, $i2 in $rng2 )... ) ) );
	
	return expr;
end

function arrViewMaterialize( subArr::SubArray )
	return parent( subArr )[ parentindices( subArr )... ];
end
