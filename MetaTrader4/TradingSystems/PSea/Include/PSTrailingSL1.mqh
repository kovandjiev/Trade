//+------------------------------------------------------------------+
//|                                                 PSTrailingSL.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Tailing functions
#property copyright "Copyright 2019, PSInvest Corp."
#property link      "https://www.psinvest.eu"
#property version   "1.00"
#property strict

#include <PSMarket.mqh>
#include <FileLog.mqh>

#define MAX_SYSTEM_ID 1

class PSTrailingSL
{
	public:
		PSTrailingSL(CFileLog *fileLog, string symbol, int period, int digits, int systemId, bool trailingInLoss = true);
		~PSTrailingSL();
		bool IsInitialised();
		bool Trailing(int ticketId);
	private:
		CFileLog *_fileLog;
		PSMarket *_market;
		string _symbol;
		int _period;
		int _systemId;
		int _digits;
		bool _trailingInLoss;
		bool _isInitialised;
		void CheckInputValues();
		//   datetime _sdtPrevtime;
		//   int _indent;
		int _orderType;
		double _orderStopLoss;
		double _orderProfit;
		//double _orderOpenPrice;
		//double _marketStopLevel;
		//double _marketSpread;

		bool IsMoveSL(double stopLoss);
		bool GetOrderDetails(int ticketId);
		
		bool SAR(int ticketId);

};

PSTrailingSL::PSTrailingSL(CFileLog *fileLog, string symbol, int period, int digits, int systemId, bool trailingInLoss)
{
	_fileLog = fileLog;
	_symbol = symbol;
	_period = period;
	_digits = digits;

	_systemId = systemId;
	_trailingInLoss = trailingInLoss;
	
	CheckInputValues();
	
	_market = new PSMarket(fileLog, symbol, period, digits);

   //  _sdtPrevtime = 0;
   //  _indent = 0;
	// if (_period > PERIOD_D1) {
	// 	_fileLog.Error(StringConcatenate("PSSignals::PSSignals. Period shouldn't greater than PERIOD_D1. Current:", period));
	// }
}

PSTrailingSL::~PSTrailingSL()
{
	delete _market;
}

void PSTrailingSL::CheckInputValues()
{
	bool log = _fileLog != NULL;
	if (!log) {
		//_fileLog.Error(StringConcatenate(__FUNCTION__, " FileLog must not be NULL!"));
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

bool PSTrailingSL::GetOrderDetails(int ticketId)
{
	if(!_market.GetOrderByTicket(ticketId))
	{
		_fileLog.Error(StringConcatenate(__FUNCTION__, " ticketId #", ticketId, " is not valid."));
		return false;
	}

	//_marketStopLevel = MarketInfo(_symbol, MODE_STOPLEVEL);
	//_marketSpread = MarketInfo(_symbol, MODE_SPREAD);
	_orderType = OrderType();
	_orderStopLoss = OrderStopLoss();
	_orderProfit = OrderProfit();
	//_orderOpenPrice = OrderOpenPrice();

	return true;
}

// systemId: number of trailing stop function
// trailingInLoss: true - trailing if order is in loss, false - SL moves only in profit
bool PSTrailingSL::Trailing(int ticketId)
{
	if (!GetOrderDetails(ticketId)) {
		return false;
	}

	if (_orderType != OP_BUY && _orderType != OP_SELL) {
		_fileLog.Error(StringConcatenate(__FUNCTION__, " Unknow order type: ", _market.OrderTypeToString(_orderType), " with ticketId #", ticketId));
	}

	if (!_trailingInLoss && _orderProfit < 0) {
		return true;
	}
	
	bool result = false;
	switch (_systemId)
	{
		case 1: result = SAR(ticketId); break;

		default: result = false; break;
	}
	
	return result;
}

bool PSTrailingSL::SAR(int ticketId)
{
	const double IndStep = 0.02;
	const double IndMax = 0.2;

	double bar1 = NormalizeDouble(iSAR(_symbol, _period, IndStep, IndMax, 1), _digits);
	// TODO You may consider to close order if direction is changed.
	//double bar2 = NormalizeDouble(iSAR(_symbol, _period, IndStep, IndMax, 2), _digits);

	double close1 = NormalizeDouble(iClose(_symbol, _period, 1), _digits);
	// double close2 = NormalizeDouble(iClose(_symbol, _period, 2), _digits);

	// if (bar2 > close2 && bar1 < close1) {
	// 	return OP_BUY;
	// }

	// if (bar2 < close2 && bar1 > close1) {
	// 	return OP_SELL;
	// }

	if (!IsMoveSL(bar1)) {
		return true;
	}
	
	if (_orderType == OP_BUY && bar1 < close1) {
		return _market.ModifyOpenedOrderSL(ticketId, _orderType, bar1);
	}
	
	if (_orderType == OP_SELL && bar1 > close1) {
		return _market.ModifyOpenedOrderSL(ticketId, _orderType, bar1);
	}

	return true;
}

bool PSTrailingSL::IsMoveSL(double stopLoss)
{
	if (_orderType == OP_BUY && stopLoss > _orderStopLoss) {
		return true;
	}

	if (_orderType == OP_SELL && stopLoss < _orderStopLoss) {
		return true;
	}

	return false;
}