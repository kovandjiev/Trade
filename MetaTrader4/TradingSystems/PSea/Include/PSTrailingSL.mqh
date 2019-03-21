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

#define MAX_SYSTEM_ID 2

class PSTrailingSL
{
	public:
		PSTrailingSL(CFileLog *fileLog, string symbol, int period, int digits, int systemId);
		~PSTrailingSL();
		bool IsInitialised();
		double GetStopLoss(int orderType = -1, double coefficient = 0);
	private:
		CFileLog *_fileLog;
		PSMarket *_market;
		string _symbol;
		int _period;
		int _systemId;
		int _digits;
		bool _isInitialised;
		void CheckInputValues();
		
		double SAR();
		double PreviousBar(int orderType, double coefficient);
};

PSTrailingSL::PSTrailingSL(CFileLog *fileLog, string symbol, int period, int digits, int systemId)
{
	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_digits = digits;

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

double PSTrailingSL::GetStopLoss(int orderType, double coefficient)
{
	double result = -1;
	switch (_systemId)
	{
		case 1: result = SAR(); break;
		case 2: result = PreviousBar(orderType, coefficient);

		default: result = 0; break;
	}
	
	return result;
}

double PSTrailingSL::SAR()
{
	const double IndStep = 0.02;
	const double IndMax = 0.2;

	double bar1 = iSAR(_symbol, _period, IndStep, IndMax, 1);

	double open1 = iOpen(_symbol, _period, 1);
	double close1 = iClose(_symbol, _period, 1);

	double price = (open1 + close1) / 2;

	return MathAbs(bar1 - price);
}

double PSTrailingSL::PreviousBar(int orderType, double coefficient)
{
	double result = -1;
	// Convert from 1 -> 0.1, 0.1 -> 0.01
	double coeff = coefficient / 10;
	if (orderType == OP_BUY) {
		double low1 = iLow(_symbol, _period, 1);
		result  = low1 / (1 + coeff);
	}

	if (orderType == OP_SELL) {
		double high1 = iHigh(_symbol, _period, 1);
		result  = high1 * (1 + coeff);
	}

	return -1;
}