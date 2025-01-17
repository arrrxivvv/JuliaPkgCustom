module ProfAllocsSave

using JLD2

using Base.StackTraces

using Infiltrator

# const TypeSFSave = Tuple{Symbol, Symbol, Int64, Bool, Bool, UInt64};

struct SFSave
	func::Symbol;
	file::Symbol;
	line::Int64;
	from_c::Bool;
	inlined::Bool;
	pointer::UInt64;
end

struct FieldLstDefined
	nFields::Int64;
	idDefinedLst::Vector{Int64};
	valDefinedLst::Vector{Any};
end

function FieldLstDefined(x::T) where {T}
	nFields = nfields(x);
	nIsDefined = 0;
	idDefinedLst = zeros(Int64, 0);
	for ii = 1 : nFields
		if isdefined(x, ii)
			nIsDefined += 1;
			push!(idDefinedLst, ii);
		end
	end
	
	valDefinedLst = Vector{Any}(undef,nIsDefined);
	valDefinedLst .= ( ii -> getfield(x, ii) ).(idDefinedLst);
	
	FieldLstDefined(nFields, idDefinedLst, valDefinedLst);
end

function methodToFieldLstDefined( x::Method )
	fldLst = FieldLstDefined( x );
	fldNameLst = fieldnames(Method);
	for ii = 1 : length(fldLst.idDefinedLst)
		if fldNameLst[fldLst.idDefinedLst[ii]] == :roots
			fldLst.valDefinedLst[ii] = Vector{Any}(undef,0);
		elseif fldNameLst[fldLst.idDefinedLst[ii]] == :specializations
			fldLst.valDefinedLst[ii] = nothing;
		end
	end
	
	return fldLst;
end

function Method( fldLst::FieldLstDefined )
	mth = ccall(:jl_new_struct_uninit, Any, (Any,), Method);
	
	for ii = 1 : length( fldLst.idDefinedLst )
		id = fldLst.idDefinedLst[ii];
		setfield!( mth, id, fldLst.valDefinedLst[ii] );
	end
	return mth;
end

mutable struct MethodSave
  name                  :: Symbol
  modulename            :: Module
  file                  :: Symbol
  line                  :: Int32
  primary_world         :: UInt64
  deleted_world         :: UInt64
  sig                   :: Type
  specializations       :: Any
  speckeyset            :: Array
  slot_syms             :: String
  external_mt           :: Any
  source                :: Any
  unspecialized         :: Core.MethodInstance
  generator             :: Any
  roots                 :: Vector{Any}
  root_blocks           :: Vector{UInt64}
  nroots_sysimg         :: Int32
  ccallable             :: Core.SimpleVector
  invokes               :: Any
  recursion_relation    :: Any
  nargs                 :: Int32
  called                :: Int32
  nospecialize          :: Int32
  nkw                   :: Int32
  isva                  :: Bool
  is_for_opaque_closure :: Bool
  nospecializeinfer     :: Bool
  constprop             :: UInt8
  max_varargs           :: UInt8
  purity                :: UInt8
end

function MethodSave( mth::Method )
	mthSave = deepcopy_convert(mth, MethodSave);
	empty!( mthSave.roots );
	mthSave;
end

Method( mthSave::MethodSave ) = deepcopy_convert(mthSave, Method);

mutable struct MethodSaveAbbrev
  name                  :: Symbol
  file                  :: Symbol
  line                  :: Int32
end

function MethodSaveAbbrev( mth::Method )
	mthAbbrev = ccall(:jl_new_struct_uninit, Any, (Any,), MethodSaveAbbrev);
	mthAbbrev.name = mth.name;
	mthAbbrev.file = mth.file;
	mthAbbrev.line = mth.line;
	return mthAbbrev;
end

function Method( mthAbbrev::MethodSaveAbbrev )
	mth = ccall(:jl_new_struct_uninit, Any, (Any,), Method);
	mth.name = mthAbbrev.name;
	mth.file = mthAbbrev.file;
	mth.line = mthAbbrev.line;
	return mth;
end

