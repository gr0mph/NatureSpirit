import 'dart:io';
import 'dart:math';
import 'dart:collection';
import 'dart:core';

var error = stderr.writeln, parse = int.parse;

class Test
{
	List<int> test = [ 1 , 2 , 3 , 4 , 5 ];

	List<int> get test2 => test;

	List<int> get extract {
		//print( test.getRange(2,5));
		return test.sublist(2,5);
	}

	void extract( int t , int order) {
		print("extract setter");
		test[2 + order] = t;
		return;
	}
}

void main()
{
	Test t = new Test();

	//print(t.test);
	print(t.extract);
	print(t.extract[0]);
	t.extract = [ 0 , 0 , 0 ];
	print(t.extract);
}
