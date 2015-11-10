def calBurstyBeta(reception, data):
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
		if (i == 0):
			if (v == 0):
				cons = -1;
			else:
				cons = 1;
			continue;
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
		print(i,v);

	for (i,v) in condSuceed.items():
		print("succeed",i,v);
		if (condFail.has_key(i)):
			condRate[i] = float(condSuceed[i]) / float(condSuceed[i] + condFail[i]);
		else:
			condRate[i] = 1;
	for (i,v) in condFail.items():
		print("fail",i,v);
		if not condRate.has_key(i):
			condRate[i] = 0;
	for (i,v) in condRate.items():
		print("rate",i,v);
		if (i < 0):
			sumI = sumI + reception;
			sumE = sumE + v;
		else:
			sumI = sumI + 1 - reception;
			sumE = sumE + reception - v;
	if (sumI == 0):
		meanI = 0;
	else:
		meanI = float(sumI) / float(maxconsP - maxconsN);
	if (sumE == 0):
		meanE = 0;
	else:
		meanE = float(sumE) / float(maxconsP - maxconsN);
	if (meanI - meanE) == 0: 
		Beta = 0;
	else:
		Beta = float(meanI - meanE) / float(meanI);
	print(Beta);

	return Beta;

#test
reception = 0.7;
data = [1,1,0,1,1,1,1,0,1,1,1,1,1,1,1,0,1,0,0,0,1,1];
calBurstyBeta(reception, data);




