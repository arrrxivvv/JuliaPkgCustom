# Utils module functions
function strAppendWith_( str::String, strApp::String )
	if !isempty(str)
		str *= "_";
	end
	str *= strApp;
	
	return str;
end

function strReadLastLine( fName::String )
	open(fName) do io
		seekend(io);
		if position(io) == 0
			return "";
		end
		seek(io, position(io) - 1);
		if Char(peek(io)) == '\n'
			if position(io) == 0
				return "";
			else
				seek(io, position(io) - 1);
			end
		end
		while position(io) > 0
			if Char(peek(io)) == '\n'
				read(io,Char);
				break;
			else
				seek( io, position(io) - 1 );
			end
		end
		# read(io, Char);
		readline(io);
	end
end
