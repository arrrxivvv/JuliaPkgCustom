using LinearAlgebra

inv!( A::AbstractMatrix ) = LinearAlgebra.inv!( lu!(A) )

function inv!( matDest::(MMatrix{2,2,T,4} where T), A::(MMatrix{2,2,T,4} where T) )
	iDet = 1 / det(A);
	matDest[1,1] = A[2,2];
	matDest[2,2] = A[1,1];
	matDest[1,2] = - A[1,2];
	matDest[2,1] = - A[2,1];
	matDest .= matDest .* iDet;
end
