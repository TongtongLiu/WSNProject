def calBurstyBeta(reception, data):
	#reception = 0.7;
	#data = [1,1,0,1,1,0,1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1];
	cons = 0;
	maxconsN = 0;
	maxconsP = 0;
	sumI = 0;
	sumE = 0;
	meanI = 0;
	meanE = 0;
	Beta = 0;
	condSuceed= {};
	condFail = {};
	condRate = {};
	for (i,v) in enumerate(data):
		if (v == 0):
			if (condFail.has_key(cons)):
				condFail[cons] = condFail[cons]  + 1;
			else:
				condFail[cons] = 1;
			if (cons < 0):
				cons = cons - 1;
			else:
				cons = -1;
		else:
			if (condSuceed.has_key(cons)):
				condSuceed[cons] = condSuceed[cons] + 1;
			else:
				condSuceed[cons] = 1;
			if (cons > 0):
				cons = cons + 1;
			else:
				cons = 1;
		if (cons > maxconsP):
			maxconsP = cons;
		if (cons < maxconsN):
			maxconsN = cons;

	for (i,v) in condSuceed.items():
		#print(i,v);
		if (condFail.has_key(i)):
			condRate[i] = condSuceed[i] / (condSuceed[i] + condFail[i]);
		else:
			condRate[i] = 1;
	for (i,v) in condFail.items():
		if not condRate.has_key(i):
			condRate[i] = 0;
	for (i,v) in condRate.items():
		if (i < 0):
			sumI = sumI + reception;
			sumE = sumE + v;
		else:
			sumI = sumI + 1 - reception;
			sumE = sumE + reception - v;
	if (sumI == 0):
		meanI = 0;
	else:
		meanI = sumI / (maxconsP - maxconsN);
	if (sumE == 0):
		meanE = 0;
	else:
		meanE = sumE / (maxconsP - maxconsN);
	if (meanI - meanE) == 0: 
		Beta = 0;
	else:
		Beta = (meanI - meanE) / meanI;
	print(Beta);
	
	return Beta;






