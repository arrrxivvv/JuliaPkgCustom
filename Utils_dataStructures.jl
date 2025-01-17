using DataStructures
import Base: iterate

function Base.iterate( heap::BinaryHeap, state = 1 )
	heapVec = heap.valtree;
	state > length(heap.valtree) ? nothing : ( heap.valtree[state], state + 1 );
end

function Base.empty!( heap::BinaryHeap )
	empty!( heap.valtree );
end

function Base.getindex( heap::BinaryHeap, ii::Int64 )
	getindex( heap.valtree, ii );
end
