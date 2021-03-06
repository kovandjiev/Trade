//+------------------------------------------------------------------+
//|                                                    PSea5_3_2.mq4 |
//|                                   Copyright 2019, PSInvest Corp. |
//|                                          https://www.psinvest.eu |
//+------------------------------------------------------------------+
// Opening order if open signal arrives. Stop loss and Take profit are dippend ATR indicator.
// Lot calculate depend risk and free martin.
#property copyright "Copyright 2019, PS Invest Corp."
#property link      "https://www.PSInvest.eu"
#property version   "5.30"
#property strict

#include <PSSignals.mqh>
#include <PSMarket.mqh>
#include <FileLog.mqh>
#include <stdlib.mqh>

extern int SignalId = 1; // Open signal system Id form 1 to 23
extern int Risk = 1; // Percent of Risk from account
extern double DynSLCoeff = 0.5; // Dynamic Stop loss coefficient 0.1 to 1.0. Default: 0.5
extern double DynTPCoeff = 2.0; // Dynamic Take profit coefficient 1.5 to 3.0 ... Default: 2.0

string _symbol;
int _period;
int _digits;
double _points;
int _magicNumber;
string _commentOrder;
int _lastBarNumber;

CFileLog *_log;
PSSignals* _signals;
PSMarket *_market;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    _symbol = Symbol();
    _period = Period();
    _digits = Digits;
    _points = Point;

    // Max 27
    _commentOrder = StringConcatenate("PSea5_3_2_", _symbol, "_", _period, "_", SignalId);
    string fileName = StringConcatenate(_commentOrder, ".log");

    _log = new CFileLog(fileName, INFO, true, IsOptimization() || IsTesting());

    _signals = new PSSignals(_log, _symbol, _period, SignalId, _digits, _points);

	 _market = new PSMarket(_log, _symbol, _period, _digits, _points);

    if(!_signals.IsInitialised())
    {
        _log.Critical("PSSignals is not initialized!");

        return INIT_FAILED;
    }
    _magicNumber = _signals.GetMagicNumber();

    _lastBarNumber = iBars(_symbol, _period);

    return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    delete _signals;
    delete _market;
    delete _log;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    if(!IsTradeAllowed() || IsTradeContextBusy()) 
    {
        return;
    }

    int currentBarNumber = iBars(_symbol, _period);

    // Process logics only if new bar is arrived.
    if(currentBarNumber == _lastBarNumber)
    {
        return;
    }
    _lastBarNumber = currentBarNumber;

    OpenOrders();
}

bool OpenOrders()
{
    int orderType = _signals.Open();
    if(orderType == OP_NONE)
    {
        return true;      
    }

    double dynValue = _market.GetAtr();
    double dynSL = dynValue * DynSLCoeff;
    double dynTP = dynValue * DynTPCoeff;

    double lot = _market.GetLotPerRisk(Risk, dynSL, orderType);

    bool result = _market.OpenOrder(orderType, lot, dynSL, dynTP, _magicNumber);
    if (IsTesting() && result) {
        _market.DrawVLine(_market.OrderTypeToColor(orderType, true), StringConcatenate(_market.OrderTypeToString(orderType), " open"), STYLE_DASH);
    }
    
    return result;
}