# JLD2.writeas( ::Type{StackFrame} ) = SFSave;
# JLD2.wconvert( ::Type{SFSave}, sf::StackFrame ) = SFSave(sf.func, sf.file, sf.line, sf.from_c, sf.inlined, sf.pointer);
# JLD2.rconvert( ::Type{StackFrame}, sf::SFSave ) = StackFrame(sf.func, sf.file, sf.line, nothing, sf.from_c, sf.inlined, sf.pointer);

JLD2.writeas( ::Type{StackFrame} ) = StackFrame;
# JLD2.wconvert( ::Type{SFSave}, sf::StackFrame ) = SFSave(sf.func, sf.file, sf.line, sf.from_c, sf.inlined, sf.pointer);
# JLD2.rconvert( ::Type{StackFrame}, sf::SFSave ) = StackFrame(sf.func, sf.file, sf.line, nothing, sf.from_c, sf.inlined, sf.pointer);

# deepcopy_internal( x, stackDict::IdDict ) = Base.deepcopy_internal( x, stackDict );
# deepcopy_internal( x::Module, stackDict::IdDict ) = x;

# function deepcopy(@nospecialize x)
    # isbitstype(typeof(x)) && return x
    # return deepcopy_internal(x, IdDict())::typeof(x)
# end

deepcopy_internal(x::Union{Symbol,Core.MethodInstance,Method,GlobalRef,DataType,Union,UnionAll,Task,Regex},
                  stackdict::IdDict) = x
deepcopy_internal(x::Tuple, stackdict::IdDict) =
    ntuple(i->deepcopy_internal(x[i], stackdict), length(x))
deepcopy_internal( x::Module, stackDict::IdDict ) = x;
# deepcopy_internal(x::Module, stackdict::IdDict) = error("deepcopy of Modules not supported")

