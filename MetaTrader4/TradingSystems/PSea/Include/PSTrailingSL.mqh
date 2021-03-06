//+------------------------------------------------------------------+
//|                                                 PSTrailingSL.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Tailing functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "2.0"
#property strict

#include <PSMarket.mqh>
#include <FileLog.mqh>

#define MAX_SYSTEM_ID 4

class PSTrailingSL
{
	public:
		PSTrailingSL(CFileLog *fileLog, string symbol, int period, int digits, double points, int systemId, double coefficient);
		~PSTrailingSL();
		bool IsInitialised();
		int GetStopLoss(int orderType);
	private:
		CFileLog *_fileLog;
		PSMarket *_market;
		string _symbol;
		int _period;
		int _systemId;
		int _digits;
		double _points;
		double _coefficient;
		int _orderType;
		bool _isInitialised;
		void CheckInputValues();
		
		double SAR();
		double PreviousBar();
		double ATR();
		double StdDev();
};

PSTrailingSL::PSTrailingSL(CFileLog *fileLog, string symbol, int period, int digits, double points, int systemId, double coefficient)
{
	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_digits = digits;
	_points = points;
	_coefficient = coefficient;

	_systemId = systemId;
	
	CheckInputValues();
}

PSTrailingSL::~PSTrailingSL()
{
}

void PSTrailingSL::CheckInputValues()
{
	bool log = _fileLog != NULL;
	if (!log) {
		Print(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
		_isInitialised = false;
		return;
	}

	bool symbol = IsSymbolValid(_symbol);
	if (!symbol) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Symbol: ", _symbol, " is not valid by system!"));
	}

	bool period = IsTimeFrameValid(_period);
	if (!period) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Time frame: ", _period, " is not valid by system!"));
	}

	bool signal = _systemId > 0 && _systemId <= MAX_SYSTEM_ID;
	if (!signal) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " SystemId: ", _systemId, " must be from: 1 to ", MAX_SYSTEM_ID));
	}

	_isInitialised = log && symbol && period && signal;

	if (!_isInitialised) 
	{
		_fileLog.Error(StringConcatenate(__FUNCTION__, " PSTrailingSL is not initialised!"));
	}
	else
	{
		_fileLog.Info(StringConcatenate(__FUNCTION__, " PSTrailingSL is initialised. Symbol: ", _symbol, ", Period (in minute): ", _period, 
			", SystemId Id: ", _systemId));
	}
}

bool PSTrailingSL::IsInitialised()
{
	return _isInitialised;
}

int PSTrailingSL::GetStopLoss(int orderType)
{
	if (orderType != OP_BUY && orderType != OP_SELL) {
		return 0;
	}
	
	double result = 0;
	_orderType = orderType;
	switch (_systemId)
	{
		case 1: result = ATR(); break;
		case 2: result = StdDev(); break;
		case 3: result = PreviousBar(); break;
		case 4: result = SAR(); break;

		default: result = 0; break;
	}
	
	return (int)MathRound(result);
}

double PSTrailingSL::SAR()
{
	const double IndStep = 0.02;
	const double IndMax = 0.2;

	double coeff = _coefficient;
	if (coeff == 0) {
		coeff = 0.1;
	}

	double bar1 = iSAR(_symbol, _period, IndStep, IndMax, 1);
	double open0 = iOpen(_symbol, _period, 0);

	double diff = MathAbs(bar1 - open0);
	double points = diff / _points;
	
	double result = points * _coefficient;

	return result;
}

double PSTrailingSL::PreviousBar()
{
	double result = 0;
	// // Convert from 1 -> 0.1, 0.1 -> 0.01
	// double coeff = _coefficient / 10;
   	double coeff = _coefficient / 1;
   
	double open0 = iOpen(_symbol, _period, 0);

	double previous1 = 0;
	if (_orderType == OP_BUY) {
		previous1 = iLow(_symbol, _period, 1);
	}

	if (_orderType == OP_SELL) {
		previous1 = iHigh(_symbol, _period, 1);
	}

	double diff = MathAbs(previous1 - open0);
	double points = diff / _points;

	result = points * (1 + coeff);

	return result;
}

double PSTrailingSL::ATR()
{
	const int atrPeriod = 14;

	double coeff = _coefficient;
	if (coeff == 0) {
		coeff = 0.1;
	}

	double bar1 = iATR(_symbol, _period, atrPeriod, 1);

	double points = bar1 / _points;
	
	double result = points * coeff;

	return result;
}

double PSTrailingSL::StdDev()
{
	const int IndPeriod = 20;
	const int IndShift = 0;
	const int IndMethod = MODE_SMA;
	const int IndPrice = PRICE_CLOSE;

	double coeff = _coefficient;
	if (coeff == 0) {
		coeff = 0.1;
	}

	double bar1 = iStdDev(_symbol, _period, IndPeriod, IndShift, IndMethod, IndPrice, 1);

	double points = bar1 / _points;
	
	double result = points * coeff;

	return result;
}
