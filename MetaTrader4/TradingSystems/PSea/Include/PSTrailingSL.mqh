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
		PSTrailingSL(CFileLog *fileLog, string symbol, int period, int systemId);
		~PSTrailingSL();
		bool IsInitialised();
		bool Trailing(int systemId, int ticketId, double &stopLoss, bool trailingInLoss = false);
	private:
      CFileLog *_fileLog;
      string _symbol;
      int _period;
      int _systemId;
		bool _isInitialised;
		void CheckInputValues();
      //   datetime _sdtPrevtime;
      //   int _indent;
      int _orderType;
      double _orderSL;
      double _orderOpenPrice;
      double _marketStopLevel;
      double _marketSpread;

      //   bool trailingByFractals(int period, int bars, double &stopLoss, bool trailingInLoss);
      //   bool trailingByShadows(int period, int bars, double &stopLoss, bool trailingInLoss);
      //   bool trailingStairs(int trailingDistance,int trailingStep, double &stopLoss);
};

PSTrailingSL::PSTrailingSL(CFileLog *fileLog, string symbol, int period, int systemId)
{
   _fileLog = fileLog;
   _symbol = symbol;
   _period = period;
   _systemId = systemId;

   //  _sdtPrevtime = 0;
   //  _indent = 0;
	// if (_period > PERIOD_D1) {
	// 	_fileLog.Error(StringConcatenate("PSSignals::PSSignals. Period shouldn't greater than PERIOD_D1. Current:", period));
	// }
}

PSTrailingSL::~PSTrailingSL()
{

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

// systemId: number of trailing stop function
// trailingInLoss: true - trailing if order is in loss, false - SL moves only in profit
bool PSTrailingSL::Trailing(int systemId, int ticketId, double &stopLoss, bool trailingInLoss)
{
   _systemId = systemId;
   stopLoss = 0.0;

   if(!OrderSelect(ticketId, SELECT_BY_TICKET))
   {
      _fileLog.Warning(StringConcatenate(__FUNCTION__, " TrailingStop ticketId #", ticketId, " is not valid."));
      return false;
   }

   _marketStopLevel = MarketInfo(_symbol, MODE_STOPLEVEL);
   _marketSpread = MarketInfo(_symbol, MODE_SPREAD);
   _orderType = OrderType();
   _orderSL = OrderStopLoss();
   _orderOpenPrice = OrderOpenPrice();

	switch (systemId)
	{
		case 1: return trailingByFractals(_period, 4/*bars: 4 or more*/, stopLoss, trailingInLoss);

		default: 
		{
		   _fileLog.Error(StringConcatenate("PSTrailingSL::Trailing Invalid systemId: ", systemId));
		   return false;
		}
	}
	
	return true;
}