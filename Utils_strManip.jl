# Utils module functions
function strAppendWith_( str::String, strApp::String )
	if !isempty(str)
		str *= "_";
	end
	str *= strApp;
	
	return str;
end