function deepcopy_internal(x::Base.SimpleVector, stackdict::IdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = Core.svec(Any[deepcopy_internal(x[i], stackdict) for i = 1:length(x)]...)
    stackdict[x] = y
    return y
end

function deepcopy_internal(x::String, stackdict::IdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = GC.@preserve x unsafe_string(pointer(x), sizeof(x))
    stackdict[x] = y
    return y
end

function deepcopy_internal(@nospecialize(x), stackdict::IdDict)
    T = typeof(x)::DataType
    nf = nfields(x)
    if ismutable(x)
        if haskey(stackdict, x)
            return stackdict[x]
        end
        y = ccall(:jl_new_struct_uninit, Any, (Any,), T)
        stackdict[x] = y
        for i in 1:nf
            if isdefined(x, i)
                xi = getfield(x, i)
                xi = deepcopy_internal(xi, stackdict)::typeof(xi)
                ccall(:jl_set_nth_field, Cvoid, (Any, Csize_t, Any), y, i-1, xi)
            end
        end
    elseif nf == 0 || isbitstype(T)
        y = x
    else
        flds = Vector{Any}(undef, nf)
        for i in 1:nf
            if isdefined(x, i)
                xi = getfield(x, i)
                xi = deepcopy_internal(xi, stackdict)::typeof(xi)
                flds[i] = xi
            else
                nf = i - 1 # rest of tail must be undefined values
                break
            end
        end
        y = ccall(:jl_new_structv, Any, (Any, Ptr{Any}, UInt32), T, flds, nf)
    end
    return y::T
end

function deepcopy_internal(x::Array, stackdict::IdDict)
    if haskey(stackdict, x)
        return stackdict[x]::typeof(x)
    end
    _deepcopy_array_t(x, eltype(x), stackdict)
end

function _deepcopy_array_t(@nospecialize(x::Array), T, stackdict::IdDict)
    if isbitstype(T)
        return (stackdict[x]=copy(x))
    end
    dest = similar(x)
    stackdict[x] = dest
    for i = 1:length(x)
        if ccall(:jl_array_isassigned, Cint, (Any, Csize_t), x, i-1) != 0
            xi = ccall(:jl_arrayref, Any, (Any, Csize_t), x, i-1)
            if !isbits(xi)
                xi = deepcopy_internal(xi, stackdict)::typeof(xi)
            end
            ccall(:jl_arrayset, Cvoid, (Any, Any, Csize_t), dest, xi, i-1)
        end
    end
    return dest
end

function deepcopy_internal(x::Union{Dict,IdDict}, stackdict::IdDict)
    if haskey(stackdict, x)
        return stackdict[x]::typeof(x)
    end

    if isbitstype(eltype(x))
        return (stackdict[x] = copy(x))
    end

    dest = empty(x)
    stackdict[x] = dest
    for (k, v) in x
        dest[deepcopy_internal(k, stackdict)] = deepcopy_internal(v, stackdict)
    end
    dest
end

function deepcopy_internal(x::Base.AbstractLock, stackdict::IdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = typeof(x)()
    stackdict[x] = y
    return y
end

function deepcopy_internal(x::Base.GenericCondition, stackdict::IdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = typeof(x)(deepcopy_internal(x.lock, stackdict))
    stackdict[x] = y
    return y
end

function deepcopy_convert(x::T, TSave::DataType, stackdict::IdDict) where {T}
	# TSave = MethodSave;
    nf = nfields(x)
    if ismutable(x)
        if haskey(stackdict, x)
            return stackdict[x]
        end
        y = ccall(:jl_new_struct_uninit, Any, (Any,), TSave)
        stackdict[x] = y
        for i in 1:nf
            if isdefined(x, i)
                xi = getfield(x, i)
				try
					xi = deepcopy_internal(xi, stackdict)::typeof(xi)
				catch err
					if isa(err, Exception)
						@infiltrate;
					end
				end
                ccall(:jl_set_nth_field, Cvoid, (Any, Csize_t, Any), y, i-1, xi)
            end
        end
    elseif nf == 0 || isbitstype(T)
        y = x
    else
        flds = Vector{Any}(undef, nf)
        for i in 1:nf
            if isdefined(x, i)
                xi = getfield(x, i)
                xi = deepcopy_internal(xi, stackdict)::typeof(xi)
                flds[i] = xi
            else
                nf = i - 1 # rest of tail must be undefined values
                break
            end
        end
        y = ccall(:jl_new_structv, Any, (Any, Ptr{Any}, UInt32), TSave, flds, nf)
    end
	# @infiltrate
    return y::TSave
end

function deepcopy_convert(x::T, TSave::DataType) where {T}
	return deepcopy_convert(x, TSave, IdDict());
end

function deepcopy_MethodSave(x::Method, stackdict::IdDict)
	T = Method;
	TSave = MethodSave;
    T = typeof(x)::DataType
    nf = nfields(x)
    if ismutable(x)
        if haskey(stackdict, x)
            return stackdict[x]
        end
        y = ccall(:jl_new_struct_uninit, Any, (Any,), TSave)
        stackdict[x] = y
        for i in 1:nf
            if isdefined(x, i)
                xi = getfield(x, i)
                xi = deepcopy_internal(xi, stackdict)::typeof(xi)
                ccall(:jl_set_nth_field, Cvoid, (Any, Csize_t, Any), y, i-1, xi)
            end
        end
    elseif nf == 0 || isbitstype(T)
        y = x
    else
        flds = Vector{Any}(undef, nf)
        for i in 1:nf
            if isdefined(x, i)
                xi = getfield(x, i)
                xi = deepcopy_internal(xi, stackdict)::typeof(xi)
                flds[i] = xi
            else
                nf = i - 1 # rest of tail must be undefined values
                break
            end
        end
        y = ccall(:jl_new_structv, Any, (Any, Ptr{Any}, UInt32), TSave, flds, nf)
    end
	empty!( y.roots );
    return y::TSave
end

# JLD2.writeas( ::Type{Method} ) = MethodSave;
JLD2.wconvert( ::Type{MethodSave}, mth::Method ) = MethodSave(mth);
JLD2.rconvert( ::Type{Method}, mthSave::MethodSave ) = Method( mthSave );

# JLD2.writeas( ::Type{Method} ) = MethodSaveAbbrev;
JLD2.wconvert( ::Type{MethodSaveAbbrev}, mth::Method ) = MethodSaveAbbrev( mth );
JLD2.rconvert( ::Type{Method}, mthAbbrev::MethodSaveAbbrev ) = Method( mthAbbrev );

JLD2.writeas( ::Type{Method} ) = FieldLstDefined;
JLD2.wconvert( ::Type{FieldLstDefined}, mth::Method ) = methodToFieldLstDefined( mth );
JLD2.rconvert( ::Type{Method}, fldLst::FieldLstDefined ) = Method( fldLst );

end
